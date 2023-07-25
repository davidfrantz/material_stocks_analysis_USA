# this script computes general statistics used in the paper

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


### total material intensity

stock_abs %>% 
  summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  mutate(intensity = mass_total / POP_NOW) %>% 
  select(intensity)

# lowest material intensity
stock_pop %>% 
  arrange(mass_total) %>%
  select(NAME.x, STATE_NAME, mass_total) %>%
  head()

# highest material intensity
stock_pop %>% 
  arrange(mass_total) %>%
  select(NAME.x, STATE_NAME, mass_total) %>%
  tail()

# IQR for buildings and mobility
stock_pop %>% 
  summarise_if(is.numeric, IQR, na.rm = TRUE) %>% 
  select(mass_total, mass_building, mass_mobility)

# intensity of parking
stock_abs %>% 
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  mutate(perc_parking_yards = mass_parking_yards / POP_NOW) %>%
  select(perc_parking_yards)


### material intensity for mobility, minus parking

all <- stock_abs %>% 
  summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  mutate(intensity = mass_mobility / POP_NOW) %>% 
  select(intensity)

parking <- stock_abs %>% 
  summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  mutate(intensity = mass_parking_yards / POP_NOW) %>% 
  select(intensity)

all-parking

