library(tidyverse)
library(tidymodels)
library(ggplot2)
library(onsvplot)
library(here)
library(knitr)
load(here("data","sim.rda"))

source("R/scripts.R")

data <- data_prep(sim)

data_train_test <- train_test_split(data)

best_fold <- get_best_cvfold(x = data_train_test$train)

log_model <- log_modeller(x = best_fold, test = data_train_test$test)
