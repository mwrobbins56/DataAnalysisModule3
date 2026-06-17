USE coffeeshop_db;

-- =========================================================
-- ADVANCED SQL ASSIGNMENT
-- Subqueries, CTEs, Window Functions, Views
-- =========================================================
-- Notes:
-- - Unless a question says otherwise, use orders with status = 'paid'.
-- - Write ONE query per prompt.
-- - Keep results readable (use clear aliases, ORDER BY where it helps).

-- I continued to use these sites: navicat.com, geeksforgeeks.org, w3schools.com and stackoverflow.com to help 
-- figure out a lot of the commands that I used in many of these queries. I also did a lot of google.com 
-- searches and which have AI assist turned on, so a lot of my searches used AI. 
-- I used google.com searches in these practice prompts, I say this to 
-- acknowledge that AI assisted in many on my responses. 
-- I have also tried to do better on the readability of my code.

-- =========================================================
-- Q1) Correlated subquery: Above-average order totals (PAID only)
-- =========================================================
-- For each PAID order, compute order_total (= SUM(quantity * products.price)).
-- Return: order_id, customer_name, store_name, order_datetime, order_total.
-- Filter to orders where order_total is greater than the average PAID order_total
-- for THAT SAME store (correlated subquery).
-- Sort by store_name, then order_total DESC.
-- These are very complicated, which I appreciate, but it just means I have spent a lot of time on each.
select 
	o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    s.name as store_name,
    o.order_datetime,
    SUM(oi.quantity * p.price) as order_total
from orders o
join customers c on o.customer_id = c.customer_id
join stores s on o.store_id = s.store_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.status = 'paid'
group by o.order_id, c.first_name, c.last_name, s.store_id, s.name, o.order_datetime
having SUM(oi.quantity * p.price) > (
    select 
		avg(store_order_total)
    from (
        select 
			SUM(oi2.quantity * p2.price) as store_order_total
        from orders o2
        join order_items oi2 on o2.order_id = oi2.order_id
        join products p2 on oi2.product_id = p2.product_id
        where o2.status = 'paid'
        group by o2.order_id
    ) as store_avg
)
order by s.name, SUM(oi.quantity * p.price) desc;
-- =========================================================
-- Q2) CTE: Daily revenue and 3-day rolling average (PAID only)
-- =========================================================
-- Using a CTE, compute daily revenue per store:
--   revenue_day = SUM(quantity * products.price) grouped by store_id and DATE(order_datetime).
-- Then, for each store and date, return:
--   store_name, order_date, revenue_day,
--   rolling_3day_avg = average of revenue_day over the current day and the prior 2 days.
-- Use a window function for the rolling average.
-- Sort by store_name, order_date.
-- This one was covered in class.
with daily_rev_store as (
	select 
		o.store_id, 
		DATE(o.order_datetime) as order_date,
		SUM(oi.quantity * p.price) as revenue_day
	from orders o
	join order_items oi on oi.order_id = o.order_id
	join products p on p.product_id = oi.product_id
	where o.status = 'paid'
	group by o.store_id, order_date)
select 
	stores.name, 
    daily_rev_store.order_date, 
	daily_rev_store.revenue_day, 
    ROUND(
		AVG(daily_rev_store.revenue_day) OVER(
        partition by daily_rev_store.store_id
		order by daily_rev_store.order_date
		rows between 2 preceding and current row), 2
		) as rolling_3day_avg
from daily_rev_store
join stores on stores.store_id = daily_rev_store.store_id
order by stores.name, order_date;
-- =========================================================
-- Q3) Window function: Rank customers by lifetime spend (PAID only)
-- =========================================================
-- Compute each customer's total spend across ALL stores (PAID only).
-- Return: customer_id, customer_name, total_spend,
--         spend_rank (DENSE_RANK by total_spend DESC).
-- Also include percent_of_total = customer's total_spend / total spend of all customers.
-- Sort by total_spend DESC.
with customer_total as (
    select 
		c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        SUM(oi.quantity * p.price) as total_spend
    from customers c
    join orders o on c.customer_id = o.customer_id
    join order_items oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    where o.status = 'paid'
    group by c.customer_id, c.first_name, c.last_name)
select 
	customer_id,
    customer_name,
    total_spend,
    dense_rank() over (order by total_spend desc) as spend_rank,
    ROUND(total_spend / SUM(total_spend) over () * 100, 2) as percent_of_total
from customer_total
order by total_spend desc;
-- =========================================================
-- Q4) CTE + window: Top product per store by revenue (PAID only)
-- =========================================================
-- For each store, find the top-selling product by REVENUE (not units).
-- Revenue per product per store = SUM(quantity * products.price).
-- Return: store_name, product_name, category_name, product_revenue.
-- Use a CTE to compute product_revenue, then a window function (ROW_NUMBER)
-- partitioned by store to select the top 1.
-- Sort by store_name.
with product_revenue as (
    select 
		s.store_id,
        s.name as store_name,
        p.name as product_name,
        ca.name as category_name,
        SUM(oi.quantity * p.price) as product_revenue
    from stores s
    join orders o on s.store_id = o.store_id
    join order_items oi on o.order_id = oi.order_id
    join products p on oi.product_id = p.product_id
    join categories ca on p.category_id = ca.category_id
    where o.status = 'paid'
    group by s.store_id, s.name, p.product_id, p.name, ca.name
), ranked as (
    SELECT 
		store_name,
        product_name,
        category_name,
        product_revenue,
        row_number() over (partition by store_id
            order by product_revenue desc
        ) as rnk
    from product_revenue
) select
    store_name,
    product_name,
    category_name,
    product_revenue
