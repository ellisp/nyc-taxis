source("setup.R")

x <-read_csv("raw-data/yellow_tripdata_2009-01.csv", n_max = 10000, col_types = cols()) %>%
  rename_all(tolower)
  

data.table::fwrite(x[ , 1:2], "sample_data.csv", sep = ",")

bcp("localhost", database = "nyc_taxi", schema = "yellow", table = "tripdata", 
    file = "output.txt", delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000")

execute_sql(con, "processing/setup-yellow-db.sql")

# Note that the first row of each file is the column headers, then there is a blank row, so
# when we upload these we start at row 3

system.time(
bcp("localhost", database = "nyc_taxi", schema = "yellow", table = "tripdata", 
    file = "raw-data/yellow_tripdata_2009-01.csv", 
    delim = ",", verbose = TRUE, extra_args = " -F 3 -b 1000000")
)
