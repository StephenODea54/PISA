                    ### LIBRARIES ###
library(tidymodels)
library(tidyverse)
library(xgboost)

                    ### LOAD IN DATASETS ###
student_data <- readRDS("./data/student_data.rds")

student_data <- student_data %>%
  select(-country, -school_id, -year, -student_id)

                    ### TRAINING AND TESTING SPLIT ###
set.seed(1)
student_split <- initial_split(student_data, strata = math)
student_train <- training(student_split)
student_test <- testing(student_split)

                    ### LASSO REGRESSION ###
## RECIPE
lasso_rec <- recipe(math ~., data = student_train) %>%
  step_dummy(all_nominal()) %>%
  step_zv(all_numeric()) %>%
  step_center(all_predictors()) %>%
  step_scale(all_predictors())

## MODEL SPECIFICATIONS
lasso_model <- linear_reg(penalty = tune("penalty"),
                          mixture = 0.5) %>%
  set_engine("glmnet") %>%
  set_mode("regression")

## WORKFLOW
lasso_workflow <- workflow() %>% 
  add_recipe(lasso_rec) %>% 
  add_model(lasso_model)

## GRID SPECIFICATIONS
lasso_grid <- grid_regular(penalty(),
                           levels = 50)

## FOLDS
set.seed(2)
student_folds <- vfold_cv(student_train, v = 5)

## TUNE GRID
set.seed(3)

doParallel::registerDoParallel()

lasso_grid_results <- tune_grid(
  lasso_workflow,
  resamples = student_folds,
  grid = lasso_grid
)

## CHECK RESULTS
lasso_grid_results %>%
  collect_metrics()

## SELECT BEST PARAMETER
lasso_best_rmse <- lasso_grid_results %>%
  select_best("rmse")

## FINALIZE WORKFLOW
lasso_final_workflow <- finalize_workflow(lasso_workflow,
                                          lasso_best_rmse)

## FIT TO TEST DATA
lasso_fit <- lasso_final_workflow %>%
  last_fit(student_split)

lasso_fit %>%
  collect_metrics()

## VIP PLOT
lasso_final_workflow  %>% fit(student_train) %>% 
  pull_workflow_fit() %>%
  vip::vi(lambda = lasso_best_rmse$penalty) %>%
  mutate(
    Importance = abs(Importance),
    Variable = fct_reorder(Variable, Importance)
  ) %>%
  ggplot(aes(x = Importance, y = Variable, fill = Sign)) +
  geom_col() +
  scale_x_continuous(expand = c(0, 0)) +
  labs(y = NULL)

## SAVE WORKFLOW AND FINAL FIT
saveRDS(lasso_final_workflow, "./models/lasso_final_workflow.rds")
saveRDS(lasso_fit, "./models/lasso_fit.rds")

                    ### BOOSTED TREES ###
## RECIPE
xgb_recipe <- recipe(math ~ ., data = student_train) %>% 
  step_dummy(all_nominal()) %>%
  step_zv(all_numeric()) %>%
  step_nzv(all_nominal())

## MODEL SPECIFICATIONS
xgb_model <- boost_tree(trees = 1000,
                                 mtry = tune(),
                                 min_n = tune(),
                                 tree_depth = tune(),
                                 learn_rate = tune(),
                                 sample_size = tune(),
                                 loss_reduction = tune()) %>%
  set_mode("regression") %>% 
  set_engine("xgboost",  objective = 'reg:squarederror')

## GRID SPECIFICATIONS
xgb_grid <- grid_latin_hypercube(
  tree_depth(), 
  min_n(), 
  finalize(mtry(), student_train),
  learn_rate(),
  loss_reduction(),
  sample_size = sample_prop(),
  size =60)

## WORKFLOW
xgb_workflow <- workflow() %>% 
  add_recipe(xgb_recipe) %>%
  add_model(xgb_model) 

## PLEASE PRAY FOR MY PC
doParallel::registerDoParallel(cores = 6)

## TUNE GRID
xgb_grid_results <- tune_grid(
  xgb_workflow,
  resamples = student_folds,
  grid = xgb_grid,
  control = control_grid(save_pred = TRUE)
)

## CHECK RESULTS
xgb_grid_results %>% collect_metrics()

xgboost_metrics %>% 
  filter(.metric == "rmse") %>% 
  select(mean, tree_depth, mtry, min_n,learn_rate, loss_reduction, sample_size) %>% 
  pivot_longer(c(tree_depth, mtry, min_n,learn_rate, loss_reduction, sample_size),
               values_to ="value",
               names_to = "parameter") %>% 
  ggplot(aes(value, mean, color = parameter)) +
  geom_point() + facet_wrap(~parameter, scales = "free_x")


## SELECT BEST PARAMETER
show_best(xgb_grid_results, "rmse")
xgb_best_rmse <- select_best(xgb_grid_results, "rmse")

## FINALIZE WORKFLOW
xgb_final_workflow <- finalize_workflow(
  xgb_workflow,
  xgb_best_rmse)

## FIT TO TEST DATA
xgb_fit <- xgb_final_workflow %>%
  last_fit(student_split)

xgb_fit %>%
  collect_metrics()

## VIP PLOT
xgb_grid_results %>% collect_metrics() -> xgb_metrics

xgb_metrics %>% 
  filter(.metric == "rmse") %>% 
  select(mean, tree_depth, mtry, min_n,learn_rate, loss_reduction, sample_size) %>% 
  pivot_longer(c(tree_depth, mtry, min_n,learn_rate, loss_reduction, sample_size),
               values_to ="value",
               names_to = "parameter") %>% 
  ggplot(aes(value, mean, color = parameter)) +
  geom_point() + facet_wrap(~parameter, scales = "free_x")

## SAVE WORKFLOW AND FINAL FIT
saveRDS(xgb_final_workflow, "./models/xgb_final_workflow.rds")
saveRDS(xgb_fit, "./models/xgb_fit.rds")
