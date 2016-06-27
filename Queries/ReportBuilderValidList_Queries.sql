Select * from dss.web_valid_list_types;

desc dss.web_valid_list_types;

var out_debug varchar2;
var out_cursor refcursor;
exec dss.ws_get_cesartest('CostReportMPSupplierSearch','175721,175722', ' ', :out_debug, :out_cursor);
print :out_debug;
print :out_cursor;

EXPLAIN PLAN
  SET STATEMENT_ID = 'st1' FOR
select /*+ PARALLEL */
    distinct co_supplier_number as valid_list_id, co_supplier_name as valid_list_desc, 
'' as valid_list_desc2 from dss.co_top_task_organization t, dss.cost_fact f, dss.co_supplier s 
where co_tt_master_project in (175721,175722) 
and t.co_key_top_task_org = f.co_key_top_task_org 
and f.co_key_supplier = s.co_key_supplier 
and f.co_key_supplier > 0;

Select Count(*)
from (
select /*+ PARALLEL */
    distinct co_supplier_number as valid_list_id, co_supplier_name as valid_list_desc, 
'' as valid_list_desc2 from dss.co_top_task_organization t, dss.cost_fact f, dss.co_supplier s 
where co_tt_master_project in (175722) 
and t.co_key_top_task_org = f.co_key_top_task_org 
and f.co_key_supplier = s.co_key_supplier 
and f.co_key_supplier > 0);


Select CO_KEY_TOP_TASK_ORG, CO_TT_MASTER_PROJECT from co_top_task_organization where co_tt_master_project in (175721,175722);

Select CO_KEY_TOP_TASK_ORG, CO_TT_MASTER_PROJECT from co_top_task_organization where co_tt_master_project in (select * from THE (select cast(StringToNumberTable('175721,175722') as NumberTableType)  from dual ));

desc dss.co_supplier; --697,428
desc dss.cost_fact; -- 83,363,540
desc dss.co_top_task_organization; --1,522,330

SELECT table_name 
FROM all_tab_columns 
WHERE OWNER = 'DSS'
  AND column_name like '%KEY%TASK%';
  
SELECT OWNER, TABLE_NAME, TABLESPACE_NAME
FROM ALL_TABLES
WHERE OWNER = 'DSS'
  AND TABLE_NAME LIKE '%TASK%';
  

select *
from dss.web_valid_list_types
where valid_type = 'CostReportMPSupplierSearch_2';

Insert into WEB_VALID_LIST_TYPES (VALID_TYPE,VALID_TYPE_ID_HEADER,VALID_TYPE_DESC_HEADER,VALID_TYPE_DESC_HEADER_2,VALID_TYPE_SQL,VALID_TYPE_NBR_COLUMNS,VALID_TYPE_SELECT_MULT,CONTROL_ID,CONTROL_DATE) values ('CostReportMPSupplierSearch_2','Supplier ID','Supplier','NA','select distinct co_supplier_number as valid_list_id, co_supplier_name as valid_list_desc, '''' as valid_list_desc2 from dss.co_top_task_organization t, dss.cost_fact f, dss.co_supplier s where co_tt_master_project in (select * from THE (select cast(StringToNumberTable(:PARAM_1) as NumberTableType)  from dual )) and t.co_key_top_task_org = f.co_key_top_task_org and f.co_key_supplier = s.co_key_supplier and f.co_key_supplier > 0',2,'Y','lop83554',sysdate);
