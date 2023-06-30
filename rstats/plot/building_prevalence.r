require(ggplot2)
require(dplyr)
require(tidyr)
require(sf)
require(viridis)
require(ggspatial)


geo <- st_read("shp/cb_2020_us_county_500k_id_clim_proj.shp")
tab <- read.csv("csv/mass-per-county/zonal_area_ENLOCALE.csv")

boundaries <- st_read("shp/us_proj_5km.gpkg")
boundaries <- st_transform(boundaries, st_crs(geo))

names(geo) <- gsub("MS_ID", "zone", names(geo))


tab <- tab %>% 
  select(
    zone,
    starts_with("area_building")
  )

tab <- tab %>% 
  pivot_longer(
    names_to = "category",
    values_to = "area",
    cols = starts_with("area_building")
  ) %>%
  mutate(category = gsub("area_building_", "", category)) %>%
  mutate(category = gsub("commercial_industrial", "commercial + industrial", category)) %>%
  mutate(category = gsub("commercial_innercity", "residential / commercial mixed use, low/mid-rise", category)) %>%
  mutate(category = gsub("highrise","residential / commercial mixed use, high-rise", category)) %>%
  mutate(category = gsub("lightweight", "residential, mobile homes + lightweight", category)) %>%
  mutate(category = gsub("multifamily", "residential, mid-rise", category)) %>%
  mutate(category = gsub("singlefamily", "residential, low-rise", category)) %>%
  mutate(category = gsub("skyscraper", "residential / commercial mixed use, skyscraper", category))

tmp <- tab %>% 
  group_by(zone) %>%
  summarise_at("area", sum) %>%
  ungroup()

names(tmp) <- gsub("area", "total_area", names(tmp))

tab <- tab %>% 
  inner_join(tmp, by = "zone") %>%
  mutate(percent = area / total_area * 100)

tab <- tab %>% 
  as.data.frame()

df <- geo %>%
  inner_join(tab, by = "zone", multiple = "all")

types <- df %>%
  st_drop_geometry() %>%
  select(category) %>%
  unique() %>%
  unlist()
n_types <- length(types)


br <- seq(0, 100, 20)


for (i in 1:n_types) {
  
  tiff(sprintf("plot/map/building_prevalence_map_%s.tif", gsub("[^[a-z]]*", "-", types[i])),
       width = 15, height = 6.55, units = "cm", pointsize = 6,
       compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")
  
  par(mai = c(0, 0, 0, 0),
      cex = 1,
      mgp = c(3, 0.5, 0))
  
  theme_set(theme_bw(base_size = 6))
  
  data <- df %>% 
    filter(category == types[i])

  fig <- ggplot(data) +
    geom_sf(
      aes_string(fill = "percent"),
      linewidth = 0
    ) +
    scale_fill_viridis(
      name = "percentage area",
      option = "viridis",
      direction = +1,
      breaks = br,
      labels = sprintf("%d%%", br),
      limits = c(0, 100)
    ) +
    geom_sf(data = boundaries, 
            fill = NA, color = "grey25", linewidth = 0.15) +
    coord_sf(datum = NA) +
    theme(
      panel.border = element_blank()
    ) +
    annotation_scale(
      location = "bl",
      height = unit(0.15, "cm"),
      style = "ticks"
    ) + 
    ggtitle(
      label = types[i],
      subtitle = "relative share compared to all buildings"
    )
  
  fig  %>% plot()
  
  dev.off()
  
}











df_p <- st_centroid(df)

coords <- st_coordinates(df_p)

df_p <- cbind(df_p, coords)



types_ <- gsub(", ", ",\n", types)

tiff(sprintf("plot/map/building_prevalence_hist.tif"),
     width = 6, height = 16, units = "cm", pointsize = 6,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

par(
    mai = c(0.3, 0.3, 0.1, 0.1),
    cex = 1)#,
    #mgp = c(3, 0.5, 0))


layout(matrix(1:14, 7, 2, byrow = TRUE))

for (i in 1:n_types) {
  
  

  data <- df_p %>% 
    filter(category == types[i])
  

  smoothScatter(
    data$X, 
    data$percent, 
    ylim = c(0,100),
    main = types_[i],
    xlab = "longitude",
    ylab = "relative share in %"
  )
  smoothScatter(
    data$percent, 
    data$Y, 
    xlim = c(0,100),
    main = types_[i],
    xlab = "relative share in %",
    ylab = "latitude"
  )

  
}

dev.off()


