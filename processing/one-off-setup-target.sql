
DROP TABLE IF EXISTS yellow.tripdata
DROP TABLE IF EXISTS yellow.d_vendor_codes
DROP TABLE IF EXISTS yellow.d_rate_codes
DROP TABLE IF EXISTS yellow.d_store_and_forward_codes
DROP TABLE IF EXISTS yellow.d_payment_type_codes
DROP TABLE IF EXISTS yellow.d_taxi_zone_codes

-- Target dimension tables

CREATE TABLE yellow.d_vendor_codes (
	vendor_code CHAR(3) PRIMARY KEY,
	vendor_name VARCHAR(63) UNIQUE
)

INSERT INTO yellow.d_vendor_codes VALUES
	('CMT', 'Creative MObile Technologies, LLC'),
	('VTS', 'VeriFone Inc.'),
	('DDS', 'DDS')


CREATE TABLE yellow.d_rate_codes (
	rate_code TINYINT PRIMARY KEY,
	rate_description VARCHAR(63) NOT NULL UNIQUE
)
INSERT INTO yellow.d_rate_codes VALUES
	(1, 'Standard rate'),
	(2, 'JFK'),
	(3, 'Newark'),
	(4, 'Nassau or Westchester'),
	(5, 'Negotiated fare'),
	(6, 'Group ride')

CREATE TABLE yellow.d_store_and_forward_codes (
	store_and_forward_code CHAR(1) PRIMARY KEY,
	store_and_forward VARCHAR(63) UNIQUE
)

INSERT INTO yellow.d_store_and_forward_codes VALUES
	('Y', 'Store and forward trip'),
	('N', 'Not a store and forward trip')

CREATE TABLE yellow.d_payment_type_codes (
	payment_type_code TINYINT PRIMARY KEY,
	payment_type VARCHAR(63) UNIQUE
)

INSERT INTO yellow.d_payment_type_codes VALUES
	(1, 'Credit card'),
	(2, 'Cash'),
	(3, 'No charge'),
	(4, 'Dispute'),
	(5, 'Unknown'),
	(6, 'Voided trip')


CREATE TABLE yellow.d_taxi_zone_codes (
	location_code SMALLINT PRIMARY KEY,
	borough        NVARCHAR(255) ,
	zone           NVARCHAR(255),
	service_zone   NVARCHAR(255)
)

-- Target main table
CREATE TABLE yellow.tripdata (
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
	fare_amt				DECIMAL(9, 2)  NULL,
	extra    				DECIMAL(9, 2)  NULL,
	mta_tax					DECIMAL(9, 2)  NULL,
	tip_amt					DECIMAL(9, 2)  NULL,
	tolls_amt				DECIMAL(9, 2)  NULL,
	improvement_surcharge   DECIMAL(9, 2)  NULL,
	total_amt				DECIMAL(9, 2) NULL,
	pickup_zone_code        SMALLINT      NULL,
	dropoff_zone_code       SMALLINT      NULL

	CONSTRAINT pk_trips        PRIMARY KEY NONCLUSTERED (trip_id)
)

CREATE CLUSTERED COLUMNSTORE INDEX ccx_yellow_trips ON yellow.tripdata

-- make foreign keys. Note that these will be dropped while adding data, but nice to have them here for completeness--
-- We make a stored procedure to do this so we can use it again later without repeating code.
DROP PROCEDURE IF EXISTS dbo.make_yellow_keys
GO

CREATE PROCEDURE dbo.make_yellow_keys 
AS
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_vendor       FOREIGN KEY (vendor_code) REFERENCES yellow.d_vendor_codes
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_rate         FOREIGN KEY (rate_code) REFERENCES yellow.d_rate_codes
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_store_fwd    FOREIGN KEY (store_and_forward_code) REFERENCES yellow.d_store_and_forward_codes
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_payment_type FOREIGN KEY (payment_type_code) REFERENCES yellow.d_payment_type_codes
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_pickup_zone FOREIGN KEY (pickup_zone_code) REFERENCES yellow.d_taxi_zone_codes
	ALTER TABLE yellow.tripdata ADD CONSTRAINT fk_dropoff_zone FOREIGN KEY (dropoff_zone_code) REFERENCES yellow.d_taxi_zone_codes
GO

EXECUTE dbo.make_yellow_keys
