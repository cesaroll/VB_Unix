#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_mp_task_mapping_hist 
# 
# Date          Developer       Description
# ===========   =========       ================================================
# 04/18/2016    Cesar L.        Created.
# 05/18/2016    Cesar L.        Getting Master_Project from Tag_the_base_master
# 06/14/2016    Cesar L.        Redesign using merge and Parallelism
#################################################################################

YEAR=$1

if [[ $# -eq 0 ]]; then
. /u/dss/$DSS_MODE/common/bin/get_calendar.com
   YEAR=$C_YEAR
fi


echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " mp_task_mapping history load "
echo "-------------------------------------------------"
echo " "


#Tables

TABLE_NAME=mp_task_mapping_master
TEMP_TABLE=mp_task_mapping_master_tmp
REVPKGSPO_TABLE=promis_revpkgspo
PHASE_REV_TABLE=promis_phase_revenue
TAG_THE_BASE=tag_the_base_master

# Directories
WORK_DIR=/u/dss/$DSS_MODE/project_structure/

# make sure tables are present...
${WORK_DIR}objects/${TABLE_NAME}.tbl
${WORK_DIR}objects/${TEMP_TABLE}.tbl

run_sql <<end_sql

Truncate Table ${TABLE_NAME};
Truncate Table ${TEMP_TABLE};

end_sql


echo " "
echo "-------------------------------------------------"
echo " First Step - Query All Data Into Temprary table "
echo "-------------------------------------------------"
echo " "

#
# Using a cycle to query by year and insert into temp table
# Otherwise we get error with the amount of uncommited data
#

YEAR_INIT=${YEAR}
while (( YEAR >= 2000)) do

  YEAR_INIT=${YEAR}
  
  if [[ YEAR_INIT -eq 2000 ]]; then
   YEAR_INIT=1900
  fi
  
  
  echo " "
  echo " `date` "
  echo "-------------------------------------------------"
  echo " From: ${YEAR_INIT} To: ${YEAR}"
  echo "-------------------------------------------------"
  echo " "
  

run_sql <<end_sql
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

ALTER SESSION ENABLE PARALLEL DML;


Insert  /*+ PARALLEL */
        Into ${TEMP_TABLE}
        (master_project                ,
         production_office             ,
         owning_production_office_flag ,
         firm                          ,
         project                       ,
         task                          ,
         association_date              ,
         disassociation_date           ,
         last_updated_by               ,
         last_update_date)
Select  /*+ PARALLEL */ 
        master_project,
        production_office,
        Decode(subproject, 1, 'Y', 'N') as opof,
        firm,
        project,
        task,
        association_date,
        disassociation_date,
        last_updated_by,
        last_update_date
From
    (Select (Select master_project
             From   (Select distinct tb.year, tb.master_project
                     From ${TAG_THE_BASE} tb
                     Where tb.revenue_package = pr.revenue_package
                       and tb.mp_status != 'U'
                       and tb.year between pr.association_year and pr.disassociation_year
                     Order By tb.year desc)
             Where rownum <= 1) as master_project,
            pr.*,
            NVL((Select production_office
                 From  (Select rp.production_office
                        From   ${REVPKGSPO_TABLE} rp
                        where  rp.revenue_package = pr.revenue_package
                          and  rp.subproject      = pr.subproject
                          and  rp.firm            = pr.firm
                        order by rp.expiration_date desc)
                 Where rownum <= 1), 
                 (Select production_office
                 From  (Select rp.production_office
                        From   ${REVPKGSPO_TABLE} rp
                        where  rp.revenue_package = pr.revenue_package
                          and  rp.firm            = pr.firm
                        order by rp.expiration_date desc)
                 Where rownum <= 1)) as Production_office
    From   (Select revenue_package,
                   subproject,       
                   firm,
                   proj as project,
                   phase as task,       
                   begin_date as association_date,
                   EXTRACT(year from begin_date) as association_year,
                   end_date as disassociation_date,
                   EXTRACT(year from end_date) as disassociation_year,
                   control_id as last_updated_by,
                   control_date as last_update_date
            From ${PHASE_REV_TABLE}
            where  revenue_package is not null
              and  proj is not null
              and  phase is not null
              and  firm is not null
              and  subproject > 0
              and  begin_date is not null
              and  begin_date Between To_Date('${YEAR_INIT}0101','YYYYMMDD') And To_Date('${YEAR}1231','YYYYMMDD')) pr
    ) sq
Where master_project is not null
  and production_office is not null;

end_sql


  
  ((YEAR = YEAR-1))
done


echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " Second Step - Group All Data and Insert Into permanent Table "
echo "-------------------------------------------------"
echo " "


run_sql <<end_sql
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

ALTER SESSION ENABLE PARALLEL DML;

Truncate Table ${TABLE_NAME};

Insert  /*+ PARALLEL */
        Into ${TABLE_NAME}
        (master_project                ,
         production_office             ,
         owning_production_office_flag ,
         firm                          ,
         project                       ,
         task                          ,
         association_date              ,
         disassociation_date           ,
         last_updated_by               ,
         last_update_date              ,
         control_date)
Select  /*+ PARALLEL */ 
        master_project,
        MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
        MIN(owning_production_office_flag) keep (dense_rank last order by last_update_date) as opof,        
        firm,
        project,
        task,
        MIN(association_date) as association_date,
        MAX(disassociation_date) as disassociation_date,
        NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
        NVL(MAX(last_update_date), sysdate) as last_update_date,
        sysdate
From ${TEMP_TABLE}
Group By master_project, project, task, firm;

DROP TABLE ${TEMP_TABLE};

end_sql


echo " "
echo " `date` "
echo " "