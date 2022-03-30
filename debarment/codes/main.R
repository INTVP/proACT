#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("country_code and country must be supplied", call.=FALSE)
} else {
  message(sprintf("running debarment matching for %s", args[1]))
}
# load libs
library(dplyr, warn.conflicts = F, quietly = T) # data wrangling
library(readxl, warn.conflicts = F, quietly = T) # read EXCEL files
library(readr, warn.conflicts = F, quietly = T) # read CSV and TXT files
library(lubridate, warn.conflicts = F, quietly = T) # date manipulation
library(stringr, warn.conflicts = F, quietly = T) # string cleaning
library(stringi, warn.conflicts = F, quietly = T) # string cleaning
library(logger, warn.conflicts = F, quietly = T) # logging
library(properties, warn.conflicts = F, quietly = T) # read system properties
library(snakecase, warn.conflicts = F, quietly = T) # fix column names
# Global variables ----
function_name <- "main"
country_code <- args[1]
country_of_interest <- args[2]

global_functions <- source("codes/functions/functions.R")
log_file <- 'debarment'
config <- setup_config(log_file = log_file)
logger::log_info("{function_name}: running {log_file} for {country_code}")

# Company legal forms ----
logger::log_info("{function_name}: Loading legal forms")
file <- "configuration/company_legalforms.xlsx"
sheets.list <- sheets.list <- excel_sheets(file)
company_legalforms <- read_excel(file, sheet = sheets.list[1])

logger::log_info("{function_name}: Loading debarment data")
file <- "output/debarrment_cleaned.csv"
debarment <-
  read_csv(file, col_types = cols(.default = col_character()))
logger::log_info("{function_name}: Filtering countires with PP data")
debarment <- debarment %>% filter(IsWB_country == TRUE)
# remove Mexico private individuals data and ID data in Indonesian
logger::log_info("{function_name}: Filtering Mexico private individuals data and ID data in Indonesian")
debarment <-
  debarment %>% filter(!id %in% c('indb.in.csv', 'mex02.en.csv'))
# Cleaning debarred bidders ----
debarment <-
  cleaning_bidders(
    df = debarment,
    var_name = 'entity.name',
    country_code = country_code,
    type = 'debarment'
  )

# country <- country_of_interest
debarment <-
  fix_legal_forms(df = debarment,
                  legalforms = company_legalforms,
                  country_code = country_code,
                  type = 'debarment')

# get debarred bidders
debarred.bidders <-
  plyr::count(debarment, "bidder_name_edited") %>%
  rename(debarred_count = 2)
# Matching ----
# file_name <-
logger::log_info("{function_name}: Loading bidder names from PP data")
file <-
  list.files(path = 'input/bidder_names/',
             pattern = tolower(sprintf("^%s_", country_code)),
             full.names = TRUE)

cols_selection <- case_when(country_code %in% c("WB", "IDB") ~ c("bidder_name", "bidder_country"),
        TRUE ~ c("bidder_name"))
df_bidders <-
  readr::read_csv(file, col_types = cols(.default = col_character())) %>%
  select(all_of(cols_selection))
if (country_code %in% c("WB", "IDB")) {
  logger::log_info(
    "{function_name}: Finding countries in {country_code} debarred data with legal form capacity for cleaning"
  )
  countries_codes <-
    read_excel(
      "configuration/countries_codes.xlsx",
      sheet = 1,
      .name_repair = snakecase::to_snake_case
    )
  debarred_countries <-
    intersect(debarment$country, company_legalforms$Country)

  debarred_countries <- as.data.frame(debarred_countries) %>%
    rename(country = 1) %>%
    left_join(countries_codes %>% select(country, alpha_2_code), by = "country")
  debarred_countries$alpha_2_code[debarred_countries$Country == "United States"] <-
    "US"
  debarred_countries$alpha_2_code[debarred_countries$Country == "Moldova"] <-
    "MD"
  logger::log_info("{function_name}: There are {nrow(debarred_countries)} countries")

  debarred_countries_freq <-
    df_bidders %>% filter(country_code %in% debarred_countries$alpha_2_code)
} else {
  logger::log_info("{function_name}: Processing all bidders in {country_code} for legal forms")

}

