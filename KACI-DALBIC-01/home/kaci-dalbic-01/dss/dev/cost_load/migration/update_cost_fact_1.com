#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# update_cost_fact_1
#
# Date          Developer       Description
# ===========   =========       ================================================
# 06/02/2016    Cesar L.        Update
#
#################################################################################

YEAR=$1

if [[ $# -ne 1 ]]; then
  echo " "
  echo "USAGE:   $0 <year>"
  echo " "
  exit -1
fi



echo
echo  `date`
echo --------------------
echo Updating co_key_top_task_org: ${YEAR}
echo --------------------
echo

run_sql <<end_sql

ALTER SESSION ENABLE PARALLEL DML;

Merge /*+ parallel */
Into cost_fact cf
Using (
        select  Distinct
                tt.key_top_task_org, 
                po.key_phase_org
        from top_task_organization  tt, 
             phase_organization     po
        where tt.tt_project         = po.project
          and tt.tt_task            = po.phase
          and tt.tt_task_firm       = po.project_firm
          --and tt.tt_project  = 176179
      ) sq
  ON  (
              cf.co_key_phase_org = key_phase_org
          and cf.co_effective_date Between to_date('01-jan-${YEAR}', 'dd-mon-yyyy') and to_date('31-dec-${YEAR}', 'dd-mon-yyyy')
      )
When Matched
Then
  Update
    Set
      cf.co_key_top_task_org = sq.key_top_task_org;

end_sql

echo
echo  `date`
echo