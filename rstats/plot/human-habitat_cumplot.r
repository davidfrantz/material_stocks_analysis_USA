require(dplyr)
require(RColorBrewer)

df_ <- read.csv("csv/joined/data_absolute.csv")

names <- c("building_percentage",
           "techno_percentage")

lab  <- c("building stocks / built-up stocks (%)",
          "built-up stocks / entire stocks (%)")
lab_left  <- c("more mobility\ninfrastructure\nstocks", "more\nplant\nstocks")
lab_right <- c("more\nbuilding\nstocks", "more\nbuilt-up\nstocks")

textx_left  <- c(5, 17.5)
texty_left  <- c(50, 50)
textx_right <- c(72.5, 52.5)
texty_right <- c(50, 70)

pal <- list(
    brewer.pal(7, "BrBG"),
    brewer.pal(7, "PiYG") %>% rev())

col <- brewer.pal(n = 8, name = "RdYlBu")[c(1, 8)] %>%
    rev()

br <- seq(0, 100, 1)
nbr <- length(br) - 1
labels <- sprintf("%.1f", br[-nbr])


for (i in 1:length(names)) {

    tmp <- df_ %>% filter(YEAR == 2018) %>%
        mutate(pop_urban = POPPCT_URBAN / 100 * POP_NOW) %>%
        mutate(pop_rural = (100 - POPPCT_URBAN) / 100 * POP_NOW) %>%
        select(names[i], pop_urban, pop_rural) %>%
        mutate(cat = cut(.data[[names[i]]], breaks = br, labels = labels)) %>%
        select(-names[i]) %>%
        group_by(cat) %>%
        summarise_all(sum) %>%
        ungroup()

    empty <- which(!labels %in% tmp$cat)
    add_df <- data.frame(labels[empty], rep(0, length(empty)), rep(0, length(empty)))
    rownames(add_df) <- labels[empty]
    colnames(add_df) <- colnames(tmp)
    tmp <- rbind(tmp, add_df)

    tmp <- tmp %>% 
        arrange(cat) %>%
        mutate(pop_urban_cum = cumsum(pop_urban)) %>%
        mutate(pop_rural_cum = cumsum(pop_rural)) %>%
        mutate(pop_urban_cum_pct = pop_urban_cum / max(pop_urban_cum) * 100) %>%
        mutate(pop_rural_cum_pct = pop_rural_cum / max(pop_rural_cum) * 100) %>%
        mutate(pop_urban_cum_pct_total = pop_urban_cum / (max(pop_rural_cum) + max(pop_urban_cum)) * 100) %>%
        mutate(pop_rural_cum_pct_total = pop_rural_cum / (max(pop_rural_cum) + max(pop_urban_cum)) * 100) %>%
        mutate(pop_total_cum_pct_total = (pop_rural_cum + pop_urban_cum) / (max(pop_rural_cum) + max(pop_urban_cum)) * 100)

    tmp
    #sum(tmp$pop_urban)
    #sum(tmp$pop_rural)
    #sum(tmp$pop_urban)+sum(tmp$pop_rural)

    mat <- tmp %>% 
        select(pop_urban, pop_rural) %>%
        as.matrix()
    rownames(mat) <- tmp$cat

    tiff(sprintf("plot/cumulative-pop/human-habitat_cumplot_%s.tif", gsub("_", "-", names[i])),
    width = 8.8, height = 4.8, units = "cm", pointsize = 7,
    compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")

    par(mai = c(0.3, 0.5, 0.08, 0.075),
        cex = 1,
        mgp = c(3, 0.5, 0))

    plot(tmp$cat %>% as.numeric(),
         tmp$pop_total_cum_pct_total,
         type = "n",
         axes = FALSE,
         xlab = "",
         ylab = "",
         xaxs = "i",
         yaxs = "i"
    )

    arrows(30, 50,
           70, 50,
           col = "grey40",
           lwd = 0.8,
           code = 3,
           length = 0.05)

    abline(v = 50,
           col = "white",
           lwd = 2)

    abline(v = 50,
           col = "grey40",
           lwd = 0.8)


    lines(tmp$cat,
          tmp$pop_total_cum_pct_total,
          col = "black",
          lty = 1)

    lines(tmp$cat,
          tmp$pop_urban_cum_pct,
          col = "black",
          lty = 2)

    lines(tmp$cat,
          tmp$pop_rural_cum_pct,
          col = "black",
          lty = 3)

    legend("topleft", legend = c("total", "urban", "rural"),
            col = c("black", "black", "black"),
            lty = c(1, 2, 3),
            bty = "n",
            cex = 0.8,
            inset = c(-0.01, -0.01),
            xpd = TRUE)

    box(bty = "l")

    axis(side = 1,
        #at = seq(2, by = 3, length.out = length(bar))[seq(1, length(bar), 4)],
        #labels = sprintf("%.0f", bar)[seq(1, length(bar), 4)],
        tcl = -0.3,
        cex.axis = 1.0,
        gap.axis = 0.2)

    axis(side = 2,
         tcl = -0.3,
         gap.axis = 0.2)

    mtext("cum. population living\nin counties with given\nmaterial stocks (%)",
          side = 2,
          line = 1.5)

    mtext(lab[i],
          side = 1,
          line = 1.5)

    text(textx_left[i], texty_left[i], lab_left[i],
        cex = 0.8,
        adj = 0,
        font = 3,
        col = "grey40")
    text(textx_right[i], texty_right[i], lab_right[i],
        cex = 0.8,
        adj = 0,
        font = 3,
        col = "grey40")

    dev.off()

    tmp %>% 
        filter(pop_urban_cum_pct > 50)
    tmp %>% 
        filter(pop_rural_cum_pct > 50)

}
