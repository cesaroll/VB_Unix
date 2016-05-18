Select * From SSE_SRP_DETAIL_VIEW;

Select count(*) From SSE_SRP_DETAIL_VIEW; --476

Select srp_number,
       mp_project_num as master_project,
       effective_date as association_date,
       To_Date('20500202', 'YYYYMMDD') as disassociation_date,
       last_updated_by,
       last_update_date,
       sysdate as control_date
From SSE_SRP_DETAIL_VIEW;

Select * From dss.stg_srp_detail;

Select * From dss.stg_srp_detail where valid is not null;

--INSERT INTO xfer_validation_errors
SELECT 'stg_srp_detail', 
         master_project || ',' ||
         ROW_NUMBER() OVER (PARTITION BY master_project ORDER BY master_project ) AS pk, 
         valid, 
         validation_result
    FROM dss.stg_srp_detail
   WHERE valid = 'N';
   
Select * FROM dss.xfer_validation_errors WHERE table_name = 'stg_srp_detail';
   
Select count(*) from dss.srp_detail_master;
Select * from dss.srp_detail_master;

Select count(*) from dss.srp_detail_master where year = 2016;
Select * from dss.srp_detail_master where year = 2016;