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

Select * From dss.web_error_log order by ERR_DATE desc;
Select * From dss.web_error_log where user_identity = 'AMERICAS\locesar' order by ERR_DATE desc;
Select * From web_error_log where user_identity like '%locesar%' order by ERR_DATE desc;

--delete web_error_log where user_identity like '%locesar%';

desc dss.web_error_log;

desc dss.web_account_mapping;


Select * from dss.master_project;

Select master_project, count(*)
from dss.master_project
group by master_project
having count(*) > 1;

desc dss.master_project;