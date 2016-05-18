select count(*) from dss.mp_task_mapping_master; 1,135,172
select * from dss.mp_task_mapping_master;


Select distinct extract(year from association_date) from dss.mp_task_mapping_master order by 1;

Select year, Count(*)
from (Select extract(year from association_date) as year 
      from dss.mp_task_mapping_master) tm
Group by year
order by year;

set linesize 800;
set pagesize 200;
column TABLE_NAME format a30;
column PARTITION_NAME format a30;
SELECT TABLE_NAME,
            PARTITION_NAME ,
            PARTITION_POSITION ,
            HIGH_VALUE
FROM DBA_TAB_PARTITIONS
WHERE
TABLE_NAME='MP_TASK_MAPPING_MASTER'
ORDER BY PARTITION_POSITION;


select * from dss.mp_task_mapping_master 
where project = 176179;


Select * FRom dss.promis_phase_revenue where proj = 176179;

Select distinct Revenue_package, proj From dss.promis_phase_revenue where proj = 176179;

select * from dss.mp_task_mapping_master 
where project = 176179 and firm = 'BBVL';

Select * FRom dss.promis_phase_revenue where proj = 176179 and firm = 'BBVL';

select count(*) from dss.mp_task_mapping_master;

select revenue_package,           
               MIN(subproject) keep (dense_rank last order by control_date) as subproject,
               DECODE(MIN(subproject) keep (dense_rank last order by control_date), 1, 'Y', 'N') as opo_flag,
               firm,
               proj as project,
               phase as task,       
               MIN(begin_date) as association_date,
               MAX(end_date) as disassociation_date,
               NVL(MIN(control_id) keep (dense_rank last order by control_date), ' ') as last_updated_by,
               NVL(MAX(control_date), sysdate) as last_update_date
        from dss.promis_phase_revenue
        where  revenue_package is not null
          and  proj = 176179
          and  phase is not null
          and  firm is not null
          and  subproject > 0
          and  begin_date is not null
        group by revenue_package, proj, phase, firm;

Select distinct revenue_package from (
select revenue_package,           
               MIN(subproject) keep (dense_rank last order by control_date) as subproject,
               DECODE(MIN(subproject) keep (dense_rank last order by control_date), 1, 'Y', 'N') as opo_flag,
               firm,
               proj as project,
               phase as task,       
               MIN(begin_date) as association_date,
               MAX(end_date) as disassociation_date,
               NVL(MIN(control_id) keep (dense_rank last order by control_date), ' ') as last_updated_by,
               NVL(MAX(control_date), sysdate) as last_update_date
        from dss.promis_phase_revenue
        where  revenue_package is not null
          and  proj = 176179
          and  phase is not null
          and  firm is not null
          and  subproject > 0
          and  begin_date is not null
        group by revenue_package, proj, phase, firm
);

Select * from dss.tag_the_base_master where revenue_package in (176179, 180786, 180775, 179954);
Select * from dss.tag_the_base_master where revenue_package in (176179);

Select  MIN(master_project) keep (dense_rank last order by year) as master_project
from dss.tag_the_base_master where revenue_package = 176179
and year between 2014 and 2050;

Select count(*) from dss.promis_phase_revenue;
