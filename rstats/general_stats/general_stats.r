# this script computes general statistics used in the paper

require(dplyr)
require(tidyr)

# table dir
dcsv <- "csv"

stock_states <- read.csv(
    sprintf("%s/mass-all-states/total_mass_all_states_ENLOCALE.csv", dcsv)
)


# Total stock in Gt
total <- stock_states$grand_total_t_10m2 %>% 
    sum() %>% `/`(1e9)
total

# Total building stocks in Gt
building <- stock_states$building %>% 
    sum() %>% `/`(1e9)
building

# Total mobility stocks in Gt
mobility <- (stock_states$street + stock_states$rail + stock_states$other) %>% 
    sum() %>% `/`(1e9)
mobility


###########################


f <- dir(
    sprintf("%s/mass-per-state/", dcsv),
    "ENLOCALE.csv",
    full.names = TRUE
)

stock_detailed <- character(0)

for (i in 1:length(f)){

    stock_detailed <- stock_detailed %>% 
        rbind(read.csv(f[i]))
}


stock_summary <- stock_detailed %>% 
    filter(!category %in% c("grand_total_t_10m2", "building", "street", "rail", "other")) %>%
    mutate(category = gsub("_.*", "", category)) %>%
    group_by(category) %>%
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
    ungroup()

# percent of minerals in mobility
# percent of aggregates in minerals in mobility
stock_summary %>% 
    filter(category %in% c("street", "rail", "other")) %>%
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
    mutate(
        perc_mineral = (aggregate + concrete + bricks + glass + all_other_minerals) / total * 100
    ) %>%
    mutate(
        perc_aggregate = aggregate / (aggregate + concrete + bricks + glass + all_other_minerals) * 100
    ) %>% 
    select(starts_with("perc"))

# Gt of minerals in mobility
# Gt of aggregates in minerals in mobility
stock_summary %>% 
    filter(category %in% c("street", "rail", "other")) %>%
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
    mutate(
        Gt_mineral = (aggregate + concrete + bricks + glass + all_other_minerals) / 1e9
    ) %>%
    mutate(
        Gt_aggregate = aggregate / 1e9
    ) %>% 
    select(starts_with("Gt"))


# percent of minerals in building
# percent of concrete in minerals in building
# percent of aggregates in minerals in building
# percent of all other materials in buildings
stock_summary %>% 
    filter(category == "building") %>%
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
    mutate(
        perc_min = (aggregate + concrete + bricks + glass + all_other_minerals) / total * 100
    ) %>%
    mutate(
        perc_con = concrete / (aggregate + concrete + bricks + glass + all_other_minerals) * 100
    ) %>% 
    mutate(
        perc_agg = aggregate / (aggregate + concrete + bricks + glass + all_other_minerals) * 100
    ) %>% 
    mutate(
        perc_bio = (other_biomass_based_materials + timber) / total * 100
    ) %>%
    mutate(
        perc_met = (aluminum + copper + iron_steel + all_other_metals) / total * 100
    ) %>%
    mutate(
        perc_pet = (all_other_fossil_fuel_based_materials + bitumen) / total * 100
    ) %>%
    mutate(
        perc_oth = (all_other_materials + insulation) / total * 100
    ) %>%
    select(starts_with("perc")) 

# Gt of minerals in building
# Gt of concrete in minerals in building
# Gt of aggregates in minerals in building
# Gt of all other materials in buildings
stock_summary %>% 
    filter(category == "building") %>%
    summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
    mutate(
        Gt_min = (aggregate + concrete + bricks + glass + all_other_minerals) / 1e9
    ) %>%
    mutate(
        Gt_con = concrete / 1e9
    ) %>% 
    mutate(
        Gt_agg = aggregate / 1e9
    ) %>% 
    mutate(
        Gt_bio = (other_biomass_based_materials + timber) / 1e9
    ) %>%
    mutate(
        Gt_met = (aluminum + copper + iron_steel + all_other_metals) / 1e9
    ) %>%
    mutate(
        Gt_pet = (all_other_fossil_fuel_based_materials + bitumen) / 1e9
    ) %>%
    mutate(
        Gt_oth = (all_other_materials + insulation) / 1e9
    ) %>%
    select(starts_with("Gt")) 


# percent of skyscrapers and subways relative to all stocks
stock_states %>% 
  summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  mutate(perc_sky = building_skyscraper / grand_total_t_10m2 * 100) %>%
  mutate(perc_sub = (rail_subway_surface+rail_subway+rail_subway_elevated) / grand_total_t_10m2 * 100) %>%
  select(starts_with("perc")) 

# Gt of low-rise residential and local roads in Gt
stock_states %>%
  summarise_if(is.numeric, sum, na.rm = TRUE) %>% 
  select(building_singlefamily, street_local) / 1e9

# total stock relative to plant biomass stock
total / 48.5
total / 48.5 * 100 # percent




