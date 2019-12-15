-- /processing/setup-staging-db.sql

USE nyc_taxi

DROP TABLE IF EXISTS dbo.tripdata_0914
DROP TABLE IF EXISTS dbo.tripdata_1516
DROP TABLE IF EXISTS dbo.tripdata_1619
DROP TABLE IF EXISTS dbo.tripdata_log
GO

CREATE TABLE dbo.tripdata_log (
	id INT IDENTITY PRIMARY KEY,
	filename VARCHAR(255),
	start_datetime DATETIME DEFAULT GETDATE()
)

-- Note that starting in September 2010, end Lat and Long start to occasionally be NULL

CREATE TABLE dbo.tripdata_0914 (
	vendor_name				CHAR(3) NOT NULL,
	trip_pickup_datetime	DATETIME NOT NULL,
	trip_dropoff_datetime	DATETIME NOT NULL,
	passenger_count			TINYINT NOT NULL,
	trip_distance			FLOAT NOT NULL,
	start_lon				FLOAT NOT NULL,
	start_lat				FLOAT NOT NULL,
	rate_code				VARCHAR(63) NULL,
	store_and_forward       VARCHAR(63) NULL,
	end_lon					FLOAT NULL,
	end_lat					FLOAT NULL,
	payment_type			VARCHAR(63),
	fare_amt				FLOAT NOT NULL,
	surcharge				FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	total_amt				FLOAT NOT NULL
)

-- From 2015 TO 2016-06 there is an extra column for improvement surcharge
CREATE TABLE dbo.tripdata_1516 (
	vendor_name				CHAR(3) NOT NULL,
	trip_pickup_datetime	DATETIME NOT NULL,
	trip_dropoff_datetime	DATETIME NOT NULL,
	passenger_count			TINYINT NOT NULL,
	trip_distance			FLOAT NOT NULL,
	start_lon				FLOAT NOT NULL,
	start_lat				FLOAT NOT NULL,
	rate_code				VARCHAR(63) NULL,
	store_and_forward       VARCHAR(63) NULL,
	end_lon					FLOAT NULL,
	end_lat					FLOAT NULL,
	payment_type			VARCHAR(63),
	fare_amt				FLOAT NOT NULL,
	surcharge				FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	improvement_surcharge   FLOAT NULL,
	total_amt				FLOAT NOT NULL
)

-- From 2016-07 there are no more lats and longs, just ids
CREATE TABLE dbo.tripdata_1619 (
	vendor_name				CHAR(3) NOT NULL,
	trip_pickup_datetime	DATETIME NOT NULL,
	trip_dropoff_datetime	DATETIME NOT NULL,
	passenger_count			TINYINT NOT NULL,
	trip_distance			FLOAT NOT NULL,
	rate_code				VARCHAR(63) NULL,
	store_and_forward       VARCHAR(63) NULL,
	pu_location_id          SMALLINT NULL,
	do_location_id          SMALLINT NULL,
	payment_type			VARCHAR(63),
	fare_amt				FLOAT NOT NULL,
	extra        			FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	improvement_surcharge   FLOAT NULL,
	total_amt				FLOAT NOT NULL,
	congestion_surcharge    FLOAT NOT NULL
)


-- 134 mb AND 19mb without indexing;    and 3.8GB with it
CREATE CLUSTERED COLUMNSTORE INDEX ccx_st1 ON dbo.tripdata_0914
CREATE CLUSTERED COLUMNSTORE INDEX ccx_st2 ON dbo.tripdata_1516
CREATE CLUSTERED COLUMNSTORE INDEX ccx_st3 ON dbo.tripdata_1619
