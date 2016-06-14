SELECT * FROM dss.xfer_validation_errors WHERE table_name = 'stg_master_project';

Select * FRom SSE_MASTER_PROJECT_VIEW;

Select * From dss.master_project_master where year = 2016;

Select distinct re_calc_method From dss.master_project_master;

Select * From SSE_MASTER_PROJECT_VIEW v
Where exists (Select 1 from dss.master_project_master 
              where year = 2016
                and master_project = v.mp_project_num
                and status != v.mp_project_status);
                
Select * From dss.master_project_master mp
where mp.year = 2016 
  and mp.status = 'OPEN'
  and exists (select 1 from SSE_MASTER_PROJECT_VIEW v
              where mp.master_project = v.mp_project_num
              and v.mp_project_status = 'APPROVED');
              
SELECT  mp_project_num,
          owning_firm,
          owning_production_office,
          mp_project_status,          
          Decode(mp_project_status, 'APPROVED', 
                    Decode((Select status from dss.master_project_master where year = 2016 and master_project = mp_project_num), 'OPEN', sysdate), 
                  (Select Min(Approval_Date) from dss.master_project_master where master_project = mp_project_num) ) as Approval_Date,
          Case  When (mp_project_status = 'APPROVED' And (Select status from dss.master_project_master where year = 2016 and master_project = mp_project_num) = 'OPEN' )
                  Then sysdate
                Else 
                  (Select Min(Approval_Date) from dss.master_project_master where master_project = mp_project_num)
          End as approval_date1,          
          start_date,
          completion_date,
          Mp_project_subtype,
          Revenue_calculation_method,
          Project_currency_code,
          Override_currency_code,
          city,
          state,
          country,
          Project_management_system_code,
          Project_management_system_code,
          Contract_type,
          Opacc,
          Mp_project_name,
          Ecrm_client,
          jv_client,
          'OA',
          Last_updated_by,
          Last_update_date,
          SYSDATE
  FROM SSE_MASTER_PROJECT_VIEW
  where mp_project_num in (41562, 41561, 41565, 41572, 41573, 41583, 41708);
  
Select Decode(1,1,0,1)
From Dual;

Select * from dss.stg_master_project where state is null;

Select * from dss.xfer_validation_rules where table_name = 'stg_master_project';

Select * from dss.master_project_master
where year = 2016
  and master_project in (41562, 41561, 41565, 41572, 41573, 41583, 41708);