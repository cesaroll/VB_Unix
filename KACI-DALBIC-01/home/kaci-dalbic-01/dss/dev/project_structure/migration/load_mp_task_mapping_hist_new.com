#!/usr/bin/ksh
. /u/dss/$DSS_MODE/warehouse/globals.com

#################################################################################
# load_mp_task_mapping_hist 
# 
# Date          Developer       Description
# ===========   =========       ================================================
# 04/18/2016    Cesar L.        Created.
# 05/18/2016    Cesar L.        Getting Master_Project from Tag_the_base_master
#################################################################################

echo " "
echo " `date` "
echo "-------------------------------------------------"
echo " Populating mp_task_mapping history data "
echo "-------------------------------------------------"
echo " "

TABLE_NAME=mp_task_mapping_master_new
REVPKGSPO_TABLE=promis_revpkgspo
PHASE_REV_TABLE=promis_phase_revenue
TAG_THE_BASE=tag_the_base_master

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
  row_tm_curr         ${TABLE_NAME}%ROWTYPE := Null;
  row_tm_new          ${TABLE_NAME}%ROWTYPE := Null;
  
  v_master_project    Number;
  v_production_office Number;

  v_count           Number    := 0;
  v_idx             Number    := 0;
  v_bulk_rows       Number    := 1000;
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
  
  /* Function: IsChanged*/
  v_FirstTime Boolean := true;
  v_Inserted Boolean;
  
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
           NVL(control_date, sysdate) as last_update_date
    from ${PHASE_REV_TABLE}
    where  revenue_package is not null
      and  proj >= 176179--is not null
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
  RETURN ${TABLE_NAME}%ROWTYPE
  IS
    p_tm   ${TABLE_NAME}%ROWTYPE;
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
  
  /* Is Changed */
  Function IsChanged
  (
    p_row       IN  ${TABLE_NAME}%ROWTYPE
  )RETURN BOOLEAN
  IS
    res BOOLEAN := false;
  Begin
        
    If v_FirstTime Then
      v_FirstTime := false;
      row_tm_curr := p_row;
    Else
    
      If p_row.master_project    != row_tm_curr.master_project    OR
         p_row.production_office != row_tm_curr.production_office OR
         p_row.project           != row_tm_curr.project           OR
         p_row.task              != row_tm_curr.task              OR
         p_row.firm              != row_tm_curr.firm  Then
              
        /* If is Changed insert current */
        P_Insert(row_tm_curr);
        
        /* Change current*/
        row_tm_curr := p_row;
        
        res := true;
        /*
        dbms_output.put_line(row_tm_curr.master_project || ' - ' || row_tm_curr.production_office || ' - ' || row_tm_curr.project || ' - ' ||   
          row_tm_curr.task || ' - ' || row_tm_curr.Firm || ' - ' ||  row_tm_curr.owning_production_office_flag  || ' - ' ||
          row_tm_curr.association_date || ' - ' ||  row_tm_curr.disassociation_date );
        */
      Else
        /* If not chaged Update necesary fields */
        
        If p_row.association_date < row_tm_curr.association_date Then
          row_tm_curr.association_date := p_row.association_date;
        End If;
        
        If p_row.disassociation_date > row_tm_curr.disassociation_date Then
          row_tm_curr.disassociation_date := p_row.disassociation_date;
        End If;
        
        If p_row.last_update_date > row_tm_curr.last_update_date Then
          
          row_tm_curr.last_update_date  := p_row.last_update_date;
          row_tm_curr.last_updated_by   := p_row.last_updated_by;
          row_tm_curr.owning_production_office_flag   := p_row.owning_production_office_flag;
          
        End If;
      
      End If;
    
    End If;
    
    RETURN(res);

  End IsChanged;
  
  
BEGIN
  
  v_start_time := DBMS_UTILITY.get_time;
  
  dbms_output.put_line('openning Main cursor');  
  
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
            /*
            dbms_output.put_line(row.revenue_package || ' - ' || row.Firm || ' - ' || row.project  || ' - ' || row.task || ' - ' ||  row.association_year 
            || ' - ' ||  row.disassociation_year || ' - ' || v_master_project || ' - ' || v_production_office);*/
            /*
            dbms_output.put_line(row_tm_new.master_project || ' - ' || row_tm_new.production_office || ' - ' || row_tm_new.project || ' - ' ||   
              row_tm_new.task || ' - ' || row_tm_new.Firm || ' - ' ||  row_tm_new.owning_production_office_flag  || ' - ' ||
              row_tm_new.association_date || ' - ' ||  row_tm_new.disassociation_date );
            */
            
            v_Inserted := IsChanged(row_tm_new);
            
          End If;
        
        End If;
        
      End Loop; -- Array Loop
      
      If v_Inserted = false Then
        P_Insert(row_tm_curr);
      End If;
      
      /* Bulk insert the rest, if any */
      P_Bulk_Insert(0);
    
    
  End Loop; --Main Bulk Loop
  
  Close cur_main;
    
  
END;
/
  
  


end_sql

echo " "
echo " `date` "
echo " "
