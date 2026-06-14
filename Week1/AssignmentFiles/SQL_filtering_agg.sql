-- ==================================
-- FILTERS & AGGREGATION
-- ==================================

USE coffeeshop_db;


-- I have used navicat.com, geeksforgeeks.org, w3schools.com and stackoverflow.com to figure out 
-- a lot of the commands that I used in many of these queries. I also did a lot of google.com 
-- searches and did not realise I had AI assist turned on, so a lot of my searches used AI. 
-- I used google.com searches in all three of these Week 1 Basic practice prompts, I say this to 
-- acknowledge that AI assisted in many on my responses. 
-- I had seen the use of COUNT, ROUND, and SUM before, but had to research the CASE and the 
-- DATE commands stuff, a lot. I needed a lot of help with Q4, Q5, Q6, Q8, Q11, and Q12.

-- Q1) Compute total items per order.
--     Return (order_id, total_items) from order_items.
select order_id, COUNT(*) as total_items
	from order_items
	group by order_id;
-- Q2) Compute total items per order for PAID orders only.
--     Return (order_id, total_items). Hint: order_id IN (SELECT ... FROM orders WHERE status='paid').
select order_id, COUNT(*) as total_items
	from orders
	where status = 'paid'
	group by order_id;
-- Q3) How many orders were placed per day (all statuses)?
--     Return (order_date, orders_count) from orders.
select DATE(order_datetime), COUNT(*) as orders_count 
	from orders
	group by DATE(order_datetime);
-- Q4) What is the average number of items per PAID order?
--     Use a subquery or CTE over order_items filtered by order_id IN (...).
-- I struggled with this, and thought I had it correct, but it was covered in class
-- and the answer was different from mine, so I corrected my response.
with total_items as (
	select order_id, customer_id, store_id 
    from orders
    where status = 'paid')
select AVG(order_items.quantity) 
	from order_items
    where order_id in (select order_id from total_items);
-- Q5) Which products (by product_id) have sold the most units overall across all stores?
--     Return (product_id, total_units), sorted desc.
select product_id, total_units
	from (select product_id , SUM(quantity) as total_units 
				from order_items
				group by product_id)
	as product_sales
	order by total_units desc;
-- Q6) Among PAID orders only, which product_ids have the most units sold?
--     Return (product_id, total_units_paid), sorted desc.
--     Hint: order_id IN (SELECT order_id FROM orders WHERE status='paid').
select product_id, SUM(quantity) as total_units_sold
	from order_items
	where order_id in
		(select order_id from orders where status = 'paid')
			group by product_id 
			order by total_units_sold desc;
-- Q7) For each store, how many UNIQUE customers have placed a PAID order?
--     Return (store_id, unique_customers) using only the orders table.
select store_id, COUNT(DISTINCT customer_id) as unique_customers
	from orders 
	where status = 'paid'
	group by store_id;
-- Q8) Which day of week has the highest number of PAID orders?
--     Return (day_name, orders_count). Hint: DAYNAME(order_datetime). Return ties if any.
-- Not sure that I really understood what is expected, but this is what I got. 
select day_name, orders_count
	from (select DAYNAME(order_datetime) as day_name,
			COUNT(*) as orders_count
			from orders
			where status = 'paid'
			group by day_name
) as day_counts
	where orders_count = (select MAX(orders_count)
		from (select COUNT(*) as orders_count
				from orders
				where status = 'paid'
				group by DAYNAME(order_datetime)
) as max_counts);
-- Q9) Show the calendar days whose total orders (any status) exceed 3.
--     Use HAVING. Return (order_date, orders_count).
-- Maybe I am missing something, but I don't get any output for this one, no matter what I try
-- Covered this in class, suggestion to lower order_count to 1 so there is output.
select DATE(order_datetime) as order_date, COUNT(order_id) as orders_count 
from orders
group by order_date
having orders_count > 1; 
-- Q10) Per store, list payment_method and the number of PAID orders.
--      Return (store_id, payment_method, paid_orders_count).
select store_id, payment_method, COUNT(*) as paid_orders_count
from orders
where status = 'paid'
group by store_id, payment_method
order by store_id, payment_method;
-- Q11) Among PAID orders, what percent used 'app' as the payment_method?
--      Return a single row with pct_app_paid_orders (0–100).
-- This one, by far, was the most complicated of these queries. Had to spend a lot of time 
-- researching the if-then-else stuff. Tried several versions, used COUNT, AVG and SUM.
-- I think this one is correct.
with paid_orders as (
    select payment_method
    from orders
    where status = 'paid'
)
select
    ROUND(SUM(payment_method = 'app') * 100.0 / COUNT(*), 2) as pct_app_paid_orders
from paid_orders;
-- Q12) Busiest hour: for PAID orders, show (hour_of_day, orders_count) sorted desc.
select HOUR(order_datetime) as hour_of_day, COUNT(*) as orders_count
from orders
where status = 'paid'
group by hour_of_day
order by orders_count desc;
-- ================
