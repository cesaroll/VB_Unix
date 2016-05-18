Select count(*) from dss.super_revenue_project_master;

Select * from dss.super_revenue_project_master;


Select distinct year, 
       srp_number,
       mp_proj_currency
from dss.tag_the_base_master
Where srp_number > 0;

Select Count(*) from (
Select distinct year, 
       srp_number,
       mp_proj_currency
from dss.tag_the_base_master
Where srp_number = master_project); --15,994

Select Count(*) from (
Select distinct year, 
       srp_number,
       mp_proj_currency
from dss.tag_the_base_master
Where srp_number = master_project and master_project = revenue_package);

Select distinct tb.year, To_date(to_char(year) || '1231', 'YYYYMMDD') last_day,
       tb.srp_number, 
       tb.mp_proj_currency
from dss.tag_the_base_master tb
Where tb.srp_number = 145148 and year = 2007;

Select * from dss.master_project_po_hist
Where master_project = 145148
  and OWNING_PRODUCTION_OFFICE_FLAG = 'Y';

Select master_project, production_office, senior_project_director, project_director, project_manager, effective_date, expiration_date
from dss.master_project_po_hist
Where master_project = 145148
  and owning_production_office_flag = 'Y';

--Select count(*) from (
Select * 
From (Select year, 
             (Select Max(Expiration_date) From dss.standard_week Where year = t.year) as expiration_date,
             srp_number, 
              mp_proj_currency
      From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where srp_number > 0 ) t
      ) tb 
      Left Join
      (Select master_project, 
              production_office, 
              senior_project_director, 
              project_director, 
              project_manager, 
              effective_date, 
              expiration_date
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y') mppo
      ON tb.srp_number = mppo.master_project
        and tb.expiration_date between mppo.effective_date and mppo.expiration_date
--Where master_project is null
Order By Year, srp_number;

Select *
From (Select year, 
             (Select Max(Expiration_date) From dss.standard_week Where year = t.year) as expiration_date,
             srp_number, 
              mp_proj_currency
      From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where srp_number in (122165, 121832, 121859) and year = 2014 ) t
      ) tb 
      Left Join
      (Select master_project, 
              production_office, 
              senior_project_director, 
              project_director, 
              project_manager, 
              effective_date, 
              expiration_date
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y') mppo
      ON tb.srp_number = mppo.master_project
        and tb.expiration_date between mppo.effective_date and mppo.expiration_date
Order By tb.Year, tb.srp_number;

Select year,
       min(Effective_Date),
       Max(Expiration_date)
from dss.standard_week 
group by year
order by year;

Select year, srp_number, mp_proj_currency, count(*) 
From (Select year, 
             (Select Max(Expiration_date) From dss.standard_week Where year = t.year) as expiration_date,
             srp_number, 
              mp_proj_currency
      From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where srp_number > 0 ) t
      ) tb 
      Left Join
      (Select master_project, 
              production_office, 
              senior_project_director, 
              project_director, 
              project_manager, 
              effective_date, 
              expiration_date
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y') mppo
      ON tb.srp_number = mppo.master_project
        and tb.expiration_date between mppo.effective_date and mppo.expiration_date
Group By Year, srp_number, mp_proj_currency
having count(*) > 1;


Select year, 
             (Select Max(Expiration_date) From dss.standard_week Where year = t.year) as expiration_date,
             srp_number, 
              mp_proj_currency
      From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where srp_number = 122165 and year = 2014) t; 


select * 
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y'
        and master_project = 122165
      Order by Production_office, seq;

--Select count(*) from (
Select t1.year,
       t1.srp_number,
       NVL(production_office, 0) as owning_production_office,
       'OPEN' as srp_status,
       mp_proj_currency as project_currency_id,
       To_Date('19550101', 'YYYYMMDD') as open_date,
       To_Date('20500202', 'YYYYMMDD') as close_date,
       NVL(senior_project_director, 0) as senior_project_director,
       NVL(project_director, 0) as project_director,
       NVL(project_manager, 0) as project_manager,
       0 as created_by,
       To_Date('19550101', 'YYYYMMDD') as creation_date,
       country,
       state,
       city,
       NVL(master_project_name, ' ') as srp_name,
       NVL(master_project_name, ' ') as srp_description,
       SUBSTR(NVL(client, ' '), 1, 240) as ecrm_client,
       'MIGRATE' as last_updated_by,
       sysdate as last_update_date,
       sysdate as control_date
From (
  Select year, srp_number, mp_proj_currency,
      (Select MIN(production_office) Keep (dense_rank last order by expiration_date)
       from dss.master_project_po_hist
       Where owning_production_office_flag = 'Y' 
        and master_project = tb.srp_number
        and tb.expiration_date between effective_date and expiration_date) as production_office,
      (Select MIN(senior_project_director) Keep (dense_rank last order by expiration_date)
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y' 
        and master_project = tb.srp_number
        and tb.expiration_date between effective_date and expiration_date) as senior_project_director,
      (Select MIN(project_director) Keep (dense_rank last order by expiration_date)
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y' 
        and master_project = tb.srp_number
        and tb.expiration_date between effective_date and expiration_date) as project_director,
      (Select MIN(project_manager) Keep (dense_rank last order by expiration_date)
      from dss.master_project_po_hist
      Where owning_production_office_flag = 'Y' 
        and master_project = tb.srp_number
        and tb.expiration_date between effective_date and expiration_date) as project_manager
  From (Select year, 
             (Select Max(Expiration_date) From dss.standard_week Where year = t.year) as expiration_date,
             srp_number, 
              mp_proj_currency
      From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where master_project = revenue_package ) t
      ) tb
) t1
Left Join
dss.master_project_master mp
ON mp.year = t1.year and mp.master_project = t1.srp_number
;

Select * From dss.master_project_master
Where year = 2014 and master_project in (121859, 121832, 122165);

Select year, srp_number, count(*)
From (Select distinct year, 
                  srp_number, 
                  mp_proj_currency
            from dss.tag_the_base_master
            Where srp_number = master_project)
Group by year, srp_number
having count(*) > 1
order by year desc, srp_number;

Select *
            from dss.tag_the_base_master
            Where srp_number = 28104 and srp_number = master_project and year = 2015;
            
Select count(*)
from dss.tag_the_base_master
Where srp_number = master_project; --32674

Select * From dss.super_revenue_project_master;

set linesize 200;
set pagesize 200;
column TABLE_NAME format a30;
column PARTITION_NAME format a30;
SELECT TABLE_NAME,
       PARTITION_NAME ,
       PARTITION_POSITION ,
       HIGH_VALUE
FROM DBA_TAB_PARTITIONS
WHERE TABLE_NAME='SUPER_REVENUE_PROJECT_MASTER'
ORDER BY PARTITION_POSITION;

Select * From dss.super_revenue_project_master
where owning_production_office = 0;