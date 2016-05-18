Select * from dss.tag_the_base_master where mp_owner = 'Y';

Select count(*) from dss.tag_the_base_master where mp_owner = 'Y'; -- 1,007,267

Select * from dss.master_project_master where year = 2010;
Select * from dss.master_project_master where owning_production_office = 0;
select count(*) from dss.master_project_master; --1,007,267
Select count(*) from dss.tag_the_base_master where mp_owner = 'Y'; -- 1,007,267

Select count(*) 
from dss.tag_the_base_master tb join dss.revenue_package_2015 rp on tb.master_project = rp.revenue_package
and  tb.year = 2015 and tb.mp_owner = 'Y'; --94,000

Select count(*) 
from dss.tag_the_base_master tb left join dss.revenue_package_2015 rp on 
        tb.master_project = rp.revenue_package
WHERE  tb.year = 2015 
  and tb.mp_owner = 'Y'; -- 94,671


Select * from dss.revenue_package_2015
union all
Select * from dss.revenue_package_2002;

select count(*) from (
Select distinct 
        2002 as year,
        owning_production_office,
        status,        
        project_subtype,
        re_calc_method,        
        NULL AS override_currency,
        'N' AS ecosys_status,
        'N' AS insight_status,
        NULL AS contract_type,
        0 AS opacc,
        revenue_package_name,
        client,
        NULL AS client_type,
        control_id,
        control_date
from dss.revenue_package_2002
union all
Select distinct 
        2003 as year,
        owning_production_office,
        status,        
        project_subtype,
        re_calc_method,        
        NULL AS override_currency,
        'N' AS ecosys_status,
        'N' AS insight_status,
        NULL AS contract_type,
        0 AS opacc,
        revenue_package_name,
        client,
        NULL AS client_type,
        control_id,
        control_date
from dss.revenue_package_2003);

desc dss.revenue_package_2015;

select * from dss.promis_revpkgspo where subproject = 1 and subproject_owner = 'Y' and revenue_package > 0 
and city is not null and state is not null and country is not null;

select * from dss.promis_revpkgspo where subproject = 1 and subproject_owner = 'Y' and revenue_package = 2665;

select revenue_package, --MAX(revision_id) as revision_id, --, city, state, country 
       MIN(city) KEEP (dense_rank last order by revision_id) as city,
       MIN(state) KEEP (dense_rank last order by revision_id) as state,
       MIN(country) KEEP (dense_rank last order by revision_id) as country
from dss.promis_revpkgspo 
where subproject = 1 
  and subproject_owner = 'Y' 
  and revenue_package between 2665 and 2670
Group By revenue_package
;
select city, state, country  from dss.promis_revpkgspo where subproject = 1 and subproject_owner = 'Y' and revenue_package = 2670 order by revision_id desc;

select distinct country from dss.promis_revpkgspo where subproject = 1 and subproject_owner = 'Y';

select * from dss.country;

SELECT DISTINCT
        tb.year,
        tb.master_project,
        NVL(tb.mp_firm, ' '),
        NVL(rp.owning_production_office, 0),
        DECODE(rp.status, null, ' ', 'C', 'CLOSED', 'P', 'PENDING_CLOSE', 'O', 'APPROVED', 'U', 'UNAPPROVED', rp.status) AS status,
        NVL(tb.mp_effective_date,  TO_DATE('01/01/1951', 'MM/DD/YYYY') ) AS approval_date,
        NVL(tb.mp_effective_date,  TO_DATE('01/01/1951', 'MM/DD/YYYY') ) AS open_date,
        NVL(tb.mp_expiration_date, TO_DATE('02/02/2050', 'MM/DD/YYYY') ) AS close_date,
        rp.project_subtype,
        NVL(rp.re_calc_method,  ' '),
        tb.rp_proj_currency,
        rp.override_currency,
        NVL(rpspo.city, ' '),
        NVL(rpspo.state, ' '),
        NVL(rpspo.country, ' '),
        NVL(rp.ecosys_status, 'N'),
        NVL(rp.insight_status, 'N'),
        rp.contract_type,
        NVL(rp.opacc, 0),
        NVL(rp.revenue_package_name, ' '),
        NVL(rp.client, ' '),
        SUBSTR(NVL(rp.client_type, '    '),1,4) AS client_type,                              --TODO: Complicated rule from Pam
        'Promis' AS migration_source,
        NVL(rp.control_id, ' ') AS last_updated_by,
        NVL(rp.control_date, SYSDATE) AS last_updated_date,
        SYSDATE AS control_date
    FROM  dss.tag_the_base_master tb 
          LEFT JOIN (Select revenue_package,
                            MIN(TRIM(city)) KEEP (dense_rank last order by revision_id) as city,
                            MIN(TRIM(state)) KEEP (dense_rank last order by revision_id) as state,
                            MIN(SUBSTR(TRIM(country),1,2)) KEEP (dense_rank last order by revision_id) as country
                     From dss.promis_revpkgspo 
                     Where subproject = 1 
                       and subproject_owner = 'Y' 
                     Group By revenue_package ) rpspo
            ON tb.master_project = rpspo.revenue_package
          LEFT JOIN dss.revenue_package_2015 rp
            ON tb.master_project = rp.revenue_package
    WHERE tb.year = 2015
      AND tb.master_project = tb.revenue_package;
      
      
select * from dss.promis_revpkgspo where revenue_package = 57992;

set linesize 200;
set pagesize 200;
column TABLE_NAME format a30;
column PARTITION_NAME format a30;
SELECT TABLE_NAME,
            PARTITION_NAME ,
            PARTITION_POSITION ,
            HIGH_VALUE
FROM DBA_TAB_PARTITIONS
WHERE
TABLE_NAME='MASTER_PROJECT_MASTER'
ORDER BY PARTITION_POSITION;


