#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_mp_task_mapping_hist 
# 
# Date          Developer       Description
# ===========   =========       ================================================
# 04/18/2016    Cesar L.        Created.
# 05/18/2016    Cesar L.        Getting Master_Project from Tag_the_base_master
# 05/19/2016    Cesar L.        Using Cursors, Bulk Collect, Bulk Insert and temp table.
#################################################################################

echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " Populating mp_task_mapping history data "
echo "-------------------------------------------------"
echo " "

#Tables

TABLE_NAME=mp_task_mapping_master
TEMP_TABLE=mp_task_mapping_master_tmp
REVPKGSPO_TABLE=promis_revpkgspo
PHASE_REV_TABLE=promis_phase_revenue
TAG_THE_BASE=tag_the_base_master

# Directories
WORK_DIR=/u/dss/$DSS_MODE/project_structure/

# make sure tables are present...
${WORK_DIR}objects/${TABLE_NAME}.tbl
${WORK_DIR}objects/${TEMP_TABLE}.tbl

echo " "
echo "-------------------------------------------------"
echo " First Step - Query All Data "
echo "-------------------------------------------------"
echo " "

run_sql <<end_sql
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

TRUNCATE TABLE ${TABLE_NAME};
TRUNCATE TABLE ${TEMP_TABLE};

