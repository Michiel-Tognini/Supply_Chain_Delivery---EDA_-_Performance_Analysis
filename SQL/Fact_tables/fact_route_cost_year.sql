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

-- First I calculate the total miles driven per route where I exclude the trips based on the above query

), trip_miles_per_route AS (
	SELECT
        l.route_id,
        EXTRACT(YEAR FROM t.dispatch_date) AS calender_year,
		t.truck_id,
        t.actual_distance_miles
    FROM trips t
    LEFT JOIN loads AS l ON t.load_id = l.load_id
	WHERE t.trip_id NOT IN (SELECT trip_id FROM invalid_planned) AND t.trip_id NOT IN (SELECT trip_id FROM invalid_actual) AND t.trip_id NOT IN (SELECT trip_id FROM delivery_2025)
	ORDER BY route_id, calender_year

), allocated_trip_costs AS (
	SELECT
        tr.route_id,
        tr.calender_year,
        tr.actual_distance_miles,
        tr.actual_distance_miles * tc.fuel_cost_per_mile AS allocated_fuel_cost,
        tr.actual_distance_miles * tc.maintenance_cost_per_mile AS allocated_maintenance_cost,
		(tr.actual_distance_miles * tc.fuel_cost_per_mile) + (tr.actual_distance_miles * tc.maintenance_cost_per_mile) AS allocated_total_cost
    FROM trip_miles_per_route tr
    LEFT JOIN fact_truck_cost_year AS tc
    ON tr.truck_id = tc.truck_id
    AND tr.calender_year = tc.calender_year
)

SELECT
    route_id,
    calender_year,
    ROUND(SUM(allocated_fuel_cost) / NULLIF(SUM(actual_distance_miles), 0), 2) AS fuel_cost_per_mile_route,
    ROUND(SUM(allocated_maintenance_cost) / NULLIF(SUM(actual_distance_miles), 0), 2) AS maintenance_cost_per_mile_route,
	ROUND(SUM(allocated_total_cost) / NULLIF(SUM(actual_distance_miles), 0), 2) AS total_cost_per_mile_route
FROM allocated_trip_costs
GROUP BY route_id, calender_year
ORDER BY route_id, calender_year;
