library(tidyverse)
library(scales)
library(frs)
library(odbc)
library(DBI)
library(clipr)
library(knitr)
library(kableExtra)
library(ggmap)
library(Cairo)

nyc_taxi <- dbConnect(odbc(), "localhost", database = "nyc_taxi")


frs::run_all_r_scripts("R", cleanup = FALSE)
