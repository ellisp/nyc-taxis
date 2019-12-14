USE nyc_taxi

DROP TABLE IF EXISTS dbo.tripdata_early
DROP TABLE IF EXISTS dbo.tripdata_later
DROP TABLE IF EXISTS dbo.tripdata_log
GO

CREATE TABLE dbo.tripdata_log (
	id INT IDENTITY PRIMARY KEY,
	filename VARCHAR(255),
	start_datetime DATETIME DEFAULT GETDATE()
)

-- Note that starting in September 2010, end Lat and Long start to occasionally be NULL

CREATE TABLE dbo.tripdata_early (
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
	-- in 2010 they start coding cash as "Cas" rather than a number so we need to allow strings here:
	payment_type			VARCHAR(63),
	fare_amt				VARCHAR(63),
	surcharge				FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	total_amt				FLOAT NOT NULL
)

-- From 2015 onwards there is an extra column
CREATE TABLE dbo.tripdata_later (
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
	-- in 2010 they start coding cash as "Cas" rather than a number so we need to allow strings here:
	payment_type			VARCHAR(63),
	fare_amt				VARCHAR(63),
	surcharge				FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	improvement_surcharge   FLOAT NULL,
	total_amt				FLOAT NOT NULL
)

-- 134 mb AND 19mb without indexing;    and 3.8GB with it
CREATE CLUSTERED COLUMNSTORE INDEX ccx_st1 ON dbo.tripdata_early
CREATE CLUSTERED COLUMNSTORE INDEX ccx_st2 ON dbo.tripdata_later
