#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

#----------------------------------------------------------------------------------------------------
#
# Date        Developer        Change
# ----------  ---------------  ----------------------------------------------------------------------
# 05/16/2016  Cesar L.         Created
#
#----------------------------------------------------------------------------------------------------

SP=ws_get_rep_criteria

run_sql <<-endsql
create or replace procedure ${SP}
   (
        p_form_id       in bic_report_criteria.form_id%type,
        p_creator_id    in bic_report_criteria.creator_id%type,
        p_result        out sys_refcursor
    )
as
begin
     open p_result for
        select distinct name, type
        from   bic_report_criteria
        where  form_id = p_form_id
          and ( (type = 'user' and creator_id = p_creator_id)
              OR type = 'shared' )
        order by type, name;
end;
/
show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;

endsql
