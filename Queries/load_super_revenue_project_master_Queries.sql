Select * From SSE_SRP_VIEW;

Select count(*) From SSE_SRP_VIEW; --171

desc SSE_SRP_VIEW;

Select * From dss.super_revenue_project_master where year = 2016;

Select srp_number,
       owning_production_office,
       project_status,
       project_currency_code,
       active_date,
       inactive_date,
       senior_project_director,
       project_director,
       project_manager,
       created_by,
       creation_date,
       country,
       state,
       Substr(city, 1, 60),
       long_name,
       description,
       ecrm_client,
       last_updated_by,
       last_update_date,
       sysdate
From SSE_SRP_VIEW;

Select * from dss.stg_super_revenue_project;
       
SELECT OWNER, TABLE_NAME, TABLESPACE_NAME
FROM ALL_TABLES
WHERE OWNER = 'DSS'
  AND TABLE_NAME LIKE '%CURRENCY%';

Select * FRom dss.OBIEE_ALL_CURRENCIES;

Desc dss.people;

Select * from dss.xfer_validation_rules where table_name = 'stg_super_revenue_project';

Select * from dss.super_revenue_project;