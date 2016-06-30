#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/29/2016  Cesar L.         Created
#
#----------------------------------------------------------------------------------------------------

SP=ws_get_customer

run_sql <<-endsql
create or replace procedure ${SP}
(
  p_cust_number   in  varchar2,
  p_cursor        out sys_refcursor
)
as
begin
     open p_cursor for
        Select * 
        From (Select * 
              From dss.Customer 
              Where Cust_Number = p_cust_number 
              order by control_date desc)
        Where rownum <= 1;
end;
/
show errors

grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql
