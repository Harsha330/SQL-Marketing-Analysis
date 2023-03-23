USE mavenfuzzyfactory;

SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM website_sessions;

SELECT *
FROM website_pageviews;


-- useage of date function 
 SELECT 
       order_items.order_id,
       order_items.order_item_id ,
       order_items.price_usd as price_paid_usd ,
       order_items.created_at,

order_item_refunds.order_item_refund_id,
order_item_refunds.refund_amount_usd,
order_item_refunds.created_at,

datediff(order_item_refunds.created_at ,order_items.created_at) as days_to_refund
FROM order_items LEFT JOIN order_item_refunds
ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE order_items.order_id IN (3489,32049,27861);




-- #1
CREATE TEMPORARY TABLE repeat_sessions
SELECT A.user_id,
	   A.website_session_id AS new_session_id,
       B.website_session_id AS repeat_session_id
FROM(
SELECT user_id, website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01'
AND created_at >= '2014-01-01'
AND is_repeat_session = 0
) AS A
LEFT JOIN website_sessions AS B
ON A.user_id = B.user_id
AND B.is_repeat_session = 1
AND B.website_session_id > A.website_session_id
AND B.created_at < '2014-11-01'
AND B.created_at >= '2014-01-01';


SELECT repeat_sessions,
	   COUNT(DISTINCT(user_id)) AS users
FROM(
SELECT user_id,
	   COUNT(DISTINCT(new_session_id)) AS new_sessions,
       COUNT(DISTINCT(repeat_session_id)) AS repeat_sessions
FROM repeat_sessions
GROUP BY 1
) AS user_level
GROUP BY 1;



-- #2

-- CREATE TEMPORARY TABLE repeat_sessions
CREATE TEMPORARY TABLE repeat_session_with_time
SELECT A.user_id,
	   A.website_session_id AS new_session_id,
       A.created_at AS new_session_created_at,
       B.website_session_id AS repeat_session_id,
       B.created_at AS repeat_session_created_at
FROM(
SELECT user_id, website_session_id, created_at
FROM website_sessions
WHERE created_at < '2014-11-03'
AND created_at >= '2014-01-01'
AND is_repeat_session = 0
) AS A
LEFT JOIN website_sessions AS B
ON A.user_id = B.user_id
AND B.is_repeat_session = 1
AND B.website_session_id > A.website_session_id
AND B.created_at < '2014-11-03'
AND B.created_at >= '2014-01-01';

SELECT *
FROM repeat_session_with_time;

CREATE TEMPORARY TABLE first_to_second
SELECT user_id,
	   DATEDIFF(second_session_created_at, new_session_created_at) AS days
FROM(
SELECT user_id,
	   new_session_id,
       new_session_created_at,
       MIN(repeat_session_id) AS second_session_id,
       MIN(repeat_session_created_at) AS second_session_created_at
FROM repeat_session_with_time
WHERE repeat_session_id IS NOT NULL
GROUP BY 1, 2, 3
) AS first_second;

SELECT AVG(days) AS avg_days,
	   MIN(days) AS min_days,
       MAX(days) AS max_days
FROM first_to_second;



-- #3
SELECT utm_source,
	   utm_campaign,
       http_referer,
       COUNT(DISTINCT CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
       COUNT(DISTINCT CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at < '2014-11-05'
AND created_at >= '2014-01-01'
GROUP BY 1, 2, 3
ORDER BY 5 DESC;

SELECT 
	CASE
		WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
	END AS channel_group,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at < '2014-11-05'
AND created_at >= '2014-01-01'
GROUP BY 1
ORDER BY 3;



-- #4

SELECT is_repeat_session,
	   COUNT(DISTINCT(A.website_session_id)) AS sessions,
       COUNT(DISTINCT(order_id)) / COUNT(DISTINCT(A.website_session_id)) AS conv_rate,
       SUM(price_usd) / COUNT(DISTINCT(A.website_session_id)) AS rev_per_session
FROM website_sessions AS A
LEFT JOIN orders AS B
ON A.website_session_id = B.website_session_id
WHERE A.created_at < '2014-11-08'
AND A.created_at >= '2014-01-01'
GROUP BY 1;
