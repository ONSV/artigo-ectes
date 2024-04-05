library(tidyverse)
library(ISLR)
library(onsvplot)
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
  geom_point(alpha = .25, color = onsv_palette$yellow) +
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
