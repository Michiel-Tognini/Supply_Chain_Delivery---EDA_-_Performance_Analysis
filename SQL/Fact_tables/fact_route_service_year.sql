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

-- All below queries are filtered not to include those trips from the invalid planned and actual delivery moments found in the EDA
-- Additionaly, trips from 2025 are exluded by not including the trip_id from the above delivery_2025 query

), pickup_delay AS (
	SELECT
  		r.route_id,
		EXTRACT(YEAR FROM actual_datetime) AS calender_year,
  		ROUND(AVG(EXTRACT(EPOCH FROM actual_datetime - scheduled_datetime) / 60), 2) AS avg_pickup_delay_minutes,
  		ROUND(AVG(detention_minutes), 2) AS avg_pickup_detention_minutes
	FROM delivery_events AS d
	LEFT JOIN loads AS l
	ON d.load_id = l.load_id
	LEFT JOIN routes AS r
	ON l.route_id = r.route_id
	WHERE event_type = 'Pickup' AND d.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND d.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND d.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
	GROUP BY r.route_id, calender_year
)
, delivery_delay AS (
	SELECT
  		r.route_id,
		EXTRACT(YEAR FROM actual_datetime) AS calender_year,
  		ROUND(AVG(EXTRACT(EPOCH FROM actual_datetime - scheduled_datetime) / 60), 2) AS avg_delivery_delay_minutes,
  		ROUND(AVG(detention_minutes), 2) AS avg_delivery_detention_minutes
	FROM delivery_events AS d
	LEFT JOIN loads AS l
	ON d.load_id = l.load_id
	LEFT JOIN routes AS r
	ON l.route_id = r.route_id
	WHERE event_type = 'Delivery' AND d.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND d.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND d.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
	GROUP BY r.route_id, calender_year
)
, on_time_pickup_pct AS (
	SELECT
		r.route_id,
		EXTRACT(YEAR FROM actual_datetime) AS calender_year,
		ROUND(COUNT(CASE WHEN on_time_flag = 'TRUE' THEN 1 END)::decimal / COUNT(on_time_flag), 2) AS on_time_pickup_pct
	FROM delivery_events AS d
	LEFT JOIN loads AS l
	ON d.load_id = l.load_id
	LEFT JOIN routes AS r
	ON l.route_id = r.route_id
	WHERE event_type = 'Pickup' AND d.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND d.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND d.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
	GROUP BY r.route_id, calender_year
)
, on_time_delivery_pct AS (
	SELECT
		r.route_id,
		EXTRACT(YEAR FROM actual_datetime) AS calender_year,
		ROUND(COUNT(CASE WHEN on_time_flag = 'TRUE' THEN 1 END)::decimal / COUNT(on_time_flag), 2) AS on_time_delivery_pct
	FROM delivery_events AS d
	LEFT JOIN loads AS l
	ON d.load_id = l.load_id
	LEFT JOIN routes AS r
	ON l.route_id = r.route_id
	WHERE event_type = 'Delivery' AND d.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND d.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND d.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
	GROUP BY r.route_id, calender_year
)
, actual_distance_per_route AS (
    SELECT
        l.route_id,
		EXTRACT(YEAR FROM tr.dispatch_date) AS calender_year,
        AVG(tr.actual_distance_miles) AS avg_actual_distance_miles,
        COUNT(DISTINCT tr.trip_id) AS n_trips
    FROM loads l
	JOIN trips AS tr
    ON l.load_id = tr.load_id
    WHERE tr.actual_distance_miles IS NOT NULL AND l.load_id NOT IN (SELECT load_id FROM invalid_planned) AND l.load_id NOT IN (SELECT load_id FROM invalid_actual) AND l.load_id NOT IN (SELECT load_id FROM delivery_2025)
    GROUP BY l.route_id, calender_year
)
, distance_deviation AS (
	SELECT
    r.route_id,
	adr.calender_year,
    r.typical_distance_miles,
    ROUND(adr.avg_actual_distance_miles, 0),
	ROUND(adr.avg_actual_distance_miles - r.typical_distance_miles, 0) AS avg_distance_deviation,
    adr.n_trips
FROM routes r
LEFT JOIN actual_distance_per_route AS adr
    ON r.route_id = adr.route_id
ORDER BY avg_distance_deviation DESC
)


SELECT
	pd.route_id,
	pd.calender_year,
	avg_pickup_delay_minutes,
	avg_pickup_detention_minutes,
	avg_delivery_delay_minutes,
	avg_delivery_detention_minutes,
	on_time_pickup_pct,
	on_time_delivery_pct,
	avg_distance_deviation
FROM pickup_delay AS pd
LEFT JOIN delivery_delay AS dd
ON pd.route_id = dd.route_id AND pd.calender_year = dd.calender_year
LEFT JOIN on_time_pickup_pct AS otp
ON pd.route_id = otp.route_id AND pd.calender_year = otp.calender_year
LEFT JOIN on_time_delivery_pct AS otd
ON pd.route_id = otd.route_id AND pd.calender_year = otd.calender_year
LEFT JOIN distance_deviation AS disdev
ON pd.route_id = disdev.route_id AND pd.calender_year = disdev.calender_year
ORDER BY route_id, calender_year
