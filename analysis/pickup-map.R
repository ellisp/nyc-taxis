


sql <- "
WITH a AS
	(SELECT
		fare_amt                       AS fare_amt,
		ROUND(start_lon, 4)            AS round_lon,
		ROUND(start_lat, 4)            AS round_lat
	 FROM dbo.tripdata_1516
    WHERE start_lon > -74.05 AND start_lon < -73.75 AND
    		   start_lat > 40.58 AND start_lat < 40.90 AND
    end_lon > -74.05 AND end_lon < -73.75 AND
    end_lat > 40.58 AND end_lat < 40.90 AND
    passenger_count > 0 AND passenger_count < 7 AND
    trip_distance > 0 AND trip_distance < 100)
SELECT
	AVG(CAST(fare_amt AS float)) AS mean_fare_amt,
	COUNT(1) AS count,
	round_lon,
	round_lat
FROM a
GROUP BY  
	round_lon,
	round_lat"

pickups <- dbGetQuery(nyc_taxi, sql) %>% as_tibble()

alpha_range <- c(0.14, 0.75)
size_range <- c(0.134, 0.173) * 4
font_family = "Calibri"
title_font_family = "Calibri"
p <- pickups %>%
  #complete(round_lon, round_lat, fill = list(count = 0)) %>%
  ggplot(aes(x = round_lon, y = round_lat, alpha = count, size = count)) +
  geom_point(colour = "yellow") +
  theme_dark_map() +
  scale_size_continuous(range = size_range, trans = "log", limits = range(pickups$count)) +
  scale_alpha_continuous(range = alpha_range, trans = "log", limits = range(pickups$count)) +
  scale_fill_gradient(low = "black", high = "white") +
  coord_map() +
  theme(legend.position = "none")

pixels_x <- diff(range(pickups$round_lon)) * 10000 + 1
pixels_y <- round((diff(range(pickups$round_lat)) * 10000 + 1) / cos(41 / 180 * pi))

CairoPNG("output/plot5.png", pixels_x * 2, pixels_y * 2, bg = "black")
print(p)
dev.off()
