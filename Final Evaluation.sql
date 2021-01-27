USE mavenfuzzyfactory;


SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM website_sessions;

SELECT *
FROM website_pageviews;



/*
1. First, I’d like to show our volume growth. Can you pull overall session and order volume, 
trended by quarter for the life of the business? Since the most recent quarter is incomplete, 
you can decide how to handle it.
*/ 

SELECT YEAR(A.created_at) AS yr,
	   QUARTER(A.created_at) AS quarter,
       COUNT(DISTINCT(A.website_session_id)) AS total_sessions,
       COUNT(DISTINCT(order_id)) AS total_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;



/*
2. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures 
since we launched, for session-to-order conversion rate, revenue per order, and revenue per session. 
*/

SELECT YEAR(A.created_at) AS yr,
	   QUARTER(A.created_at) AS quarter,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS session_to_order_conv_rate,
       SUM(price_usd) / COUNT(DISTINCT(order_id)) AS rev_per_order,
       SUM(price_usd) / COUNT(DISTINCT(A.website_session_id)) AS rev_per_session
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;



/*
3. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders 
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/

SELECT 
	YEAR(A.created_at) AS yr,
	QUARTER(A.created_at) AS quarter,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS bsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS overall_brand_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
GROUP BY 1, 2;



/*
4. Next, let’s show the overall session-to-order conversion rate trends for those same channels, 
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/

SELECT 
	YEAR(A.created_at) AS yr,
	QUARTER(A.created_at) AS quarter,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN A.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN A.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN A.website_session_id ELSE NULL END) AS overall_brand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN A.website_session_id ELSE NULL END) AS organic_search_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) /
		COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN A.website_session_id ELSE NULL END) AS direct_type_in_conv_rate
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
GROUP BY 1, 2;



/*
5. We’ve come a long way since the days of selling a single product. Let’s pull monthly trending for revenue 
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/

SELECT YEAR(created_at) AS yr,
	   MONTH(created_at) AS mo,
       SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
       SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_margin,
       SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
       SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_margin,
       SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
       SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_margin,
       SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
       SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_margin,
       COUNT(DISTINCT(order_id)) AS total_sales,
       SUM(price_usd) AS total_revenue,
       SUM(price_usd - cogs_usd) AS total_margin
FROM order_items
GROUP BY 1, 2
ORDER BY 1, 2;



/*
6. Let’s dive deeper into the impact of introducing new products. Please pull monthly sessions to 
the /products page, and show how the % of those sessions clicking through another page has changed 
over time, along with a view of how conversion from /products to placing an order has improved.
*/

CREATE TEMPORARY TABLE products_pageview
SELECT website_session_id,
	   website_pageview_id,
       created_at AS saw_product_page_at
FROM website_pageviews
WHERE pageview_url = '/products';

SELECT *
FROM products_pageview;

SELECT YEAR(A.saw_product_page_at) AS yr,
	   MONTH(A.saw_product_page_at) AS mo,
       COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(B.website_session_id)) AS clicked_next_page,
       COUNT(DISTINCT(B.website_session_id)) / COUNT(DISTINCT(A.website_session_id)) AS clickthrough_rate,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS products_to_order_rate
FROM products_pageview AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
AND A.website_pageview_id < B.website_pageview_id
LEFT JOIN orders AS C
ON A.website_session_id = C.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2;

—- test

/*
7. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item). 
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/

CREATE TEMPORARY TABLE primary_products
SELECT order_id,
	   primary_product_id,
       created_at AS ordered_at
FROM orders
WHERE created_at > '2014-12-05';


SELECT A.*,
	   B.product_id AS cross_sell_product_id
FROM primary_products AS A
LEFT JOIN order_items AS B
ON A.order_id = B.order_id
AND B.is_primary_item = 0;


SELECT primary_product_id,
	   COUNT(DISTINCT order_id) AS total_orders, 
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS p1_cross_sold,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS p2_cross_sold,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS p3_cross_sold,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS p4_cross_sold,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS p1_cross_sell_rate,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS p2_cross_sell_rate,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS p3_cross_sell_rate,
       COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS p4_cross_sell_rate
FROM(
SELECT A.*,
	   B.product_id AS cross_sell_product_id
FROM primary_products AS A
LEFT JOIN order_items AS B
ON A.order_id = B.order_id
AND B.is_primary_item = 0
) AS with_cross_sell_product
GROUP BY 1;
