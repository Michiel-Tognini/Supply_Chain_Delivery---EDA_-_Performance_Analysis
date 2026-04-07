-- First those trips that are invalid are filtered for
-- These are trips where planned pickup > planned delivery, actual pickup > actual delivery, and trips from 2025

WITH simplified_delivery_events AS(
    SELECT
        trip_id,
		load_id,

        MAX(CASE 
            WHEN event_type = 'Pickup' THEN scheduled_datetime 
        END) AS planned_pickup_datetime,

        MAX(CASE 
            WHEN event_type = 'Delivery' THEN scheduled_datetime 
        END) AS planned_delivery_datetime,

        MAX(CASE 
            WHEN event_type = 'Pickup' THEN actual_datetime 
        END) AS actual_pickup_datetime,

        MAX(CASE 
            WHEN event_type = 'Delivery' THEN actual_datetime 
        END) AS actual_delivery_datetime

    FROM delivery_events
    GROUP BY trip_id, load_id
	
), invalid_planned AS (
	SELECT
		trip_id,
		load_id,
		planned_pickup_datetime,
		planned_delivery_datetime
	FROM simplified_delivery_events
	WHERE planned_delivery_datetime < planned_pickup_datetime
	
), invalid_actual AS (
	SELECT
		trip_id,
		load_id,
		actual_pickup_datetime,
		actual_delivery_datetime
	FROM simplified_delivery_events
	WHERE actual_delivery_datetime < actual_pickup_datetime
	
), delivery_2025 AS (
	SELECT
		trip_id,
		load_id,
		actual_delivery_datetime
	FROM simplified_delivery_events
	WHERE actual_delivery_datetime >= '2025-01-01 00:00:00'
)

-- truck_year_usage is filtered to not include those trips from the invalid planned and actual delivery moments found in the EDA
-- Additionaly, trips from 2025 are exluded by not including the trip_id from the above delivery_2025 query

, truck_usage AS (
    SELECT
        t.truck_id,
        t.model_year,
        EXTRACT(YEAR FROM tr.dispatch_date) AS calender_year,
		SUM(actual_distance_miles) AS total_miles_driven
    FROM trips tr
    JOIN trucks t ON tr.truck_id = t.truck_id
	WHERE tr.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND tr.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND tr.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
    GROUP BY t.truck_id, t.model_year, calender_year
), truck_fuel AS (
    SELECT
        t.truck_id,
		t.model_year,
        EXTRACT(YEAR FROM f.purchase_date) AS calender_year,
		SUM(f.total_cost) AS fuel_cost
    FROM fuel_purchases AS f
    JOIN trucks t ON f.truck_id = t.truck_id
	GROUP BY t.truck_id, t.model_year, calender_year
), truck_maintenance AS (
    SELECT
        t.truck_id,
		t.model_year,
        EXTRACT(YEAR FROM m.maintenance_date) AS calender_year,
		SUM(m.total_cost) AS maintenance_cost
    FROM maintenance_records m
    JOIN trucks t ON m.truck_id = t.truck_id
    GROUP BY t.truck_id, t.model_year, calender_year
)

SELECT
	tu.truck_id,
	tu.calender_year,
	ROUND(fuel_cost, 0) AS fuel_cost,
	ROUND(maintenance_cost, 0) AS maintenance_cost,
	ROUND(fuel_cost + maintenance_cost, 0) AS total_cost,
	total_miles_driven,
	ROUND(fuel_cost / total_miles_driven, 2) AS fuel_cost_per_mile,
	ROUND(maintenance_cost / total_miles_driven, 2) AS maintenance_cost_per_mile,
	ROUND((fuel_cost + maintenance_cost) / total_miles_driven, 2) AS cost_per_mile
FROM 
	truck_usage AS tu
LEFT JOIN truck_fuel AS tf
ON tu.truck_id = tf.truck_id AND tu.calender_year = tf.calender_year
LEFT JOIN truck_maintenance AS tm
ON tm.truck_id = tf.truck_id AND tm.calender_year = tf.calender_year;
