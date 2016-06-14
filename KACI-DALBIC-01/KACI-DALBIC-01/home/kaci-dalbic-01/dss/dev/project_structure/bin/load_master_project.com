#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_master_project
#
# Date          Developer       Description
# ===========   =========       ================================================
# 03/17/2016    Cesar L.        Load MASTER_PROJECT_MASTER table
#                               from SSE_MASTER_PROJECT_VIEW
# 04/21/2016    Cesar L.        Add City, State and Country.
# 05/03/2016    Cesar L.        Add Approval_date from previous years if exist.
#                               Fix Merge when comparing posible null values.
# 06/14/2016    Cesar L.        Update Merge to use sysdate when changing status
#                               from OPEN to APPROVED.
#################################################################################

YEAR=$1

echo
#echo  `date`
echo --------------------
echo Loading Master Project data
echo --------------------
echo

if [[ $# -eq 0 ]]; then
. /u/dss/$DSS_MODE/common/bin/get_calendar.com
   YEAR=$C_YEAR
fi

echo
echo Processing Year: [$YEAR]
echo
echo

# Directories
#
WORK_DIR=/u/dss/$DSS_MODE/project_structure/

#
# Tables
#
BASE_NAME=master_project_master
DATASET=master_project
STAGE_TABLE=stg_${DATASET}

# make sure tables are present...
${WORK_DIR}objects/${STAGE_TABLE}.tbl           >> $LOG
${WORK_DIR}objects/${BASE_NAME}.tbl             >> $LOG
${WORK_DIR}objects/${DATASET}.view              >> $LOG

echo
echo Starting Load and validation
echo

run_sql <<-END_SQL >>${LOG} 2>&1

  WHENEVER SQLERROR EXIT -1 ROLLBACK;

  TRUNCATE TABLE ${STAGE_TABLE};

  INSERT INTO ${STAGE_TABLE}
  (
          master_project            ,
          owning_firm               ,
          owning_production_office  ,
          status                    ,
          approval_date             ,
          open_date                 ,
          close_date                ,
          project_subtype           ,
          re_calc_method            ,
          project_currency_id       ,
          override_currency_id      ,
          city                      ,
          state                     ,
          country                   ,
          ecosys_status             ,
          insight_status            ,
          contract_type             ,
          opacc                     ,
          master_project_name       ,
          ecrm_client               ,
          jv_client                 ,
          migration_source          ,
          last_updated_by           ,
          last_update_date          ,
          control_date
  )
  SELECT  mp_project_num,
          owning_firm,
          owning_production_office,
          mp_project_status,
          (Select Min(Approval_Date) from master_project_master where master_project = mp_project_num),
          start_date,
          completion_date,
          Mp_project_subtype,
          Revenue_calculation_method,
          Project_currency_code,
          Override_currency_code,
          city,
          state,
          country,
          Project_management_system_code,
          Project_management_system_code,
          Contract_type,
          Opacc,
          Mp_project_name,
          Ecrm_client,
          jv_client,
          'OA',
          Last_updated_by,
          Last_update_date,
          SYSDATE
  FROM SSE_MASTER_PROJECT_VIEW;


  DELETE FROM xfer_validation_errors WHERE table_name = '${STAGE_TABLE}';
  commit;

  exec xfer_validation('${STAGE_TABLE}', ${YEAR});

  INSERT INTO xfer_validation_errors
  SELECT '${STAGE_TABLE}',
         master_project || ',' ||
         ROW_NUMBER() OVER (PARTITION BY master_project ORDER BY master_project ) AS pk,
         valid,
         validation_result
    FROM ${STAGE_TABLE}
   WHERE valid = 'N';

  DELETE FROM ${STAGE_TABLE}
   WHERE valid = 'N';

  commit;
END_SQL

#exit

echo
echo Starting Merge
echo

run_sql <<-END_SQL >>${LOG} 2>&1

  MERGE INTO ${BASE_NAME} mpm
  USING (
        SELECT DISTINCT
                master_project          ,
                owning_firm             ,
                owning_production_office,
                status                  ,
                approval_date           ,
                open_date               ,
                close_date              ,
                project_subtype         ,
                re_calc_method          ,
                project_currency_id     ,
                override_currency_id    ,
                city                    ,
                state                   ,
                country                 ,
                ecosys_status           ,
                insight_status          ,
                contract_type           ,
                opacc                   ,
                master_project_name     ,
                ecrm_client             ,
                jv_client               ,
                migration_source        ,
                last_updated_by         ,
                last_update_date        ,
                control_date
        FROM ${STAGE_TABLE}
        ) smp
    ON  (
             mpm.year           = ${YEAR}
         AND mpm.master_project = smp.master_project
        )
  WHEN MATCHED
  THEN
    UPDATE
      SET
          mpm.owning_firm              = smp.owning_firm             ,
          mpm.owning_production_office = smp.owning_production_office,
          mpm.status                   = smp.status                  ,
          mpm.approval_date            = Decode(smp.status, 'APPROVED', Decode(mpm.status, 'OPEN', sysdate, smp.approval_date), smp.approval_date),
          mpm.open_date                = smp.open_date               ,
          mpm.close_date               = smp.close_date              ,
          mpm.project_subtype          = smp.project_subtype         ,
          mpm.re_calc_method           = smp.re_calc_method          ,
          mpm.project_currency_id      = smp.project_currency_id     ,
          mpm.override_currency_id     = smp.override_currency_id    ,
          mpm.city                     = smp.city                    ,
          mpm.state                    = smp.state                   ,
          mpm.country                  = smp.country                 ,
          mpm.ecosys_status            = smp.ecosys_status           ,
          mpm.insight_status           = smp.insight_status          ,
          mpm.contract_type            = smp.contract_type           ,
          mpm.opacc                    = smp.opacc                   ,
          mpm.master_project_name      = smp.master_project_name     ,
          mpm.ecrm_client              = smp.ecrm_client             ,
          mpm.jv_client                = smp.jv_client               ,
          mpm.migration_source         = smp.migration_source        ,
          mpm.last_updated_by          = smp.last_updated_by         ,
          mpm.last_update_date         = smp.last_update_date        ,
          mpm.control_date             = SYSDATE
    WHERE
          Decode(mpm.owning_firm              , smp.owning_firm             , 0, 1) = 1
      OR  Decode(mpm.owning_production_office , smp.owning_production_office, 0, 1) = 1
      OR  Decode(mpm.status                   , smp.status                  , 0, 1) = 1
      OR  Decode(mpm.approval_date            , smp.approval_date           , 0, 1) = 1
      OR  Decode(mpm.open_date                , smp.open_date               , 0, 1) = 1
      OR  Decode(mpm.close_date               , smp.close_date              , 0, 1) = 1
      OR  Decode(mpm.project_subtype          , smp.project_subtype         , 0, 1) = 1
      OR  Decode(mpm.re_calc_method           , smp.re_calc_method          , 0, 1) = 1
      OR  Decode(mpm.project_currency_id      , smp.project_currency_id     , 0, 1) = 1
      OR  Decode(mpm.override_currency_id     , smp.override_currency_id    , 0, 1) = 1
      OR  Decode(mpm.city                     , smp.city                    , 0, 1) = 1
      OR  Decode(mpm.state                    , smp.state                   , 0, 1) = 1
      OR  Decode(mpm.country                  , smp.country                 , 0, 1) = 1
      OR  Decode(mpm.ecosys_status            , smp.ecosys_status           , 0, 1) = 1
      OR  Decode(mpm.insight_status           , smp.insight_status          , 0, 1) = 1
      OR  Decode(mpm.contract_type            , smp.contract_type           , 0, 1) = 1
      OR  Decode(mpm.opacc                    , smp.opacc                   , 0, 1) = 1
      OR  Decode(mpm.master_project_name      , smp.master_project_name     , 0, 1) = 1
      OR  Decode(mpm.ecrm_client              , smp.ecrm_client             , 0, 1) = 1
      OR  Decode(mpm.jv_client                , smp.jv_client               , 0, 1) = 1
      OR  Decode(mpm.migration_source         , smp.migration_source        , 0, 1) = 1
      OR  Decode(mpm.last_updated_by          , smp.last_updated_by         , 0, 1) = 1
      OR  Decode(mpm.last_update_date         , smp.last_update_date        , 0, 1) = 1
  WHEN NOT MATCHED
  THEN
    INSERT  (
            mpm.year                     ,
            mpm.master_project           ,
            mpm.owning_firm              ,
            mpm.owning_production_office ,
            mpm.status                   ,
            mpm.approval_date            ,
            mpm.open_date                ,
            mpm.close_date               ,
            mpm.project_subtype          ,
            mpm.re_calc_method           ,
            mpm.project_currency_id      ,
            mpm.override_currency_id     ,
            mpm.city                     ,
            mpm.state                    ,
            mpm.country                  ,
            mpm.ecosys_status            ,
            mpm.insight_status           ,
            mpm.contract_type            ,
            mpm.opacc                    ,
            mpm.master_project_name      ,
            mpm.ecrm_client              ,
            mpm.jv_client                ,
            mpm.migration_source         ,
            mpm.last_updated_by          ,
            mpm.last_update_date         ,
            mpm.control_date
          )
    VALUES  (
            ${YEAR}                     ,
            smp.master_project          ,
            smp.owning_firm             ,
            smp.owning_production_office,
            smp.status                  ,
            smp.approval_date           ,
            smp.open_date               ,
            smp.close_date              ,
            smp.project_subtype         ,
            smp.re_calc_method          ,
            smp.project_currency_id     ,
            smp.override_currency_id    ,
            smp.city                    ,
            smp.state                   ,
            smp.country                 ,
            smp.ecosys_status           ,
            smp.insight_status          ,
            smp.contract_type           ,
            smp.opacc                   ,
            smp.master_project_name     ,
            smp.ecrm_client             ,
            smp.jv_client               ,
            smp.migration_source        ,
            smp.last_updated_by         ,
            smp.last_update_date        ,
            SYSDATE
          );

END_SQL

$UPDATE_STATS ${BASE_NAME}

echo
echo  `date`
echo
