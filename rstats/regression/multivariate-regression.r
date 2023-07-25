# this script runs the multivariate regression to explain building and infrastructure intensity
# (C) Thomas Udelhoven, David Frantz
rm(list=ls())
library(rgdal)
library(ggplot2)
library(spdep)     # for analyzing spatial objects
library(spatialreg)# for analyzing spatial autocorrelation
require(dplyr)
library(ggplot2)
library(lmtest) # for likelihood ratio test

##############################################
### functions
##############################################

# to preprocess spatialpolygondataframe: fix invalid geometries 
preprocess_spatial_data <- function (spdataset, data) { # spdataset: spatialpolygondataframe, data: dataframe 
  # merge data and remove NAs
  data$FIPS <- as.character(data$FIPS)
  spdataset <- merge(x=spdataset, y=data, by.x="FIPS", by.y="FIPS")
  spdataset <- spdataset[complete.cases(spdataset@data), ]
  return(spdataset)
}

#################################################
### load data, preprocessing and select variables
#################################################

df_pop_ <- read.csv("csv/joined/data_per-pop.csv")
year <- 2000

sub <- df_pop_ %>% filter(YEAR == year)
data <- sub %>% 
  dplyr::mutate(GDP_2018 = GDP_2018 / POP_NOW) %>%
  dplyr::select(
    STATE_NAME,
    FIPS,
    mass_building,
    mass_mobility,
    POP_PER_AREA,
    POPPCT_URBAN,
    starts_with("MEAN_R"),
    vacancy_rate,
    household_size,
    grid_index,
    GDP_2018,
    POP_NOW
  )

names(data)
data$mass_building <- log(data$mass_building)
data$mass_mobility <- log(data$mass_mobility)
data$POP_PER_AREA <- log(data$POP_PER_AREA)
data$GDP_2018 <- log(data$GDP_2018)


# only one record "District of Columbia"
z <- which(data$STATE_NAME=="District of Columbia")
data <- data[-z,]



# remove some more variables
data <- data %>% 
  dplyr::select(
    -MEAN_RPOP, 
    -MEAN_RNATURALINC, 
    -MEAN_RNETMIG,
#    -GDP_2018
    -POP_NOW,
    -vacancy_rate
  )

data <- data[complete.cases(data), ]
# scale
data[, -c(1,2)] <- scale(data[,-c(1,2)])


### Data analysis

# visual instpection
#pairs(data %>% dplyr::select(-c(STATE_NAME,FIPS)))
#r <- cor(data %>% dplyr::select(-STATE_NAME))
#corrplot::corrplot(r)

# import shapefile with US-counties
US <- readOGR("E:\\tmp\\davidF\\shp\\cb_2020_us_county_500k_id_clim_proj.shp") 

US@data <- US@data[, 17, drop = FALSE]
spplot(US,"FIPS",main="Counties")

# preprocess shapefile (invalid geometries!)
US <- preprocess_spatial_data(US,data)
spplot(US,"FIPS",main="Counties")

# Analyse spatial autocorrelation effects for the total data set
neighbors_nb  <- poly2nb(US)

# empty elements
empty_or_na <- which(sapply(neighbors_nb, function(x) all(is.na(x) | x == 0)))

if (length(empty_or_na) > 0) {
  # Exclude those elements from the neighbors list
  neighbors_nb <- neighbors_nb[-empty_or_na]
  # Exclude the corresponding regions from the SpatialPolygonsDataFrame
  US <- US[-empty_or_na, ]
  # Recreate neighbours list
  neighbors_nb <- poly2nb(US)
}

# Creating a listw object and 
listw_neighbors <- nb2listw(neighbors_nb)

# check for spatial autocorrelation
moran.mc(US$mass_building, listw_neighbors, nsim = 999)
moran.mc(US$mass_mobility, listw_neighbors, nsim = 999)

# result: data are spatial dependent! This should to be considered in regression analysis


#################################################
### Regression
#################################################

data <- as.data.frame(US)

##############################################
### model_mass_builing
##############################################

# step 1: variable selection

#vars <- setdiff(names(data), c("FIPS", "STATE_NAME", "mass_building", "mass_mobility"))
vars <- setdiff(names(data), c("FIPS", "STATE_NAME", "mass_building", "mass_mobility","grid_index"))
main_effects <- paste(vars, collapse = " + ")

# search for pairwise interaction with grid_size due to complex relation with mass_building
#interaction_effects <- paste(paste("grid_index", vars, sep = ":"), collapse = " + ")
#fmla <- paste("mass_building"," ~ ", main_effects, " + ", interaction_effects)
fmla <- paste("mass_building"," ~ ", main_effects)

# sample 500 objects to account for spatial autocorrelation
datasub <- data[sample(1:nrow(data), 500),]
init_model_b <- lm(as.formula(fmla), data = datasub)

# identify most relevant variables
final_model_b <- step(init_model_b, k = log(nrow(datasub)), direction = "both", trace = FALSE)
summary(final_model_b)
formula <- formula(final_model_b)

# Create a 3D scatterplot
# For plotting, we will first create a new dataframe with the predicted values from the model
#df_for_plot <- datasub
#df_for_plot$predicted_volume <- predict(final_model_b, df_for_plot)
#install.packages("rgl")
#library(rgl)

