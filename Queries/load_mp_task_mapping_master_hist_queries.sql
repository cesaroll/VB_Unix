select count(*) from dss.mp_task_mapping_master; 1,135,172
select * from dss.mp_task_mapping_master;


Select distinct extract(year from association_date) from dss.mp_task_mapping_master order by 1;

Select year, Count(*)
from (Select extract(year from association_date) as year 
      from dss.mp_task_mapping_master) tm
Group by year
order by year;

set linesize 800;
set pagesize 200;
column TABLE_NAME format a30;
column PARTITION_NAME format a30;
SELECT TABLE_NAME,
            PARTITION_NAME ,
            PARTITION_POSITION ,
            HIGH_VALUE
FROM DBA_TAB_PARTITIONS
WHERE
TABLE_NAME='MP_TASK_MAPPING_MASTER2'
ORDER BY PARTITION_POSITION;


select * from dss.mp_task_mapping_master 
where project = 176179;


Select * FRom dss.promis_phase_revenue where proj = 176179;

Select distinct Revenue_package, proj From dss.promis_phase_revenue where proj = 176179;

select * from dss.mp_task_mapping_master 
where project = 176179 and firm = 'BBVL';

Select * FRom dss.promis_phase_revenue where proj = 176179 and firm = 'BBVL';

select count(*) from dss.mp_task_mapping_master;

select revenue_package,           
               MIN(subproject) keep (dense_rank last order by control_date) as subproject,
               DECODE(MIN(subproject) keep (dense_rank last order by control_date), 1, 'Y', 'N') as opo_flag,
               firm,
               proj as project,
               phase as task,       
               MIN(begin_date) as association_date,
               MAX(end_date) as disassociation_date,
               NVL(MIN(control_id) keep (dense_rank last order by control_date), ' ') as last_updated_by,
               NVL(MAX(control_date), sysdate) as last_update_date
        from dss.promis_phase_revenue
        where  revenue_package is not null
          and  proj = 176179
          and  phase is not null
          and  firm is not null
          and  subproject > 0
          and  begin_date is not null
        group by revenue_package, proj, phase, firm;

Select distinct revenue_package from (
select revenue_package,           
               MIN(subproject) keep (dense_rank last order by control_date) as subproject,
               DECODE(MIN(subproject) keep (dense_rank last order by control_date), 1, 'Y', 'N') as opo_flag,
               firm,
               proj as project,
               phase as task,       
               MIN(begin_date) as association_date,
               MAX(end_date) as disassociation_date,
               NVL(MIN(control_id) keep (dense_rank last order by control_date), ' ') as last_updated_by,
               NVL(MAX(control_date), sysdate) as last_update_date
        from dss.promis_phase_revenue
        where  revenue_package is not null
          and  proj = 176179
          and  phase is not null
          and  firm is not null
          and  subproject > 0
          and  begin_date is not null
        group by revenue_package, proj, phase, firm
);

Select * from dss.tag_the_base_master where revenue_package in (176179, 180786, 180775, 179954);
Select * from dss.tag_the_base_master where revenue_package in (176179);

Select  MIN(master_project) keep (dense_rank last order by year) as master_project
from dss.tag_the_base_master where revenue_package = 176179
and year between 2014 and 2050;

Select count(*) from dss.promis_phase_revenue;
Select MIN(proj), MAX(proj) from dss.promis_phase_revenue;
Select Count(*) from dss.promis_phase_revenue where proj >= 500000;
Select Count(*) from dss.promis_phase_revenue where proj >= 176179;

Select revenue_package,
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
    from dss.promis_phase_revenue
    where  revenue_package is not null
      and  proj = 176179 --is not null
      and  phase is not null
      and  firm = 'BBVL'
      and  subproject > 0
      and  begin_date is not null
    order by revenue_package, proj, phase, firm, association_year, disassociation_year;


    
Select master_project
From (Select year, master_project
      From dss.tag_the_base_master
      where revenue_package = 176179
        and year between 2014 and 2050
      order by year desc)
Where rownum <= 1;

DESc dss.promis_revpkgspo;


Select * 
                from (Select production_office 
                      from dss.promis_revpkgspo
                      where revenue_package = 176179
                        --and subproject = 1
                        and firm = 'BBVL'
                      order by expiration_date desc) 
                where rownum <= 1;
                

Select count(*) from dss.mp_task_mapping_master;
Select * from dss.mp_task_mapping_master where master_project = 176179 and firm = 'BBVL';
Select * from dss.mp_task_mapping_master;
Select * from dss.mp_task_mapping_master where firm = 'BBVL';


