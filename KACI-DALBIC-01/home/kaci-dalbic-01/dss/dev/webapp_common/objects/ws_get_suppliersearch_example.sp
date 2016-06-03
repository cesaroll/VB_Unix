#!/usr/bin/ksh
. /u/dss/$DSS_MODE/transfers/globals.com

SP=ws_get_suppliersearch_example

run_sql <<-endsql
create or replace procedure ${SP}
   (
        p_supplier_number       in varchar2,
        p_supplier_name         in varchar2,
        p_supplie_type          in varchar2,
        p_supplie_fed_tax_id    in varchar2,
        p_site_address1         in varchar2,
        p_site_country          in varchar2,
        p_site_state            in varchar2,
        p_site_city             in varchar2,
        p_site_zip              in varchar2,
        p_result            out sys_refcursor
     )
as
begin
     open p_result for
        select supplier_name
                           , supplier_number
                           , supplier_type
                           , supplier_fed_tax_id
                           , site_address1
                           , site_address2
                           , site_address3
                           , site_id
                           , site_name
                           , site_country
                           , site_state
                           , site_city
                           , site_zip                        
        from dss.supplier
        where upper(SUPPLIER_NUMBER)like decode('','','%',upper('%'||''||'%'))
                and SUPPLIER_NAME like decode('','','%','')
                and ((SUPPLIER_TYPE is null and 'Select' = 'Select')
                or (SUPPLIER_TYPE is not null
                and (SUPPLIER_TYPE like decode('Select','Select','%','Select'))
                                  )
                                    )
                and SUPPLIER_FED_TAX_ID  like decode('','','%','')
                and ((SITE_COUNTRY is null and 'Select' = 'Select')
                or (SITE_COUNTRY is not null
                and (SITE_COUNTRY like decode('Select','Select','%','Select'))
                                      )
                                         )
               and SITE_ADDRESS1 like decode('','','%','')
               and SITE_STATE like decode('','','%','')
               and SITE_CITY = DECODE(p_site_city, '', '%', p_site_city)
               and SITE_ZIP like decode('','','%','')
        order by 1,2,3,4,5,6,7,8,9,10,11;
end;
/
show errors

  grant execute on ${SP} to dss_admin, dss_support_role, reports;


