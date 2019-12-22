use nyc_taxi
select * from dbo.tripdata_log order by id desc

select '0914' AS years, count(1) / 1000000 AS 'Million rows' from dbo.tripdata_0914
union
select '1516' AS years, count(1) / 1000000 AS 'Million rows' from dbo.tripdata_1516
union
select '1619' AS years, count(1) / 1000000 AS 'Million rows' from dbo.tripdata_1619

/*
SELECT
	COUNT(1) AS FREQ,
	MONTH(trip_pickup_datetime) AS month,
	YEAR(trip_pickup_datetime) AS year
FROM yellow.tripdata
GROUP BY
	MONTH(trip_pickup_datetime),
	YEAR(trip_pickup_datetime)
ORDER by year, month	



*/

