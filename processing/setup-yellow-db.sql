

CREATE TABLE yellow.tripdata (
	vendor_name				CHAR(3) NOT NULL,
	trip_pickup_datetime	DATETIME NOT NULL,	
	trip_dropoff_datetime	DATETIME NOT NULL,
	passenger_count			TINYINT NOT NULL,
	trip_distance			NUMERIC(5, 2) NOT NULL,
	start_lon				FLOAT NOT NULL,
	start_lat				FLOAT NOT NULL,
	rate_code				VARCHAR(8) NULL,
	store_and_forward       NVARCHAR(8) NULL,
	end_lon					FLOAT NOT NULL,
	end_lat					FLOAT NOT NULL,
	payment_type			VARCHAR(6),
	fare_amt				NUMERIC(5,2) NOT NULL,
	surcharge				NUMERIC(2,1) NOT NULL,
	mta_tax					NUMERIC(5,2) NOT NULL,
	tip_amt					NUMERIC(5,2) NOT NULL,
	tolls_amt				NUMERIC(5, 2) NOT NULL,
	total_amt				NUMERIC(5, 2) NOT NULL
)

CREATE CLUSTERED COLUMNSTORE INDEX ccx_yellow_trips ON yellow.tripdata