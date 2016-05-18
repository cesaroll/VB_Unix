#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_mp_task_mapping_hist 
# 
# Date          Developer       Description
# ===========   =========       ================================================
# 04/18/2016    Cesar L.        Created.
# 05/18/2016    Cesar L.        Getting Master_Project from Tag_the_base_master
#################################################################################

echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " Populating mp_task_mapping history data "
echo "-------------------------------------------------"
echo " "

TABLE_NAME=mp_task_mapping_master
REVPKGSPO_TABLE=promis_revpkgspo
PHASE_REV_TABLE=promis_phase_revenue
TAG_THE_BASE=tag_the_base_master

run_sql <<end_sql
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

TRUNCATE TABLE ${TABLE_NAME};

DECLARE  
  
  v_start_time      NUMBER;  
  v_end_time        NUMBER;

BEGIN
  
  v_start_time := DBMS_UTILITY.get_time;
  
  Insert Into ${TABLE_NAME}
   (
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
   )
  Select master_project,
         production_office,
         opo_flag,
         firm,
         project,
         task,
         association_date,
         disassociation_date,
         last_updated_by,
         last_update_date,
         sysdate
  From (
    Select pr.*,
           NVL((Select * 
                from (Select production_office 
                      from ${REVPKGSPO_TABLE} 
                      where revenue_package = pr.master_project
                        and subproject = pr.subproject
                        and firm = pr.firm
                      order by expiration_date desc) 
                where rownum <= 1 ),
               (Select * 
                from (Select production_office 
                      from ${REVPKGSPO_TABLE} 
                      where revenue_package = pr.master_project
                        and firm = pr.firm
                      order by expiration_date desc) 
                where rownum <= 1 ) 
              ) as production_office
    From (
        Select master_project,           
               MIN(subproject) keep (dense_rank last order by last_update_date) as subproject,
               DECODE(MIN(subproject) keep (dense_rank last order by last_update_date), 1, 'Y', 'N') as opo_flag,
               firm,
               project,
               task,       
               MIN(association_date) as association_date,
               MAX(disassociation_date) as disassociation_date,
               NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
               NVL(MAX(last_update_date), sysdate) as last_update_date
        From (               
              select (Select  MIN(tb.master_project) keep (dense_rank last order by year) 
                      from ${TAG_THE_BASE} tb 
                      where tb.revenue_package = ppr.revenue_package
                        and year between EXTRACT(year from begin_date) and EXTRACT(year from end_date) ) as master_project,
                     subproject,       
                     firm,
                     proj as project,
                     phase as task,       
                     begin_date as association_date,
                     end_date as disassociation_date,
                     control_id as last_updated_by,
                     control_date as last_update_date
              from ${PHASE_REV_TABLE} ppr
              where  revenue_package is not null
                and  proj is not null
                and  phase is not null
                and  firm is not null
                and  subproject > 0
                and  begin_date is not null) 
        Where master_project is not null
        Group by master_project, project, task, firm ) pr
  )
  Where production_office is not null;
  
END;
/

end_sql

echo " "
echo " `date` "
echo " "

