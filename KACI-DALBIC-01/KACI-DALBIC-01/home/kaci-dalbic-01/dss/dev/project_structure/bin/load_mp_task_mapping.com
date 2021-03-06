#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_mp_task_mapping
#
# Date          Developer       Description
# ===========   =========       ================================================
# 04/22/2016    Cesar L.        Load MP_TASK_MAPPING_MASTER table
#                               from SSE_MP_TASK_MAPPING_VIEW
# 06/14/2016    Cesar L.        Redesign using merge and Parallelism.
#################################################################################

YEAR=$1

if [[ $# -eq 0 ]]; then
. /u/dss/$DSS_MODE/common/bin/get_calendar.com
   YEAR=$C_YEAR
fi

echo
echo  `date`
echo --------------------
echo "Loading MP Task Mapping ${YEAR} data"
echo --------------------
echo

# Directories
#
WORK_DIR=/u/dss/$DSS_MODE/project_structure/

#
# Tables
#
BASE_NAME=mp_task_mapping
TABLE_NAME=mp_task_mapping_master
STAGE_TABLE=stg_${BASE_NAME}

# make sure tables are present...
${WORK_DIR}objects/${STAGE_TABLE}.tbl            >> $LOG
${WORK_DIR}objects/${TABLE_NAME}.tbl             >> $LOG
${WORK_DIR}objects/${BASE_NAME}.view $YEAR        >> $LOG
${WORK_DIR}objects/${BASE_NAME}_yyyy.view $YEAR   >> $LOG

#* ****************************************************************** *
#*                 Staging Table Load                                 *
#* ****************************************************************** *

echo " "
echo " Staging Load"
echo " "

DIS_DTE='02022050'

run_sql <<-END_SQL >>${LOG} 2>&1
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

ALTER SESSION ENABLE PARALLEL DML;

TRUNCATE TABLE ${STAGE_TABLE};

  /* ****************************************************************** */
  /*                    Insert into Stagging table                      */
  /* ****************************************************************** */
  
  Insert /*+ PARALLEL */
        Into ${STAGE_TABLE}
        (master_project               ,
         production_office            ,
         owning_production_office_flag,
         firm                         ,
         project                      ,
         task                         ,
         association_date             ,
         disassociation_date          ,
         last_updated_by              ,
         last_update_date             ,
         control_date)
  select /*+ PARALLEL */ 
         tmv.master_project,
         tmv.production_office,
         NVL(tm.owning_production_office_flag, tmv.opo_flag) as opo_flag,
         tmv.firm,
         tmv.project,
         tmv.task,
         Decode(tm.master_project, null, sysdate, tm.association_date) as association_date,             
         To_Date('${DIS_DTE}', 'MMDDYYYY') as disassociation_date,
         tmv.last_updated_by,
         tmv.last_update_date,
         sysdate
  From (select mp_project_num as master_project,
              production_office,
              MIN(owning_production_office_flag) KEEP (Dense_Rank Last Order By last_update_date) as  opo_flag,
              firm,
              project_num as project,
              task_num as task,                                    
              MIN(last_updated_by) KEEP (Dense_Rank Last Order By last_update_date) as  last_updated_by,
              MAX(last_update_date) as last_update_date
       from SSE_MP_TASK_MAPPING_VIEW
       group by mp_project_num, production_office, project_num, task_num, firm) tmv
       Left Join
       ${TABLE_NAME} tm 
       on
              tmv.master_project       = tm.master_project
          and tmv.production_office    = tm.production_office
          and tmv.project              = tm.project
          and tmv.task                 = tm.task
          and tmv.firm                 = tm.firm
  Where tm.master_project is Null
    Or  Decode(tm.disassociation_date, To_Date('${DIS_DTE}', 'MMDDYYYY'), 0, 1) = 1
    Or  Decode(tm.owning_production_office_flag, tmv.opo_flag, 0, 1 ) = 1;           
  
  Commit;
     

  /* ****************************************************************** */
  /*                      Staging Validation                            */
  /* ****************************************************************** */

  DELETE FROM xfer_validation_errors WHERE table_name = '${STAGE_TABLE}';
  COMMIT;

  exec xfer_validation('${STAGE_TABLE}', ${YEAR});

  INSERT INTO xfer_validation_errors
  SELECT '${STAGE_TABLE}',
         master_project || ',' || production_office || ',' || project || ',' || task || ',' || firm || ',' ||
         ROW_NUMBER() OVER (PARTITION BY master_project,production_office,project,task,firm  ORDER BY master_project,production_office,project,task,firm) AS pk,
         valid,
         validation_result
    FROM ${STAGE_TABLE}
   WHERE valid = 'N';

  DELETE FROM ${STAGE_TABLE}
  WHERE valid = 'N';

  Commit;
  
END_SQL


#* ****************************************************************** *
#*                Enddate non existing records                        *
#* ****************************************************************** *


echo " "
echo "Starting End Date Process"
echo " "

run_sql <<-END_SQL >>${LOG} 2>&1

ALTER SESSION ENABLE PARALLEL DML;

  UPDATE /*+ PARALLEL */
         ${TABLE_NAME} t
    SET  disassociation_date = sysdate-1,
         last_updated_by     = 'System',
         last_update_date    = SYSDATE
  WHERE disassociation_date >= sysdate
    AND NOT EXISTS (select 1
                    from SSE_MP_TASK_MAPPING_VIEW v
                    where v.mp_project_num    = t.master_project
                      and v.production_office = t.production_office
                      and v.project_num       = t.project
                      and v.task_num          = t.task
                      and v.firm              = t.firm);

END_SQL

#* ****************************************************************** *
#*                   Merge staging  records                           *
#* ****************************************************************** *

echo " "
echo "Starting Merge"
echo " "

run_sql <<-END_SQL >>${LOG} 2>&1

ALTER SESSION ENABLE PARALLEL DML;

  MERGE /*+ PARALLEL */
        INTO ${TABLE_NAME} t
  USING (
        SELECT /*+ PARALLEL */
               DISTINCT
               master_project               ,
               production_office            ,
               owning_production_office_flag,
               firm                         ,
               project                      ,
               task                         ,
               association_date             ,
               disassociation_date          ,
               last_updated_by              ,
               last_update_date             ,
               control_date
        FROM ${STAGE_TABLE}
        ) s
    ON  (
              t.master_project    = s.master_project
          AND t.production_office = s.production_office
          AND t.project           = s.project
          AND t.task              = s.task
          AND t.firm              = s.firm
        )
  WHEN MATCHED
  THEN
    UPDATE /*+ PARALLEL */
      SET t.owning_production_office_flag = s.owning_production_office_flag,
          t.association_date              = s.association_date             ,
          t.disassociation_date           = s.disassociation_date          ,
          t.last_updated_by               = s.last_updated_by              ,
          t.last_update_date              = s.last_update_date             ,
          t.control_date                  = sysdate
    WHERE
          Decode(t.owning_production_office_flag, s.owning_production_office_flag, 0, 1) = 1
      OR  Decode(t.association_date             , s.association_date             , 0, 1) = 1
      OR  Decode(t.disassociation_date          , s.disassociation_date          , 0, 1) = 1
      OR  Decode(t.last_updated_by              , s.last_updated_by              , 0, 1) = 1
      OR  Decode(t.last_update_date             , s.last_update_date             , 0, 1) = 1
  WHEN NOT MATCHED
  THEN
    INSERT  /*+ PARALLEL */
          ( t.master_project               ,
            t.production_office            ,
            t.owning_production_office_flag,
            t.firm                         ,
            t.project                      ,
            t.task                         ,
            t.association_date             ,
            t.disassociation_date          ,
            t.last_updated_by              ,
            t.last_update_date             ,
            t.control_date
          )
    VALUES  (
            s.master_project               ,
            s.production_office            ,
            s.owning_production_office_flag,
            s.firm                         ,
            s.project                      ,
            s.task                         ,
            s.association_date             ,
            s.disassociation_date          ,
            s.last_updated_by              ,
            s.last_update_date             ,
            sysdate
          );

END_SQL

$UPDATE_STATS ${TABLE_NAME}

echo
echo  `date`
echo
