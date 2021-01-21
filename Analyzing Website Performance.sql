USE mavenfuzzyfactory;

SELECT *
FROM website_pageviews;

SELECT *
FROM website_sessions;



-- #1: Finding top website pages

SELECT pageview_url, COUNT(DISTINCT(website_pageview_id)) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY sessions DESC;



-- #2: Finding top entry pages

CREATE TEMPORARY TABLE entry_page
SELECT website_session_id, MIN(website_pageview_id) AS first_page
FROM website_pageviews 
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT pageview_url AS landing_page_url, 
	   COUNT(DISTINCT(A.website_session_id)) AS sessions_hitting_page
FROM entry_page AS A
LEFT JOIN website_pageviews AS B
ON A.first_page = B.website_pageview_id
GROUP BY pageview_url;



-- #3: Calculating bounce rates

-- step 1: find the entry page

CREATE TEMPORARY TABLE first_pageviews
SELECT website_session_id, MIN(website_pageview_id) AS first_page
FROM website_pageviews 
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

select * from first_pageviews;

-- step 2: identify the landing page and restrict to home 

CREATE TEMPORARY TABLE sessions_w_home_landing_page
SELECT A.website_session_id, 
	   pageview_url AS landing_page
FROM first_pageviews AS A
LEFT JOIN website_pageviews AS B
ON A.first_page = B.website_pageview_id
WHERE pageview_url = '/home';

SELECT *
FROM sessions_w_home_landing_page;

-- step 3: count pageviews per session

CREATE TEMPORARY TABLE pageview_count
SELECT A.website_session_id,
	   COUNT(*) AS pageview_count
FROM sessions_w_home_landing_page AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
GROUP BY A.website_session_id;

SELECT *
FROM pageview_count;

-- step 4: calculate # of sessions, # of bounced sessions, and bounce rate

SELECT COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT CASE WHEN pageview_count = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
       COUNT(DISTINCT CASE WHEN pageview_count = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS bounce_rate
FROM pageview_count;



-- #4: Analyzing landing page tests (A/B testing)

-- step 1: find out when lander-1 was deployed

CREATE TEMPORARY TABLE first_deployed
SELECT MIN(created_at) AS first_deployed
FROM website_pageviews
WHERE pageview_url = '/lander-1';

SELECT * FROM first_deployed;

-- step 2: find the entry page

CREATE TEMPORARY TABLE first_page
SELECT A.website_session_id, 
       MIN(A.website_pageview_id) AS first_page
FROM website_pageviews AS A
INNER JOIN website_sessions AS B
ON A.website_session_id = B.website_session_id
AND B.created_at > '2012-06-19 00:35:54' 
AND B.created_at < '2012-07-28'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY A.website_session_id;

select * from first_page;

-- step 3: identify the landing page and restrict to home and lander-1 

CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT A.website_session_id, 
	   pageview_url AS landing_page
FROM first_page AS A
LEFT JOIN website_pageviews AS B
ON A.first_page = B.website_pageview_id
WHERE pageview_url IN ('/home', '/lander-1');

SELECT * FROM sessions_w_landing_page;

-- step 4: count pageviews per session

CREATE TEMPORARY TABLE pageview_count
SELECT A.website_session_id, landing_page, count(*) as session_count
FROM sessions_w_landing_page AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
GROUP BY A.website_session_id, landing_page;

SELECT *
FROM pageview_count;

-- step 5: calculate # of sessions, # of bounced sessions, and bounce rate

SELECT landing_page,
	   COUNT(DISTINCT(website_session_id)) AS total_sessions,
       COUNT(DISTINCT CASE WHEN session_count = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
       COUNT(DISTINCT CASE WHEN session_count = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS bounce_rate
FROM pageview_count
GROUP BY landing_page;



-- #5: Landing page trend analysis

-- step 1: find the first website_pageview_id for relevant sessions

CREATE TEMPORARY TABLE sessions_min_pv_id
SELECT A.website_session_id,
	   MIN(B.website_pageview_id) AS first_pageview_id,
       COUNT(B.website_pageview_id) AS count_pageviews
FROM website_sessions AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at > '2012-06-01'
AND A.created_at < '2012-08-31'
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY A.website_session_id;

SELECT * FROM sessions_min_pv_id;

-- step 2: identify landing page 

CREATE TEMPORARY TABLE sessions_landing_page
SELECT A.*, 
	   B.pageview_url AS landing_page, 
       B.created_at AS session_created_at
FROM sessions_min_pv_id AS A
LEFT JOIN website_pageviews AS B
ON A.first_pageview_id = B.website_pageview_id;

SELECT * FROM sessions_landing_page;

-- step 3: calculate the metrics

SELECT MIN(DATE(session_created_at)) AS week_start_date,
       COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS bounce_rate,
	   COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
       COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_landing_page
GROUP BY WEEK(session_created_at);



-- #6: Building conversion funnels

-- step 1: select all pageviews for relevant sessions

SELECT A.website_session_id,
	   B.pageview_url,
       CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
       CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
       CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
       CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
       CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
       CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions AS A
LEFT JOIN website_pageviews AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at BETWEEN '2012-08-06' AND '2012-09-04' 
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand';

-- step 2: make the funnel

CREATE TEMPORARY TABLE funnel
SELECT website_session_id,
	   MAX(products_page) AS products_madeit,
       MAX(mrfuzzy_page) AS mrfuzzy_madeit,
       MAX(cart_page) AS cart_madeit,
       MAX(shipping_page) AS shipping_madeit,
       MAX(billing_page) AS billling_madeit,
       MAX(thankyou_page) AS thankyou_madeit
FROM (SELECT A.website_session_id,
			 B.pageview_url,
             CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
			 CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
			 CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
			 CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
			 CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
			 CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	  FROM website_sessions AS A
	  LEFT JOIN website_pageviews AS B
	  ON A.website_session_id = B.website_session_id
	  WHERE A.created_at BETWEEN '2012-08-06' AND '2012-09-04' 
	  AND utm_source = 'gsearch'
	  AND utm_campaign = 'nonbrand') AS pageviews
GROUP BY website_session_id;

SELECT * FROM funnel;

-- step 3: calculate the metrics

SELECT COUNT(DISTINCT(website_session_id)) AS sessions,
	   COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) AS to_products,
       COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
       COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS to_cart,
       COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
       COUNT(DISTINCT CASE WHEN billling_madeit = 1 THEN website_session_id ELSE NULL END) AS to_billing,
       COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) AS to_thankyou,
       COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS lander_click_rt,
       COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN products_madeit = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
       COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN mrfuzzy_madeit = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
       COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_madeit = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
       COUNT(DISTINCT CASE WHEN billling_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_madeit = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
       COUNT(DISTINCT CASE WHEN thankyou_madeit = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billling_madeit = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM funnel;



-- #7: Analyzing conversion funnel tests

-- step 1: find out when billing-2 was first deployed

SELECT MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2';
-- first_pv_id = 53550

-- step 2: limit to the relevant sessions

CREATE TEMPORARY TABLE relevant
SELECT A.website_session_id,
	   pageview_url,
       order_id
FROM website_pageviews AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.website_pageview_id >= 53550
AND A.created_at < '2012-11-10'
AND pageview_url IN ('/billing', '/billing-2');

SELECT * FROM relevant;

-- step 3: calculate the metrics

SELECT pageview_url AS billing_version_seen,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(website_session_id)) AS billing_to_order_rt
from relevant
GROUP BY pageview_url;