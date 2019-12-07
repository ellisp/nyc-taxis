source("setup.R")

#
execute_sql(nyc_taxi, "processing/setup-yellow-db.sql")

# Note that the first row of each file is the column headers, then there is a blank row, so
# when we upload these we start at row 3

system.time({
  files <- list.files("raw-data", pattern = "yellow.*\\.csv", full.names = TRUE)
  for (f in files){
    sql <- paste0("INSERT INTO dbo.tripdata_log (filename) VALUES ('", f, "')")
    dbGetQuery(nyc_taxi, sql)
    bcp("localhost", database = "nyc_taxi", schema = "yellow", table = "tripdata", 
        file = f, 
        delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000")
  
  }
})
