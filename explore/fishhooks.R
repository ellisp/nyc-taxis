
source("setup.R")

files <- list.files("raw-data", pattern = "yellow.*\\.csv", full.names = TRUE)
x <- read_csv(files[83], n_max = 1e5)
y <- read_csv(files[15], n_max = 1e5)
z <- read_csv(files[1], n_max = 1e5)

f= files[15]

dim(x)
dim(y)
dim(z)

x
View(x)
View(y)

all_file_heads <-lapply(files, function(f){
  read_csv(f, n_max = 1e4, col_types = cols())
})

sapply(all_file_heads, ncol)

names19 <- function(d){
  n <- names(d)
  n <- c(n, rep(NA, 19 - length(n)))
  return(n)
}

lapply(all_file_heads, names19) %>%
  do.call(rbind, .) %>%
  as.data.frame(stringsAsFactors = FALSE) %>%
  group_by_all() %>%
  summarise(freq = n()) %>%
  kable() %>%
  kable_styling() %>%
  write_clip()

            