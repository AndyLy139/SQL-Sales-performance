

--Write a SQL statement to show the total dollar amount sold to customers summarized by product category name and each month of each Year (YYYY-MM). Only include non-canceled orders that were shipped within 7 days of ordering.
SELECT 
  p.category_name, 
  Format_Date('%Y-%m',o.order_date) AS Year_Month,
  ROUND(SUM(oi.quantity * oi.unit_price), 2) AS Total_Dollars
FROM `order_entry_dataset.order_items` oi
INNER JOIN `order_entry_dataset.products` p USING (product_id)
INNER JOIN `order_entry_dataset.orders` o USING (order_id)
WHERE 
  o.order_status >= 4 AND 
  o.ship_date <= DATE_ADD(o.order_date, INTERVAL 7 day)
GROUP BY 1, 2
order by Year_Month;

--Write a SQL statement to show the total dollar amount sold summarized by Customer marital status and Year along with RANK. The largest sales by marital status by year should be ranked #1.
SELECT 
   c.MARITAL_STATUS,
   ROUND(SUM(oi.quantity * oi.unit_price), 2) AS Total_Dollars,
   Format_Date('%Y',o.ORDER_DATE) as Order_Year,
   RANK() OVER ( Order By ROUND(SUM(oi.quantity * oi.unit_price), 2) Desc) as Rank_Number
FROM `order_entry_dataset.customers` as c
INNER JOIN `order_entry_dataset.orders` as o USING (customer_ID)
INNER JOIN `order_entry_dataset.order_items`  as oi USING (order_ID)
Group by c.MARITAL_STATUS, Order_Year
Order by Rank_Number;

#Write a SQL statement to show the total dollar amount sold across product categories for all orderable products. Calculate the percentage contribution of each product category’s sales to the overall total sales
WITH Calculation AS (
  SELECT 
    p.CATEGORY_NAME,
    round(SUM(oi.quantity * oi.unit_price) OVER(PARTITION BY p.category_name)  / SUM(oi.quantity * oi.unit_price) OVER(),2 ) * 100 AS Sales_Contribution_Percentage
  FROM `order_entry_dataset.order_items` AS oi
  INNER JOIN `order_entry_dataset.products` AS p USING (product_ID)
  WHERE p.PRODUCT_STATUS = 'orderable'
),
TotalDollars as(
  SELECT 
    p.CATEGORY_NAME,
    round(sum(oi.quantity*oi.unit_price), 2) as Total_Dollars
  FROM `order_entry_dataset.order_items` AS oi
  INNER JOIN `order_entry_dataset.products` AS p USING (product_ID)
  WHERE p.PRODUCT_STATUS = 'orderable'
  group by p.CATEGORY_NAME
)

SELECT 
  p.CATEGORY_NAME,
  TotalDollars.Total_Dollars,
  Calculation.Sales_Contribution_Percentage
FROM `order_entry_dataset.products` AS p
INNER JOIN Calculation ON p.CATEGORY_NAME = Calculation.CATEGORY_NAME
Inner Join TotalDollars on p.CATEGORY_NAME = TotalDollars.category_name 
WHERE p.PRODUCT_STATUS = 'orderable'
group by p.CATEGORY_NAME, Calculation.Sales_Contribution_Percentage,TotalDollars.Total_Dollars
order by 3 desc;

#Write a SQL statement to show the most profitable product overall orders. (unit price above Min Price).Only consider products that are available in the US or Canadian warehouses with list price over $50.
Select 
    Product_Name,
    Max(Unit_Profit) as Most_Unit_Profit
   
From(
    Select  
      p.product_name as Product_Name,
      sum(oi.unit_price - p.min_price) AS Unit_Profit
    FROM `order_entry_dataset.products` p
      JOIN `order_entry_dataset.order_items` oi ON p.product_id = oi.product_id
      JOIN `order_entry_dataset.inventoriess` i ON p.product_id = i.product_id
      JOIN `order_entry_dataset.warehouses` w ON i.warehouse_id = w.warehouse_id
    Where oi.unit_price > p.MIN_PRICE 
      and p.list_price > 50 
      and w.country in ('US','CA')
    Group by Product_Name
  )
group by Product_Name
Limit 1;

Select 
  Month_Year,
  MonthLy_Total_Dollars,
  Prev_Month_Dollars,
  Monthly_Total_Dollars - Prev_Month_Dollars as Monthly_Sales_Different,
  100 * (Monthly_Total_Dollars - Prev_Month_Dollars)  / Prev_Month_Dollars as Percentage_Sales_Increase
  From(
    select 
      Month_Year,
      Monthly_Total_Dollars,
      lag(Monthly_Total_Dollars,1,0) over (Order by Month_Year) as Prev_Month_Dollars

    From (
      select
        format_Date('%m-%Y', o.order_date) as Month_Year,
        round(sum(oi.quantity * oi. unit_price),2) as Monthly_Total_Dollars
        
      from 
        `order_entry_dataset.orders` as o
        join `order_entry_dataset.order_items` as oi on o.order_ID = oi.order_ID
      Group by
        Month_Year
      Order by 1 Desc
    )
  )
WHERE Prev_Month_Dollars <> 0
ORDER BY Month_Year
Limit 1;

#Who is the “best” Sales Manager? Justify your rationale and back it up with queries and data. You may also wish to graph various data to support your justification. DO NOT just total up sales. Consider multiple factors and build a weighted model with SQL. Look at other tables beyond just orders
select
  First_Name,
  Last_Name,
  Rep_ID,
  Total_Sales,
  Order_By_Rep_Count
from(
  select 
    First_Name,
    Last_Name,
    o.Sales_Rep_Id as Rep_ID,
    count(o.SALES_REP_ID) as Order_By_Rep_Count,
    sum(oi.quantity*oi.unit_Price) as Total_Sales 
  From `order_entry_dataset.salesreps` as s
  Inner Join `order_entry_dataset.orders` as o on s.employee_id = o.SALES_REP_ID
  inner join `order_entry_dataset.order_items` as oi on o.order_id = oi.order_id
  Group by First_Name, Last_Name,o.Sales_Rep_Id
)
order by Total_Sales desc
limit 1;


