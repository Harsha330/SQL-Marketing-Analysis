USE mavenfuzzyfactory;

SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM website_sessions;

SELECT *
FROM website_pageviews;



-- #1

SELECT YEAR(created_at) AS yr,
	   MONTH(created_at) AS mo,
       COUNT(DISTINCT(order_id)) AS number_of_sales,
       SUM(price_usd) AS total_revenue,
       SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1, 2;



-- #2

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS conv_rate,
       SUM(price_usd) / COUNT(DISTINCT(A.website_session_id)) AS revenue_per_session,
       COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
       COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at > '2012-04-01'
AND A.created_at < '2013-04-05'
GROUP BY 1, 2;



-- #3

-- step 1: find the /products pageviews we care about
CREATE TEMPORARY TABLE products_pv
SELECT website_session_id,
	   website_pageview_id,
       created_at,
       CASE
			WHEN created_at < '2013-01-06' THEN 'A.Pre_Product_2'
            WHEN created_at >= '2013-01-06' THEN 'B.Post_Product_2'
            ELSE 'something is wrong'
	   END AS time_period
FROM website_pageviews
WHERE created_at < '2013-04-06'
AND created_at > '2012-10-06'
AND pageview_url = '/products';

SELECT *
FROM products_pv;


-- step 2: find the next page views AFTER the products page view
CREATE TEMPORARY TABLE sessions_w_next_pv
SELECT A.time_period,
	   A.website_session_id,
       MIN(B.website_pageview_id) AS min_next_pv_id
FROM products_pv AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
AND A.website_pageview_id < B.website_pageview_id
GROUP BY 1, 2;

SELECT *
FROM sessions_w_next_pv;


-- step 3: find the pageview_url with the next page views
CREATE TEMPORARY TABLE next_pv_with_url
SELECT A.time_period,
	   A.website_session_id,
       B.pageview_url AS next_pageview_url
FROM sessions_w_next_pv AS A
LEFT JOIN website_pageviews AS B
ON A.min_next_pv_id = B.website_pageview_id;

SELECT *
FROM next_pv_with_url;


-- step 4: calculate the metrics
SELECT time_period,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
       COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS pct_w_next_pg,
       COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
       COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS pct_to_mrfuzzy,
       COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
       COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS pct_to_lovebear
FROM next_pv_with_url
GROUP BY 1;



-- #4

-- step 1: narrow down to relevant sessions
CREATE TEMPORARY TABLE sessions_with_relevant_products
SELECT website_session_id,
	   website_pageview_id,
       pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at < '2013-04-10'
AND created_at > '2013-01-06'
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear');

SELECT *
FROM sessions_with_relevant_products;


-- step 2: find the relevant pageview_url
SELECT DISTINCT(pageview_url)
FROM sessions_with_relevant_products AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
AND A.website_pageview_id < B.website_pageview_id;

CREATE TEMPORARY TABLE madeit_flag
SELECT website_session_id,
	   CASE
			WHEN product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
            WHEN product_page_seen = '/the-forever-love-bear' then 'lovebear'
            ELSE 'something is wrong'
	   END AS product_seen,
       MAX(cart_page) AS cart_madeit,
       MAX(shipping_page) AS shipping_madeit,
       MAX(billing_page) AS billing_madeit,
       MAX(thankyou_page) AS thankyou_madeit
FROM(

SELECT A.website_session_id,
	   A.product_page_seen,
       CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
       CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
       CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
       CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_with_relevant_products AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
AND A.website_pageview_id < B.website_pageview_id
) AS pageview_level
GROUP BY 1, 2;

SELECT *
FROM madeit_flag;


-- step 3: build the funnel
SELECT product_seen,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS to_cart,
       COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
       COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) AS to_billing,
       COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM madeit_flag
GROUP BY 1;


-- step 4: compare the rates by product
SELECT product_seen,
       COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS product_page_click_rt,
       COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
       COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
       COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM madeit_flag
GROUP BY 1;



-- #5

-- step 1: identify relevant /cart page views and sessions
CREATE TEMPORARY TABLE cart_sessions
SELECT website_session_id AS cart_session_id,
	   website_pageview_id AS cart_pageview_id,
       CASE
           WHEN created_at < '2013-09-25' THEN 'A.Pre_Cross_Sell'
           WHEN created_at >= '2013-01-06' THEN 'B.Post_Cross_Sell'
           ELSE 'something is wrong'
	   END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
AND pageview_url = '/cart';

SELECT *
FROM cart_sessions;


-- step 2: identify which of those clicked through to the shipping page
CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT A.time_period,
	   A.cart_session_id,
       MIN(B.website_pageview_id) AS pv_id_after_cart
