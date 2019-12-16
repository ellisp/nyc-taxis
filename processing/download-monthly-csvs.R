
# Data are in S3 buckets linkedc to from https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page,
# at urls like: 
# https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_2019-01.csv


source("setup.R")

# Download original CSVs. This is > 140GB of data so make sure you have disk space, and only do this
# if you have unlimited internet downloads...
#
# Note that this will keep going for 10 tries of the whole cycle if it missed some things on the first round.
for(i in 1:10){
  
  core_url <- "https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_YYYY-MM.csv"
  all_years <- 2009:2019
  all_months <- str_pad(1:12, 2, "left", pad = "0")
  
  for(y in all_years){
    message(paste("Downloading", y))
    for(m in all_months){
      this_url <- gsub("YYYY", y, core_url)
      this_url <- gsub("MM", m, this_url)
      filename <- str_extract(this_url, "yellow.*\\.csv$")
      destfile <- paste0("raw-data/", filename)
      try({status <- frs::download_if_fresh(this_url, destfile = destfile)})
      if(!status %in% c(0, 987)){
        # delete any partial download that did not complete:
        unlink(destfile)
      }
    }
  }

}