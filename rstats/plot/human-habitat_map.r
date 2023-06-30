require(terra)
require(dplyr)
require(ggplot2)
require(biscale)
require(ggspatial)


img <- brick(
    "/data/ahsoka/gi-sds/hub/mat_stocks/paper-data-USA/main/human-habitat/percent_rgb.tif")
img <- rast(
  "A:/hub/mat_stocks/paper-data-USA/main/main/human-habitat/percent_rgb.tif")


boundaries <- st_read("shp/us_proj_5km.gpkg")
boundaries <- st_transform(boundaries, st_crs(img))


img_df <- as.data.frame(img, xy = TRUE)
colnames(img_df) <- c("x", "y", "r", "g", "b")

img_df <- img_df[-which(img_df$r + img_df$g + img_df$b == 0), ]
img_df <- img_df %>%
    mutate(r = pmax(r, 0)) %>%
    mutate(g = pmax(g, 0)) %>%
    mutate(b = pmax(b, 0)) %>%
    mutate(r = pmin(r, 100)) %>%
    mutate(g = pmin(g, 100)) %>%
    mutate(b = pmin(b, 100)) %>%
    mutate(r = r / 100) %>%
    mutate(g = g / 100) %>%
    mutate(b = b / 100)

sum(img_df$g > (img_df$r + img_df$b)) / sum((img_df$g + img_df$r + img_df$b) > 0)
sum((img_df$r + img_df$b)  > img_df$g) / sum((img_df$g + img_df$r + img_df$b) > 0)

sub_df <- img_df %>%
    filter((r+b) > g)

sum(sub_df$r > sub_df$b) / sum((sub_df$g + sub_df$r + sub_df$b) > 0)
sum(sub_df$b > sub_df$r) / sum((sub_df$g + sub_df$r + sub_df$b) > 0)
sum(sub_df$r == sub_df$b) / sum((sub_df$g + sub_df$r + sub_df$b) > 0)

img_df <- img_df %>%
  mutate(rb = r+b) %>%
  mutate(g_bi = pmin(as.integer(g / 0.25) + 1L, 4L)) %>%
  mutate(r_bi = pmin(as.integer(r / 0.25) + 1L, 4L)) %>%
  mutate(b_bi = pmin(as.integer(b / 0.25) + 1L, 4L)) %>%
  mutate(rb_bi = pmin(as.integer(rb / 0.25) + 1L, 4L)) %>%
  mutate(rb_bi_g.rb = paste(g_bi, rb_bi, sep = "-")) %>%
  mutate(rb_bi_r.b = paste(r_bi, b_bi, sep = "-"))




#bi_img_df <- bi_class(img_df, x = rb, y = g, style = "equal", dim = 4)


tiff("plot/map/human_habitat_map.tif",
width = 18, height = 10.8, units = "cm", pointsize = 6,
compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

  par(
    mai = c(0, 0, 0, 0),
    cex = 1,
    mgp = c(3, 0.5, 0)
  )
  
  theme_set(theme_bw(base_size = 6))
  
  #fig <- ggplot() +
  #    geom_tile(
  #        data = img_df,
  #        aes(x = x, y = y, fill = rgb(r, g, b))) +
  #    scale_fill_identity() +
  #    coord_sf(datum = NA) +
  #    theme(
  #      panel.border = element_blank(),
  #      legend.position = "none"
  #    )

  fig <- ggplot() +
    geom_raster(
      data = img_df, 
      mapping = aes(x = x, y = y, fill = rb_bi_r.b), 
      show.legend = FALSE
    ) +
    bi_scale_fill(pal = "GrPink2", dim = 4) +
    geom_sf(
      data = boundaries, 
      fill = NA, 
      color = "grey25",
      lwd = 0.15
    ) +
    coord_sf(datum = NA) +
    theme(
      panel.border = element_blank(),
      legend.position = "none",
      axis.title.x=element_blank(),
      axis.title.y=element_blank()
    ) +
    annotation_scale(
      location = "bl",
      height = unit(0.15, "cm"),
      style = "ticks"
    )
    #bi_theme()

  
  fig  %>% plot()
  

dev.off()


tiff("plot/map/human_habitat_legend.tif",
     width = 2.0, height = 2.0, units = "cm", pointsize = 6,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

  bi_legend(pal = "GrPink2",
            size = 6,
            dim = 4)

dev.off()
  
