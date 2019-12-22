

-------------------First look at the data---------------------
SELECT TOP 10 * FROM yellow.tripdata 
GO

-------------------Filtered version of the data--------------
DROP VIEW IF EXISTS yellow.tripdata_filtered
GO

CREATE VIEW yellow.tripdata_filtered AS 
	(SELECT * 
	 FROM yellow.tripdata
	 WHERE start_lon > -74.05 AND start_lon < -73.75 AND
		   start_lat > 40.58 AND start_lat < 40.90 AND
		   end_lon > -74.05 AND end_lon < -73.75 AND
		   end_lat > 40.58 AND end_lat < 40.90)
GO

------------Passenger counts----------
SELECT
	count(1) as freq,
	passenger_count,
	vendor_code
FROM yellow.tripdata_filtered
GROUP BY vendor_code, passenger_count
ORDER BY passenger_count DESC



-------------------Revised filtered version of the data--------------
DROP VIEW IF EXISTS yellow.tripdata_filtered
GO

CREATE VIEW yellow.tripdata_filtered AS 
	(SELECT * 
	 FROM yellow.tripdata
	 WHERE start_lon > -74.05 AND start_lon < -73.75 AND
		   start_lat > 40.58 AND start_lat < 40.90 AND
		   end_lon > -74.05 AND end_lon < -73.75 AND
		   end_lat > 40.58 AND end_lat < 40.90 AND
		   passenger_count > 0 AND passenger_count < 7)
GO


-----------------trip distance----
WITH a AS (SELECT ROUND(trip_distance, 1) AS rounded_trip_distance 
           FROM yellow.tripdata)
SELECT
	COUNT(1) AS freq,
	rounded_trip_distance
FROM a
GROUP BY rounded_trip_distance
ORDER BY rounded_trip_distance


-------------------Revised filtered version of the data--------------
DROP VIEW IF EXISTS yellow.tripdata_filtered
GO

CREATE VIEW yellow.tripdata_filtered AS 
	(SELECT 
		*,
		trip_duration_min = DATEDIFF(minute, trip_dropoff_datetime, trip_pickup_datetime),
		trip_speed_mph = trip_distance / DATEDIFF(hour, trip_dropoff_datetime, trip_pickup_datetime)
	 FROM yellow.tripdata
	 WHERE start_lon > -74.05 AND start_lon < -73.75 AND
		   start_lat > 40.58 AND start_lat < 40.90 AND
		   end_lon > -74.05 AND end_lon < -73.75 AND
		   end_lat > 40.58 AND end_lat < 40.90 AND
		   passenger_count > 0 AND passenger_count < 7 AND
		   trip_distance > 0 AND trip_distance < 100)
GO

----------------Distribution of trip durations-------------
WITH a AS (SELECT ROUND(trip_duration_min, 0) AS rounded_trip_duration 
           FROM yellow.tripdata_filtered 
		   WHERE trip_duration_min <= 600)
SELECT
	COUNT(1) AS freq,
	rounded_trip_duration
FROM a
GROUP BY rounded_trip_duration
ORDER BY rounded_trip_duration


----------------Distribution of mphs-------------
WITH a AS (SELECT ROUND(trip_speed_mph, 0) AS rounded_trip_speed 
           FROM yellow.tripdata_filtered 
		   WHERE trip_speed_mph <= 120 AND trip_duration_min < 180)
SELECT
	COUNT(1) AS freq,
	rounded_trip_speed
FROM a
GROUP BY rounded_trip_speed
ORDER BY rounded_trip_speed


-- TODO - density plots of the various $ amounts paid----------

-------------------Revised filtered version of the data--------------
DROP VIEW IF EXISTS yellow.tripdata_filtered2
GO

CREATE VIEW yellow.tripdata_filtered2 AS 
	(SELECT 
		*
	 FROM yellow.tripdata_filtered
	 WHERE trip_speed_mph > 1 AND trip_speed_mph < 60 AND trip_duration_min < 180 AND
	      total_amt > 0 AND total_amt < 200 AND
		  fare_amt > 0 AND fare_amt < 200 AND
		  tip_amt >= 0 AND tip_amt < 200
	 )
GO

-----------------------spatially aggregated set--------
DROP TABLE IF EXISTS yellow.tripdata_sp_agg


WITH a AS
	(SELECT
		fare_amt                       AS fare_amt,
		fare_amt / trip_distance       AS fare_distance,
		ROUND(start_lon, 4)            AS round_lon,
		ROUND(start_lat, 4)            AS round_lat
	 FROM yellow.tripdata_filtered2)
SELECT
	AVG(fare_amt) AS mean_fare_amt,
	AVG(fare_distance) AS mean_fare_distance,
	round_lon,
	round_lat
INTO yellow.tripdata_sp_agg
FROM a
GROUP BY  
	round_lon,
	round_lat
GO
-- then use that for drawing plots


-------------Arc distance---
DROP FUNCTION IF EXISTS dbo.arc_distance
GO
/*
	arc-distance in miles lat and lon of two points
	@param @theta_1 starting longitude
	@param @phi_1 starting latitude
	@param @theta_2 ending longitude
	@param @phi_2 ending latitude
*/
CREATE FUNCTION arc_distance(@theta_1 REAL, @phi_1 REAL, @theta_2 REAL, @phi_2 REAL)
RETURNS REAL
AS
BEGIN
	DECLARE @temp REAL
	DECLARE @distance REAL

	SET @temp = POWER(SIN(@theta_2 - @theta_1) /  2 * PI() / 180, 2) +
	            COS(@theta_1 * PI() / 180) * COS(@theta_2 * PI() / 180.0) * 
				  POWER(SIN((@phi_2 - @phi_1 ) / 2 * PI() / 180), 2)

	SET @distance = 2 * ATN2(SQRT(@temp), SQRT(1 - @temp)) * 3958.8

	RETURN(@distance)

END
GO

WITH b AS
	(SELECT top 10000
		ROUND(trip_distance, 1) AS trip_distance, 
		ROUND(dbo.arc_distance(start_lon, start_lat, end_lon, end_lat), 1) AS arc_distance
	 FROM yellow.tripdata_filtered)
SELECT
	COUNT(1) AS freq,
	trip_distance,
	arc_distance
FROM b
GROUP BY 
	trip_distance, 
	arc_distance
GO



-------------------pickup by time of day-------------
WITH a AS 
    (SELECT 
		DATEPART(hour, trip_pickup_datetime) AS hour_of_day,
		DATEPART(dw, trip_pickup_datetime) AS day_of_week,
		tip_amt,
		fare_amt
	 FROM yellow.tripdata)
SELECT
	COUNT(1) AS freq,
	AVG(tip_amt / fare_amt) AS tip_percentage,
	hour_of_day,
	day_of_week
FROM a
GROUP BY
	hour_of_day,
	day_of_week
-- Then use that for drawing plots

