# this script runs the multivariate regression to explain building and infrastructure intensity
# (C) Thomas Udelhoven, David Frantz

require(dplyr)

df_pop_ <- read.csv("csv/joined/data_per-pop.csv")


year <- 2000

sub <- df_pop_ %>% filter(YEAR == year)
data <- sub %>% 
  select(
    STATE_NAME,
    mass_building,
    mass_mobility,
    POP_PER_AREA,
    POPPCT_URBAN,
    starts_with("MEAN_R"),
    vacancy_rate,
    household_size,
    grid_index,
    GDP_2018
  )

names(data)
data$mass_building <- log(data$mass_building)
data$mass_mobility <- log(data$mass_mobility)
data$POP_PER_AREA <- log(data$POP_PER_AREA)
data$GDP_2018 <- log(data$GDP_2018)

# scale
data[, -c(1,2,3)] <- scale(data[,-c(1,2,3)])

# only one record "District of Columbia"
z <- which(data$STATE_NAME=="District of Columbia")
data <- data[-z,]

# remove some more variables
data <- data %>% 
  select(
    -MEAN_RPOP, 
    -MEAN_RNATURALINC, 
    -MEAN_RNETMIG
  )

data <- data[complete.cases(data), ]
### Data analysis
pairs(data %>% select(-STATE_NAME))
#r <- cor(data %>% select(-STATE_NAME))
#corrplot::corrplot(r)


# dataframe for mass_building
mb <- data %>% select(-mass_mobility)
# dataframe for mass_mobility
mm <- data %>% select(-mass_building)

# 50% samples from each STATE
# mass_building

mb_train <- mb %>% group_by(STATE_NAME) %>% sample_frac(.5)
mb_valid <- data %>%  anti_join(mb_train)

# mass_mobility
mm_train <- mm %>% group_by(STATE_NAME) %>% sample_frac(.5)
mm_valid <- data %>%  anti_join(mm_train)



# LM

lmmb <-  lm(mass_building ~ . -STATE_NAME -vacancy_rate, data = mb_train)
lmmb <- step(lmmb)

lmmm <-  lm(mass_mobility ~ . -STATE_NAME -vacancy_rate, data = mm_train)
lmmm <- step(lmmm)

summary(lmmb)
summary(lmmm)

par(mfrow=c(2,2))
plot(lmmb)
plot(lmmm)
par(mfrow=c(1,1))

mb_valid <- mb_valid %>% 
  mutate(predicted_log = predict(lmmb, mb_valid)) %>%
  mutate(predicted = exp(predicted_log)) %>%
  mutate(observed = exp(mass_building)) %>%
  mutate(observed_log = mass_building)

mm_valid <- mm_valid %>% 
  mutate(predicted_log = predict(lmmm, mm_valid)) %>%
  mutate(predicted = exp(predicted_log)) %>%
  mutate(observed = exp(mass_mobility)) %>%
  mutate(observed_log = mass_mobility)

cor(mb_valid$observed_log, mb_valid$predicted_log)^2
cor(mm_valid$observed_log, mm_valid$predicted_log)^2

#plot(mb_valid$predicted_log, mb_valid$observed_log, xlim = c(4, 7), ylim=c(4,7))
#plot(mm_valid$predicted_log, mm_valid$observed_log)
#plot(mm_valid$predicted, mm_valid$observed)
