USE coffeeshop_db;

-- =========================================================
-- SUBQUERIES & NESTED LOGIC PRACTICE
-- =========================================================

-- I used these sites again: navicat.com, geeksforgeeks.org, w3schools.com and stackoverflow.com to help 
-- figure out a lot of the commands that I used in many of these queries. I also did a lot of google.com 
-- searches and which have AI assist turned on, so a lot of my searches used AI. 
-- I used google.com searches in these practice prompts, I say this to 
-- acknowledge that AI assisted in many on my responses. 
-- I have also tried to do better on the readability of my code.

-- Q1) Scalar subquery (AVG benchmark):
--     List products priced above the overall average product price.
--     Return product_id, name, price.
-- I added the avg_overal_price column while testing so I could see the average price shown. 
-- Using 'select avg(price) from products' 2X took several tries to figure out. I think it is correct. 
SELECT product_id,
    name,
    price
--  (select avg(price) from products) as avg_overall_price
from products
where price > (select avg(price) from products)
order by price desc;
-- Q2) Scalar subquery (MAX within category):
--     Find the most expensive product(s) in the 'Beans' category.
--     (Return all ties if more than one product shares the max price.)
--     Return product_id, name, price.
-- I have tried to always use the table names instead of the shorter names (like products instead of p),
-- but using the short names (p, p2, c, c2) had to be used in the subquery since it uses the 
-- sames tables as the main part of the query. 
select p.product_id,
    p.name,
    p.price
from products p
join categories c on p.category_id = c.category_id
where c.name = 'Beans' 
	and p.price = (
    select MAX(p2.price)
		from products p2
        join categories c2 on p2.category_id = c2.category_id
		where c2.name = 'Beans');
-- Q3) List subquery (IN with nested lookup):
--     List customers who have purchased at least one product in the 'Merch' category.
--     Return customer_id, first_name, last_name.
--     Hint: Use a subquery to find the category_id for 'Merch', then a subquery to find product_ids.
-- I had to really look through the database to see exactly what the correct answer would be, 
-- Merch is category_id 5, the Merch products are Mugs and T-Shirts, product_ids 11 and 12. 
-- Figuring that info out helped me get a better understanding of how to get this completed. 
select customer_id,
    first_name,
    last_name
    from customers 
    where customer_id in (
		select o.customer_id
        from orders o
        join order_items oi on o.order_id = oi.order_id
        where oi.product_id in (
			select p.product_id 
            from products p 
            where p.category_id = (
				select c.category_id 
                from categories c
                where c.name = 'Merch')
		)
	);
-- Q4) List subquery (NOT IN / anti-join logic):
--     List products that have never been ordered (their product_id never appears in order_items).
--     Return product_id, name, price.
-- When I looked through the database, I could see that there would be no output from this query, 
-- 12 separate product_ids and all 12 are listed in the order_items table. 
select product_id,
	   name,
       price
       from products
       where product_id not in (
		   select distinct product_id 
           from order_items);
-- Q5) Table subquery (derived table + compare to overall average):
--     Build a derived table that computes total_units_sold per product
--     (SUM(order_items.quantity) grouped by product_id).
--     Then return only products whose total_units_sold is greater than the
--     average total_units_sold across all products.
--     Return product_id, product_name, total_units_sold.
-- I had to do many searches to finally figure this one out, I believe it is correct. 
-- The derived table was very difficult to get. 
select p.product_id,
    p.name as product_name,
    sold.total_units_sold
from products p
join (select product_id,
        SUM(quantity) as total_units_sold
    from order_items
    group by product_id
) as sold on p.product_id = sold.product_id
where sold.total_units_sold > (
    select avg(total_units_sold)
    from (select SUM(quantity) as total_units_sold
        from order_items
        group by product_id
    ) as get_avg
);