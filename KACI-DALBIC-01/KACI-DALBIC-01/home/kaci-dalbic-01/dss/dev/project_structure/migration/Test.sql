EXPLAIN PLAN
  SET STATEMENT_ID = 'st1' FOR
Insert  /*+ PARALLEL */
        Into dss.mp_task_mapping_master2
        (master_project                ,
         production_office             ,
         owning_production_office_flag ,
         firm                          ,
         project                       ,
         task                          ,
         association_date              ,
         disassociation_date           ,
         last_updated_by               ,
         last_update_date              ,
         control_date)
Select  /*+ PARALLEL */
        master_project,
        MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
        Decode(MIN(subproject) keep (dense_rank last order by last_update_date), 1, 'Y', 'N') as opof,
        firm,
        project,
        task,
        MIN(association_date) as association_date,
        MAX(disassociation_date) as disassociation_date,
        NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
        NVL(MAX(last_update_date), sysdate) as last_update_date,
        sysdate
From 
    (Select (Select master_project
             From   (Select distinct tb.year, tb.master_project
                     From dss.tag_the_base_master tb
                     Where tb.revenue_package = pr.revenue_package
                       and tb.year between pr.association_year and pr.disassociation_year
                     Order By tb.year desc)
             Where rownum <= 1) as master_project,
            pr.*,
            NVL((Select production_office
                 From  (Select rp.production_office
                        From   dss.promis_revpkgspo rp
                        where  rp.revenue_package = pr.revenue_package
                          and  rp.subproject      = pr.subproject
                          and  rp.firm            = pr.firm
                        order by rp.expiration_date desc)
                 Where rownum <= 1), 
                 (Select production_office
                 From  (Select rp.production_office
                        From   dss.promis_revpkgspo rp
                        where  rp.revenue_package = pr.revenue_package
                          and  rp.firm            = pr.firm
                        order by rp.expiration_date desc)
                 Where rownum <= 1)) as Production_office
    From   (Select revenue_package,
                   subproject,       
                   firm,
                   proj as project,
                   phase as task,       
                   begin_date as association_date,
                   EXTRACT(year from begin_date) as association_year,
                   end_date as disassociation_date,
                   EXTRACT(year from end_date) as disassociation_year,
                   control_id as last_updated_by,
                   control_date as last_update_date
            From dss.promis_phase_revenue
            where  revenue_package is not null
              and  proj is not null
              and  phase is not null
              and  firm is not null
              and  subproject > 0
              and  begin_date is not null
              and  begin_date >= To_Date('20160101','YYYYMMDD')) pr
    ) sq
Where master_project is not null
  and production_office is not null
Group By master_project, project, task, firm;