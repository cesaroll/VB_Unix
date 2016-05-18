select * 
      --distinct name, type 
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 15100)
       OR type = 'shared')
order by type, name;

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


SELECT OWNER, TABLE_NAME, TABLESPACE_NAME
FROM ALL_TABLES
WHERE OWNER = 'DSS'
  AND TABLE_NAME LIKE '%MD%';
  
Select * from dss.web_account_mapping; --83554

exec ws_get_reprotcriteria('REPORT_COST_DETAIL', 15100, 

SET SERVEROUTPUT ON SIZE 1000000
DECLARE
  l_cursor  SYS_REFCURSOR;
  l_name   dss.bic_report_criteria.name%type;
  l_type   dss.bic_report_criteria.type%type;
BEGIN

  dss.ws_get_report_criteria('REPORT_COST_DETAIL', 15100, l_cursor);
            
  LOOP 
    FETCH l_cursor
    INTO  l_name, l_type;
    EXIT WHEN l_cursor%NOTFOUND;
    
    DBMS_OUTPUT.PUT_LINE(l_name || ' | ' || l_type);
    
  END LOOP;
  
  CLOSE l_cursor;
END;
/

Select * From dss.web_account_mapping; --qzymf3-a = 83554

insert into dss.bic_report_criteria values ('REPORT_COST_DETAIL', 'Testing', 83554, 9999, 'user', 'test', 0, sysdate);

select * 
      --distinct name, type 
from dss.bic_report_criteria 
where form_id = 'REPORT_COST_DETAIL'
 and ((type = 'user' and creator_id = 83554)
       OR type = 'shared')
order by type, name;
