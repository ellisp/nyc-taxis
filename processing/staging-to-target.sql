/*
/processing/staging-to-target.sql

Mild cleanup of data in the dbo staging area and send it to target tables,
which are eventually transferred to the yellow schema

Peter Ellis 14 December 2019

30 minutes for 670,000 writes with all the foreign keys on - will take forever at this rate...
80 minutes for 2m writes with the foreign keys off - not much better
Changed recovery model to "simple", increases the speed to 280,000 rows in 10 minutes - much better but still going to take 12 days at that rate.
Removed the trip_id column so no longer has a primary key. Spped is similar, about 4 minutes for 100,000 rows
Tried taking the columnstore index off. Note this will make the file size extremely large and may not work. But this is much faster, 2 minutes for 180,000 rows. Only 8 days work...
*/


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
    trip_id                 BIGINT IDENTITY,
	vendor_code				CHAR(3)       NOT NULL,
	trip_pickup_datetime	DATETIME      NOT NULL,
	trip_dropoff_datetime	DATETIME      NOT NULL,
	passenger_count			TINYINT       NULL,
	trip_distance			DECIMAL(9, 4) NULL,
	start_lon				DECIMAL(9, 6) NULL,
	start_lat				DECIMAL(9, 6) NULL,
	rate_code				TINYINT       NULL,
	store_and_forward_code  CHAR(1)       NULL,
	end_lon					DECIMAL(9, 6) NULL,
	end_lat					DECIMAL(9, 6) NULL,
	payment_type_code   	TINYINT       NULL,
	fare_amt				DECIMAL(9, 2) NULL,
	surcharge				DECIMAL(9, 2) NULL,
	mta_tax					DECIMAL(9, 2) NULL,
	tip_amt					DECIMAL(9, 2) NULL,
	tolls_amt				DECIMAL(9, 2) NULL,
	improvement_surcharge   DECIMAL(9, 2) NULL,
	total_amt				DECIMAL(9, 2) NULL,

	 CONSTRAINT pk_trips        PRIMARY KEY NONCLUSTERED (trip_id)
	--CONSTRAINT fk_vendor       FOREIGN KEY (vendor_code) REFERENCES dbo.d_vendor_codes,
	--CONSTRAINT fk_rate         FOREIGN KEY (rate_code) REFERENCES dbo.d_rate_codes,
	--CONSTRAINT fk_store_fwd    FOREIGN KEY (store_and_forward_code) REFERENCES dbo.d_store_and_forward_codes,
	--CONSTRAINT fk_payment_type FOREIGN KEY (payment_type_code) REFERENCES dbo.d_payment_type_codes
)

CREATE CLUSTERED COLUMNSTORE INDEX ccx_yellow_trips ON dbo.tripdata


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
SELECT -- top 200000
	CASE
		WHEN vendor_name = '1' THEN 'CMT'
		WHEN vendor_name = '2' THEN 'VTS'
		ELSE vendor_name
	END,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	TRY_CAST(trip_distance AS DECIMAL(9, 4)),
	TRY_CAST(start_lon AS DECIMAL(9, 6)),
	TRY_CAST(start_lat AS DECIMAL(9, 6)),
	CASE 
		WHEN rate_code IN (1,2,3,4,5,6) THEN rate_code
		ELSE NULL
	END,
	CASE 
		WHEN store_and_forward IN ('0', 'FALSE', 'N') THEN 'N'
		WHEN store_and_forward IN ('1', 'TRUE', 'Y') THEN 'Y'
	END,
	TRY_CAST(end_lon AS DECIMAL(9, 6)),
	TRY_CAST(end_lat AS DECIMAL(9, 6)),
	CASE
		WHEN payment_type IN ('credit', 'cre', '1') THEN 1
		WHEN payment_type IN ('cash', 'csh', 'cas', '2') THEN 2
		WHEN payment_type IN ('no', 'no charge', 'noc', '3') THEN 3
		WHEN payment_type IN ('disput', 'dis', '4') THEN 4
		WHEN payment_type IN ('unknown', 'unk', '5') THEN 5
		WHEN payment_type In ('voided trip', 'voi', 'voided', '6') THEN 6
		ELSE NULL
	END,
	TRY_CAST(fare_amt AS DECIMAL(9, 2)),
	TRY_CAST(surcharge AS DECIMAL(9, 2)),
	TRY_CAST(mta_tax AS DECIMAL(9, 2)),
	TRY_CAST(tip_amt AS DECIMAL(9, 2)),
	TRY_CAST(tolls_amt AS DECIMAL(9, 2)),
	TRY_CAST(total_amt AS DECIMAL(9, 2))
