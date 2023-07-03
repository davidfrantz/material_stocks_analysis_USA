# this script runs the linear regression to analyze the relationship between building and infrastructure stocks
# (C) Thomas Udelhoven, David Frantz

require(dplyr)

df_area_ <- read.csv("csv/joined/data_per-area.csv")


year <- 2018

data <- df_area_ %>%
  filter(YEAR == year) %>%
  select(
    STATE_NAME,
    mass_building,
    mass_mobility
  )

names(data)


# only one record "District of Columbia"
z <- which(data$STATE_NAME=="District of Columbia")
data <- data[-z,]


data <- data[complete.cases(data), ]

### Data analysis
pairs(data %>% select(-STATE_NAME))


r2 <- matrix(NA, 100, 2)

for (i in 1:100){
  
  # 50% samples from each STATE
  
  data_train <- data %>% group_by(STATE_NAME) %>% sample_frac(.5)
  data_valid <- data %>%  anti_join(data_train)
  
  nrow(data_train)
  nrow(data_valid)
  
  # LM
  
  lm_data <-  lm(mass_building ~ mass_mobility -STATE_NAME, data = data_train)
  
  summary(lm_data)
  r2[i,1] <- summary(lm_data)$r.squared
  
  data_valid <- data_valid %>% 
    mutate(predicted = predict(lm_data, data_valid)) %>%
    mutate(observed = mass_building)
  
  r2[i,2] <- cor(data_valid$observed, data_valid$predicted)^2
  
}


colMeans(r2)

