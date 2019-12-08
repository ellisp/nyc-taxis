select * from dbo.tripdata_log order by id desc
select count(1) / 1000000 AS 'Million rows' from yellow.tripdata


SELECT
	COUNT(1) AS FREQ,
	MONTH(trip_pickup_datetime) AS month,
	YEAR(trip_pickup_datetime) AS year
FROM yellow.tripdata
GROUP BY
	MONTH(trip_pickup_datetime),
	YEAR(trip_pickup_datetime)
ORDER by year, month	