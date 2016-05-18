SELECT * FROM dss.xfer_validation_rules;

SELECT * FROM dss.xfer_validation_rules WHERE table_name = 'stg_master_project_po';
SELECT * FROM dss.xfer_validation_rules WHERE table_name = 'stg_mp_task_mapping';

SELECT * FROM dss.xfer_validation_rules WHERE table_name = 'stg_master_project_po' AND column_name = 'primary key';
DELETE xfer_validation_rules WHERE table_name = 'stg_master_project_po' AND column_name = 'primary key';

SELECT DISTINCT table_name FROM dss.xfer_validation_rules;

DESC dss.xfer_validation_rules;


Insert into DSS.XFER_VALIDATION_RULES (TABLE_NAME,COLUMN_NAME,COL_TYPE,MAX_LENGTH,REQUIRED,INTEGRITY_TABLE,INTEGRITY_COLUMN) 
values ('stg_master_project_po','primary key','unique',0,'N',null,'master_project,production_office,control_date,expiration_date');


DESC user_tables;

INSERT INTO STG_MASTER_PROJECT_PO
  SELECT * FROM (
    SELECt * FROM STG_MASTER_PROJECT_PO
  ) WHERE ROWNUM <= 1;

DESC dss.xfer_validation_errors;

SELECT DISTINCT table_name FROM dss.xfer_validation_errors;

INSERT INTO xfer_validation_errors VALUES ('stg_mp_po', '190425,704,20160407,20500202', 'N', 'primary key is not unique; state has no value;');
DELETE xfer_validation_errors WHERE table_name = 'stg_master_project_po';

SELECT * FROM dss.xfer_validation_errors;

SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project_po';
SELECT count(*) FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project_po';
SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project';
SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_mp_task_mapping';

