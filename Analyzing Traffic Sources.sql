USE mavenfuzzyfactory;

-- #1
SELECT utm_source, utm_campaign, http_referer, COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY  1, 2, 3
ORDER BY 4 DESC;


-- #2
SELECT COUNT(DISTINCT(A.website_session_id)) AS sessions, 
	   COUNT(DISTINCT(order_id)) AS orders, 
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS session_to_order_conv_rate
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-04-14' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand';


-- #3
SELECT MIN(DATE(created_at)) AS week_start_date, COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-10' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);


-- #4
SELECT device_type,
	   COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS session_to_order_conv_rate
FROM website_sessions as A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2012-05-11' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY device_type;


-- #5
SELECT MIN(DATE(created_at)) AS week_start_date,
	   COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
       COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE created_at > '2012-04-15' AND created_at < '2012-06-09' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at), WEEK(created_at);