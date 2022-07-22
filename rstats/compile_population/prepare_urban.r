# this script prepares the urban rate for the counties

require(dplyr)
require(tidyr)

d <- read.csv("csv/stats-per-county/PctUrbanRural_County.csv") %>%
    filter(STATENAME != "Alaska") %>%
    filter(STATENAME != "Hawaii") %>%
    filter(STATENAME != "Puerto Rico") %>% 
    mutate(FIPS = sprintf("%05d", STATE * 1000 + COUNTY)) %>%
    select(FIPS, POPPCT_URBAN, POPPCT_RURAL, POP_URBAN, POP_RURAL)
d %>% nrow()

# Renamed Shannon county -> Oglala Lakota County, new FIPS code in 2015
d <- d %>% mutate(FIPS = replace(FIPS, FIPS == "46113", "46102"))

# Added Bedford city to Bedford County in 2013
# recompute percentages
# drop columns
d <- d %>% mutate(FIPS = replace(FIPS, FIPS == "51515", "51019")) %>%
    group_by(FIPS) %>%
    summarize_at(vars(starts_with("POP_")), sum) %>%
    ungroup() %>%
    mutate(POPPCT_URBAN = POP_URBAN / (POP_URBAN + POP_RURAL) * 100) %>%
    mutate(POPPCT_RURAL = POP_RURAL / (POP_URBAN + POP_RURAL) * 100) %>%
    select(- starts_with("POP_"))

nrow(d)

write.csv(d, "csv/stats-per-county/counties_urbanrate.csv")
