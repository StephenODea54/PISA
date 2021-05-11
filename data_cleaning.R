                    ### LIBRARIES ###
library(tidyverse)
library(learningtower)
library(choroplethrMaps)
data(student)
head(student)

                    ### DATA CLEANING ###
### FILTER DATA FOR YEAR 2012 AND DROP NA VALUES
student_data <- student %>%
  filter(year == 2012) %>%
  drop_na()

### INSPECT DATA
glimpse(student_data)

### THE MODEL WILL ONLY INCLUDE MATH SCORES
student_data <- student_data %>%
  select(-read, -science, -stu_wgt)

                    ### SUMMARY STATISTICS
## CREATE MODE FUNCTION
mode <- function(x){
  names(which.max(table(x)))
}

## MEAN OF CONTINUOUS FEATURES, AGGREGATED BY COUNTRY
summarized_quant_data <- student_data %>%
  group_by(country) %>% 
  summarise_if(is.numeric, mean) %>%
  rename(
    avg_math_score = math,
    avg_wealth = wealth,
    avg_escs = escs
  )

## MODE OF DISCRETE FEATURES, AGGREGATED BY COUNTRY
summarized_qual_data <- student_data %>%
  select_if(is.factor) %>%
  pivot_longer(!country, names_to = "category", values_to = "value") %>%
  group_by(category, country) %>%
  summarise(mode = mode(value)) %>%
  pivot_wider(names_from = category, values_from = mode)

## JOIN
summarized_data <- summarized_quant_data %>%
  left_join(summarized_qual_data)

## AVERAGE MATH SCORE FOR MALES, AGGREGATED BY COUNTRY
male_average_math_score <- student_data %>%
  group_by(country) %>%
  filter(gender == "male") %>%
  summarise(avg_math_score_male = mean(math))

## AVERAGE MATH SCORE FOR FEMALES, AGGREGATED BY COUNTRY
female_average_math_score <- student_data %>%
  group_by(country) %>%
  filter(gender == "female") %>%
  summarise(avg_math_score_female = mean(math))

## JOIN
average_math_score_by_gender <- male_average_math_score %>%
  left_join(female_average_math_score) %>%
  group_by(country) %>%
  summarise(diff_in_score = abs(avg_math_score_male - avg_math_score_female))

## JOIN
summarized_data <- summarized_data %>%
  left_join(average_math_score_by_gender)

                    ### CHOROPLETH ###
### LOAD COUNTRY DATA FOR CHOROPLETH
data(country.map)

### JOIN
summarized_data  %>% full_join(country.map %>% select(long, lat, group, iso_a3), by = c("country" = "iso_a3")) -> map_data

### TEST
ggplot(map_data, aes(long, lat, group = group, fill = avg_math_score)) + geom_polygon()

### SAVING FILES
saveRDS(map_data, "./data/map_data.rds")
saveRDS(student_data, "./data/student_data.rds")
saveRDS(summarized_data, "./data/summarized_data.rds")