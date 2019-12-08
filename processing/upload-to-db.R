# This file deletes an old version of the database, sets up tables and uploads all the CSVs to the database.
# This takes about six minutes per month of data on my laptop
#
# Peter Ellis

source("setup.R")

# Only uncomment the next line if you want to wipe away the database (if it's already there) and start
# from scratch. I've commented it out to avoid me doing this by mistake; the code below is written
# so you can resume uploading in case you get interrupted, or if you want to add some new months
# of data at some point (in which case you don't need to uncomment that next line)
#
# execute_sql(nyc_taxi, "processing/setup-yellow-db.sql")

# Note that the first row of each file is the column headers, then there is a blank row, so
# when we upload these we start at row 3

# The -m 100 means it will skip up to 100 bad rows

system.time({
  files <- list.files("raw-data", pattern = "yellow.*\\.csv", full.names = TRUE)
  for (f in files){
    already_done <- dbGetQuery(nyc_taxi, "SELECT filename FROM dbo.tripdata_log")$filename
    if(! f %in% already_done){
      sql <- paste0("INSERT INTO dbo.tripdata_log (filename) VALUES ('", f, "')")
      dbGetQuery(nyc_taxi, sql)
      bcp("localhost", database = "nyc_taxi", schema = "yellow", table = "tripdata", 
          file = f, 
          delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000 -m 100")
    }
  
  }
})
