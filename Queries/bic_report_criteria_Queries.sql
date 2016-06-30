select --* 
      distinct name, type, criteria_id, creator_id
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 15100)
       OR type = 'shared')
order by type, name;

select * 
      --distinct name, type, criteria_id, creator_id
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 0)
       OR type = 'shared')
order by type, name;

Select distinct name, type, criteria_id, creator_id from dss.bic_report_criteria where type = 'user' and creator_id = 0;

Select * From dss.bic_report_criteria
Where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 15100)
       OR type = 'shared');

Select REPLACE(REPLACE(name, '<' , ''), '>', '') as name, type
from (
select distinct name, type 
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 15100)
       OR type = 'shared')
order by type, name
);

select count(* )
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and type = 'shared';

 --and creator_id = " & CStr(lCustomerNumber) & ")" 
 --           "        or (type = 'shared') )" & _


Select * from dss.bic_report_criteria
where form_id = 'REPORT_COST_DETAIL'
  and creator_id > 0 and type = 'user';

select Name, Type,  
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and type IN ( 'shared', 'user')
group by Name, Type
order by type, name;

desc dss.bic_report_criteria;

select *
from dss.bic_report_criteria 
where form_id = 'WEB_REPORT_COST_DETAIL'
order by Creator_id, Name;

select --*
      distinct name, type, criteria_id, creator_id
from dss.bic_report_criteria 
where form_id = 'WEB_REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 0)
       OR type = 'shared')
order by type, name;

select --*
      distinct name, type, criteria_id, creator_id
from dss.bic_report_criteria 
where form_id = 'WEB_REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 83554)
       OR type = 'shared')
order by type, name;

select form_id, name, creator_id, criteria_id, type,
        Min(Key_Name) Keep (dense_rank last order by control_date) as Key_Name,
        Min(Key_Value) Keep (dense_rank last order by control_date) as Key_Value,
        Max(Control_Date) as Control_Date
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 0)
       OR type = 'shared')
Group By form_id, name, creator_id, criteria_id, type
order by type, name;

Select max(Criteria_Id) from dss.bic_report_criteria;
