library(tidyverse)
library(scales)
library(frs)
library(ff)
library(biglm)
library(odbc)
library(DBI)

nyc_taxi <- dbConnect(odbc(), "localhost", database = "nyc_taxi")
