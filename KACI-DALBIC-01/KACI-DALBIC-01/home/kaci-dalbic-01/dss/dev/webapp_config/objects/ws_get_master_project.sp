#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 05/23/2016  Cesar L.         Created
#
#----------------------------------------------------------------------------------------------------

SP=ws_get_master_project

run_sql <<-endsql
create or replace procedure ${SP}
(
  p_master_id     in  number,
  p_cursor        out sys_refcursor
)
as
begin
     open p_cursor for
        Select *
        From master_project
        Where master_project = p_master_id;
end;
/
show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql
