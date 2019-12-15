/*
/processing/staging-to-target.sql

Mild cleanup of data in the dbo staging area and send it to target tables,
which are eventually transferred to the yellow schema

Peter Ellis 14 December 2019

13 million rows in 2 minutes with no foreign keys during upload, no datatype changes
13 million rows in 8 minutes with foreign keys, no datatype changes
2 million rows in 15 seconds, fk after upload, no datatype changes
2 million rows in 18 seconds, fk after upload, 5 try_cast operations
2 million rows in 18 seconds, fk after upload, 5 try_cast operations and 6 implicit cast
13 million rows in 2 minutes, fk after upload, 5 try_cast operations 
13 million rows in 2 minutes, fk after upload, 6 try_cast operations
13 million rows in 2 minutes, fk after upload, 13 try_cast operations

Note that some of the arithmetic overflow errors are from excessivley large negative figures eg -20m in the total fare.
It is easy to forget this is possible when troubleshooting!
*/

-- Drop foreign key constraints so can do everything faster:
ALTER TABLE yellow.tripdata DROP CONSTRAINT fk_vendor
ALTER TABLE yellow.tripdata DROP CONSTRAINT fk_rate
ALTER TABLE yellow.tripdata DROP CONSTRAINT fk_store_fwd
ALTER TABLE yellow.tripdata DROP CONSTRAINT fk_payment_type




-- First six years, with no surcharge data:
INSERT INTO yellow.tripdata(
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
SELECT -- top 2000000
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
INSERT INTO yellow.tripdata(
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
SELECT -- top 2000000
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
-- Re-create the foreign keys
ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_vendor       FOREIGN KEY (vendor_code) REFERENCES yellow.d_vendor_codes
ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_rate         FOREIGN KEY (rate_code) REFERENCES yellow.d_rate_codes
ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_store_fwd    FOREIGN KEY (store_and_forward_code) REFERENCES yellow.d_store_and_forward_codes
ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_payment_type FOREIGN KEY (payment_type_code) REFERENCES yellow.d_payment_type_codes

-- Turn any physically impossible values remaining into NULL. Note that ones that don't fit with the datatype (eg longitude with more than 3 digits to left of decimal point)
-- will already have become NULL in the process above
UPDATE yellow.tripdata SET start_lon = NULL, start_lat = NULL WHERE ABS(start_lon) > 180 OR start_lon = 0
UPDATE yellow.tripdata SET end_lon = NULL, end_lat = NULL WHERE ABS(end_lon) > 180 OR end_lon = 0
UPDATE yellow.tripdata SET start_lat = NULL, start_lon = NULL WHERE ABS(start_lat) > 90 OR start_lat = 0
UPDATE yellow.tripdata SET end_lat = NULL, end_lon = NULL WHERE ABS(end_lat) > 90 OR end_lat = 0
UPDATE yellow.tripdata SET trip_distance = NULL WHERE trip_distance <= 0
UPDATE yellow.tripdata SET passenger_count = NULL WHERE passenger_count < 1
UPDATE yellow.tripdata SET fare_amt = NULL WHERE fare_amt <= 0
UPDATE yellow.tripdata SET surcharge = NULL WHERE surcharge < 0
UPDATE yellow.tripdata SET tip_amt = NULL WHERE tip_amt < 0
UPDATE yellow.tripdata SET improvement_surcharge = NULL WHERE improvement_surcharge < 0
UPDATE yellow.tripdata SET total_amt = NULL WHERE total_amt <= 0

-- Reorganise the columnstore index
ALTER INDEX ccx_yellow_trips ON yellow.tripdata REORGANIZE with (COMPRESS_ALL_ROW_GROUPS = ON)  


/*
-- if you're really sure it's all ok you might want to delete the staging tables to save space:
DROP TABLE dbo.tripdata_0914
DROP TABLE dbo.tripdata_1516

-- and then you *might* want to now shrink the database and rebuild the indexes. This is a rare situation when it makes sense I think.

*/
