data_prep <- function(x) {
  
  x_prep <- x |> 
    mutate(
      IDADE = if_else(
        grepl("anos", IDADE),
        str_sub(IDADE,1,3),
        "0"
      ),
      IDADE = as.numeric(IDADE),
      ESC_DECOD = factor(
        ESC_DECOD,
        levels = c("nenhuma","1 a 3 anos","4 a 7 anos","8 a 11 anos","12 a mais")
      )
    ) |> 
    drop_na() |> 
    select(IDADE, RACACOR, SEXO, ESTCIV, LOCOCOR, ESC_DECOD, MOTOCICLISTA) |> 
    rename(
      idade = IDADE,
      cor = RACACOR,
      sexo = SEXO,
      estado_civil = ESTCIV,
      local_obito = LOCOCOR,
      escolaridade = ESC_DECOD,
      motociclista = MOTOCICLISTA) |> 
    mutate(across(c(cor, sexo, estado_civil, local_obito), 
                  as_factor),
           motociclista = factor(motociclista, levels = c("nao","sim")))
 
  return(x_prep)
   
}

train_test_split <- function(x) {
  
  #set seed
  set.seed(123)
  
  #separar em teste e treino inicial
  data_split <- initial_split(x, prop = 0.8)
  
  train_split <- training(data_split)
  test_split <- testing(data_split)
  
  return(list(train = train_split, test = test_split))
}

get_best_cvfold <- function(x) {
  
  metrix <- metric_set(accuracy, precision, sens, roc_auc)
  
  log_model <- 
    logistic_reg(mixture = 1) |> 
    set_engine("glm")
  
  prep_steps <- 
    recipe(motociclista ~ ., x) |>
    step_dummy(all_nominal_predictors())
  
  data_folds <- vfold_cv(data = x)
  
  log_wflow <- 
    workflow() |> 
    add_recipe(prep_steps) |> 
    add_model(log_model)
  
  log_cvfit <- fit_resamples(object = log_wflow, resamples = data_folds, metrics = metrix)
  
  best_fold_id <- log_cvfit |> 
    collect_metrics(summarize = FALSE) |> 
    pivot_wider(names_from = .metric, values_from = .estimate) |> 
    select(-.estimator, -.config) |> 
    mutate(mean = (accuracy + precision + sens + roc_auc)/4) |> 
    filter(mean == max(mean)) |> 
    pull(id) |> 
    str_sub(-1,) |> 
    as.numeric()
  
  best_fold <- analysis(log_cvfit$splits[[best_fold_id]])
  
  return(best_fold)
}

log_modeller <- function(x, test) {
  
  log_model <- 
    logistic_reg(mixture = 1) |> 
    set_engine("glm")
  
  prep_steps <- 
    recipe(motociclista ~ ., x) |>
    step_dummy(all_nominal_predictors())
  
  log_wflow <- 
    workflow() |> 
    add_recipe(prep_steps) |> 
    add_model(log_model)
  
  log_fit <-
    log_wflow |> 
    fit(x)
  
  log_preds <- log_fit |> 
    predict(test) |> 
    bind_cols(test)
  
  metricas <- metric_set(accuracy, precision, sens)
  metricas_res <- metricas(log_preds,
                           truth = motociclista,
                           estimate = .pred_class)
  
  coefs <- 
    log_fit |>
    tidy() |> 
    mutate(
      odds = exp(estimate)
    )
  
  return(list(predictions = log_preds,
              metrics = metricas_res,
              coefs = coefs,
              fit = log_fit))
}