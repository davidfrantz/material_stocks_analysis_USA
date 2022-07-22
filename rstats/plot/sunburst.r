require(dplyr)
require(tidyr)
require(plotly)

df_ <- read.csv("csv/joined/data_absolute.csv")


tmp <- df_ %>% 
  filter(YEAR == 2018) %>%
  select(starts_with("mass")) %>%
  summarise_if(is.numeric, sum) %>%
  gather("type", "value") %>%
  mutate(type = gsub("mass_", "", type)) %>%
  mutate(parent = gsub("_.*", "", type)) %>%
  mutate(percent = value / max(value) * 100)

tmp$parent[tmp$type == "total"]          <- ""
tmp$parent[tmp$type == "building"]       <- "total"
tmp$parent[tmp$type == "mobility"]       <- "total"
tmp$parent[tmp$type == "RES"]            <- "building"
tmp$parent[tmp$type == "RCMU"]           <- "building"
tmp$parent[tmp$type == "CI"]             <- "building"
tmp$parent[tmp$type == "street"]         <- "mobility"
tmp$parent[tmp$type == "rail"]           <- "mobility"
tmp$parent[tmp$type == "airport"]        <- "mobility"
tmp$parent[tmp$type == "parking_yards"]  <- "mobility"

tmp$type <- tmp$type %>%
  #gsub("other_", "", .) %>%
  gsub("rail_other", "other_rails", .) %>%
  gsub("rail_", "", .) %>%
  gsub("street_", "", .) %>%
  gsub("building_", "", .)

tmp$parent[tmp$type == "RES_LR"]   <- "RES"
tmp$parent[tmp$type == "RES_MR"]   <- "RES"
tmp$parent[tmp$type == "RES_MLB"]  <- "RES"
tmp$parent[tmp$type == "RCMU_RR"]  <- "RCMU"
tmp$parent[tmp$type == "RCMU_HR"]  <- "RCMU"
tmp$parent[tmp$type == "RCMU_SKY"] <- "RCMU"

tmp$type <- tmp$type %>%
  gsub("RES_", "", .) %>%
  gsub("RCMU_", "", .)

tmp <- tmp %>% filter(type != "bio")
# 

fig <- plot_ly(
  tmp,
  labels = ~type,
  parents      = ~parent,
  values       = ~value,
  type         = "sunburst",
  branchvalues = "total",
  insidetextorientation='tangential',
  #insidetextorientation='radial',
  marker = list(
   line = list(color = rep("black", nrow(tmp)),
               width = 1) #1
  ),
  textfont = list(size = 64,
                 color = "white"),
  sort = FALSE
) %>%
layout(
  sunburstcolorway = 
    c("#ae8b12","#78678b"),
  extendsunburstcolors = TRUE
)

fig

#getwd()
dir.create("plot/sunburst")
save_image(
  fig, 
  width = 1100, 
  height = 1100, 
  file = "plot/sunburst/sunburst-orca.png"
)
