#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 06/17/2016  Cesar L.         Created
#
#----------------------------------------------------------------------------------------------------

SP=ws_get_countries

run_sql <<-endsql
create or replace procedure ${SP}
   (
        p_cursor        out sys_refcursor
    )
as
begin
     open p_cursor for
       select Country_Code as Code,
              Country_Name as Name,
              Country_Description as Description,
              Last_Updated_By
       from country
       order by Country_Name;
end;
/
show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql