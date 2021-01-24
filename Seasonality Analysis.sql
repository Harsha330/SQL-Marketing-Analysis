USE mavenfuzzyfactory;


SELECT *
FROM website_pageviews;

SELECT *
FROM website_sessions;

SELECT *
FROM orders;



-- #1

SELECT YEAR(A.created_at) AS yr,
	   MONTH(A.created_at) AS mo,
       COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2013-01-01'
GROUP BY 1, 2;

SELECT MIN(DATE(A.created_at)) AS week_start_date,
       COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) AS orders
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2013-01-01'
GROUP BY WEEK(A.created_at);



-- #2

SELECT hr,
	   ROUND(AVG(CASE WHEN weekday = 0 THEN sessions ELSE NULL END), 1) AS mon,  
       ROUND(AVG(CASE WHEN weekday = 1 THEN sessions ELSE NULL END), 1) AS tues,
       ROUND(AVG(CASE WHEN weekday = 2 THEN sessions ELSE NULL END), 1) AS weds,
       ROUND(AVG(CASE WHEN weekday = 3 THEN sessions ELSE NULL END), 1) AS thurs,
       ROUND(AVG(CASE WHEN weekday = 4 THEN sessions ELSE NULL END), 1) AS fri,
       ROUND(AVG(CASE WHEN weekday = 5 THEN sessions ELSE NULL END), 1) AS sat,
       ROUND(AVG(CASE WHEN weekday = 6 THEN sessions ELSE NULL END), 1) AS sun
FROM(
SELECT DATE(created_at) AS created_date,
	   WEEKDAY(created_at) AS weekday,
       HOUR(created_at) AS hr,
       COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
GROUP BY 1, 2, 3
) AS daily_hourly
GROUP BY 1;