DECLARE

   /* Type declarations */
  TYPE tmTabType    IS TABLE OF ${TEMP_TABLE}%ROWTYPE;

  /* Variables */  

  tab_new_tm          tmTabType := tmTabType();  
  row_tm_new          ${TEMP_TABLE}%ROWTYPE := Null;
  
  v_master_project    Number;
  v_production_office Number;

  v_count           Number    := 0;
  v_idx             Number    := 0;
  v_bulk_rows       Number    := 5000;
  v_bulk_rows_tot   Number    := 0;
  

  v_start_time      NUMBER;
  v_end_time        NUMBER;
  
  /* Function: Get Master Project */
  v_curr_rp   Number := 0;
  v_curr_ay   Number := 0;
  v_curr_dy   Number := 0;
  v_curr_mp   Number := 0;
  
  /* Function: Get Production office */
  v_curr_subp   Number  := 0;  
  v_curr_firm   varchar2(10);
  v_curr_po     Number  := 0;
    
  
  /*  Main Cursor  */
  CURSOR cur_main
  IS
    Select revenue_package,
           subproject,       
           firm,
           proj as project,
           phase as task,       
           begin_date as association_date,
           EXTRACT(year from begin_date) as association_year,
           end_date as disassociation_date,
           EXTRACT(year from end_date) as disassociation_year,
           control_id as last_updated_by,
           control_date as last_update_date
    from ${PHASE_REV_TABLE}
    where  revenue_package is not null
      and  proj is not null
      and  phase is not null
      and  firm is not null
      and  subproject > 0
      and  begin_date is not null
    order by revenue_package, proj, phase, firm, association_year, disassociation_year;
  
  Type MainCurType Is Table Of cur_main%ROWTYPE;
  cur_main_array MainCurType;
  
  /* Function: Get Master Project */
    
  Function Get_Master_Project
  (
    p_rev_pac    IN  number,
    p_assoc_year IN  number,
    p_disa_year  IN  number,    
    p_mp         OUT number
  )
  RETURN BOOLEAN
  IS
    res BOOLEAN := false;
  BEGIN
    
    If p_rev_pac    = v_curr_rp AND 
       p_assoc_year = v_curr_ay AND
       p_disa_year  = v_curr_dy AND 
       v_curr_mp    > 0 Then
    
      /* If everything is the same just return current master_project */
      
      res   := true;
      p_mp  := v_curr_mp;
       
    Else
    
      /* If not the same save values and search */
      
      /*Initialize*/
      v_curr_rp := 0;
      v_curr_ay := 0;
      v_curr_dy := 0;
      v_curr_mp := 0;

      FOR row IN (
        Select master_project
        From (Select distinct year, master_project
              From dss.tag_the_base_master
              where revenue_package = p_rev_pac
                and year between p_assoc_year and p_disa_year
              order by year desc)
        Where rownum <= 1
      ) LOOP
      
        res   := true;
        p_mp  := row.master_project;
        
        /*Set Current Values*/
        v_curr_rp := p_rev_pac;
        v_curr_ay := p_assoc_year;
        v_curr_dy := p_disa_year;
        v_curr_mp := p_mp;
        
        exit;
      
      END LOOP;
    
    End If;    

    RETURN(res);

  END Get_Master_Project;
  
  
  /* Function: Get Production office */
  
  Function Get_Production_Office
  (
    p_mp         IN  number,
    p_subp       IN  number,
    p_firm       IN  varchar2,    
    p_po         OUT number
  )
  RETURN BOOLEAN
  IS
    res BOOLEAN := false;
  BEGIN
    
    If p_mp       = v_curr_mp   AND 
       p_subp     = v_curr_subp AND
       p_firm     = v_curr_firm AND 
       v_curr_po  > 0 Then
    
      /* If everything is the same just return current production office */
      
      res   := true;
      p_po  := v_curr_po;
       
    Else
    
      /* If not the same save values and search */
      
      /*Initialize*/
      v_curr_subp := 0;
      v_curr_po   := 0;
      

      FOR row IN (
        Select production_office
        from (Select production_office 
              from ${REVPKGSPO_TABLE}
              where revenue_package = p_mp
                and subproject = p_subp
                and firm = p_firm
              order by expiration_date desc) 
        where rownum <= 1
      ) LOOP
      
        res   := true;
        p_po  := row.production_office;
        
        /*Set Current Values*/
        v_curr_subp := p_subp;
        v_curr_firm := p_firm;
        v_curr_po   := p_po;
        
        exit;
      
      END LOOP;
      
      If res = false Then
      
        FOR row IN (
          Select production_office
          from (Select production_office 
                from ${REVPKGSPO_TABLE}
                where revenue_package = p_mp
                  and firm = p_firm
                order by expiration_date desc) 
          where rownum <= 1
        ) LOOP
        
          res   := true;
          p_po  := row.production_office;
          
          /*Set Current Values*/
          v_curr_subp := p_subp;
          v_curr_firm := p_firm;
          v_curr_po   := p_po;
          
          exit;
        
        END LOOP;
      
      End If;
      
      If res = false Then
      
        FOR row IN (
          Select production_office
          from (Select production_office 
                from ${REVPKGSPO_TABLE}
                where revenue_package = p_mp
                order by expiration_date desc) 
          where rownum <= 1
        ) LOOP
        
          res   := true;
          p_po  := row.production_office;
          
          /*Set Current Values*/
          v_curr_subp := p_subp;
          v_curr_firm := p_firm;
          v_curr_po   := p_po;
          
          exit;
        
        END LOOP;
      
      End If;
    
    End If;    

    RETURN(res);

  END Get_Production_Office;
  
  
  /* Function to Convert Cursor row into Task Mapping row */
  FUNCTION TM_Convert
  (
    p_row   IN  cur_main%ROWTYPE,
    p_mp    IN  Number,
    p_po    IN  Number
  )
  RETURN ${TEMP_TABLE}%ROWTYPE
  IS
    p_tm   ${TEMP_TABLE}%ROWTYPE;
  BEGIN
    
    p_tm.master_project                := p_mp;
    p_tm.production_office             := p_po;
    
    Select Decode(p_row.subproject, 1, 'Y', 'N')
    Into p_tm.owning_production_office_flag
    From dual;
    
    p_tm.firm                          := p_row.firm;
    p_tm.project                       := p_row.project;
    p_tm.task                          := p_row.task;
    p_tm.association_date              := p_row.association_date;
    p_tm.disassociation_date           := p_row.disassociation_date;
    p_tm.last_updated_by               := p_row.last_updated_by;
    p_tm.last_update_date              := p_row.last_update_date;
    
    RETURN(p_tm);
    
  END TM_Convert; 
  
  
  /* Perform Bulk insert */
  Procedure P_Bulk_Insert
  (
    p_rows  IN Number default v_bulk_rows
  )
  Is
  Begin

    IF v_idx >= p_rows THEN

      --Bulk bind
      FORALL i IN tab_new_tm.FIRST .. tab_new_tm.LAST
        INSERT INTO ${TEMP_TABLE}
        VALUES tab_new_tm(i);

      COMMIT;

      v_count := v_count + v_idx;

      --Initialize table variable and index
      tab_new_tm  := tmTabType();
      v_idx       :=  0;

      v_end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('Insert at count: ' || v_count || ' Elapsed time: ' || to_char(v_end_time-v_start_time));

    END IF;

  End P_Bulk_Insert;
  
  
  /* Insert Procedure */
  Procedure P_Insert
  (
    p_row       IN  ${TEMP_TABLE}%ROWTYPE
  )
  Is    
  Begin
    
    v_idx := v_idx + 1;
    
    tab_new_tm.EXTEND;
    tab_new_tm(v_idx) := p_row;

    P_Bulk_Insert();
    
    
  End P_Insert;
  
  
BEGIN
  
  v_start_time := DBMS_UTILITY.get_time;
  
  dbms_output.put_line('Openning Main cursor');  
  
  Open cur_main;
  
  Loop
    Fetch cur_main Bulk Collect Into cur_main_array Limit v_bulk_rows;
    
    EXIT WHEN cur_main_array.count < 1;
    
    v_bulk_rows_tot := v_bulk_rows_tot + cur_main_array.count;
    
    dbms_output.put_line('Inside Main Cursos Bulk Collect: ' || v_bulk_rows_tot);
    
      For i IN 1 .. cur_main_array.count Loop
    
        If Get_Master_Project(cur_main_array(i).revenue_package, cur_main_array(i).association_year, cur_main_array(i).disassociation_year, v_master_project) Then
        
          If Get_Production_Office(v_master_project, cur_main_array(i).subproject, cur_main_array(i).firm, v_production_office) Then
          
            row_tm_new := TM_Convert(cur_main_array(i), v_master_project, v_production_office);
            
            P_Insert(row_tm_new);
                   
          End If;
                  
        End If;
        
      End Loop; -- Array Loop
    
  End Loop; --Main Bulk Loop
  
  Close cur_main;
    
  /* Bulk insert the rest, if any */
  P_Bulk_Insert(0);
  
