#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/27/2016  Cesar L.         Test
#                              
#----------------------------------------------------------------------------------------------------

SP=ws_get_cesartest


# Directories
#
COMMON_OBJS_DIR=/u/dss/$DSS_MODE/common/


# make sure functions are present...
${COMMON_OBJS_DIR}objects/StringToNumberTable.func       >> $LOG

run_sql <<-endsql

create or replace procedure ${SP}
(
  p_type        in  varchar2,
  p_param_1     in  varchar2,
  p_param_2     in  varchar2,
  p_cursor      out sys_refcursor
)
as
  v_query_str   varchar2(1000);
  type NumbersTable is table of number;
begin

  --ALTER SESSION ENABLE PARALLEL DML;
  
  dbms_output.put_line('P_type:    ' || p_type);
  dbms_output.put_line('p_param_1: ' || p_param_1);
  dbms_output.put_line('p_param_2: ' || p_param_2);
    
  select distinct valid_type_sql
  into v_query_str
  from dss.web_valid_list_types
  where valid_type = p_type;
  
  dbms_output.put_line('Query String: ' || chr(10) || v_query_str);
  
  open p_cursor for v_query_str using p_param_1;
  
end;
/
  show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql

