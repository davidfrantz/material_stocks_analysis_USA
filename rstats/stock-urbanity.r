# this script visualizes material stock density and intensity as a function of urban population

require(dplyr)
require(tidyr)

# table dir
dcsv <- "csv"

stock_abs <- read.csv(
  sprintf("%s/joined/data_absolute.csv", dcsv)
) %>% 
  filter(YEAR == 2018)


stock_km2 <- read.csv(
  sprintf("%s/joined/data_per-area.csv", dcsv)
) %>% 
  filter(YEAR == 2018)


stock_pop <- read.csv(
  sprintf("%s/joined/data_per-pop.csv", dcsv)
) %>% 
  filter(YEAR == 2018)


a <- stock_km2 %>% 
  select(POPPCT_URBAN, starts_with("mass_building_R")) %>%
  select(-mass_building_RES, -mass_building_RCMU) %>%
  mutate(POPPCT_URBAN = ceiling(POPPCT_URBAN/10)*10) %>% 
  group_by(POPPCT_URBAN) %>%
  summarise_if(is.numeric, mean) %>%
  as.matrix()

rownames(a) <- a[,1]
a <- a[,-1]

barplot(t(a), legend = TRUE, col = 1:6, args.legend	= list(x = "topleft"), xlab = "urban population [%]", ylab = "stocks [t/km�]")

a <- stock_pop %>% 
  select(POPPCT_URBAN, starts_with("mass_building_R")) %>%
  select(-mass_building_RES, -mass_building_RCMU) %>%
  mutate(POPPCT_URBAN = ceiling(POPPCT_URBAN/10)*10) %>% 
  group_by(POPPCT_URBAN) %>%
  summarise_if(is.numeric, mean) %>%
  as.matrix()

rownames(a) <- a[,1]
a <- a[,-1]

barplot(t(a), legend = TRUE, col = 1:6, args.legend	= list(x = "topright"), xlab = "urban population [%]", ylab = "stocks [t/cap]")

