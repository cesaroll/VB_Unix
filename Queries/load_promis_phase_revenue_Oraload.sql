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
TABLE_NAME='PROMIS_PHASE_REVENUE'
ORDER BY PARTITION_POSITION;

Select Count(*) from dss.promis_phase_revenue;

Select count(*) from dss.tag_the_base_master;



Select distinct revenue_package, master_project
from dss.tag_the_base_master;

Select A.*, B.master_project
From 
(Select revenue_package, master_project, year
from dss.tag_the_base_master
group by revenue_package, master_project, year
order by revenue_package, master_project, year) A,
(Select distinct revenue_package, master_project
from dss.tag_the_base_master
order by revenue_package, master_project) B
Where A.revenue_package = b.revenue_package
  and A.master_project != b.master_project;
