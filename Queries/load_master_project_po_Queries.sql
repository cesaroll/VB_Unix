SELECT COUNT(*) FROM sse_mp_prod_office_view;
Select * from sse_mp_prod_office_view;

desc sse_mp_prod_office_view;

SELECT * FROM dss.stg_master_project_po; --77

SELECT * FROM dss.stg_master_project_po 
WHERE (master_project, production_office) 
IN (SELECT master_project, production_office
FROM dss.stg_master_project_po
GROUP BY master_project, production_office
HAVING COUNT(*) > 1);

SELECT  stg.*, 
        ROW_NUMBER() OVER (PARTITION BY stg.master_project, stg.production_office ORDER BY stg.master_project, stg.production_office) AS dup_id
FROM dss.stg_master_project_po stg
WHERE (stg.master_project, stg.production_office) 
IN (SELECT master_project, production_office
FROM dss.stg_master_project_po
GROUP BY master_project, production_office
HAVING COUNT(*) > 1);

SELECT COUNT(*)
FROM dss.stg_master_project_po
GROUP BY master_project, production_office
HAVING COUNT(*) > 1;

SELECT  stg.*, 
        ROW_NUMBER() OVER (PARTITION BY stg.master_project, stg.production_office ORDER BY stg.master_project, stg.production_office) AS dup_id
FROM dss.stg_master_project_po stg;


--INSERT INTO xfer_validation_errors
  SELECT 'stg_master_project_po', 
         master_project || ',' || production_office || ',' || TO_CHAR(control_date, 'YYYYMMDD') || ',' || TO_CHAR(expiration_date, 'YYYYMMDD') || ',' ||
         ROW_NUMBER() OVER (PARTITION BY master_project,production_office,control_date,expiration_date  ORDER BY master_project,production_office,control_date,expiration_date) AS pk,
         valid, 
         validation_result
    FROM dss.stg_master_project_po
   WHERE valid = 'N';

SELECt DISTINCT production_office FROM dss.stg_master_project_po ORDEr BY production_office;

SELECt * FROM dss.mgt_organization;

SELECT DISTINCT org_item_head FROM dss.mgt_organization
WHERE ORG_ITEM_HEAD IN (SELECt DISTINCT production_office FROM dss.stg_master_project_po);

SELECT DISTINCT org_item_num FROM dss.mgt_organization
WHERE org_item_num IN (SELECt DISTINCT production_office FROM dss.stg_master_project_po);

SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project_po';
select count(*) FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project_po';
SELECT distinct validation_result FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project_po';

SELECT DISTINCT table_name FROM dss.xfer_validation_errors;

