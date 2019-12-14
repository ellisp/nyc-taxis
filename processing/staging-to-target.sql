
DROP TABLE IF EXISTS dbo.tripdata
DROP TABLE IF EXISTS dbo.d_vendor_codes
DROP TABLE IF EXISTS dbo.d_rate_codes
DROP TABLE IF EXISTS dbo.d_store_and_forward_codes
DROP TABLE IF EXISTS dbo.d_payment_type_codes

-- Target dimension tables

CREATE TABLE dbo.d_vendor_codes (
	vendor_code CHAR(3) PRIMARY KEY,
	vendor_name VARCHAR(63) UNIQUE
)

INSERT INTO dbo.d_vendor_codes VALUES
	('CMT', 'Creative MObile Technologies, LLC'),
	('VTS', 'VeriFone Inc.'),
	('DDS', 'DDS')


CREATE TABLE dbo.d_rate_codes (
	rate_code TINYINT PRIMARY KEY,
	rate_description VARCHAR(63) NOT NULL UNIQUE
)
INSERT INTO dbo.d_rate_codes VALUES
	(1, 'Standard rate'),
	(2, 'JFK'),
	(3, 'Newark'),
	(4, 'Nassau or Westchester'),
	(5, 'Negotiated fare'),
	(6, 'Group ride')

CREATE TABLE dbo.d_store_and_forward_codes (
	store_and_forward_code CHAR(1) PRIMARY KEY,
	store_and_forward VARCHAR(63) UNIQUE
)

INSERT INTO dbo.d_store_and_forward_codes VALUES
	('Y', 'Store and forward trip'),
	('N', 'Not a store and forward trip')

CREATE TABLE dbo.d_payment_type_codes (
	payment_type_code TINYINT PRIMARY KEY,
	payment_type VARCHAR(63) UNIQUE
)

INSERT INTO dbo.d_payment_type_codes VALUES
	(1, 'Credit card'),
	(2, 'Cash'),
	(3, 'No charge'),
	(4, 'Dispute'),
	(5, 'Unknown'),
	(6, 'Voided trip')


-- Target main table
CREATE TABLE dbo.tripdata (
	vendor_code				CHAR(3)       NOT NULL,
	trip_pickup_datetime	DATETIME      NOT NULL,
	trip_dropoff_datetime	DATETIME      NOT NULL,
	passenger_count			TINYINT       NOT NULL,
	trip_distance			DECIMAL(9, 4) NOT NULL,
	start_lon				DECIMAL(9, 6) NOT NULL,
	start_lat				DECIMAL(9, 6) NOT NULL,
	rate_code				TINYINT       NULL,
	store_and_forward_code  CHAR(1)       NULL,
	end_lon					DECIMAL(9, 6) NULL,
	end_lat					DECIMAL(9, 6) NULL,
	payment_type_code   	TINYINT       NULL,
	fare_amt				VARCHAR(63)   NULL,
	surcharge				DECIMAL(9, 2) NOT NULL,
	mta_tax					DECIMAL(9, 2) NULL,
	tip_amt					DECIMAL(9, 2) NOT NULL,
	tolls_amt				DECIMAL(9, 2) NOT NULL,
	improvement_surcharge   DECIMAL(9, 2) NULL,
	total_amt				DECIMAL(9, 2) NOT NULL,

	CONSTRAINT fk_vendor       FOREIGN KEY (vendor_code) REFERENCES dbo.d_vendor_codes,
	CONSTRAINT fk_rate         FOREIGN KEY (rate_code) REFERENCES dbo.d_rate_codes,
	CONSTRAINT fk_store_fwd    FOREIGN KEY (store_and_forward_code) REFERENCES dbo.d_store_and_forward_codes,
	CONSTRAINT fk_payment_type FOREIGN KEY (payment_type_code) REFERENCES dbo.d_payment_type_codes
)

CREATE CLUSTERED COLUMNSTORE INDEX ccx_yellow_trips ON dbo.tripdata
GO

