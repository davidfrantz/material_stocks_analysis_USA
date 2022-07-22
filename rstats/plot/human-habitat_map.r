require(raster)
require(dplyr)
require(ggplot2)


img <- brick(
    "/data/ahsoka/gi-sds/hub/mat_stocks/paper-data-USA/main/human-habitat/percent_rgb.tif")


img_spdf <- as(img, "SpatialPixelsDataFrame")
img_df <- as.data.frame(img_spdf)
colnames(img_df) <- c("r", "g", "b", "x", "y")

img_df <- img_df[-which(img_df$g + img_df$g + img_df$b == 0), ]
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



tiff("plot/map/human_habitat_map.tif",
width = 5.5, height = 3.0, units = "cm", pointsize = 6,
compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

  par(
    mai = c(0, 0, 0, 0),
    cex = 1,
    mgp = c(3, 0.5, 0)
  )
  
  theme_set(theme_bw(base_size = 6))
  
  fig <- ggplot() +
      geom_tile(
          data = img_df,
          aes(x = x, y = y, fill = rgb(r, g, b))) +
      scale_fill_identity() +
      coord_sf(datum = NA) +
      theme(
        panel.border = element_blank(),
        legend.position = "none"
      )
      
  fig  %>% plot()

dev.off()
