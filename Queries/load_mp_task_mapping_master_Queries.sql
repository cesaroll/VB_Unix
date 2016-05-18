select * from dss.mgt_organization;

desc dss.mgt_organization;

SELECT OWNER, TABLE_NAME, TABLESPACE_NAME
FROM ALL_TABLES
WHERE OWNER = 'DSS'
  AND TABLE_NAME LIKE '%PROJECT%';
  


desc dss.project_master;

select count(*) from SSE_MP_Task_Mapping_VIEW; 612,146
select * from SSE_MP_Task_Mapping_VIEW;


select mp_project_num as master_project,
       production_office,
       project_num as project,
       task_num as task,
       firm,
       owning_production_office_flag,
       last_updated_by,
       last_update_date
from SSE_MP_Task_Mapping_VIEW;

select mp_project_num as master_project,
       production_office,
       project_num as project,
       task_num as task,
       firm,
       owning_production_office_flag,
       last_updated_by,
       last_update_date
from SSE_MP_Task_Mapping_VIEW
where mp_project_num = 102231
order by mp_project_num, production_office, project_num, task_num, firm;

select * from dss.mp_task_mapping_master where master_project = 102231
order by master_project, production_office, project, task, firm;



select mp_project_num as master_project,
       production_office,
       project_num as project,
       task_num as task,
       firm,
       MIN(owning_production_office_flag) KEEP (Dense_Rank Last Order By last_update_date) as  opo_flag,
       MIN(last_updated_by) KEEP (Dense_Rank Last Order By last_update_date) as  last_updated_by,
       MAX(last_update_date)
from SSE_MP_Task_Mapping_VIEW
where mp_project_num = 102231
group by mp_project_num, production_office, project_num, task_num, firm;

Select count(*) from dss.stg_mp_task_mapping;--12,427
Select * from dss.stg_mp_task_mapping;
Select * from dss.stg_mp_task_mapping where valid is not null;

select count(*) from dss.mp_task_mapping_master t --599,697
Where exists (select 1 
    from SSE_MP_TASK_MAPPING_VIEW
    where mp_project_num = t.master_project
      and production_office = t.production_office
      and project_num = t.project
      and task_num = t.task
      and firm = t.firm)
  and disassociation_date >= TO_DATE('02/02/2050', 'MM/DD/YYYY');

select count(*) from SSE_MP_Task_Mapping_VIEW --22
where mp_project_num <= 0
      or production_office <= 0
      or project_num <= 0
      or task_num is null
      or firm is null;
      
select * from SSE_MP_Task_Mapping_VIEW --22
where mp_project_num <= 0
      or production_office <= 0
      or project_num <= 0
      or task_num is null
      or firm is null;
      
Select * from dss.project_master;

SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_mp_task_mapping';

SELECT count(*), validation_result 
FROM dss.xfer_validation_errors 
WHERE table_name = 'stg_mp_task_mapping'
group by validation_result
order by 1;


-- To end date non-existing records
select count(*) from dss.mp_task_mapping_master t
Where not exists (select 1 
    from SSE_MP_TASK_MAPPING_VIEW
    where mp_project_num = t.master_project
      and production_office = t.production_office
      and project_num = t.project
      and task_num = t.task
      and firm = t.firm)
  and disassociation_date >= sysdate;
  
select * from dss.mp_task_mapping_master t
Where not exists (select 1 
    from SSE_MP_TASK_MAPPING_VIEW
    where mp_project_num = t.master_project
      and production_office = t.production_office
      and project_num = t.project
      and task_num = t.task
      and firm = t.firm)
  and disassociation_date >= sysdate;

select *
    from SSE_MP_TASK_MAPPING_VIEW
    where mp_project_num = 17447;
      and production_office = 237
      and project_num = 17442
      and task_num = '0470'
      and firm = 'BVP';
      
select count(*) from dss.mp_task_mapping_master where last_updated_by     = 'MIGRATE';
select * from dss.mp_task_mapping_master where last_updated_by     = 'MIGRATE';

