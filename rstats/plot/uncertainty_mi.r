require(tidyverse)

dim <- read.csv("csv/aggregated_dimensions/aggregated.csv")

dim <- dim %>% 
  mutate(cat = gsub("^area_", "", cat)) %>%
  mutate(cat = gsub("^volume_", "", cat)) %>%
  mutate(cat = gsub("zone_", "climate", cat))



avg <- numeric(0)

for (g in c("building", "street", "rail", "other")){

  tmp <- 
    read.csv(sprintf("csv/factors/%s.csv", g)) %>% 
    filter(material == "total") %>% 
    pivot_longer(2:ncol(.), names_to = "cat", values_to = "mi") %>%
    mutate(cat = paste(g, cat, sep="_")) %>%
    mutate(estimate = "average")

  avg <- rbind(avg, tmp)  

}


low <- numeric(0)

for (g in c("building", "street", "rail", "other")){
  
  tmp <- 
    read.csv(sprintf("csv/factors/%s_low.csv", g)) %>% 
    filter(material == "total") %>% 
    pivot_longer(2:ncol(.), names_to = "cat", values_to = "mi") %>%
    mutate(cat = paste(g, cat, sep="_")) %>%
    mutate(estimate = "low")
  
  low <- rbind(low, tmp)  
  
}


high <- numeric(0)

for (g in c("building", "street", "rail", "other")){
  
  tmp <- 
    read.csv(sprintf("csv/factors/%s_high.csv", g)) %>% 
    filter(material == "total") %>% 
    pivot_longer(2:ncol(.), names_to = "cat", values_to = "mi") %>%
    mutate(cat = paste(g, cat, sep="_")) %>%
    mutate(estimate = "high")
  
  high <- rbind(high, tmp)  
  
}


mi <- rbind(avg, low, high)


tab <- dim %>% 
  inner_join(mi, by = "cat") %>%
  mutate(mass = val * mi / 1e9)


key <- c(
  "building_singlefamily_climate1", 
  "building_singlefamily_climate2", 
  "building_singlefamily_climate3", 
  "building_singlefamily_climate4", 
  "building_singlefamily_climate5", 
  "building_multifamily", 
  "building_lightweight", 
  "building_commercial_innercity", 
  "building_highrise", 
  "building_skyscraper", 
  "building_commercial_industrial", 
  "street_motorway", 
  "street_primary", 
  "street_secondary", 
  "street_tertiary", 
  "street_motorway_elevated", 
  "street_other_elevated", 
  "street_bridge_motorway", 
  "street_bridge_other", 
  "street_tunnel", 
  "street_local_climate1", 
  "street_local_climate2", 
  "street_local_climate3", 
  "street_local_climate4", 
  "street_local_climate5", 
  "street_local_climate6", 
  "street_track_climate1", 
  "street_track_climate2", 
  "street_track_climate3", 
  "street_track_climate4", 
  "street_track_climate5", 
  "street_track_climate6", 
  "rail_railway", 
  "rail_tram", 
  "rail_other", 
  "rail_subway", 
  "rail_subway_elevated", 
  "rail_subway_surface", 
  "rail_bridge", 
  "rail_tunnel", 
  "other_airport",
  "other_parking" 
)


lab <- c(
  "low-rise, hot-humid", 
  "low-rise, hot-/mixed-dry", 
  "low-rise, mixed-humid", 
  "low-rise, marine", 
  "low-rise, (very) cold", 
  "mid-rise", 
  "mobile homes / lightweight", 
  "low-/mid-rise", 
  "high-rise", 
  "skyscraper", 
  "commercial / industrial", 
  "motorways", 
  "primary", 
  "secondary", 
  "tertiary", 
  "elevated motorway", 
  "elevated roads", 
  "motorway bridge", 
  "bridge", 
  "tunnel", 
  "local, wet / no freeze", 
  "local, wet / freeze, thaw", 
  "local, wet / hard-freeze, thaw", 
  "local, dry / no freeze", 
  "local, dry / freeze, thaw", 
  "local, dry / hard freeze, thaw", 
  "rural, wet / no freeze", 
  "rural, wet / freeze, thaw", 
  "rural, wet / hard-freeze, thaw", 
  "rural, dry / no freeze", 
  "rural, dry / freeze, thaw", 
  "rural, dry / hard freeze, thaw", 
  "railway", 
  "tram", 
  "other rails", 
  "subway, underground", 
  "subway, elevated", 
  "subway, above-ground", 
  "bridge", 
  "tunnel", 
  "airport",
  "parking / yards"
)



