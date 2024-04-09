library(dplyr)
library(ggplot2)
library(ISLR)
library(onsvplot)
library(yardstick)
library(flextable)
source("R/main.R")

load("data/sim.rda")

# sim |> 
#   mutate(ano = year(DTOBITO),
#          tipo = case_match(
#            str_sub(CAUSABAS, 0, 2),
#            "V0" ~ "pedestre",
#            "V1" ~ "ciclista",
#            "V2" ~ "motociclista",
#            "V3" ~ "triciclo",
#            "V4" ~ "automovel",
#            "V5" ~ "caminhonete",
#            "V6" ~ "transporte",
#            "V7" ~ "onibus",
#            "V8" ~ "outros"
#          )) |> 
#   count(ano, tipo) |> 
#   ggplot(aes(ano, n, color = tipo)) +
#     geom_line(linewidth = 1) +
#     geom_point() +
#     scale_x_continuous(breaks = seq(2011, 2020, 2))

# logreg_plot <- Default |>
#   mutate(
#     default = case_match(default, "No" ~ 0, "Yes" ~ 1),
#     student = case_match(student, "No" ~ 0, "Yes" ~ 1)
#   ) |>
#   ggplot(aes(balance, default)) +
#   geom_segment(aes(
#     x = 0,
#     xend = 2700,
#     y = 1,
#     yend = 1
#   ),
#   linewidth = 0.2,
#   lty = "longdash") +
#   geom_segment(aes(
#     x = 0,
#     xend = 2700,
#     y = 0,
#     yend = 0
#   ),
#   linewidth = 0.2,
#   lty = "longdash") +
#   geom_point(alpha = .10, color = onsv_palette$yellow, size = 0.5) +
#   stat_smooth(
#     method = "glm",
#     color = onsv_palette$blue,
#     se = F,
#     method.args = list(family = binomial),
#     linewidth = 0.5
#   ) +
#   theme_minimal() +
#   scale_x_continuous(limits = c(0, 2800)) +
#   theme(axis.text = element_blank()) +
#   labs(x = NULL, y = NULL)

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
  scale_y_discrete() +
  coord_fixed() +
  theme_minimal() +
  labs(x = "Truth", y = "Predicted") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

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
  flextable() |>
  colformat_double(digits = 3) |>
  set_header_labels(.metric = "Metric", .estimate = "Value") |>
  autofit() |>
  bg(j = ~ .estimate, bg = col_numeric("RdBu", c(0, 1))) |>
  color(
    j = ~ .estimate,
    i = ~ .estimate < 0.2 | .estimate > 0.8,
    color = "white"
  ) |>
  fontsize(size = 9, part = "all") |>
  line_spacing(space = 0.55, part = "body") |>
  line_spacing(space = 0.6, part = "header") |>
  color(color = "white", part = "header") |>
  bg(bg = onsv_palette$blue, part = "header") |> 
  theme_vanilla()

roc_plot <- probs |>
  roc_curve(motociclista, .pred_sim, event_level = "second") |>
  ggplot(aes(x = 1 - specificity, y = sensitivity)) +
  geom_path(color = onsv_palette$blue, lty = "longdash") +
  geom_area(fill = onsv_palette$blue, alpha = 0.2) +
  geom_abline(lty = 2, color = onsv_palette$red) +
  coord_equal() +
  theme_minimal() +
  labs(x = "False Positive Rate", y = "True Positive Rate") +
  theme(plot.margin = margin(0.3, 0.3, 0.1, 0.3, "cm"),
        axis.text = element_text(size = 8),
        axis.title = element_text(size = 10))

terms <-
  data.frame(
    vars = c(
      "|Age",
      "White|Race",
      "Black|Race",
      "Native|Race",
      "Asian|Race",
      "Female|Sex",
      "Married|Marital status",
      "Common law|Marital status",
      "Widowed|Marital status",
      "Divorced|Marital status",
      "Road|Place of death",
      "Home|Place of death",
      "Others|Place of death",
      "Health Est.|Place of death",
      "1-3 years|Ed. level",
      "4-7 years|Ed. level",
      "8-11 years|Ed. level",
      "12+ years|Ed. level"
    )
  )

odds_tbl <- log_model$fit |>
  extract_fit_parsnip() |>
  tidy() |>
  mutate(estimate = exp(estimate)) |>
  filter(term != "(Intercept)") |>
  bind_cols(terms) |>
  relocate(vars) |>
  select(vars, estimate, p.value) |> 
  separate(vars, into = c("class", "var"), sep = "\\|") |> 
  relocate(var) |> 
  flextable() |>
  colformat_double(digits = 3) |>
  set_header_labels(var = "Variable",
                    class = "Classes",
                    estimate = "Odds Ratio",
                    p.value = "P-value") |>
  autofit() |>
  merge_v(j = ~ var) |> 
  bg(
    j = ~ estimate,
    bg = col_numeric(palette = "RdBu", domain = c(0.4, 1.5)),
    part = "body"
  ) |>
  color(j = ~ p.value,
        color = onsv_palette$red,
        i = ~ p.value > 0.05) |>
  color(
    j = ~ estimate,
    i = ~ estimate > 1.4 | estimate < 0.6,
    color = "white"
  ) |>
  fontsize(size = 9, part = "all") |>
  line_spacing(space = 0.55, part = "body") |>
  line_spacing(space = 0.6, part = "header") |>
  color(color = "white", part = "header") |>
  bg(bg = onsv_palette$blue, part = "header") |>
  theme_vanilla()

ggsave("plots/heatmap.png", cm_heatmap, bg = "transparent", dpi = 300, height = 5, units = "cm")
ggsave("plots/roc.png", roc_plot, bg = "transparent", dpi = 300, height = 8, units = "cm")
save_as_image(metric_tbl, "plots/metric.png", res = 300, expand = 0)
save_as_image(odds_tbl, "plots/odds.png", res = 300, expand = 0)

