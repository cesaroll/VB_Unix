#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/28/2016  Cesar L.         Created
#
#----------------------------------------------------------------------------------------------------

SP=ws_get_project

run_sql <<-endsql
create or replace procedure ${SP}
(
  p_project_id    in  number,
  p_cursor        out sys_refcursor
)
as
begin
     open p_cursor for
        Select *
        From top_task_organization
        Where tt_project = p_project_id;
end;
/
show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql
