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
