/*
This script creates a table in the database to store logs of SQL scripts that have been run by execute_sql()
*/
CREATE TABLE dbo.sql_executed_by_r_log
(
  log_event_code INT NOT NULL IDENTITY PRIMARY KEY, 
  start_time     DATETIME, 
  end_time       DATETIME,
  sub_text       NVARCHAR(200),
  script_name    NVARCHAR(1000),
  batch_number   INT,
  result         NCHAR(30),
  err_mess       VARCHAR(8000),
  duration       NUMERIC(18, 2),
  sub_out        NVARCHAR(255),
  ruser          NVARCHAR(255),
);