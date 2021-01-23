USE mavenfuzzyfactory;


SELECT *
FROM website_pageviews;

SELECT *
FROM website_sessions;

SELECT *
FROM orders;



-- #1

SELECT MIN(DATE(created_at)) as week_start_date,
	   COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at > '2012-08-22' 
AND created_at < '2012-11-29'
AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);



-- #2

SELECT utm_source,
	   COUNT(DISTINCT(website_session_id)) AS sessions,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) / COUNT(DISTINCT(website_session_id)) AS pct_mobile
FROM website_sessions
WHERE created_at > '2012-08-22' 
AND created_at < '2012-11-30'
AND utm_campaign = 'nonbrand'
GROUP BY utm_source;



-- #3

SELECT device_type,
	   utm_source,
       COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS conv_rate
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at > '2012-08-22' 
AND A.created_at < '2012-09-19'
AND utm_campaign = 'nonbrand'
GROUP BY device_type, utm_source;



-- #4

SELECT MIN(DATE(created_at)) as week_start_date,
	   COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_pct_of_g_dtop,
       COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
       COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) / 
			COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_pct_of_g_mob
FROM website_sessions
WHERE created_at > '2012-11-04' 
AND created_at < '2012-12-22'
AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);



-- #5

SELECT YEAR(created_at) AS yr,
	   MONTH(created_at) AS mo,
       COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS nonbrand,
       COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) AS brand,
       COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE NULL END) /
			COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS brand_pct_of_nonbrand,
	   COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) AS direct,
       COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE NULL END) /
			COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS direct_pct_of_nonbrand,
	   COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) AS organic,
       COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE NULL END) /
			COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE NULL END) AS organic_pct_of_nonbrand
FROM(
SELECT website_session_id,
	   created_at,
       CASE
		   WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
           WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
           WHEN utm_campaign = 'brand' THEN 'paid_brand'
           WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	   END AS channel_group
FROM website_sessions
WHERE created_at < '2012-12-23'
) AS sessions_channel_group
GROUP BY 1, 2;
