/*
This is an example SQL query to drop one month's data from the database, most likely
necessary because of a problem with the data and we want to try it again for just that month.

Obviously we could turn this into a stored procedure but it's not really necessary;
straightforward to just edit this, as it will always bew used in an ad hoc way anyway.

Peter Ellis 9 Decmeber 2019

*/

DELETE FROM dbo.tripdata_log WHERE filename LIKE '%2014-02%'
DELETE FROM yellow.tripdata WHERE YEAR(trip_pickup_datetime) = 2014 AND MONTH(trip_pickup_datetime) = 2