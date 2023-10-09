library(tidyverse)
library(tidymodels)
library(ggplot2)
library(onsvplot)
library(here)
library(knitr)
load(here("data","sim.rda"))

source("R/scripts.R")

dados <- data_prep(sim)

modelo <- modelo_motociclista(dados)