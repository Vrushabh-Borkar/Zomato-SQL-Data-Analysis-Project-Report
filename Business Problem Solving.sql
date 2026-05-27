-- Business Problem Solving ---


/*
1. Write a query to find the top 5 most frequently ordered dishes by customer called "Arjun Mehta" in the last 1 year.
*/

SELECT 
	c.customer_name,
    o.order_item AS dishes,
    COUNT(*) AS total_orders
FROM orders AS o
JOIN customers AS c
ON C.customer_id = o.customer_id
WHERE
	o.order_date >= CURDATE() - INTERVAL 1 YEAR
AND
	c.customer_name = "Arjun Mehta"
 GROUP BY o.order_item
 ORDER BY total_orders DESC
 LIMIT 5
 ;
 
/*
2. Popular Time Slots
-- Question: Identify the time slots during which the most orders are placed. based on 2-hour intervals.
*/
-- Approch 1 :-
SELECT 
    CASE
        WHEN HOUR(order_time) BETWEEN 0 AND 1 THEN '00:00 - 01:59'
        WHEN HOUR(order_time) BETWEEN 2 AND 3 THEN '02:00 - 03:59'
        WHEN HOUR(order_time) BETWEEN 4 AND 5 THEN '04:00 - 05:59'
        WHEN HOUR(order_time) BETWEEN 6 AND 7 THEN '06:00 - 07:59'
        WHEN HOUR(order_time) BETWEEN 8 AND 9 THEN '08:00 - 09:59'
        WHEN HOUR(order_time) BETWEEN 10 AND 11 THEN '10:00 - 11:59'
        WHEN HOUR(order_time) BETWEEN 12 AND 13 THEN '12:00 - 13:59'
        WHEN HOUR(order_time) BETWEEN 14 AND 15 THEN '14:00 - 15:59'
        WHEN HOUR(order_time) BETWEEN 16 AND 17 THEN '16:00 - 17:59'
        WHEN HOUR(order_time) BETWEEN 18 AND 19 THEN '18:00 - 19:59'
        WHEN HOUR(order_time) BETWEEN 20 AND 21 THEN '20:00 - 21:59'
        ELSE '22:00 - 23:59'
    END AS time_slot,
    COUNT(*) AS total_orders
FROM Orders
GROUP BY time_slot
ORDER BY total_orders DESC;

-- Approch 2  - 
SELECT 		
		FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,
        FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 + 2 AS end_time,
		COUNT(*) AS total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC;


/*
3. Order Value Analysis
-- Question: Find the average order value per customer who has placed more than 750 orders. 
-- Return customer_name, and aov(average order value)
*/

SELECT 
	o.customer_id,
    c.customer_name,
    AVG(o.total_amount) AS AOV,
    COUNT(o.order_id) AS total_orders
FROM orders AS o
	JOIN customers AS c
	ON c.customer_id = o.customer_id
GROUP BY 1
HAVING total_orders > 750
; 


/*
4. High-Value Customers
-- Question: List the customers who have spent more than 100K in total on food orders. -- return customer_name, and customer_id!
*/

SELECT 
	o.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS total_spent
FROM orders AS o
	JOIN customers AS c
	ON c.customer_id = o.customer_id
GROUP BY 1
HAVING total_spent > 100000
;

SELECT * FROM orders;

/*
5. Orders Without Delivery
-- Question: Write a query to find orders that were placed but not delivered. 
-- Return each restuarant name, city and number of not delivered orders
*/

SELECT
		r.restaurant_name,
        r.city,
        COUNT(*) AS not_deliverd
FROM orders AS o
	JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
    JOIN deliveries AS d
    ON o.order_id = d.order_id
WHERE d.delivery_status != 'Delivered'
GROUP BY 1,2
ORDER BY not_deliverd DESC;

/*
6. Restaurant Revenue Ranking:
-- Rank restaurants by their total revenue from the last year, including their name, 
-- total revenue, and rank within their city.
*/

SELECT 
	r.restaurant_name,
    r.city,
    SUM(o.total_amount) AS revenue,
    RANK() OVER (
				  PARTITION BY r.city ORDER BY SUM(o.total_amount)DESC
				) AS Ranks
FROM restaurants AS r
JOIN orders AS o
ON r.restaurant_id = o.restaurant_id
WHERE o.order_date >= CURDATE() - INTERVAL 1 YEAR
GROUP BY 1,2 ;

/*
7. Most Popular Dish by City:
-- Identify the most popular dish in each city based on the number of orders.
*/

SELECT
	r.city,
    o.order_item AS dish,
    COUNT(o.order_id) AS total_orders