Select count(*) from dss.mp_task_mapping_master_tmp; -- 5k rows every 20 secs.
Select * from dss.mp_task_mapping_master_tmp;

Select * 
              from dss.promis_revpkgspo
              where revenue_package = 176179
                --and subproject = 1
                --and firm = 'BBVL'
                ;

Select master_project                ,
           MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
           MIN(owning_production_office_flag) keep (dense_rank last order by last_update_date) as opof,
           firm                          ,
           project                       ,
           task                          ,
           MIN(association_date) as association_date,
           MAX(disassociation_date) as disassociation_date,
           NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
           NVL(MAX(last_update_date), sysdate) as last_update_date
    From dss.mp_task_mapping_master_tmp
    Group By master_project, project, task, firm;

SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;
declare
  v_curr_po Number := 0;
  res BOOLEAN := false;
begin  
                
    FOR row IN (
        Select production_office
        from (Select production_office 
              from dss.promis_revpkgspo
              where revenue_package = 176179
                and subproject = 1
                and firm = 'BBVL'
              order by expiration_date desc) 
        where rownum <= 1
      ) LOOP
      
        res   := true;
        v_curr_po  := row.production_office;
        
        exit;
      
      END LOOP;

  DBMS_OUTPUT.PUT_LINE('PO: ' || v_curr_po);

  If res = false Then
      
        FOR row IN (
          Select production_office
          from (Select production_office 
                from dss.promis_revpkgspo
              where revenue_package = 176179
                and firm = 'BBVL'
                order by expiration_date desc) 
          where rownum <= 1
        ) LOOP
        
          res   := true;
          v_curr_po  := row.production_office;
          
          exit;
        
        END LOOP;
      
      End If; 
      
      DBMS_OUTPUT.PUT_LINE('PO: ' || v_curr_po);
  
  If res = false Then
      
        FOR row IN (
          Select production_office
          from (Select production_office 
                from dss.promis_revpkgspo
              where revenue_package = 176179
                order by expiration_date desc) 
          where rownum <= 1
        ) LOOP
        
          res   := true;
          v_curr_po  := row.production_office;
          
          exit;
        
        END LOOP;
      
      End If; 
      
      DBMS_OUTPUT.PUT_LINE('PO: ' || v_curr_po);
  
end;
/


Select * 
                      from dss.promis_revpkgspo
                      where revenue_package = 179954
                      --and subproject = 1
                        and firm = 'BBVL';
                        
Select * 
              from dss.promis_revpkgspo
              where revenue_package = 176179
                --and subproject = 1
                and firm = 'BBVL'
                ;
                
select * from dss.mp_task_mapping_master 
where project = 163108;

Select revenue_package,
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
    from dss.promis_phase_revenue
    where  revenue_package = 163102 -- is not null
      and  proj = 163108
      and  phase is not null
      and  firm is not null
      and  subproject > 0
      and  begin_date is not null
    order by revenue_package, proj, phase, firm, association_year, disassociation_year;
    
Select Distinct year, master_project
From dss.tag_the_base_master
Where Revenue_package = 163102;

Select distinct year, master_project
              From dss.tag_the_base_master
              where revenue_package = 163102
                and year between 2008 and 2050
              order by year desc;

Select master_project
        From (Select distinct year, master_project
              From dss.tag_the_base_master
              where revenue_package = 163102
                and year between 2008 and 2050
              order by year desc)
        Where rownum <= 1;
        
select *
                    from SSE_MP_TASK_MAPPING_VIEW v
                    where v.mp_project_num    = 163102
                      and v.production_office = 921
                      and v.project_num       = 163108
                      and v.task_num          = 0101
                      and v.firm              = '0101';
                      
Select Extract(year from begin_date), count(*)
from dss.promis_phase_revenue 
group by Extract(year from begin_date)
order by 1;


           
Select  master_project,
        MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
        Decode(MIN(subproject) keep (dense_rank last order by last_update_date), 1, 'Y', 'N') as opof,
        firm,
        project,
        task,
        MIN(association_date) as association_date,
        MAX(disassociation_date) as disassociation_date,
        NVL(MAX(last_update_date), sysdate) as last_update_date
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
              and  begin_date is not null) pr
    ) sq
Where master_project is not null
  and production_office is not null
Group By master_project, project, task, firm;

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

Select * from dss.mp_task_mapping_master2;
Select count(*) from dss.mp_task_mapping_master2;


