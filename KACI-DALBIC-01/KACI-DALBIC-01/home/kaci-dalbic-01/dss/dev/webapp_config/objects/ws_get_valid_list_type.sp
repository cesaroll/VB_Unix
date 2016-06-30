#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/30/2016  Cesar L.         Get Valid list type by valid_type name
#                              
#----------------------------------------------------------------------------------------------------

SP=ws_get_valid_list_type


# Tables
#
TABLE_NAME=web_valid_list_types


run_sql <<-endsql

create or replace procedure ${SP}
(
  p_type        in  ${TABLE_NAME}.Valid_Type%TYPE,
  p_cursor      out sys_refcursor
)
as
begin
  
  dbms_output.put_line('P_type:    ' || p_type);
  
  open p_cursor for   
    select  valid_type_id_header as HeaderId, 
            valid_type_desc_header as HeaderDesc, 
            valid_type_desc_header_2 as HeaderDesc2,
            valid_type_nbr_columns as ColNumber,
            valid_type_select_mult as MultiSelect,
            control_id,
            control_date,
            regexp_count(valid_type_sql, 'PARAM') as ParmNum
    from ${TABLE_NAME}
    where valid_type = p_type;
    
  
end;
/
  show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql

