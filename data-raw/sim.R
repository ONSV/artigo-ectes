library(microdatasus)
library(tidyverse)

if(file.exists("data-raw/datasus.rda")) {
  load("data-raw/datasus.rda")
} else {
  df <- fetch_datasus(
    year_start = 2011,
    year_end = 2020,
    uf = "SP",
    information_system = "SIM-DO",
    vars = c("IDADE", "RACACOR", "SEXO", "ESC",
             "ESTCIV", "CAUSABAS", "DTOBITO")
  )
  save(df, file = "data-raw/datasus.rda")
}

df <- df |> 
  rename(
    idade = IDADE, cor = RACACOR, sexo = SEXO,
    escolaridade = ESC, estado_civil = ESTCIV,
    causa = CAUSABAS, peso = PESO, data = DTOBITO
  ) |> 
  mutate(
    data = dmy(data)
  )