color <- c(
  rep(rgb(192, 40, 47, maxColorValue = 255), 7),
  rep(rgb(254, 102, 109, maxColorValue = 255), 3),
  rep(rgb(255, 213, 215, maxColorValue = 255), 1),
  rep(rgb(228, 239, 255, maxColorValue = 255), 21),
  rep(rgb(168, 197, 234, maxColorValue = 255), 8),
  rep(rgb(113, 142, 179, maxColorValue = 255), 1),
  rep(rgb(62, 91, 128, maxColorValue = 255), 1)
)

nkey <- length(key)
width <- 0.35
width2 <- 0.5



tiff(sprintf("A:\\hub\\mat_stocks\\paper-data-USA\\material_stocks_analysis_USA\\plot/uncertainty/%s", "mass-uncertainty-dims.tif"),
     width = 18, height = 8, units = "cm", pointsize = 7,
     compression = "lzw", res = 600, type = "cairo", antialias = "subpixel")


par(mai = c(1.4, 0.4, 0.1, 0.4),
    cex = 1)

plot(
  0,
  xlim = c(1, nkey),
  ylim = c(0, max(tab$mass)),
  type = "n",
  xlab = "",
  ylab = "",
  axes = FALSE
)


for (i in 1:nkey){

  avg <- tab %>% filter(cat == key[i], estimate == "average") %>% select(mass) %>% unlist()
  low <- tab %>% filter(cat == key[i], estimate == "low") %>% select(mass) %>% unlist()
  high <- tab %>% filter(cat == key[i], estimate == "high") %>% select(mass) %>% unlist()
  
  polygon(
    c(i-width, i-width, i+width, i+width),
    c(0, avg, avg, 0),
    col = color[i],
    border = NA
  )
  
  arrows(i, high, i, low, angle = 90, code = 3, length = 0.025)

}

axis(2, font = 2)
mtext("Mass in Gt", 2, line = 2, font = 2)

axis(
  side = 1,
  at = 1:nkey,
  labels = lab,
  las = 2,
  cex = 0.8
)



par(new = TRUE)


plot(
  0,
  xlim = c(1, nkey),
  ylim = c(0, max(tab$val)),
  type = "n",
  xlab = "",
  ylab = "",
  axes = FALSE
)


for (i in 1:nkey){
  
  dim <- tab %>% filter(cat == key[i], estimate == "average") %>% select(val) %>% unlist()
  #if (length(grep("building", key[i])) == 1) dim <- dim / 1e9 else dim <- dim / 1e6

  lines(
    c(i-width2, i-width2, i+width2, i+width2),
    c(0, dim, dim, 0),
    col = "grey20",
    lty = 1,
    lwd = 0.3
  )
  
}

axis(4, font = 2)
mtext("area or volume in m² or m³", 4, line = 2, font = 2)

box(bty = "u")

dev.off()



tab <- tab %>%
  mutate(group = gsub("_.*", "", cat))


avg <- tab %>% filter(estimate == "average") %>% select(mass) %>% unlist() %>% sum()
low <- tab %>% filter(estimate == "low") %>% select(mass) %>% unlist() %>% sum()
high <- tab %>% filter(estimate == "high") %>% select(mass) %>% unlist() %>% sum()
avg
low
high

avg <- tab %>% filter(estimate == "average") %>% select(mass) %>% unlist()
low <- tab %>% filter(estimate == "low") %>% select(mass) %>% unlist()
high <- tab %>% filter(estimate == "high") %>% select(mass) %>% unlist()
avg
low
high


tmp <- tab %>% 
  filter(group == "building") %>% 
  select(-mi) %>% 
  pivot_wider(names_from = "estimate", values_from = "mass") %>%
  select(average, low, high) %>% 
  as.matrix()

  
n_iter <- 10000
M <- rep(NA, n_iter)
  
for (j in 1:n_iter){

  rnd <- runif(nrow(tmp), 1, 3.999) %>% floor()
  
  mass <- rep(NA, nrow(tmp))
  
  for (i in 1:nrow(tmp)) mass[i] <- tmp[i,rnd[i]]
  
  M[j] <- sum(mass)

}


mean(M)
sd(M)



as.matrix(tmp)[1:nrow(tmp),rnd] %>% dim()

str(expand.grid(tmp)) 



(avg-low)/avg*100
(avg-high)/high*100
