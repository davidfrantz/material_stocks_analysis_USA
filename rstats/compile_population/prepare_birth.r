require(dplyr)
require(tidyr)

# changes in counties to consider:
# https://www.census.gov/programs-surveys/geography/technical-documentation/county-changes.2010.html
###########################################################################################################
# new FIPS code (accounted for)
# - Oglala Lakota County, South Dakota (46-102)
#   Changed name and code from Shannon County (46-113) effective May 1, 2015.
###########################################################################################################
# complete assimilation (accounted for)
# - Bedford (independent) city, Virginia (51-515):
#   Changed to town status and added to Bedford County (51-019) effective July 1, 2013.

d19 <- read.csv("csv/stats-per-county/co-est2019-alldata.csv") %>%
    filter(SUMLEV != 40) %>%
    filter(STNAME != "Alaska") %>%
    filter(STNAME != "Hawaii") %>%
    mutate(FIPS = sprintf("%05d", STATE * 1000 + COUNTY)) %>%
    select(FIPS, starts_with("RBIRTH"))
d19 %>% nrow()

d10 <- read.csv("csv/stats-per-county/co-est2010-alldata.csv") %>%
    filter(SUMLEV != 40) %>%
    filter(STNAME != "Alaska") %>%
    filter(STNAME != "Hawaii") %>%
    mutate(FIPS = sprintf("%05d", STATE * 1000 + COUNTY)) %>%
    select(- ends_with("2010")) %>%
    select(FIPS, starts_with("RBIRTH"))
d10 %>% nrow()

# Renamed Shannon county -> Oglala Lakota County, new FIPS code in 2015
d10 <- d10 %>% mutate(FIPS = replace(FIPS, FIPS == "46113", "46102"))

# Added Bedford city to Bedford County in 2013
d10 <- d10 %>% mutate(FIPS = replace(FIPS, FIPS == "51515", "51019"))
d10 <- d10 %>% group_by(FIPS) %>%
    summarize_at(vars(starts_with("RBIRTH")), mean) %>%
    ungroup()

# should be 0
anti_join(d19, d10, by = "FIPS") %>%
bind_rows(
anti_join(d10, d19, by = "FIPS"))

data <- d19 %>% 
    full_join(d10, by = "FIPS")

names(data) <- gsub("RBIRTH", "", names(data))

data <- data %>%
    gather("YEAR", "RBIRTH", 2:ncol(data))

nrow(data)

write.csv(data, "csv/stats-per-county/counties_birth.csv")
