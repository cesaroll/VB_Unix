Select * from dss.master_project_po_2012; --View

Select * From dss.standard_week;

Select year, Max(Expiration_date) 
From dss.standard_week
Group by year
order by year;

Select Max(Expiration_date) From dss.standard_week where year = 2015;

  SELECT *
  FROM  dss.master_project_po_hist
  WHERE (Select Max(Expiration_date) From dss.standard_week where year = 2015) BETWEEN effective_date AND expiration_date
  Order by expiration_date desc;