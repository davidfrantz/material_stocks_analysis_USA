require(rjson)
library(rayshader)
library(ggplot2)
require(raster)
require(viridis)
require(ggthemes)
require(terra)
require(ggspatial)


json <- fromJSON(file = "plot/map/cities.json")
wanted <- c("Los Angeles", "New York", "Lubbock")


city3d <- function(lat, lon, name, state, pop, fname, vmax){
  
  dbase <- "/data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/ALL"
  stock <- rast(sprintf("%s/mass_grand_total_kt_100m2.tif", dbase))

  
  width <- 15000

  cc <- vect(cbind(lon,lat))
  crs(cc)  <- "epsg:4326"
  map <- project(cc, crs(stock))
  extent <- ext(map)
  extent$xmin <- extent$xmin-width
  extent$xmax <- extent$xmax+width
  extent$ymin <- extent$ymin-width
  extent$ymax <- extent$ymax+width

  stock <- crop(stock, extent)

  stock_df <- as.data.frame(stock, xy = TRUE)
  colnames(stock_df) <- c("x", "y", "value")
  stock_df[stock_df == 0] <- NA
  
  print(stock_df$value %>% max())
  
  stock_df <- rbind(stock_df, c(
    ext(stock)$xmax-res(stock)[1]/2, 
    ext(stock)$ymax-res(stock)[2]/2,
    vmax)
  )
  
  gg <- ggplot() +
    geom_tile(data = stock_df, aes(x = x, y = y, fill = value)) +
    scale_fill_gradientn(
      colours = c("grey95", viridis(5), "orange", "red", "magenta"),
      values = c(0, seq(0.01, 0.075, length.out = 5), 0.2, 0.3, 1),
        breaks = c(25, 200, 400, 600),
      na.value = "white") +
      coord_equal() +
    theme_map() +
    theme(legend.position = "none") +
    ggtitle(sprintf("%s, %s - Population: %d", name, state, pop)) +
    theme(legend.position = "top")  +
    annotation_scale(
      location = "bl",
      height = unit(0.15, "cm"),
      style = "ticks"
    ) + 
    annotation_north_arrow(
      location = "tr",
      #height = unit(0.30, "cm"),
      #width = unit(0.30, "cm"),
      style = north_arrow_fancy_orienteering,
      pad_x = unit(-0.3, "cm"),
      pad_y = unit(-0.3, "cm"),
    )
  
  ggsave(
    filename = sprintf("%s_2d.png", fname),
    plot = gg,
    device = "png",
    scale = 1
  )

  gg3 <- plot_gg(gg,
                 multicore = TRUE,
                 width = 5,
                 height = 5,
                 units = "cm",
                 scale = 350,
                 triangulate = TRUE,
                 #save_height_matrix = TRUE)
                 soliddepth = -0.5)#,
  gg3
  
  
  render_highquality(fname,
                     width = 3000*0.25,
                     height = 2500*0.25,
                     parallel = TRUE,
                     progress = TRUE, 
                     ambient_light = TRUE,
                     camera_location = c(465.03, 2079.96, 1473.23), 
                     print_scene_info = TRUE)

  while (rgl::rgl.cur() > 0) { rgl::rgl.close() }
  
}



for (i in 1:length(json)) {
  
  if (!json[[i]]$city %in% wanted) next

  item <- as.data.frame(t(unlist(json[i])))

  lat <- as.numeric(item$latitude)
  lon <- as.numeric(item$longitude)
  name <- item$city
  state <- item$state
  pop <- as.integer(item$population)
  fname <- sprintf("plot/map/%04d_%s_%s",
      i,
      gsub(" ", "-", name),
      gsub(" ", "-", state))
  vmax <-  618.5618 # for scale (max in NY)

  if (state %in% c("Hawaii", "Alaska")) next

  city3d(lat, lon, name, state, pop, fname, vmax)

  cat(sprintf("done with city # %d: %s, %s\n", i, item$city, item$state))
  flush.console()

}

