# this script prepares annual population for the counties

require(dplyr)
require(tidyr)

# changes in counties to consider:
# https://www.census.gov/programs-surveys/geography/technical-documentation/county-changes.2010.html
###########################################################################################################
# new FIPS code (accounted for)
# - Oglala Lakota County, South Dakota (46-102)
#   Changed name and code from Shannon County (46-113) effective May 1, 2015.
# - Miami-Dade County, Florida (12-086):
#   Renamed from Dade County (12-025) effective July 22, 1997.
###########################################################################################################
# complete assimilation (accounted for)
# - Bedford (independent) city, Virginia (51-515):
#   Changed to town status and added to Bedford County (51-019) effective July 1, 2013.
###########################################################################################################
# territorial changes (NOT accounted for)
# - York County, Virginia (51-199):
#   Exchanged territory with Newport News (independent) city (51-700) effective July 1, 2007; estimated net detached population: 293.
#   Newport News (independent) city, Virginia (51-700):
#   Exchanged territory with York County (51-199) effective July 1, 2007; estimated net added population: 293.
# - Carteret County, North Carolina (37-031):
#   Boundary correction added from and detached unpopulated parts to Craven County (37-049); estimated area added: five square miles; estimated area detached: 16 square miles.
#   Craven County, North Carolina (37-049):
#   Boundary correction added from and detached unpopulated parts to Carteret County (37-031); estimated area added: 16 square miles; estimated area detached: five square miles.


d19 <- read.csv("csv/stats-per-county/co-est2019-alldata.csv") %>%
    filter(SUMLEV != 40) %>%
    filter(STNAME != "Alaska") %>%
    filter(STNAME != "Hawaii") %>%
    mutate(FIPS = sprintf("%05d", STATE * 1000 + COUNTY)) %>%
    select(FIPS, starts_with("POPESTIMATE"))
d19 %>% nrow()

d10 <- read.csv("csv/stats-per-county/co-est2010-alldata.csv") %>%
    filter(SUMLEV != 40) %>%
    filter(STNAME != "Alaska") %>%
    filter(STNAME != "Hawaii") %>%
    mutate(FIPS = sprintf("%05d", STATE * 1000 + COUNTY)) %>%
    select(- ends_with("2010")) %>%
    select(FIPS, starts_with("POPESTIMATE"))
d10 %>% nrow()


# Renamed Shannon county -> Oglala Lakota County, new FIPS code in 2015
d10 <- d10 %>% mutate(FIPS = replace(FIPS, FIPS == "46113", "46102"))

# Added Bedford city to Bedford County in 2013
d10 <- d10 %>% mutate(FIPS = replace(FIPS, FIPS == "51515", "51019"))
d10 <- d10 %>% group_by(FIPS) %>%
    summarize_at(vars(starts_with("POPESTIMATE")), sum) %>%
    ungroup()


# should be 0
anti_join(d19, d10, by = "FIPS") %>%
bind_rows(
anti_join(d10, d19, by = "FIPS"))

data <- d10 %>% 
    full_join(d19, by = "FIPS")

names(data) <- gsub("POPESTIMATE", "", names(data))


data <- data %>%
    gather("YEAR", "POP", 2:ncol(data))

nrow(data)


# pop change
fun <- function(x, dummy = 1L) {
    data.frame(
        YEAR = x$YEAR,
        POP  = x$POP,
        RPOP = c(NA, diff(x$POP) / x$POP[1:(length(x$POP)-1)] * 1000)
    )
}

data <- data %>% 
    group_by(FIPS) %>%
    group_modify(fun) %>%
    ungroup()

nrow(data)


write.csv(data, "csv/stats-per-county/counties_pop.csv")
