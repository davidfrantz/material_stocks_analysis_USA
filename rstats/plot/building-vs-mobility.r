require(dplyr)

df_area__area_ <- read.csv("csv/joined/data_per-area.csv")


xnames <- "mass_building"
ynames <- "mass_mobility"


xlab <- "log. mass of buildings (kg/km²)"
ylab <- "log. mass of mobility\ninfrastructure (kg/km²)"

legend_pos <- "topleft"
legend_xinset <- -0.05
legend_yinset <- -0.075



tiff(
  sprintf("plot/material-density/%s_vs_%s.tif",
    gsub("_", "-", xnames),
    gsub("_", "-", ynames)
  ),
  width = 5.5, height = 3.0, units = "cm", pointsize = 7,
  compression = "lzw", res = 600, type = "cairo", antialias = "subpixel"
)

  par(
    mai = c(0.3, 0.4, 0.08, 0.05),
    cex = 1,
    mgp = c(3, 0.5, 0)
  )


  sub <- df_area_ %>% 
    filter(YEAR == 2018) %>%
    select(xnames, ynames) %>%
    filter(.data[[xnames]] > 0) %>%
    filter(.data[[ynames]] > 0) %>%
    mutate_at(vars(starts_with("mass")), .funs = funs(. * 1000))

  plot(sub[[xnames]],
       sub[[ynames]],
       log = "xy",
       xlab = "",
       ylab = "",
       axes = FALSE,
       pch = 19,
       cex = 0.1
   )

  axis(side = 1, tcl = -0.3)
  axis(side = 2, tcl = -0.3)

  box(bty = "l")

  mtext(ylab,
        side = 2,
        line = 1.5)

  mtext(xlab,
        side = 1,
        line = 1.5)

  lsub <- sub %>%
          mutate(across(where(is.numeric), log))

  mod <- lm(
    get(ynames) ~ get(xnames) +
              I(get(xnames) * get(xnames)), lsub)
  modsum <- summary(mod)

  line <- data.frame(seq(-1e2, 1e2, 0.1))
  colnames(line) <- xnames
  predict(mod, newdata = line) %>%
      exp() %>%
      lines(exp(line[[xnames]]), .)

  p <- modsum %>%
      capture.output() %>%
      grep("p-value", ., value = TRUE) %>%
      gsub(".*, +p", "p", .)

  legend(legend_pos,
         legend = c(
              sprintf("R²: %.3f", modsum$r.squared),
              sprintf("n: %d", modsum$residuals %>% length()),
              p),
          bty = "n",
          cex = 0.8,
          inset = c(legend_xinset, legend_yinset),
          xpd = TRUE)
  
  legend(
    "bottomright", 
    legend = sprintf(
      "y = %.2f + %.2f x + %.2f x²",
      coef(mod)[1], coef(mod)[2], coef(mod)[3]
    ),
    bty = "n",
    cex = 0.8,
    #inset = c(legend_xinset, legend_yinset),
    xpd = TRUE
   )

dev.off()

