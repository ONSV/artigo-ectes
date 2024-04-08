library(dplyr)
library(ggplot2)
library(ISLR)
library(onsvplot)
library(yardstick)
library(patchwork)
library(gt)
source("R/main.R")

load("data/sim.rda")

sim |> 
  mutate(ano = year(DTOBITO),
         tipo = case_match(
           str_sub(CAUSABAS, 0, 2),
           "V0" ~ "pedestre",
           "V1" ~ "ciclista",
           "V2" ~ "motociclista",
           "V3" ~ "triciclo",
           "V4" ~ "automovel",
           "V5" ~ "caminhonete",
           "V6" ~ "transporte",
           "V7" ~ "onibus",
           "V8" ~ "outros"
         )) |> 
  count(ano, tipo) |> 
  ggplot(aes(ano, n, color = tipo)) +
    geom_line(linewidth = 1) +
    geom_point() +
    scale_x_continuous(breaks = seq(2011, 2020, 1))

logreg_plot <- Default |>
  mutate(
    default = case_match(default, "No" ~ 0, "Yes" ~ 1),
    student = case_match(student, "No" ~ 0, "Yes" ~ 1)
  ) |>
  ggplot(aes(balance, default)) +
  geom_point(alpha = .10, color = onsv_palette$yellow) +
  geom_segment(aes(
    x = 0,
    xend = 2700,
    y = 1,
    yend = 1
  ), linetype = "longdash") +
  geom_segment(aes(
    x = 0,
    xend = 2700,
    y = 0,
    yend = 0
  ), linetype = "longdash") +
  stat_smooth(
    method = "glm",
    color = onsv_palette$blue,
    se = F,
    method.args = list(family = binomial)
  ) +
  theme_minimal() +
  scale_x_continuous(limits = c(0, 2800)) +
  labs(x = NULL, y = NULL)

cm <- log_model$predictions |>
  mutate(
    motociclista = fct_recode(motociclista, Yes = "sim", No = "nao"),
    .pred_class = fct_recode(.pred_class, Yes = "sim", No = "nao")
  ) |>
  conf_mat(truth = motociclista, estimate = .pred_class)
  
cm_heatmap <- cm$table |> 
  as_tibble() |> 
  ggplot(aes(Truth, Prediction)) +
  geom_tile(aes(fill = n), show.legend = F, color = "white") +
  geom_text(aes(label = n, color = if_else(n > 10000, "white", "black"))) +
  scale_fill_gradientn(colors = rev(c(onsv_palette$blue, 
                                      onsv_palette$lightblue))) +
  scale_color_identity() +
  scale_y_discrete(position = "right") +
  coord_fixed() +
  theme_minimal() +
  labs(x = "Truth", y = "Predicted")

probs <- 
  log_model$fit |> 
  predict(log_model$predictions, type = "prob") |> 
  bind_cols(log_model$predictions)

auc <- roc_auc(probs, motociclista, .pred_sim, event_level = "second")

metric_tbl <- summary(cm, event_level = "second") |>
  filter(.metric %in% c("accuracy", "sens", "spec", "precision")) |>
  bind_rows(auc) |>
  mutate(
    .metric = case_match(
      .metric,
      "sens" ~ "sensitivity",
      "roc_auc" ~ "roc auc",
      "spec" ~ "specificity",
      .default = .metric
    ),
    .metric = str_to_title(.metric)
  ) |>
  arrange(.estimate) |>
  select(-.estimator) |>
  gt() |>
  fmt_number(decimals = 3) |>
  cols_align(align = "center") |>
  cols_label(.estimate = "Value", .metric = "Metric") |>
  data_color(method = "numeric", palette = "RdYlGn") |>
  tab_options(
    column_labels.background.color = onsv_palette$blue,
    column_labels.font.weight = "bold"
  ) |>
  tab_style(style = cell_text(color = onsv_palette$blue),
            locations = cells_title())

roc_plot <- probs |>
  roc_curve(motociclista, .pred_sim, event_level = "second") |>
  ggplot(aes(x = 1 - specificity, y = sensitivity)) +
  geom_path(color = onsv_palette$blue) +
  geom_abline(lty = 2, linewidth = 1, color = onsv_palette$red) +
  coord_equal() +
  theme_minimal() +
  labs(x = "False Positive Rate", y = "True Positive Rate")

terms <-
  c(
    "Age",
    "White (Race)",
    "Black (Race)",
    "Asian (Race)",
    "Female (Sex)",
    "Married (Marital status)",
    "Common law (Marital status)",
    "Widow (Marital stats)",
    "Divorced (Marital stats)",
    "Road (Place)"
  )

log_model$fit |> 
  extract_fit_parsnip() |> 
  tidy() |> 
  mutate(estimate = exp(estimate)) |> 
  filter(term != "(Intercept)")
