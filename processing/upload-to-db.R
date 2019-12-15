# /processing/upload-to-db.R
#
# This file deletes an old version of the staging tables in the database, sets up tables and 
# uploads all the CSVs to the database. This takes about six minutes per month of data on my laptop.
#
# Peter Ellis

# Only uncomment the next line if you want to wipe away the database (if it's already there) and start
# from scratch. I've commented it out to avoid me doing this by mistake; the code below is written
# so you can resume uploading in case you get interrupted, or if you want to add some new months
# of data at some point (in which case you don't need to uncomment that next line)
#
execute_sql(nyc_taxi, "processing/setup-staging-db.sql")

# Note that the first row of each file is the column headers, then there is a blank row, so
# when we upload these we start at row 3

# The -m 4000 means it will skip up to 4000 bad rows which is enough for the 2010 files that have
# bad extra columns in them. There are 11,366/2 such failures in 2010-03 and 2,225/2 in 2010-02

system.time({
  files <- list.files("raw-data", pattern = "yellow.*\\.csv", full.names = TRUE)
  for (f in files){
    already_done <- dbGetQuery(nyc_taxi, "SELECT filename FROM dbo.tripdata_log")$filename
    if(! f %in% already_done){
      sql <- paste0("INSERT INTO dbo.tripdata_log (filename) VALUES ('", f, "')")
      dbGetQuery(nyc_taxi, sql)
      
      if(grepl("_2015-", f, fixed = TRUE) | grepl("2016\\-0[1-6]", f)){
        bcp("localhost", database = "nyc_taxi", schema = "dbo", table = "tripdata_1516", 
            file = f, 
            delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000 -m 6000") 
      } else {
        if(grepl("\\_201[6-9]", f)) {
          bcp("localhost", database = "nyc_taxi", schema = "dbo", table = "tripdata_1619", 
              file = f, 
              delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000 -m 6000")
        } else {
          
          bcp("localhost", database = "nyc_taxi", schema = "dbo", table = "tripdata_0914", 
              file = f, 
              delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000 -m 6000")
        }
      }
    }
  }
})



# source("processing/one-off-setup-target.R")

# I expect this next script to take quite a few hours to run, so rather than uncommenting it
# you might prefer to do it in Management Studio
# execute_sql(nyc_taxi, "processing/staging-to-target.sql")

