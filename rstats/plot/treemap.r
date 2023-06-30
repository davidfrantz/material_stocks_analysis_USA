require(dplyr)
require(tidyr)
require(plotly)
require(treemap)


df_ <- read.csv("csv/joined/data_absolute.csv")


tmp <- df_ %>% 
  filter(YEAR == 2018) %>%
  select(starts_with("mass")) %>%
  summarise_if(is.numeric, sum) %>%
  gather("lod4", "value") %>%
  mutate(lod4 = gsub("mass_", "", lod4)) %>%
  mutate(lod2 = gsub("_[^_]*$", "", lod4)) %>%
  mutate(lod1 = gsub("building.*", "building", lod2)) %>%
  mutate(lod1 = gsub("rail.*", "mobility", lod1)) %>%
  mutate(lod1 = gsub("street.*", "mobility", lod1)) %>%
  mutate(lod1 = gsub("parking", "mobility", lod1)) %>%
  mutate(lod1 = gsub("airport", "mobility", lod1)) %>%
  filter(!lod4 %in% c("total", "mobility", "building", "street", "rail", "bio", "building_RES", "building_RCMU")) %>%
  mutate(lod4 = gsub("building_", "", lod4)) %>%
  mutate(lod4 = gsub("rail_", "", lod4)) %>%
  mutate(lod4 = gsub("street_", "", lod4)) %>%
  mutate(lod2 = gsub("building$", "Non-Res", lod2)) %>%
  mutate(lod2 = gsub("building_", "", lod2)) %>%
  mutate(lod2 = gsub("street_.*", "street", lod2)) %>%
  mutate(lod2 = gsub("rail_.*", "rail", lod2)) %>%
  mutate(lod3 = gsub(".*motorway.*", "motorway", lod4)) %>%
  mutate(lod3 = gsub(".*subway.*", "subway", lod3)) %>%
  mutate(lod3 = gsub(".*primary.*", "numbered", lod3)) %>%
  mutate(lod3 = gsub(".*secondary*", "numbered", lod3)) %>%
  mutate(lod3 = gsub(".*tertiary.*", "numbered", lod3)) %>%
  mutate(lod3 = gsub(".*local*", "rural", lod3)) %>%
  mutate(lod3 = gsub(".*track*", "rural", lod3))

  tmp



tiff("plot/treemap/tree_map_nolabel.tif",
     width = 9, height = 4.5, units = "cm", pointsize = 7,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel"
)

treemap(
  tmp,
  index = c("lod1", "lod2", "lod3", "lod4"),
  vSize = "value",
  type = "index",
  fontsize.labels = 0,
  border.lwds = 1, 
  title = "",
  #force.print.labels
)

dev.off()




tiff("plot/treemap/tree_map_nolabel_for_zoom.tif",
     width = 9*3, height = 4.5*3, units = "cm", pointsize = 7,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel"
)

treemap(
  tmp,
  index = c("lod1", "lod2", "lod3", "lod4"),
  vSize = "value",
  type = "index",
  fontsize.labels = 0,
  border.lwds = 1, 
  title = "",
  #force.print.labels
)

dev.off()





tmp$lod4 <- gsub("subway", "sw", tmp$lod4)
tmp$lod4 <- gsub("elevated", "el", tmp$lod4)
tmp$lod4 <- gsub("bridge", "br", tmp$lod4)
tmp$lod4 <- gsub("tunnel", "tu", tmp$lod4)

tmp$lod3 <- gsub("subway", "sw", tmp$lod3)
tmp$lod3 <- gsub("elevated", "el", tmp$lod3)
tmp$lod3 <- gsub("bridge", "br", tmp$lod3)
tmp$lod3 <- gsub("tunnel", "tu", tmp$lod3)

tmp$lod2 <- gsub("subway", "sw", tmp$lod2)
tmp$lod2 <- gsub("elevated", "el", tmp$lod2)
tmp$lod2 <- gsub("bridge", "br", tmp$lod2)
tmp$lod2 <- gsub("tunnel", "tu", tmp$lod2)

tmp$lod1 <- gsub("subway", "sw", tmp$lod1)
tmp$lod1 <- gsub("elevated", "el", tmp$lod1)
tmp$lod1 <- gsub("bridge", "br", tmp$lod1)
tmp$lod1 <- gsub("tunnel", "tu", tmp$lod1)




tiff("plot/treemap/tree_map.tif",
     width = 36, height = 18, units = "cm", pointsize = 7,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel"
)

treemap(
  tmp,
  index = c("lod1", "lod2", "lod3", "lod4"),
  vSize = "value",
  type = "index",
  fontsize.labels = 5,
  border.lwds = 1, 
  title = "",
  force.print.labels = TRUE
)

dev.off()