#with(df_for_plot, {
#  plot3d(household_size, grid_index, predicted_volume, type = "s", col = "red", size = 1, main = "3D Interaction Plot")
#  lines3d(household_size, grid_index, predicted_volume, col = "blue", lwd = 2)
#})
# step 2:full model, including all data and spatial autocorrelation effects

model_mass_building_full <- sacsarlm(formula, data = data, listw = listw_neighbors)   # based on original data
summary(model_mass_building_full)


# residual analysis
df <- data.frame(Fitted = fitted(model_mass_building_full),
                 Residuals = residuals(model_mass_building_full))

ggplot(df, aes(Fitted, Residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Residuals vs Fitted Values", x = "Fitted Values", y = "Residuals")

df <- data.frame(residuals = residuals(model_mass_building_full))

ggplot(df, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line(color = "red") +
  theme_minimal() +
  labs(title = "Q-Q Plot of Residuals", x = "Theoretical Quantiles", y = "Sample Quantiles")

# R2 and RMSE, check for spatial autocorrelation
formula <- "mass_building ~ 1"
model_mass_building_restr <- sacsarlm(formula, data = data, listw = listw_neighbors)   # based on original data
# Conduct log-likelihood ratio test
lrtest(model_mass_building_full, model_mass_building_restr)

RMSE <- sqrt(mean((model_mass_building_full$fitted.values-data$mass_building)^2))
print(RMSE)

data$residuals <- model_mass_building_full$residuals
moran.mc(data$residuals, listw_neighbors, nsim = 999)

# predict all data

US$mass_building_resid <- model_mass_building_full$residuals
US$mass_building_fitted <- model_mass_building_full$fitted.values

spplots <- list()
spplots[[1]] <- spplot(US,"mass_building_resid",main="Residuals of the SAR-model: mass building", at = seq(-4, 4, by = 0.1))
spplots[[2]] <- spplot(US,"mass_building_fitted",main="Fitted data of the SAC/SARLM-model: mass building", at = seq(-4, 4, by = 0.1))
spplots[[3]] <- spplot(US,"mass_building",main="Mass building", at = seq(-4, 4, by = 0.1))

##############################################
### model_mass_mobility
##############################################
#fmla <- paste("mass_mobility"," ~ ", main_effects, " + ", interaction_effects)
# sample 700 objects to account for spatial autocorrelation
datasub <- data[sample(1:nrow(data), 700),]
init_model_m <- lm(as.formula(fmla), data = datasub)
summary(init_model_m)
fmla <- paste("mass_mobility"," ~ ", main_effects)

init_model_m <- lm(as.formula(fmla), data = datasub)
summary(init_model_m)
# identify most relevant variables
final_model_m <- step(init_model_m, k = log(nrow(datasub)), direction = "both", trace = FALSE)
summary(final_model_m)
formula <- formula(final_model_m)
formula


# full model, including all data and spatial autocorrelation effects
model_mass_mobility_full <- sacsarlm(formula, data = data, listw = listw_neighbors)   # based on original data
summary(model_mass_mobility_full)


# residual analysis
df <- data.frame(Fitted = fitted(model_mass_mobility_full),
                 Residuals = residuals(model_mass_mobility_full))

ggplot(df, aes(Fitted, Residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal() +
  labs(title = "Residuals vs Fitted Values", x = "Fitted Values", y = "Residuals")

df <- data.frame(residuals = residuals(model_mass_building_full))

ggplot(df, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line(color = "red") +
  theme_minimal() +
  labs(title = "Q-Q Plot of Residuals", x = "Theoretical Quantiles", y = "Sample Quantiles")

# R2 and RMSE, check for spatial autocorrelation
# Conduct log-likelihood ratio test
formula <- "mass_mobility ~ 1"
model_mass_mobility_restr <- sacsarlm(formula, data = data, listw = listw_neighbors)   # based on original data
lrtest(model_mass_mobility_full, model_mass_mobility_restr)

# RMSE
RMSE <- sqrt(mean((model_mass_mobility_full$fitted.values-data$mass_mobility)^2))
print(RMSE)

# check for spatial autocorrelation in the training set
data$residuals <- model_mass_mobility_full$residuals
moran.mc(data$residuals, listw_neighbors, nsim = 999)


# predict all data
US$mass_mobility_resid <- model_mass_mobility_full$residuals
US$mass_mobility_fitted <- model_mass_mobility_full$fitted.values

spplots[[4]] <- spplot(US,"mass_mobility_resid",main="Residuals of the SAR-model: mass mobility", at = seq(-4, 4, by = 0.1))
spplots[[5]] <- spplot(US,"mass_mobility_fitted",main="Fitted data of the SAC/SARLM-model: mass mobility", at = seq(-4, 4, by = 0.1))
spplots[[6]] <- spplot(US,"mass_mobility",main="Mass mobility", at = seq(-4, 4, by = 0.1))

# Export as tiffs
for (i in seq_along(spplots)) {
  filename <- paste0("plot_", i, ".tiff")
  tiff(filename, units="in", width=10, height=6, res=300)
  print(spplots[[i]])  
  dev.off()
}