from ranked
where rnk = 1
order by store_name;
-- =========================================================
-- Q5) Subquery: Customers who have ordered from ALL stores (PAID only)
-- =========================================================
-- Return customers who have at least one PAID order in every store in the stores table.
-- Return: customer_id, customer_name.
-- Hint: Compare count(distinct store_id) per customer to (select count(*) from stores).
-- This query was confusing, I got output but I don't feel good about it. 
select 
	c.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) as customer_name
from customers c
join orders o on c.customer_id - o.customer_id
where o.status = 'paid'
group by c.customer_id, c.first_name, c.last_name
having COUNT(distinct o.store_id) = (select COUNT(*) from stores);
-- =========================================================
-- Q6) Window function: Time between orders per customer (PAID only)
-- =========================================================
-- For each customer, list their PAID orders in chronological order and compute:
--   prev_order_datetime (LAG),
--   minutes_since_prev (difference in minutes between current and previous order).
-- Return: customer_name, order_id, order_datetime, prev_order_datetime, minutes_since_prev.
-- Only show rows where prev_order_datetime is NOT NULL.
-- Sort by customer_name, order_datetime.
-- The timestampdiff function is the best way that I could find to get the correct difference in minutes.
with paid_orders as (
    select 
		CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        o.order_id,
        o.order_datetime,
        LAG(o.order_datetime) over (partition by o.customer_id
            order by o.order_datetime
        ) as prev_order_datetime
    from orders o
    join customers c on o.customer_id = c.customer_id
    where o.status = 'paid'
) select 
	customer_name,
    order_id,
    order_datetime,
    prev_order_datetime,
    timestampdiff(minute, prev_order_datetime, order_datetime) as minutes_since_prev
from paid_orders
where prev_order_datetime is not null
order by customer_name, order_datetime;
-- =========================================================
-- Q7) View: Create a reusable order line view for PAID orders
-- =========================================================
-- Create a view named v_paid_order_lines that returns one row per PAID order item:
--   order_id, order_datetime, store_id, store_name,
--   customer_id, customer_name,
--   product_id, product_name, category_name,
--   quantity, unit_price (= products.price),
--   line_total (= quantity * products.price)
-- ============================================
-- This was the most frustrating so far, the view was not that difficult to get
-- but I got the view created but the select view query was not correct. 
-- And once I think it was correct it still would not run so I struggled for a while. 
-- So after several more tweaks to the view (after some research), and to get the  
-- entire thing to work I added the 'or replace' to get it all to run finally.
create or replace view v_paid_order_lines as
select
    o.order_id,
    o.order_datetime,
    s.store_id,
    s.name as store_name,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    p.product_id,
    p.name as product_name,
    cat.name as category_name,
    oi.quantity,
    p.price as unit_price,
    oi.quantity * p.price as line_total
from orders o
join stores s on o.store_id = s.store_id
join customers c on o.customer_id = c.customer_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
join categories cat on p.category_id = cat.category_id
where o.status = 'paid';
-- After creating the view, write a SELECT that uses the view to return:
--   store_name, category_name, revenue
-- where revenue is SUM(line_total),
-- sorted by revenue DESC.
select store_name, category_name, SUM(line_total) as revenue
from v_paid_order_lines
group by store_name, category_name
order by revenue desc;
-- =========================================================
-- Q8) View + window: Store revenue share by payment method (PAID only)
-- =========================================================
-- Create a view named v_paid_store_payments with:
--   store_id, store_name, payment_method, revenue
-- where revenue is total PAID revenue for that store/payment_method.
-- This one was similar to the previous one, but I figured it out a little quicker.
-- Since I knew I would need to rerun this query to get it, I put 'or replace' to start.
create or replace view v_paid_store_payments as
select 
	s.store_id,
    s.name as store_name,
    o.payment_method,
    SUM(oi.quantity * p.price) as revenue
from stores s 
join orders o on s.store_id = o.store_id
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.status = 'paid'
group by s.store_id, store_name, o.payment_method;
-- Then query the view to return:
--   store_name, payment_method, revenue,
--   store_total_revenue (window SUM over store),
--   pct_of_store_revenue (= revenue / store_total_revenue)
-- Sort by store_name, revenue DESC.
-- This query the view was more complicated, but the problems I had there helped me figure this one. 
select 
	store_name,
    payment_method,
    revenue,
    SUM(revenue) over (partition by store_id) as store_total_revenue,
    ROUND(revenue / SUM(revenue) over (Partition by store_id) * 100, 2) as pct_of_store_revenue
from v_paid_store_payments
order by store_name, revenue desc;
-- =========================================================
-- Q9) CTE: Inventory risk report (low stock relative to sales)
-- =========================================================
-- Identify items where on_hand is low compared to recent demand:
-- Using a CTE, compute total_units_sold per store/product for PAID orders.
-- Then join inventory to that result and return rows where:
--   on_hand < total_units_sold
-- Return: store_name, product_name, on_hand, total_units_sold, units_gap (= total_units_sold - on_hand)
-- Sort by units_gap DESC.
-- The problem here is that on-hand amounts are high and the highest number of units sold.
-- So, as written there is no output using the db, so I switched the numbers to show high stock numbers.
with total_units as (
    select
        o.store_id,
        oi.product_id,
        SUM(oi.quantity) as total_units_sold
    from orders o
    join order_items oi on o.order_id = oi.order_id
    where o.status = 'paid'
    group by o.store_id, oi.product_id
)
select
    s.name as store_name,
    p.name as product_name,
    i.on_hand,
    t.total_units_sold,
    i.on_hand - t.total_units_sold as units_gap
from inventory i
join total_units t on i.store_id = t.store_id and i.product_id  = t.product_id
join stores s on i.store_id = s.store_id
join products p on i.product_id  = p.product_id
where i.on_hand > t.total_units_sold
order by units_gap desc;