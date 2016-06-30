Select * From dss.Customer order by control_date desc;

Select * From (Select * 
From dss.Customer 
Where Cust_Number = '37559' 
order by control_date desc)
Where rownum <= 1;

Select count(*) From dss.Customer;

desc dss.Customer;