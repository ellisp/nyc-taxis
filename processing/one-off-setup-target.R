# This file sets up the fresh version of the target tables in the yellow sxchema
#
# Peter Ellis 15 December 2019

execute_sql(nyc_taxi, "processing/one-off-setup-target.sql")

download_if_fresh("https://s3.amazonaws.com/nyc-tlc/misc/taxi+_zone_lookup.csv",
                  destfile = "processing/taxi_zone_lookup.csv")

lu <- read_csv("processing/taxi_zone_lookup.csv", col_types = "cccc")

data.table::fwrite(lu, "processing/taxi_zone_lookup.txt", sep = "|", quote = FALSE, col.names = FALSE)

bcp("localhost", database = "nyc_taxi", schema = "yellow", table = "d_taxi_zone_codes", 
    file = "processing/taxi_zone_lookup.txt", 
    delim = "|", verbose = TRUE)
