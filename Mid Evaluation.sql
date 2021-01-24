USE mavenfuzzyfactory;


SELECT *
FROM website_pageviews;

SELECT *
FROM website_sessions;

SELECT *
FROM orders;



/*
1.	Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
	   COUNT(DISTINCT(A.website_session_id)) AS total_sessions,
       COUNT(DISTINCT(order_id)) AS total_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-11-27'
AND utm_source = 'gsearch'
GROUP BY 1, 2;



/*
2.	Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/ 

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN A.website_session_id ELSE NULL END) AS brand_sessions,
       COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS brand_orders,
	   COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN A.website_session_id ELSE NULL END) AS nonbrand_sessions,
       COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS nonbrand_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-11-27'
AND utm_source = 'gsearch'
GROUP BY 1, 2;



/*
3.	While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN A.website_session_id ELSE NULL END) AS desktop_sessions,
       COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN order_id ELSE NULL END) AS desktop_orders,
	   COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN A.website_session_id ELSE NULL END) AS mobile_sessions,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN order_id ELSE NULL END) AS mobile_orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-11-27'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY 1, 2;



/*
4.	I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/ 

-- step 1: check various utm sources

SELECT DISTINCT utm_source, utm_campaign, http_referer
FROM website_sessions
WHERE created_at < '2012-11-27';

-- step 2: calculate metrics for each channel

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN A.website_session_id ELSE NULL END) AS gsearch_sessions,
	   COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN A.website_session_id ELSE NULL END) AS bsearch_sessions,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN A.website_session_id ELSE NULL END) AS direct_type_in_sessions,
       COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN A.website_session_id ELSE NULL END) AS organic_search_sessions
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-11-27'
GROUP BY 1, 2;



/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 
*/ 

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
	   COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS session_to_order_conv_rate
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-11-27'
GROUP BY 1, 2;



/*
6.	For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use 
nonbrand sessions and revenue since then to calculate incremental value)
*/ 

-- step 1: see when the test was first implemented

SELECT MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';
-- 23504

-- step 2: find the first pageview ids

CREATE TEMPORARY TABLE first_pageviews
SELECT A.website_session_id,
	   MIN(A.website_pageview_id) AS min_pageview_id
FROM website_pageviews AS A
INNER JOIN website_sessions AS B
ON A.website_session_id = B.website_session_id
AND B.created_at < '2012-07-28'
AND A.website_pageview_id >= 23504
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY A.website_session_id;

SELECT * FROM first_pageviews;

-- step 3: match the landing page

CREATE TEMPORARY TABLE landing_page
SELECT A.website_session_id,
	   B.pageview_url AS landing_page
FROM first_pageviews AS A
LEFT JOIN website_pageviews AS B
ON A.min_pageview_id = B.website_pageview_id
WHERE B.pageview_url in ('/home', '/lander-1');

SELECT * FROM landing_page;

-- step 4: bring in orders

CREATE TEMPORARY TABLE landing_page_with_orders
SELECT A.*, B.order_id
FROM landing_page AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id;

SELECT * FROM landing_page_with_orders;

-- step 5: find the diff between conversion rates

SELECT landing_page,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(website_session_id)) AS conv_rate
FROM landing_page_with_orders
GROUP BY 1;
-- 0.0088

-- step 6: find the most recent pageview for gsearch nonbrand where traffic was sent to home
SELECT MAX(A.website_session_id) AS most_recent_home_pageview
FROM website_sessions AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
WHERE utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
AND pageview_url = '/home'
AND A.created_at < '2012-11-27';
-- 17145

-- step 7: find out how many sessions since that pageview
SELECT COUNT(website_session_id) AS sessions_since_pageview
FROM website_sessions
WHERE created_at < '2012-11-27'
AND website_session_id > 17145
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand';
-- 22972

-- step 8: multiply the conversion rate difference with the # of sessions since that pageview
-- (22972 x 0.0088) / 4 =  about 50 extra orders per month!



/*
7.	For the landing page test you analyzed previously, it would be great to show a full conversion funnel 
from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/ 

CREATE TEMPORARY TABLE madeit_tagged
SELECT website_session_id,
	   MAX(homepage) AS homepage_madeit,
       MAX(lander) AS lander_madeit,
       MAX(products_page) AS products_madeit,
       MAX(mrfuzzy_page) AS mrfuzzy_madeit,
       MAX(cart_page) AS cart_madeit,
       MAX(shipping_page) AS shipping_madeit,
       MAX(billing_page) AS billing_madeit,
       MAX(thankyou_page) AS thankyou_madeit
FROM(
SELECT A.website_session_id,
	   pageview_url,
       CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
       CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander,
       CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
       CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
       CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
       CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
       CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
       CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
WHERE utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
AND A.created_at < '2012-07-28'
AND A.created_at > '2012-06-19'
) AS pageview_level
GROUP BY website_session_id;

SELECT * FROM madeit_tagged;

SELECT 
	CASE
		WHEN homepage_madeit = 1 THEN 'saw_homepage'
        WHEN lander_madeit = 1 THEN 'saw_lander'
        ELSE 'something is wrong..'
	END AS segment,
    COUNT(DISTINCT(website_session_id)) AS sessions,
    COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) AS to_thankyou,
    COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS lander_click_rt,
    COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt ,
    COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_madeit = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM madeit_tagged
GROUP BY 1;



/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/

SELECT billing_version,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       SUM(price_usd) / COUNT(DISTINCT(website_session_id)) AS rev_per_page_seen
FROM(
SELECT A.website_session_id,
	   pageview_url AS billing_version,
       order_id,
       price_usd
FROM website_pageviews AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at > '2012-09-10'
AND A.created_at < '2012-11-10'
AND pageview_url IN ('/billing', '/billing-2')
) AS billing_pageview_and_order
GROUP BY 1;

-- old version: $22.83 per billing page view
-- new version: $31.34 per billing page view
-- LIFT: $8.51 per billing page view

SELECT COUNT(website_session_id) AS billing_sessions_last_month
FROM website_pageviews
WHERE pageview_url IN ('/billing', '/billing-2')
AND created_at BETWEEN '2012-10-27' AND '2012-11-27'; -- past month

-- 1193 billing sessions last month
-- LIFT = $8.51 per billing page view
-- VALUE OF BILLING TEST: $10,152 over the last month