df_bidders <- plyr::count(df_bidders, 'bidder_name')
df_bidders <-
  cleaning_bidders(df = df_bidders,
                            var_name = 'bidder_name',
                            country_code = country_code, type = 'procurement')

df_bidders <-
  fix_legal_forms(df = df_bidders,
                  legalforms = company_legalforms,
                  country_code = country_code, type = 'procurement')
df_bidders <- df_bidders %>%
  select(bidder_name, bidder_name_edited)
df_bidders_d <- plyr::count(df_bidders, 'bidder_name_edited') %>%
  rename(df_bidders_freq = 2)
df_bidders_merged <- df_bidders_d %>%
  left_join(debarred.bidders, by = "bidder_name_edited")
df_bidders_merged <- df_bidders_merged %>%
  filter(
    !bidder_name_edited %in% c(
      "md abul hossain",
      "gonzalo celorio morayta",
      "md alamgir jahan",
      "mirza aminul islam",
      "md abdur razzak"
    )
  ) %>% # drop the entrepreneur(s)
  filter(bidder_name_edited != '') %>%
  filter(is.na(debarred_count) == FALSE) # drop non matches

logger::log_info("{function_name}: Merging debarment data to PP data using cleaned bidder name")
df_final <- df_bidders_merged %>%
  left_join(debarment)
logger::log_info("{function_name}: Standardizing column names")
df_final <- df_final %>%
  rename(startDate = sanction.startdate) %>%
  rename(endDate = sanction.enddate) %>%
  rename(name = sanction.authority.name) %>%
  group_by(bidder_name_edited) %>%
  add_count(name = "bidder_sanction_times") %>%
  select(
    bidder_name_edited,
    id,
    entity.name,
    country,
    bidder_sanction_times,
    startDate,
    endDate,
    name,
    df_bidders_freq
  )

# order by name, and date first to last
logger::log_info("{function_name}: ordering debarred bidders by name, and date first to last")
df_final <- df_final %>%
  arrange(bidder_name_edited, startDate) %>%
  filter(is.na(df_bidders_freq) == FALSE)

logger::log_info("{function_name}: Fixing missing sanctioning authority for UG, ID, and MX")
df_final$name[df_final$name == "Uganda"] <-
  "The Public Procurement and Disposal of Public Assets Authority"
df_final$name[df_final$id == 'indb.en.csv'] <-
  'Lembaga Kebijakan Pengadaan Barang/Jasa Pemerintah'
df_final$name[df_final$id == 'mex01.en.csv'] <-
  'Comisión Federal de Competencia Económica'


# remove unwanted variables such as counts, and add count of bidders within sanctions "n_row"
df_final <- df_final %>%
  ungroup() %>%
  group_by(bidder_name_edited) %>%
  mutate(n_row = row_number()) %>%
  select(-df_bidders_freq) %>%
  select(bidder_name_edited, everything())
df_final <- df_final %>%
  mutate(bidder_hasSanction = 'true') %>%
  mutate(bidder_previousSanction = ifelse(n_row > 1, 'true', 'false')) %>%
  select(-n_row)

# get the original names from PP data
df_bidders_n <-
  plyr::count(df_bidders, c("bidder_name", "bidder_name_edited"))

logger::log_info("{function_name}: Reshaping data")
df_final_reshaped <- df_final %>%
  left_join(df_bidders %>% select(1, 2), by = "bidder_name_edited") %>%
  ungroup() %>%
  mutate(n = row_number()) %>%
  select(
    bidder_name,
    startDate,
    endDate,
    name,
    bidder_hasSanction,
    bidder_previousSanction,
    n
  )

file_name <-
  sprintf(
    "output/data/%s_sanctions.csv",
    country_code
  )
logger::log_info("{function_name}: Exporting to {file_name}")
write_excel_csv(x = df_final_reshaped, file = file_name, na = "")
