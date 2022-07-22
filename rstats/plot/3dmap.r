require(rayshader)
require(ggplot2)
require(raster)
require(viridis)
require(ggthemes)
require(rgdal)

dbase <- "/data/ahsoka/gi-sds/hub/mat_stocks/stock/USA/ALL"
stock <- raster(sprintf("%s/mass_grand_total_Gt_10km2.tif", dbase))

fshp <- "shp/us_proj_5km.gpkg"



stock_spdf <- as(stock, "SpatialPixelsDataFrame")
stock_df <- as.data.frame(stock_spdf)
colnames(stock_df) <- c("value", "x", "y")
stock_df[stock_df == 0] <- NA


boundaries_ <- readOGR(dsn = fshp)

boundaries <- spTransform(boundaries_, crs(stock))

gg <- ggplot() +
    geom_tile(data = stock_df, aes(x = x, y = y, fill = value)) +
    geom_polygon(data = boundaries, aes(x = long, y = lat, group = group), 
        fill = NA, color = "grey25", size = 0.25) +
    scale_fill_gradientn(
        colours = c("grey95", viridis(5), "orange", "red", "magenta"),
        values = c(0, seq(0.01, 0.075, length.out = 5), 0.2, 0.3, 1),
        breaks = c(0.01, 0.1, 0.2, 0.28),
        na.value = "white") +
    labs(fill = "Total stock [Gt/10km²]") +
    coord_equal() +
    theme_map() +
    theme(legend.position = "top") #+
    #theme(legend.position = "none") #+
    #theme(legend.key.width = unit(1000, "cm"))


dir.create("plot/map")
tiff("plot/map/map_total_stocks_2d.tif",
width = 8.8, height = 6, units = "cm", pointsize = 8,
compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")
    gg
dev.off()


gg3 <- plot_gg(gg,
    multicore = TRUE,
    width = 5,
    height = 5,
    units = "cm",
    scale = 350,
    triangulate = TRUE)#,
    #windowsize=c(5000,2500))
gg3


render_highquality("plot/map/map_total_stocks_3d.tif",
    width = 8000,
    height = 6000,
    parallel = TRUE,
    progress = TRUE, 
    ambient_light = TRUE,
    camera_location = c(-126.00, 2282.85, 1218.86), 
    print_scene_info = TRUE
)