FROM cart_sessions AS A
LEFT JOIN website_pageviews AS B
ON A.cart_session_id = B.website_session_id
AND A.cart_pageview_id < B.website_pageview_id
GROUP BY 1, 2
HAVING MIN(B.website_pageview_id) IS NOT NULL;

SELECT *
FROM cart_sessions_seeing_another_page;


-- step 3: find the orders associated with the sessions and analyze purchased products 
CREATE TEMPORARY TABLE session_orders
SELECT time_period,
	   cart_session_id,
       order_id,
       items_purchased,
       price_usd
FROM cart_sessions AS A
INNER JOIN orders AS B
ON A.cart_session_id = B.website_session_id;

-- subquery to be used later
SELECT *
FROM session_orders;

SELECT A.time_period,
	   A.cart_session_id,
       CASE WHEN B.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
       CASE WHEN C.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
       C.items_purchased,
       C.price_usd
FROM cart_sessions AS A
LEFT JOIN cart_sessions_seeing_another_page AS B
ON A.cart_session_id = B.cart_session_id
LEFT JOIN session_orders AS C
ON A.cart_session_id = C.cart_session_id;


-- step 4: aggregate and summarize
SELECT time_period,
	   COUNT(DISTINCT(cart_session_id)) AS cart_sessions,
       SUM(clicked_to_another_page) AS clickthroughs,
       SUM(clicked_to_another_page) / COUNT(DISTINCT(cart_session_id)) AS cart_ctr,
       SUM(placed_order) AS orders_placed,
       SUM(items_purchased) AS products_purchased,
       SUM(items_purchased) / SUM(placed_order) AS products_per_order,
       SUM(price_usd) AS revenue,
       SUM(price_usd) / SUM(placed_order) AS aov,
       SUM(price_usd) / COUNT(DISTINCT(cart_session_id)) AS rev_per_cart_session       
FROM(
SELECT A.time_period,
	   A.cart_session_id,
       CASE WHEN B.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
       CASE WHEN C.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
       C.items_purchased,
       C.price_usd
FROM cart_sessions AS A
LEFT JOIN cart_sessions_seeing_another_page AS B
ON A.cart_session_id = B.cart_session_id
LEFT JOIN session_orders AS C
ON A.cart_session_id = C.cart_session_id
) AS full_data
GROUP BY 1;



-- #6

SELECT 
	CASE
		WHEN A.created_at < '2013-12-12' THEN 'A.Pre_Birthday_Bear'
        WHEN A.created_at >= '2013-12-12' THEN 'B.Post_Birthday_Bear'
        ELSE 'something is wrong'
	END AS time_period,
    -- COUNT(DISTINCT(A.website_session_id)) AS sessions,
    -- COUNT(DISTINCT(B.order_id)) AS orders,
    COUNT(DISTINCT(B.order_id)) / COUNT(DISTINCT(A.website_session_id)) AS conv_rate,
    -- SUM(B.price_usd) AS total_revenue,
    -- SUM(B.items_purchased) AS total_products_sold,
    SUM(B.price_usd) / COUNT(DISTINCT(B.order_id)) AS aov,
    SUM(B.items_purchased) / COUNT(DISTINCT(B.order_id)) AS products_per_order,
    SUM(B.price_usd) / COUNT(DISTINCT(A.website_session_id)) AS revenue_per_session
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1; 



-- #7

SELECT *
FROM order_item_refunds;

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT CASE WHEN product_id = 1 THEN A.order_item_id ELSE NULL END) AS p1_orders,
       COUNT(DISTINCT CASE WHEN product_id = 1 THEN B.order_item_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN product_id = 1 THEN A.order_item_id ELSE NULL END) AS p1_refund_rt,
	   COUNT(DISTINCT CASE WHEN product_id = 2 THEN A.order_item_id ELSE NULL END) AS p2_orders,
       COUNT(DISTINCT CASE WHEN product_id = 2 THEN B.order_item_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN product_id = 2 THEN A.order_item_id ELSE NULL END) AS p2_refund_rt,
	   COUNT(DISTINCT CASE WHEN product_id = 3 THEN A.order_item_id ELSE NULL END) AS p3_orders,
       COUNT(DISTINCT CASE WHEN product_id = 3 THEN B.order_item_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN product_id = 3 THEN A.order_item_id ELSE NULL END) AS p3_refund_rt,
	   COUNT(DISTINCT CASE WHEN product_id = 4 THEN A.order_item_id ELSE NULL END) AS p4_orders,
       COUNT(DISTINCT CASE WHEN product_id = 4 THEN B.order_item_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN product_id = 4 THEN A.order_item_id ELSE NULL END) AS p4_refund_rt
FROM order_items AS A
LEFT JOIN order_item_refunds AS B
ON A.order_item_id = B.order_item_id
WHERE A.created_at < '2014-10-15'
GROUP BY 1, 2;