FROM orders AS o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1, 2;

/*
-- 8. Customer Churn:
-- Find customers who haven’t placed an order in 2024 but did in 2023.
*/

SELECT DISTINCT customer_id FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2023
AND
	order_id NOT IN(
					SELECT customer_id FROM orders
                    WHERE EXTRACT(YEAR FROM order_date) = 2024
					) ;
                    
/*
9. Cancellation Rate Comparison:
-- Calculate and compare the order cancellation rate for each restaurant between the -- current year and the previous year.
*/

-- Approch 1

 WITH cancel_2023 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE 
                WHEN d.delivery_status <> 'Delivered' 
                     OR d.delivery_id IS NULL 
                THEN 1 
              END) AS cancelled_orders
    FROM Orders o
    LEFT JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2023
    GROUP BY o.restaurant_id
),

cancel_2024 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE 
                WHEN d.delivery_status <> 'Delivered' 
                     OR d.delivery_id IS NULL 
                THEN 1 
              END) AS cancelled_orders
    FROM Orders o
    LEFT JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
)

SELECT 
    r.restaurant_name,
    
    ROUND((c23.cancelled_orders / c23.total_orders) * 100, 2) AS cancel_rate_2023,
    
    ROUND((c24.cancelled_orders / c24.total_orders) * 100, 2) AS cancel_rate_2024,
    
    ROUND(
        ((c24.cancelled_orders / c24.total_orders) -
         (c23.cancelled_orders / c23.total_orders)) * 100,
        2
    ) AS rate_difference
FROM restaurants r
LEFT JOIN cancel_2023 c23
    ON r.restaurant_id = c23.restaurant_id
LEFT JOIN cancel_2024 c24
    ON r.restaurant_id = c24.restaurant_id;
    
-- Approch 2

WITH cancel_ratio_23 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE 
                WHEN d.delivery_id IS NULL 
                     OR d.delivery_status <> 'Delivered'
                THEN 1
              END) AS not_delivered
    FROM Orders o
    LEFT JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2023
    GROUP BY o.restaurant_id
),

cancel_ratio_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE 
                WHEN d.delivery_id IS NULL 
                     OR d.delivery_status <> 'Delivered'
                THEN 1
              END) AS not_delivered
    FROM Orders o
    LEFT JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
),

last_year_data AS (
    SELECT 
        restaurant_id,
        ROUND((not_delivered * 100.0 / total_orders), 2) AS cancel_ratio
    FROM cancel_ratio_23
),

current_year_data AS (
    SELECT 
        restaurant_id,
        ROUND((not_delivered * 100.0 / total_orders), 2) AS cancel_ratio
    FROM cancel_ratio_24
)

SELECT 
    c.restaurant_id,
    c.cancel_ratio AS current_year_cancel_ratio,
    l.cancel_ratio AS last_year_cancel_ratio
FROM current_year_data c
JOIN last_year_data l
    ON c.restaurant_id = l.restaurant_id;

/*
10. Rider Average Delivery Time:
-- Determine each rider's average delivery time.
*/

SELECT 
    r.rider_name,
    AVG(
        CASE
            WHEN d.delivery_time >= o.order_time 
            THEN 
				TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time)
            ELSE 
				TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(d.delivery_time, '24:00:00'))
			END
    ) AS avg_delivery_time_minutes
FROM riders r
JOIN deliveries d
    ON r.rider_id = d.rider_id
JOIN Orders o
    ON d.order_id = o.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY r.rider_name;

/*
11. Monthly Restaurant Growth Ratio:
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining
*/

WITH growth_ratio AS (
    SELECT 
        o.restaurant_id,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        COUNT(o.order_id) AS cr_month_orders,
        
        LAG(COUNT(o.order_id), 1) OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY YEAR(o.order_date), MONTH(o.order_date)
        ) AS prev_month_orders

    FROM Orders o
    JOIN deliveries d
        ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
    GROUP BY o.restaurant_id, YEAR(o.order_date), MONTH(o.order_date)
)

SELECT
    restaurant_id,
    year,
    month,
    prev_month_orders,
    cr_month_orders,

    ROUND(
        ((cr_month_orders - prev_month_orders) * 100.0) 
        / NULLIF(prev_month_orders, 0),
        2
    ) AS growth_ratio
FROM growth_ratio;

/*
12. Customer Segmentation:
-- Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending 
-- compared to the average order value (AOV). If a customer's total spending exceeds the AOV, 
-- label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's 
-- total number of orders and total revenue
*/


