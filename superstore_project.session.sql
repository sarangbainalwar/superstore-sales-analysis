select *
FROM orders

 --1. Total Sales, Total Profit, and Total Orders
select count(*) as total_orders,
    sum(sales) as total_sales,
    sum(profit) as total_profit
from orders;

--2. Top 10 Selling Products by Quantity
select category,
    "sub-category",
    product_name,
    quantity
FROM orders
order by quantity desc
limit 10;

--3. Top 5 customers by revenue
select customer_name,
    round(sum(sales)::numeric, 2) as Revenue
from orders
GROUP BY customer_name
ORDER BY Revenue DESC
limit 5

--4. Which 5 States had the highest total sales?
select state,
    round(sum(sales)::numeric,2) as total_sales
from orders
GROUP by state
order by total_sales desc
limit 5;


--5. Get all orders that had more than 20% discount.
select *
from orders 
where discount > 0.2

--6. Monthly Sales Trend: Sales by month-year

select extract(month from order_date) as month,
round(sum(sales)::numeric,2) as Monthly_sales
from orders 
group by 1
order by 1 desc

-- 7. Calculate average delivery time in days (ship_date - order_date)

SELECT 
  ROUND(AVG((ship_date::date - order_date::date)::int), 2) AS avg_delivery_days
FROM 
  orders;

-- 8.Year-wise profit trend (Which year had loss or max profit?

select extract(year from order_date) as year,sum(profit) as total_profit
from orders 
group by year
order by total_profit asc 

-- 9. Sales and Profit by Category & Sub-Category
SELECT 
    category,
    "sub-category",
    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit
FROM orders
GROUP BY category, "sub-category"
ORDER BY category, total_sales DESC;


-- 10. Segment-wise profit margins

SELECT 
    segment,
    ROUND(SUM(sales)::numeric, 2) AS total_sales,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,
        CASE 
            WHEN SUM(sales) = 0 THEN 0
            ELSE (SUM(profit) / SUM(sales)) * 100
        END
     AS profit_margin_percent
FROM orders 
GROUP BY segment
ORDER BY profit_margin_percent DESC;

--11.Join with Returns: Which customers have the most returned orders?

select o.customer_name,count(*) as total_returns
from orders o 
join returns r 
on o.order_id = r.order_id
group by o.customer_name
order by count(*) DESC 
limit 1;

--12. Return rate per region (how many % of orders were returned?)

SELECT
    t1.region,
    round(t1.num_of_returns::numeric / t2.total_orders*100::numeric,2)  AS return_ratio      -- cast fixes integer math
FROM (
    SELECT o.region, COUNT(*) AS num_of_returns
    FROM orders o
    JOIN returns r  ON r.order_id = o.order_id
    GROUP BY o.region
) AS t1
JOIN (
    SELECT region, COUNT(*) AS total_orders
    FROM orders
    GROUP BY region
) AS t2
  ON t1.region = t2.region
  order by return_ratio;

--13. Create a region-wise sales summary using a CTE that shows total sales, total profit, and total quantity.

select region,round(sum(sales)::numeric,2) as total_sales,sum(profit) as total_profit,sum(quantity) as total_quantity
from orders 
group by region

--14.Find customers who placed more than 10 orders and also had at least 1 returned order (use orders and returns).

select o.customer_name
from orders o 
join returns r 
on o.order_id = r.order_id
group by customer_name
having count(*) > 10

-- Advanced SQL Tasks on Superstore Dataset (PostgreSQL)
--15.Running Total of Monthly Sales

select 
extract(month from order_date) as month,
round(sum(sales)::numeric,2) as monthly_sales,
round(sum(sum(sales)) over (order by extract(month from order_date))::numeric,2) as running_total_sales
from orders
group by month 
order by month

--changing column name from "sub-category" tp "sub_category"
alter table orders
rename column "sub-category" to sub_category

--16. Rank Sub-Categories Within Categories by Profit

select category,sub_category,
rank() over(partition by category order by sum(profit) desc) as profit_rank,round(sum(profit)::numeric,2) as total_profit
from ORDERs
group by category,sub_category
order by category, profit_rank

--17. identify products that are frequently returned and their return rates

with return_products as 
(select o.order_id,o.product_name
from orders o
join returns r
on o.order_id = r.order_id)

select rp.product_name,oc.total_orders, count(*) as return_count,
    round(count(*)::numeric / oc.total_orders * 100, 2) as return_rate
from return_products rp
join (
    select o.product_name,count(*) as total_orders
    from orders o
    group by o.product_name
) as  oc 
on rp.product_name = oc.product_name
group by rp.product_name, oc.total_orders
order by return_rate desc;

--18. Customer Loyalty score using CASE.
select customer_id,customer_name,
count(distinct order_id) as total_orders,
sum(sales) as total_sales,
case 
when count(distinct order_id) >= 10 then 'Gold'
when count(distinct order_id) BETWEEN 5 and 9 then 'silver'
else 'Bronze'
end as loyalty_score
from orders
group by customer_id,customer_name
order by total_sales desc;