-- First six years, with no surcharge data:
INSERT INTO dbo.tripdata(
	vendor_code,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	trip_distance,
	start_lon,
	start_lat,
	rate_code,
	store_and_forward_code,
	end_lon,
	end_lat,
	payment_type_code,
	fare_amt,
	surcharge,
	mta_tax,
	tip_amt,
	tolls_amt,
	total_amt
)
SELECT top 1000
	CASE
		WHEN vendor_name = 1 THEN 'CMT'
		WHEN vendor_name = 2 THEN 'VTS'
		ELSE vendor_name
	END,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	trip_distance,
	start_lon,
	start_lat,
	CASE 
		WHEN rate_code IN (1,2,3,4,5,6) THEN rate_code
		ELSE NULL
	END,
	CASE 
		WHEN store_and_forward IN ('0', 'FALSE', 'N') THEN 'N'
		WHEN store_and_forward IN ('1', 'TRUE', 'Y') THEN 'Y'
	END,
	end_lon,
	end_lat,
	CASE
		WHEN payment_type IN ('credit', 'cre', '1') THEN 1
		WHEN payment_type IN ('cash', 'csh', 'cas', '2') THEN 2
		WHEN payment_type IN ('no', 'no charge', '3') THEN 3
		WHEN payment_type IN ('disput', 'dis', '4') THEN 4
		WHEN payment_type IN ('unknown', 'unk', '5') THEN 5
		WHEN payment_type In ('voided trip', 'voi', 'voided', '6') THEN 6
		ELSE NULL
	END,
	CASE WHEN ISNUMERIC(fare_amt) = 1 THEN fare_amt ELSE NULL END,
	surcharge,
	mta_tax,
	tip_amt,
	tolls_amt,
	total_amt
FROM dbo.tripdata_early



-- 2015 onwards, we have surcharge data:
INSERT INTO dbo.tripdata(
	vendor_code,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	trip_distance,
	start_lon,
	start_lat,
	rate_code,
	store_and_forward_code,
	end_lon,
	end_lat,
	payment_type_code,
	fare_amt,
	surcharge,
	mta_tax,
	tip_amt,
	tolls_amt,
	improvement_surcharge,
	total_amt
)
SELECT top 1000
    CASE
		WHEN vendor_name = 1 THEN 'CMT'
		WHEN vendor_name = 2 THEN 'VTS'
		ELSE vendor_name
	END,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	trip_distance,
	start_lon,
	start_lat,
	CASE 
		WHEN rate_code IN (1,2,3,4,5,6) THEN rate_code
		ELSE NULL
	END,
	CASE 
		WHEN store_and_forward IN ('0', 'FALSE', 'N') THEN 'N'
		WHEN store_and_forward IN ('1', 'TRUE', 'Y') THEN 'Y'
	END,
	end_lon,
	end_lat,
	CASE
		WHEN payment_type IN ('credit', 'cre', '1') THEN 1
		WHEN payment_type IN ('cash', 'csh', 'cas', '2') THEN 2
		WHEN payment_type IN ('no', 'no charge', '3') THEN 3
		WHEN payment_type IN ('disput', 'dis', '4') THEN 4
		WHEN payment_type IN ('unknown', 'unk', '5') THEN 5
		WHEN payment_type In ('voided trip', 'voi', 'voided', '6') THEN 6
		ELSE NULL
	END,
	CASE WHEN ISNUMERIC(fare_amt) = 1 THEN fare_amt ELSE NULL END,
	surcharge,
	mta_tax,
	tip_amt,
	tolls_amt,
	improvement_surcharge,
	total_amt
FROM dbo.tripdata_later


-- if everything works can now transfer over to the production databases and drop the temporary versions of the data
DROP TABLE IF EXISTS yellow.tripdata
DROP TABLE IF EXISTS yellow.d_payment_type_codes
DROP TABLE IF EXISTS yellow.d_store_and_forward_codes
DROP TABLE IF EXISTS yellow.d_rate_codes
DROP TABLE IF EXISTS yellow.d_vendor_codes
ALTER SCHEMA yellow TRANSFER dbo.d_payment_type_codes
ALTER SCHEMA yellow TRANSFER dbo.d_store_and_forward_codes
ALTER SCHEMA yellow TRANSFER dbo.d_rate_codes
ALTER SCHEMA yellow TRANSFER dbo.d_vendor_codes
ALTER SCHEMA yellow TRANSFER dbo.tripdata



/*
-- if you're really sure it's all ok you might want to delete the staging tables to save space:
DROP TABLE dbo.tripdata_early
DROP TABLE dbo.tripdata_later

-- you *might* want to now shrink the database and rebuild the indexes. This is a rare situation when it makes sense I think.

*/
