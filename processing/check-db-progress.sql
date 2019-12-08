select * from dbo.tripdata_log order by id desc
select count(1) / 1000000 AS 'Million rows' from yellow.tripdata