FROM dbo.tripdata_0914

		




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
SELECT -- top 200000
    CASE
		WHEN vendor_name = '1' THEN 'CMT'
		WHEN vendor_name = '2' THEN 'VTS'
		ELSE vendor_name
	END,
	trip_pickup_datetime,
	trip_dropoff_datetime,
	passenger_count,
	TRY_CAST(trip_distance AS DECIMAL(9, 4)),
	TRY_CAST(start_lon AS DECIMAL(9, 6)),
	TRY_CAST(start_lat AS DECIMAL(9, 6)),
	CASE 
		WHEN rate_code IN (1,2,3,4,5,6) THEN rate_code
		ELSE NULL
	END,
	CASE 
		WHEN store_and_forward IN ('0', 'FALSE', 'N') THEN 'N'
		WHEN store_and_forward IN ('1', 'TRUE', 'Y') THEN 'Y'
	END,
	TRY_CAST(end_lon AS DECIMAL(9, 6)),
	TRY_CAST(end_lat AS DECIMAL(9, 6)),
	CASE
		WHEN payment_type IN ('credit', 'cre', '1') THEN 1
		WHEN payment_type IN ('cash', 'csh', 'cas', '2') THEN 2
		WHEN payment_type IN ('no', 'no charge', 'noc', '3') THEN 3
		WHEN payment_type IN ('disput', 'dis', '4') THEN 4
		WHEN payment_type IN ('unknown', 'unk', '5') THEN 5
		WHEN payment_type In ('voided trip', 'voi', 'voided', '6') THEN 6
		ELSE NULL
	END,
	TRY_CAST(fare_amt AS DECIMAL(9, 2)),
	TRY_CAST(surcharge AS DECIMAL(9, 2)),
	TRY_CAST(mta_tax AS DECIMAL(9, 2)),
	TRY_CAST(tip_amt AS DECIMAL(9, 2)),
	TRY_CAST(tolls_amt AS DECIMAL(9, 2)),
	TRY_CAST(improvement_surcharge AS DECIMAL(9, 2)),
	TRY_CAST(total_amt AS DECIMAL(9, 2))
FROM dbo.tripdata_1516

------------------Updates--------------

UPDATE dbo.tripdata SET start_lon = NULL, start_lat = NULL WHERE ABS(start_lon) > 180
UPDATE dbo.tripdata SET end_lon = NULL, end_lat = NULL WHERE ABS(end_lon) > 180
UPDATE dbo.tripdata SET start_lat = NULL, start_lon = NULL WHERE ABS(start_lat) > 90
UPDATE dbo.tripdata SET end_lat = NULL, end_lon = NULL WHERE ABS(end_lat) > 90
UPDATE dbo.tripdata SET trip_distance = NULL WHERE trip_distance < 0
UPDATE dbo.tripdata SET passenger_count = NULL WHERE passenger_count < 1
UPDATE dbo.tripdata SET fare_amt = NULL WHERE fare_amt < 0
UPDATE dbo.tripdata SET surcharge = NULL WHERE surcharge < 0
UPDATE dbo.tripdata SET tip_amt = NULL WHERE tip_amt < 0
UPDATE dbo.tripdata SET improvement_surcharge = NULL WHERE improvement_surcharge < 0
UPDATE dbo.tripdata SET total_amt = NULL WHERE total_amt < 0


----------------Transfer-------------------------
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
DROP TABLE dbo.tripdata_0914
DROP TABLE dbo.tripdata_1516

-- you *might* want to now shrink the database and rebuild the indexes. This is a rare situation when it makes sense I think.

*/
