require(ggplot2)
require(dplyr)
require(sf)
require(viridis)


df_pop <- st_read("shp/joined/data_per-pop.gpkg")


names <- c("mass_building",
           "mass_mobility")

lab <- c("mass of\nbuildings\n(kg/cap)",
         "mass of\nmobility\ninfrastructure\n(kg/cap)")

ramp <- c("rocket", "mako")

mn <- rep(25e3, 2)
mx <- c(1000e3, 50000e3)

br <- c(25e3, 50e3, 100e3, 250e3, 500e3, 1000e3, 2500e3, 5000e3, 10000e3, 25000e3, 50000e3)


for (i in 1:length(names)) {

    tiff(sprintf("plot/map/material-intensity_map_%s.tif", gsub("_", "-", names[i])),
    width = 5.5, height = 3.0, units = "cm", pointsize = 6,
    compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

    par(mai = c(0, 0, 0, 0),
        cex = 1,
        mgp = c(3, 0.5, 0))

        theme_set(theme_bw(base_size = 6))

        data <- df_pop %>% 
                        filter(YEAR == 2018) %>%
                        mutate_at(vars(starts_with("mass")), .funs = funs(. * 1000)) %>%
                        select(names[i]) %>%
                        rename("X" = names[i]) %>%
                        mutate(X = log(X))

        fig <- ggplot(data) +
            geom_sf(
                aes_string(fill = "X"),
                lwd = 0
            ) +
            coord_sf(datum = NA) +
            scale_fill_viridis(
                name = lab[i],
                option = ramp[i],
                breaks = log(br),
                labels = sprintf("%.0f", br/1e3),
                limits = c(mn[i], mx[i]) %>% log()
            ) +
            theme(
                panel.border = element_blank()
            )

        fig  %>% plot()

    dev.off()
    
 }

