require(ggplot2)
require(dplyr)
require(sf)
require(viridis)


df_pop <- st_read("shp/joined/data_per-pop.gpkg")


names <- c("mass_building",
           "mass_mobility")

lab <- c("mass of\nbuildings\n(t/cap)",
         "mass of\nmobility\ninfrastructure\n(t/cap)")

ramp <- c("rocket", "mako")

br <- c(25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000)


for (i in 1:length(names)) {
  
  tiff(sprintf("plot/map/material-intensity_hist_%s.tif", gsub("_", "-", names[i])),
       width = 7, height = 5, units = "cm", pointsize = 6,
       compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")
  
  par(mai = c(0.3, 0.2, 0.1, 0.1),
      cex = 1,
      mgp = c(3, 0.5, 0))
  

  data <- df_pop %>% 
    filter(YEAR == 2018) %>%
    #mutate_at(vars(starts_with("mass")), .funs = funs(. * 1000)) %>%
    select(names[i]) %>%
    rename("X" = names[i]) %>%
    mutate(X2 = log(X))

  mn <- data$X %>% min()
  mx <- data$X %>% max()
  
  print(c(mn, mx))
  

  bins <- seq(log(25), log(50000), length = 100)
  
  h <- hist(
    data$X2,
    breaks = bins,
    plot = FALSE
  )
  
  pos <- ceiling((h$mids - log(mn))/(log(mx)-log(mn))*99)
  pos <- pmax(pos, 1)
  pos <- pmin(pos, 99)
  
  ramp <- if (i == 1) rocket(99) %>% rev() else mako(99) %>% rev()
  cols <- ramp[pos]
  
  hist(
    data$X2,
    breaks = bins,
    col = cols,
    border = NA,
    axes = FALSE,
    xlim = c(log(25), log(50000)),
    main = NA
  )
  
  
  axis(
    side = 1,
    at = log(br),
    labels = br,
    las = 2
  )
  
  axis(
    side = 2
  )
  
  abline(h = 0)
  abline(v = log(mn), lty = 3)
  abline(v = log(mx), lty = 3)
  
  
  box(bty = "l")
  
  
  dev.off()
  
}

