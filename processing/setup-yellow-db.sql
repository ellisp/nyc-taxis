USE nyc_taxi

DROP TABLE IF EXISTS yellow.tripdata
DROP TABLE IF EXISTS dbo.tripdata_log
GO

CREATE TABLE dbo.tripdata_log (
	id INT IDENTITY PRIMARY KEY,
	filename VARCHAR(255),
	start_datetime DATETIME,
	end_datetime DATETIME
)

CREATE TABLE yellow.tripdata (
	vendor_name				CHAR(3) NOT NULL,
	trip_pickup_datetime	DATETIME NOT NULL,
	trip_dropoff_datetime	DATETIME NOT NULL,
	passenger_count			TINYINT NOT NULL,
	trip_distance			FLOAT NOT NULL,
	start_lon				FLOAT NOT NULL,
	start_lat				FLOAT NOT NULL,
	rate_code				VARCHAR(63) NULL,
	store_and_forward       VARCHAR(63) NULL,
	end_lon					FLOAT NOT NULL,
	end_lat					FLOAT NOT NULL,
	payment_type			VARCHAR(63),
	fare_amt				FLOAT NOT NULL,
	surcharge				FLOAT NOT NULL,
	mta_tax					FLOAT NULL,
	tip_amt					FLOAT NOT NULL,
	tolls_amt				FLOAT NOT NULL,
	total_amt				FLOAT NOT NULL
)

CREATE CLUSTERED COLUMNSTORE INDEX ccx_yellow_trips ON yellow.tripdata