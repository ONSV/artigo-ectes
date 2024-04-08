library(dplyr)
library(ggplot2)
library(ISLR)
library(onsvplot)
library(yardstick)
library(vip)
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

Default |>
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
  
cm$table |> 
  as_tibble() |> 
  ggplot(aes(Truth, Prediction)) +
  geom_tile(aes(fill = n), show.legend = F) +
  geom_text(aes(label = n, color = if_else(n > 10000, "white", "black"))) +
  scale_fill_gradientn(colors = rev(c(onsv_palette$blue, 
                                      onsv_palette$lightblue))) +
  scale_color_identity() +
  coord_fixed() +
  labs(x = "True Classes", y = "Predicted Classes")


summary(cm, event_level = "second")

probs <- 
  log_model$fit |> 
  predict(log_model$predictions, type = "prob") |> 
  bind_cols(log_model$predictions)

probs |>
  roc_curve(motociclista, .pred_sim, event_level = "second") |>
  ggplot(aes(x = 1 - specificity, y = sensitivity)) +
  geom_path(aes(color = "Predicted curve")) +
  geom_abline(lty = 3) +
  coord_equal() +
  theme_minimal() +
  geom_segment(aes(
    x = 0,
    xend = 0,
    y = 0,
    yend = 1,
    color = "Ideal curve"
  ), linetype = "longdash") +
  geom_segment(aes(
    x = 0,
    xend = 1,
    y = 1,
    yend = 1,
    color = "Ideal curve"
  ), linetype = "longdash") +
  geom_point(aes(0, 1, color = "Ideal curve")) +
  labs(x = "Specificity", y = "Sensitivity")

roc_auc(probs, motociclista, .pred_sim, event_level = "second")

log_model$fit |> 
  extract_fit_parsnip() |> 
  tidy() |> 
  mutate(estimate = exp(estimate)) |> 
  filter(p.value < 0.05)

