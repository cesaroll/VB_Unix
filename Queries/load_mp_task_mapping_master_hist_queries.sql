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
Select MIN(proj), MAX(proj) from dss.promis_phase_revenue;
Select Count(*) from dss.promis_phase_revenue where proj >= 500000;
Select Count(*) from dss.promis_phase_revenue where proj >= 176179;

Select revenue_package,
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
    from dss.promis_phase_revenue
    where  revenue_package is not null
      and  proj = 176179 --is not null
      and  phase is not null
      and  firm is not null
      and  subproject > 0
      and  begin_date is not null
    order by revenue_package, proj, phase, firm, association_year, disassociation_year;


    
Select master_project
From (Select year, master_project
      From dss.tag_the_base_master
      where revenue_package = 176179
        and year between 2012 and 2013
      order by year desc)
Where rownum <= 1;

DESc dss.promis_revpkgspo;


Select * 
                from (Select production_office 
                      from dss.promis_revpkgspo
                      where revenue_package = 176179
                        and subproject = 1
                        and firm = 'BVCOR'
                      order by expiration_date desc) 
                where rownum <= 1;
                
Select * from dss.mp_task_mapping_master_new;
Select * from dss.mp_task_mapping_master_new where task = 8521;
Select count(*) from dss.mp_task_mapping_master_new;
Select count(*) from dss.mp_task_mapping_master;

Select count(*) from dss.mp_task_mapping_master_tmp; -- Insert at count: 175478 Elapsed time: 6674
Select count(*) from dss.mp_task_mapping_master_tmp_bkp;
Select * from dss.mp_task_mapping_master_tmp;

Select production_office 
              from dss.promis_revpkgspo
              where revenue_package = 176179
                --and subproject = 1
                and firm = 'CCEDC';
                
Select master_project                ,
           MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
           MIN(owning_production_office_flag) keep (dense_rank last order by last_update_date) as opof,
           firm                          ,
           project                       ,
           task                          ,
           MIN(association_date)         ,
           MAX(disassociation_date)      ,
           NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
           NVL(MAX(last_update_date), sysdate) as last_update_date
    From dss.mp_task_mapping_master_tmp
    Group By master_project, project, task, firm
    Order by master_project, project, task, firm;
