SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

DECLARE

  /* Types */
  TYPE split_tbl_type IS TABLE OF user_tab_columns.column_name%TYPE;

  /* Variables */
  split_result  split_tbl_type;
  query_str     varchar2(999);
  query_fields  varchar2(256);
  
  p_tbl           dss.xfer_validation_rules.table_name%type        := 'stg_master_project_po';
  p_col           dss.xfer_validation_rules.column_name%type       := 'primary key';
  p_unique_cols   dss.xfer_validation_rules.integrity_column%type  := 'master_project, production_office, control_date, expiration_date';
      
  /* Declare Split Function  */
  FUNCTION Split
  (
    p_list      IN varchar2,
    p_delimiter IN varchar2 default ','
  )
  RETURN split_tbl_type
  IS
    split_tbl split_tbl_type := split_tbl_type();
  BEGIN
    
    FOR row IN (      
      SELECT regexp_substr(p_list,'[^,]+', 1, level) item 
      FROM dual
      CONNECT BY regexp_substr(p_list, '[^,]+', 1, level) IS NOT NULL
    ) LOOP
    
      IF TRIM(row.item) IS NOT NULL THEN
      
        split_tbl.extend(1);
        split_tbl(split_tbl.last) := TRIM(row.item);
        
      
      END IF;
      
    END LOOP;
    
    RETURN(split_tbl);
    
  END Split;

BEGIN

  --split_result := Split('SMITH,,ALLEN,WARD, ,JONES');
  split_result := Split(p_unique_cols);
  /*
  FOR i IN split_result.FIRST..split_result.LAST LOOP  
    dbms_output.put_line('>' || split_result(i) || '<');  
  END LOOP; -- split_result
  */
  
  FOR i IN split_result.FIRST..split_result.LAST LOOP  
    query_fields := query_fields || split_result(i);
    
    IF i < split_result.LAST THEN
      query_fields := query_fields || ', ';
    END IF;
    
  END LOOP; -- split_result
  
  dbms_output.put_line(query_fields);
  /*
  query_str := 'SELECT ' || query_fields ||  
               ' FROM dss.' || p_tbl || 
               ' GROUP BY ' || query_fields || 
               ' HAVING COUNT(*) > 1 ';*/
               
  query_str := 'UPDATE ' || p_tbl || 
                ' SET valid = ''N'', ' ||
                    ' validation_result = DECODE(validation_result, null, '''', validation_result || '' '') || ''' || p_col || ' is not unique;'' ' ||
               'WHERE (' || query_fields || ') IN (' ||
               'SELECT ' || query_fields ||  
               ' FROM dss.' || p_tbl || 
               ' GROUP BY ' || query_fields || 
               ' HAVING COUNT(*) > 1 )';
  
 
  dbms_output.put_line(query_str);

END;