END;
/


end_sql

echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " Second Step - Group All Data "
echo "-------------------------------------------------"
echo " "

run_sql <<end_sql
SET LINESIZE 200;
WHENEVER SQLERROR EXIT -1 ROLLBACK;
SET SERVEROUTPUT ON;

TRUNCATE TABLE ${TABLE_NAME};

DECLARE

   /* Type declarations */
  TYPE tmTabType    IS TABLE OF ${TABLE_NAME}%ROWTYPE;

  /* Variables */  

  tab_new_tm          tmTabType := tmTabType();  
  row_tm_new          ${TABLE_NAME}%ROWTYPE := Null;

  v_count           Number    := 0;
  v_idx             Number    := 0;
  v_bulk_rows       Number    := 5000;
  v_bulk_rows_tot   Number    := 0;
  

  v_start_time      NUMBER;
  v_end_time        NUMBER;
  
  /*  Main Cursor  */
  CURSOR cur_main
  IS
    Select master_project                ,
           MIN(production_office) keep (dense_rank last order by last_update_date) as production_office,
           MIN(owning_production_office_flag) keep (dense_rank last order by last_update_date) as opof,
           firm                          ,
           project                       ,
           task                          ,
           MIN(association_date) as association_date,
           MAX(disassociation_date) as disassociation_date,
           NVL(MIN(last_updated_by) keep (dense_rank last order by last_update_date), ' ') as last_updated_by,
           NVL(MAX(last_update_date), sysdate) as last_update_date
    From ${TEMP_TABLE}
    Group By master_project, project, task, firm;

  Type MainCurType Is Table Of cur_main%ROWTYPE;
  cur_main_array MainCurType;
  
  /* Function to Convert Cursor row into Task Mapping row */
  FUNCTION TM_Convert
  (
    p_row   IN  cur_main%ROWTYPE
  )
  RETURN ${TABLE_NAME}%ROWTYPE
  IS
    p_tm   ${TABLE_NAME}%ROWTYPE;
  BEGIN
  
  
    p_tm.master_project                := p_row.master_project;
    p_tm.production_office             := p_row.production_office;
    p_tm.owning_production_office_flag := p_row.opof;
    p_tm.firm                          := p_row.firm;
    p_tm.project                       := p_row.project;
    p_tm.task                          := p_row.task;
    p_tm.association_date              := p_row.association_date;
    p_tm.disassociation_date           := p_row.disassociation_date;
    p_tm.last_updated_by               := p_row.last_updated_by;
    p_tm.last_update_date              := p_row.last_update_date;
    p_tm.control_date                  := sysdate;
    
    RETURN(p_tm);
    
  END TM_Convert; 
  
  
  /* Perform Bulk insert */
  Procedure P_Bulk_Insert
  (
    p_rows  IN Number default v_bulk_rows
  )
  Is
  Begin

    IF v_idx >= p_rows THEN

      --Bulk bind
      FORALL i IN tab_new_tm.FIRST .. tab_new_tm.LAST
        INSERT INTO ${TABLE_NAME}
        VALUES tab_new_tm(i);

      COMMIT;

      v_count := v_count + v_idx;

      --Initialize table variable and index
      tab_new_tm  := tmTabType();
      v_idx       :=  0;

      v_end_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('Insert at count: ' || v_count || ' Elapsed time: ' || to_char(v_end_time-v_start_time));

    END IF;

  End P_Bulk_Insert;
  
  
  /* Insert Procedure */
  Procedure P_Insert
  (
    p_row       IN  ${TABLE_NAME}%ROWTYPE
  )
  Is    
  Begin
    
    v_idx := v_idx + 1;
    
    tab_new_tm.EXTEND;
    tab_new_tm(v_idx) := p_row;

    P_Bulk_Insert();
    
    
  End P_Insert;
  
BEGIN
  
  v_start_time := DBMS_UTILITY.get_time;
  
  dbms_output.put_line('Openning Main cursor');  
  
  Open cur_main;
  
  Loop
    Fetch cur_main Bulk Collect Into cur_main_array Limit v_bulk_rows;
    
    EXIT WHEN cur_main_array.count < 1;
  
    v_bulk_rows_tot := v_bulk_rows_tot + cur_main_array.count;
    
    dbms_output.put_line('Inside Main Cursos Bulk Collect: ' || v_bulk_rows_tot);
    
    
    For i IN 1 .. cur_main_array.count Loop
    
       row_tm_new := TM_Convert(cur_main_array(i));
            
       P_Insert(row_tm_new);
        
    End Loop; -- Array Loop
    
    
  End Loop; --Main Bulk Loop
  
  Close cur_main;
    
  /* Bulk insert the rest, if any */
  P_Bulk_Insert(0);
    

END;
/


DROP TABLE ${TEMP_TABLE};

end_sql

echo " "
echo " `date` "
echo " "
