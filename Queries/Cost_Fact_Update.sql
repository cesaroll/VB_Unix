Desc dss.cost_fact;

Select Count(*) from dss.cost_fact; -- 83,363,540

Select Count(*) from dss.cost_fact where CO_EFFECTIVE_DATE >= to_date('01-feb-2016', 'dd-mon-yyyy'); --369, 427

Select * From dss.cost_fact;

select count(*) from dss.top_task_organization; -- 1,522,324

select count(*) from dss.phase_organization; -- 1,532,251

select distinct tt.key_top_task_org, po.KEY_PHASE_ORG
        from dss.top_task_organization tt, dss.phase_organization po
       where tt.tt_project = po.project
         and tt.tt_task    = po.phase
         and tt.tt_task_firm = po.project_firm
         and tt.tt_project  = 176179;

      select  Distinct
              tt.key_top_task_org, 
              po.KEY_PHASE_ORG
        from dss.cost_fact              cf, 
             dss.top_task_organization  tt, 
             dss.phase_organization     po
       where tt.tt_project        = po.project
         and tt.tt_task           = po.phase
         and tt.tt_task_firm      = po.project_firm
         and tt.tt_project        = 176179
         and cf.co_key_phase_org  = po.key_phase_org
         and cf.CO_EFFECTIVE_DATE >= to_date('01-feb-2016', 'dd-mon-yyyy');
         
      for update of cf.co_key_top_task_org;


Merge /*+ first_rows parallel(cost_fact) parallel(top_task_organization) parallel(phase_organization) */

EXPLAIN PLAN
  SET STATEMENT_ID = 'st1' FOR
Merge /*+ parallel(cost_fact) */
Into cost_fact cf
Using (
        select  Distinct
                tt.key_top_task_org, 
                po.key_phase_org
        from top_task_organization  tt, 
             phase_organization     po
        where tt.tt_project         = po.project
          and tt.tt_task            = po.phase
          and tt.tt_task_firm       = po.project_firm          
      ) sq
  ON  (
              cf.co_key_phase_org = key_phase_org
          and cf.co_effective_date Between to_date('01-jan-2015', 'dd-mon-yyyy') and to_date('31-dec-2015', 'dd-mon-yyyy')
      )
When Matched
Then
  Update
    Set
      cf.co_key_top_task_org = sq.key_top_task_org;
      
Select * from dss.cost_fact where co_key_top_task_org is not null;
Select /*+ PARALLEL */ Count(*) from cost_fact where co_key_top_task_org is not null;

Select MIN(co_effective_date), Max(co_effective_date) from cost_fact;