SELECT 
	cx_category,
    SUM(total_orders) AS total_orders,
    SUM(total_spent) AS total_revenue
FROM
(SELECT 
	customer_id,
	SUM(total_amount) AS total_spent,
    COUNT(order_id) AS total_orders,
	CASE WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders)
    THEN "GOLD"
    ELSE "SILVER"
    END AS cx_category
FROM orders 
GROUP BY 1
ORDER BY SUM(total_amount)DESC)
AS teb1
GROUP BY 1;

SELECT AVG(total_amount) FROM orders;

/*
13. Rider Monthly Earnings:
-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
*/

SELECT 
		d.rider_id,
		r.rider_name,
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(o.total_amount) AS order_amount,
        SUM(o.total_amount) * 8 /100 AS riders_earning
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id 
LEFT JOIN riders AS r
ON d.rider_id = r.rider_id
WHERE d.delivery_status = "Delivered"
GROUP BY 1,2, 3, 4
ORDER BY 1, 2, 3, 4 ;

/*
Q.14 Rider Ratings Analysis:
-- Find the number of 5-star, 4-star, and 3-star ratings each rider has. Riders receive this rating based on delivery time. 
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating, 
-- if they deliver 15 and 20 minute they get 4 star rating 
-- if they deliver after 20 minute they get 3 star rating.
*/

SELECT
    r.rider_id,
    r.rider_name,
    o.order_id,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) < 15
            THEN 'five_star'
        WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) BETWEEN 15 AND 20
            THEN 'four_star'
        ELSE 'three_star'
    END AS rating
FROM Orders o
JOIN deliveries d
    ON o.order_id = d.order_id
JOIN riders r
    ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered';

/*
15. Q.15 Order Frequency by Day:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant.
*/

SELECT 
		r.restaurant_name,
        DAYNAME(o.order_date) AS day_of_week,
        COUNT(o.order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id)) AS ranks
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1,2
ORDER BY 1,3;

/*
16. Customer Lifetime Value (CLV):
-- Calculate the total revenue generated by each customer over all their orders.
*/

SELECT 
		o.customer_id,
        c.customer_name,
        SUM(o.total_amount) AS total_revenue
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id 
GROUP BY 1,2;

/*
17. Monthly Sales Trends:
-- Identify sales trends by comparing each month's total sales to the previous month.
*/

SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(MONTH FROM order_date) as month,
    SUM(total_amount) as total_sale,
    LAG(SUM(total_amount), 1) 
    OVER(
        ORDER BY EXTRACT(YEAR FROM order_date),
                 EXTRACT(MONTH FROM order_date)
    ) as prev_month_sale
FROM orders
GROUP BY 1, 2;

/*
18. Rider Efficiency:
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.
*/

SELECT
    r.rider_id,
    r.rider_name,
    AVG(
        CASE
            WHEN d.delivery_time >= o.order_time 
            THEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time)
            ELSE TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(d.delivery_time, '24:00:00'))
        END
    ) AS avg_delivery_time_minutes,
    MIN(
        CASE
            WHEN d.delivery_time >= o.order_time 
            THEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time)
            ELSE TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(d.delivery_time, '24:00:00'))
        END
    ) AS min_delivery_time_minutes,
    MAX(
        CASE
            WHEN d.delivery_time >= o.order_time 
            THEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time)
            ELSE TIMESTAMPDIFF(MINUTE, o.order_time, ADDTIME(d.delivery_time, '24:00:00'))
        END
    ) AS max_delivery_time_minutes
FROM Orders o
JOIN deliveries d
    ON o.order_id = d.order_id
JOIN riders r
    ON d.rider_id = r.rider_id
WHERE d.delivery_status = 'Delivered'
GROUP BY r.rider_id, r.rider_name
ORDER BY avg_delivery_time_minutes;


/*
19. Order Item Popularity:
-- Track the popularity of specific order items over time and identify seasonal demand spikes.
*/

SELECT 
	order_item,
	seasons,
	COUNT(order_id) AS total_orders
FROM
(
SELECT *,
		EXTRACT(MONTH FROM order_date) AS month,
        CASE
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN "spring"
             WHEN EXTRACT(MONTH FROM order_date) < 9 THEN "summer"
            ELSE "winter"
		END AS seasons
FROM orders
) AS t1
GROUP BY 1,2
ORDER BY 1, 3 DESC;


/*
20. Rank each city based on the total revenue for last year 2023
*/

SELECT
	r.city,
    SUM(o.total_amount) AS total_revenue,
    RANK() OVER(ORDER BY SUM(o.total_amount)DESC)
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1
ORDER BY 2 DESC;