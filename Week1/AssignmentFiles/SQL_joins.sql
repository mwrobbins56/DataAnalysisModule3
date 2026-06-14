USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- I have used navicat.com, geeksforgeeks.org, w3schools.com and stackoverflow.com to figure out 
-- a lot of the commands that I used in many of these queries. I also did a lot of google.com 
-- searches and did not realise I had AI assist turned on, so a lot of my searches used AI. 
-- I used google.com searches in all three of these Week 1 Basic practice prompts, I say this to 
-- acknowledge that AI assisted in many on my responses. 

-- Q1) Join products to categories: list product_name, category_name, price.
-- I figured this one out from the examples in TopHat
select products.name as product_name, 
	categories.name as category_name, 
    products.price
		from products
		inner join categories
		on products.category_id = categories.category_id;
-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
-- For this one I found how to join several tables in the same query on dba.stackexchange.com.
select order_items.order_id, 
	   orders.order_datetime, 
       stores.name as store_name, 
	   products.name as product_name, 
       order_items.quantity, 
	   (order_items.quantity * products.price) as line_total
		from order_items
		inner join orders on order_items.order_id = orders.order_id
		inner join stores on orders.store_id = stores.store_id
		inner join products on order_items.product_id = products.product_id
		order by orders.order_datetime, order_items.order_id;
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
-- I went to stackoverflow.com to see this one.
select CONCAT(customers.first_name, ' ', customers.last_name) as customer_name,
	stores.name as store_name, 
    orders.order_datetime, 
	SUM(order_items.quantity * products.price) as order_total
from orders
	join customers on orders.customer_id = customers.customer_id
	join stores on orders.store_id = stores.store_id
	join order_items on orders.order_id = order_items.order_id
	join products on order_items.product_id = products.product_id
where orders.status = 'paid'
group by orders.order_id, customer_name, store_name, orders.order_datetime;
-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
-- I finally got this to work and then got no output. Looking at the database, I can see that 
-- there are no customers that have never placed an order. 
select customers.first_name, customers.last_name, customers.city, customers.state
from customers
left join orders on customers.customer_id = orders.customer_id
where orders.order_id is null;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
-- This was the toughest one yet, I could not get it to work with ROW_NUMBER 
-- but while looking at PARTITION BY I found the DENSE_RANK command and got it to work.
-- Found help with CTE (with) on geeksforgeeks.org for the best explanations.  
-- I spent a lot of time here.
with top_sales as (select stores.name as store_name, products.name as product_name, 
	SUM(order_items.quantity) as total_units,
	row_number() over (partition by stores.store_id 
	order by SUM(order_items.quantity)desc) as store_rank
from stores
	join orders on stores.store_id = orders.store_id
	join order_items on orders.order_id = order_items.order_id
	join products on order_items.product_id = products.product_id
where orders.status = 'paid'
group by stores.store_id, products.product_id, products.name)
select store_name, product_name, total_units
	from top_sales
	where store_rank = 1;
-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
-- This was less complicated with just using joins. Uses things learned earlier.
select stores.name as store_name, products.name as product_name, inventory.on_hand
	from inventory
	join stores on inventory.store_id = stores.store_id
	join products on inventory.product_id = products.product_id
where inventory.on_hand < 12 
order by store_name, product_name;
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
-- This one is less comlicated also, used stuff learned previously.
select stores.name as store_name, 
	CONCAT(employees.first_name, ' ', employees. last_name) as manager_name, 
	employees.hire_date
from employees
join stores on employees.store_id = stores.store_id
where title = 'Manager';
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
-- Back to the more difficult queries. Spent a lot of time on this one, had to go back and 
-- look at the subquery and CTE (with) stuff again. Went back to geeksforgeeks.org for help. 
with product_revenue as (
	select products.name as product_name, 
		SUM(order_items.quantity * products.price) as total_revenue
	from products
	join order_items on products.product_id = order_items.product_id
	join orders on order_items.order_id = orders.order_id
	where orders.status = 'paid'
	group by products.product_id, product_name)
select product_name, total_revenue
from product_revenue
where total_revenue > (select AVG(total_revenue) from product_revenue)
order by total_revenue;
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
-- I had looked up and used the CONCAT function earlier. I think this is correct, especially
-- since as far as I can tell there are no customers with no orders.
select CONCAT(customers.first_name, ' ', customers.last_name) as customer_name,
	MAX(orders.order_datetime) as last_paid_order_date
	from customers
	left join orders on customers.customer_id - orders.customer_id and orders.status = 'paid'
	group by customer_name;
-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
-- This one was complicated also, but I think I figured it out. It did take a bit to figure 
-- out that I needed both group by and order by to get the output.
select stores.name as store_name, categories.name as category_name, 
	SUM(order_items.quantity) as total_units,
	SUM(order_items.quantity * products.price) as total_revenue
		from stores
		join orders on stores.store_id = orders.store_id
		join order_items on orders.order_id = order_items.order_id
		join products on order_items.product_id = products.product_id
		join categories on products.category_id = categories.category_id
	where orders.status = 'paid'
		group by store_name, category_name
		order by store_name, category_name;