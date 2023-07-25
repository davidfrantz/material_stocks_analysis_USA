require(rayshader)
require(ggplot2)
require(viridis)
require(ggthemes)
require(terra)
require(sf)
require(ggspatial)

dbase <- "/data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/ALL"

stock <- rast(sprintf("%s/mass_grand_total_Gt_10km2.tif", dbase))

fshp <- "shp/us_proj_5km.gpkg"



#stock_spdf <- as(stock, "SpatialPixelsDataFrame")
stock_df <- as.data.frame(stock, xy = TRUE)
colnames(stock_df) <- c("x", "y", "value")
stock_df[stock_df == 0] <- NA


#boundaries_ <- readOGR(dsn = fshp)
boundaries_ <- st_read(fshp)

#boundaries <- st_transform(boundaries_, crs(stock))
boundaries <- st_transform(boundaries_, crs(stock))

gg <- ggplot() +
    geom_raster(data = stock_df, aes(x = x, y = y, fill = value)) +
    geom_sf(data = boundaries, 
        fill = NA, color = "grey25", linewidth = 0.25) +
    scale_fill_gradientn(
        colours = c("white", "grey95", viridis(5), "orange", "red", "magenta"),
        values = c(0, 0.0001, seq(0.01, 0.075, length.out = 5), 0.2, 0.3, 1),
        breaks = c(0.0001, 0.01, 0.1, 0.2, 0.28),
        na.value = "white") +
    labs(fill = "Total stock [Gt/10km?]") +
    coord_sf() +
    theme_map() +
    #theme(legend.position = "top") #+
    theme(legend.position = "none")   +
    annotation_scale(
      location = "bl",
      height = unit(0.15, "cm"),
      style = "ticks"
    ) #+
    #theme(legend.key.width = unit(1000, "cm"))
gg

dir.create("plot/map")
tiff("plot/map/map_total_stocks_2d.tif",
width = 8.8*2, height = 6*2, units = "cm", pointsize = 8,
compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")
    gg
dev.off()


gg3 <- plot_gg(gg,
    multicore = TRUE,
    width = 5,
    height = 5,
    units = "cm",
    scale = 350,
    triangulate = TRUE, height_aes = "fill")#,
    #windowsize=c(5000,2500))
gg3


#render_highquality("plot/map/map_total_stocks_3d2_dd.tif",
render_highquality("map_total_stocks_3d2_ddef.tif",
                                      
    width = 4096*.75,
    height = 4096*.75,
    parallel = TRUE,
    progress = TRUE, 
    ambient_light = TRUE,
    camera_location = c(-126.00, 2282.85, 1218.86), 
    print_scene_info = TRUE
)

