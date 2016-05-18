Select count(*) from dss.srp_detail_master;

Select * from dss.srp_detail_master;

Select count(*) from dss.tag_the_base_master Where srp_number > 0 and master_project = revenue_package; --23,130 --1,024,485

Select year, srp_number, master_project, revenue_package, mp_proj_currency
from dss.tag_the_base_master
Where srp_number > 0
Order By Year desc, srp_number, master_project, revenue_package;

Select *
from dss.tag_the_base_master
Where srp_number > 0
Order By Year desc, srp_number, master_project, revenue_package;

Select year, master_project, count(*)
from dss.tag_the_base_master
Where srp_number > 0 and master_project = revenue_package
Group By year, master_project
Having count(*) > 1;

Select year, srp_number, master_project, revenue_package, mp_proj_currency
from dss.tag_the_base_master
Where year = 2015 and master_project = 144292
Order By Year desc, srp_number, master_project, revenue_package;