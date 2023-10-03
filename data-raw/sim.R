library(microdatasus)
library(tidyverse)

if (file.exists("data-raw/datasus.rda")) {
  load("data-raw/datasus.rda")
} else {
  df <- fetch_datasus(
    year_start = 2011,
    year_end = 2020,
    information_system = "SIM-DO",
    vars = c(
      "IDADE", "RACACOR", "SEXO", "ESC", "ESTCIV", "CAUSABAS", "DTOBITO",
      "HORAOBITO", "LOCOCOR", "QTDFILVIVO"
    )
  )
  save(df, file = "data-raw/datasus.rda")
}

# função para decodificar idades do datasus
decod_idade <- function(arg) {
  arg <- as.character(arg)

  res <- case_when(
    str_sub(arg, 1, 1) == 0 ~ paste(str_sub(arg, 2, 3), "minutos"),
    str_sub(arg, 1, 1) == 1 ~ paste(str_sub(arg, 2, 3), "horas"),
    str_sub(arg, 1, 1) == 2 ~ paste(str_sub(arg, 2, 3), "dias"),
    str_sub(arg, 1, 1) == 3 ~ paste(str_sub(arg, 2, 3), "meses"),
    str_sub(arg, 1, 1) == 4 ~ paste(str_sub(arg, 2, 3), "anos"),
    str_sub(arg, 1, 1) == 5 ~ paste0(1, str_sub(arg, 2, 3), " anos"),
  )

  return(res)
}

# regex para categorias CID 10 de interesse
lista_cid <- paste0("V", seq(0, 8, 1), collapse = "|")

# tratando os dados
sim <- df |> 
  select(-QTDFILVIVO, -HORAOBITO) |> 
  mutate(
    IDADE = decod_idade(IDADE),
    RACACOR = as.character(RACACOR),
    RACACOR = case_match(
      RACACOR,
      "1" ~ "branca",
      "2" ~ "preta",
      "3" ~ "amarela",
      "4" ~ "parda",
      "5" ~ "indigena",
      .default = NA
    ),
    SEXO = as.character(SEXO),
    SEXO = case_match(
      SEXO,
      "1" ~ "masculino",
      "2" ~ "feminino",
      .default = NA
    ),
    ESC = as.character(ESC),
    ESC_DECOD = case_match(
      ESC,
      "1" ~ "nenhuma",
      "2" ~ "1 a 3 anos",
      "3" ~ "4 a 7 anos",
      "4" ~ "8 a 11 anos",
      "5" ~ "12 a mais",
      .default = NA
    ),
    ESTCIV = as.character(ESTCIV),
    ESTCIV = case_match(
      ESTCIV,
      "1" ~ "solteiro",
      "2" ~ "casado",
      "3" ~ "viuvo",
      "4" ~ "separado",
      "5" ~ "uniao",
      .default = NA
    ),
    DTOBITO = dmy(DTOBITO),
    LOCOCOR = as.character(LOCOCOR),
    LOCOCOR = case_match(
      LOCOCOR,
      "1" ~ "hospital",
      "2" ~ "saude",
      "3" ~ "domicilio",
      "4" ~ "via",
      "5" ~ "outros",
      .default = NA
    ),
    MOTOCICLISTA = if_else(
      grepl("V2", CAUSABAS),
      "sim",
      "nao"
    )
  ) |> 
  filter(grepl(lista_cid, CAUSABAS))

save(sim, file = "data/sim.rda")
