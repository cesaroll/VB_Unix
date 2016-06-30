#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/30/2016  Cesar L.         Get List of valid selection values by type and parms 
#                              and according to its corresponding SQL in table.
#                              
#----------------------------------------------------------------------------------------------------

SP=ws_get_valid_list_values


# Directories
#
COMMON_OBJS_DIR=/u/dss/$DSS_MODE/common/


# make sure functions are present...
${COMMON_OBJS_DIR}objects/StringToNumberTable.func       >> $LOG


# Tables
#
TABLE_NAME=web_valid_list_types


run_sql <<-endsql

create or replace procedure ${SP}
(
  p_type        in  ${TABLE_NAME}.Valid_Type%TYPE,
  p_param_1     in  varchar2,
  p_param_2     in  varchar2,
  p_param_3     in  varchar2,
  p_cursor      out sys_refcursor
)
as
  v_query_str   ${TABLE_NAME}.Valid_Type_Sql%TYPE;
  v_nbr_parms   number(2) := 0;
  
begin
  
  EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
  
  dbms_output.put_line('P_type:    ' || p_type);
  dbms_output.put_line('p_param_1: ' || p_param_1);
  dbms_output.put_line('p_param_2: ' || p_param_2);
  dbms_output.put_line('p_param_3: ' || p_param_3 || chr(10));
    
  select  valid_type_sql,           
          regexp_count(valid_type_sql, 'PARAM')
  into    v_query_str,
          v_nbr_parms
  from ${TABLE_NAME}
  where valid_type = p_type;
  
  dbms_output.put_line('Nbr Parms: ' || TO_CHAR(v_nbr_parms));
  
  dbms_output.put_line(chr(10) || 'Query String: ' || chr(10) || v_query_str || chr(10));
    
  
  IF v_nbr_parms=1 THEN
  
    dbms_output.put_line('Using 1 Parm');
    open p_cursor for v_query_str using p_param_1;
  
  ELSIF v_nbr_parms=2 THEN
  
    dbms_output.put_line('Using 2 Parms');
    open p_cursor for v_query_str using p_param_1, p_param_2;
  
  ELSIF v_nbr_parms=2 THEN
  
    dbms_output.put_line('Using 3 Parms');
    open p_cursor for v_query_str using p_param_1, p_param_2, p_param_3;
  
  END IF;
  
end;
/
  show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql

