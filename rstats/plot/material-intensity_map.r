require(ggplot2)
require(dplyr)
require(sf)
require(viridis)
require(ggspatial)


df_pop <- st_read("shp/joined/data_per-pop.gpkg")

boundaries <- st_read("shp/us_proj_5km.gpkg")
boundaries <- st_transform(boundaries, st_crs(df_pop))



proj <- st_crs(
  "PROJCS[\"Azimuthal_Equidistant\",GEOGCS[\"GCS_WGS_1984\",DATUM[\"D_WGS_1984\",SPHEROID[\"WGS_1984\",6378137.0,298.257223563]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Azimuthal_Equidistant\"],PARAMETER[\"false_easting\",8264722.17686],PARAMETER[\"false_northing\",4867518.35323],PARAMETER[\"longitude_of_center\",-97.5],PARAMETER[\"latitude_of_center\",52.0],UNIT[\"Meter\",1.0]]"
)


df_pop     <- df_pop %>% st_transform(proj)
boundaries <- boundaries %>% st_transform(proj)

names <- c("mass_building",
           "mass_mobility")

lab <- c("mass of\nbuildings\n(t/cap)",
         "mass of\nmobility\ninfrastructure\n(t)")

ramp <- c("rocket", "mako")

br <- c(25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000)


for (i in 1:length(names)) {

    tiff(sprintf("plot/map/material-intensity_map_%s.tif", gsub("_", "-", names[i])),
    width = 15, height = 6.55, units = "cm", pointsize = 6,
    compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

    par(mai = c(0, 0, 0, 0),
        cex = 1,
        mgp = c(3, 0.5, 0))

        theme_set(theme_bw(base_size = 6))

        data <- df_pop %>% 
                        filter(YEAR == 2018) %>%
                        #mutate_at(vars(starts_with("mass")), .funs = funs(. * 1000)) %>%
                        select(names[i]) %>%
                        rename("X" = names[i]) %>%
                        mutate(X = log(X))
        
        mn <- data$X %>% min(na.rm = TRUE) %>% exp()
        mx <- data$X %>% max(na.rm = TRUE) %>% exp()

        print(c(mn, mx))

        fig <- ggplot(data) +
            geom_sf(
                aes_string(fill = "X"),
                lwd = 0
            ) +
            scale_fill_viridis(
                name = lab[i],
                option = ramp[i],
                direction = -1,
                breaks = log(br),
                labels = sprintf("%.0f", br/1),
                limits = c(mn, mx) %>% log()
            ) +
            geom_sf(data = boundaries, 
                  fill = NA, color = "grey25", lwd = 0.15) +
            coord_sf(datum = NA) +
            theme(
                panel.border = element_blank()
            ) +
            annotation_scale(
              location = "bl",
              height = unit(0.15, "cm"),
              style = "ticks"
            )
        
        fig  %>% plot()

    dev.off()
    
 }

