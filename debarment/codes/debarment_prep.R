#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("HERE_API_KEY must be supplied", call. = FALSE)
} else {
  message("running debarment data cleaning")
}
# load libraries
library(dplyr, warn.conflicts = F, quietly = T) # data wrangling
library(readxl, warn.conflicts = F, quietly = T) # read EXCEL files
library(httr, warn.conflicts = F, quietly = T) # read EXCEL files
library(readr, warn.conflicts = F, quietly = T) # read CSV and TXT files
library(lubridate, warn.conflicts = F, quietly = T) # date manipulation
library(stringr, warn.conflicts = F, quietly = T) # string cleaning
library(stringi, warn.conflicts = F, quietly = T) # string cleaning
library(logger, warn.conflicts = F, quietly = T) # logging
library(properties, warn.conflicts = F, quietly = T) # read system properties
library(snakecase, warn.conflicts = F, quietly = T) # fix column nameslibrary(dplyr) # data wrangling
library(magrittr, warn.conflicts = F, quietly = T)
# Global variables ----
function_name <- "debarment_prep"
api_key <- args[1]

global_functions <- source("codes/functions/functions.R")
log_file <- 'debarment_prep'
config <- setup_config(log_file = log_file)
logger::log_info("{function_name}: running debarment data cleaning")


# Importing the EU countries_list names ----
output_wd <- "output"
global_functions <- source("codes/functions/functions.R")
# WB countries list
logger::log_info("{function_name}: Loading WB countries list")
WB_countries <-
  read.csv("configuration/wb_countries.txt", header = FALSE)
# loading countries_codes country names and codes for filtering the data
countries_codes <-
  read_excel("configuration/countries_codes.xlsx", sheet = 1)

colnames(countries_codes)[2] <- 'country code'
countries_codes$`country code` <-
  as.character(countries_codes$`country code`)
countries_codes$Country <- as.character(countries_codes$Country)
countries_codes$`Alpha-3 code` <-
  as.character(countries_codes$`Alpha-3 code`)
# Import all the debarment data sets ----
logger::log_info("{function_name}: Importing debarment CSVs...")
files.list <-
  list.files(path = "input/csv/",
             full.names = TRUE,
             pattern = "*.csv")
debarment.df <-
  lapply(files.list, function(file)
    read_csv(file, col_types = cols(.default = col_character())))
files.list <- substring(files.list, 14, )
debarment.df <-
  setNames(debarment.df, files.list) # assign file names
logger::log_info("{function_name}: binding all the data sets together and add their name as ID")
debarment.df <-
  bind_rows(debarment.df, .id = 'id') # bind all the data sets together and add their name as ID
# Preliminary cleaning for the countries_list ----
logger::log_info("{function_name}: Preliminary cleaning of countries")
countries <-
  plyr::count(debarment.df, c("entity.address.country")) %>%
  mutate(entity.address.country.clean = tolower(entity.address.country)) %>% # lowercase
  mutate(entity.address.country.clean = gsub("b\\'|\\'", "", entity.address.country.clean)) %>% #remove odd wrappers
  mutate(entity.address.country.clean = str_squish(entity.address.country.clean)) # remove spaces
# cleaning names
# Manual cleaning
logger::log_info("{function_name}: Implementing manual cleaning steps...")
logger::log_info("{function_name}: steps can be found in codes/functions.R (clean_countries)")

countries <- clean_countries(countries)

# removing punctuation
# Categories definition: -----
logger::log_info("{function_name}: Implementing country cleaning steps by category")

logger::log_info("{function_name}: Category 1 Has a country and cleaned")
# 1 <- Has a country and cleaned
# 2 <- Non ADB Member Country, Cleaned using address & API
# 3 <- Non ADB Member Country, Cleaned using Reg-ex Countries pattern
# 4 <- Other countries_list (MX,PH,PK,UG)
# flag the ones that explicitly has more than one country (category 1) ----
logger::log_info("{function_name}: flag the ones that explicitly has more than one country (category 1)")
countries$HasMoreThanOneCountry <-
  grepl(
    "\\/",
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )
logger::log_info("{function_name}: Exclude these from the cleaning process")
# Exclude these from the cleaning process
countries$entity.address.country.clean[countries$HasMoreThanOneCountry ==
                                         F] <-
  gsub("[[:punct:]]", "", countries$entity.address.country.clean[countries$HasMoreThanOneCountry ==
                                                                   F])
countries <- countries %>%
  mutate(entity.address.country.clean = str_squish(entity.address.country.clean)) # remove extra spaces
# Flag the ones that has a country and cleaned
logger::log_info("{function_name}: Flag the ones that has a country and cleaned")
countries <- countries %>%
  mutate(
    category = ifelse(
      test = entity.address.country == "Non ADB Member Country" |
        entity.address.country == "b'None'",
      yes = NA,
      no = 1
    )
  )
countries.copy <- countries
# putting category 1 back to debarment.df
countries.copy <- countries.copy %>%
  filter(is.na(category) == F) %>%
  select(
    entity.address.country,
    entity.address.country.clean,
    HasMoreThanOneCountry,
    category
  ) %>%
  rename(country.final = entity.address.country.clean)
debarment.df.final <- debarment.df %>%
  left_join(countries.copy, by = "entity.address.country")
logger::log_info("{function_name}: Category 1 done")
# Selecting Non ADB Member Countries ----
logger::log_info("{function_name}: Category 2 Non ADB Member Country, Cleaned using address & API")
debarment.df2 <- debarment.df %>%
  filter(
    entity.address.country == "Non ADB Member Country" |
      entity.address.country == "b'None'"
  )
# Get the raw addresses to extract countries_list
logger::log_info("{function_name}: Get the raw addresses to extract countries")
countries2 <- plyr::count(debarment.df2, c("entity.address.raw"))

# FIXING COUNTRY NAMES ----
# changing it to country name from country code
#...............................................................................................
logger::log_info("{function_name}: Cleaning countries using API...")
lang = 'en'

countries2$base_url <- NA
countries2$base_url <- mapply(FUN = get_url,
                              x = countries2[, 'entity.address.raw'],
                              api_key = api_key)
# Requesting the API country name
countries2$response <- NA
countries2$response <-
  lapply(X = countries2$base_url, FUN = response_url)
# Extracting the name of the city
countries2$new_name <- NA
countries2$new_name <- mapply(FUN = new_country,
                              x = countries2[, 'response'],
                              address = countries2[, 'entity.address.raw'])
countries2$new_name <- as.character(countries2$new_name)

# MANUAL FIXES
logger::log_info("{function_name}: Cleaning countries using API...Implementing manual fixes")
countries2 <-
  countries2 %>% select(-3, -4) # keep only the address and the country
# Flag the ones that got matched as group 2
countries2 <- countries2 %>%
  mutate(category = ifelse(
    test = new_name != "NULL",
    yes = 2,
    no = NA
  ))
# Get the names of the countries_list
countries2 <-
  countries2 %>% left_join(countries_codes %>% select(1, 3) %>% rename(new_name = 2) , by = "new_name") # Join the countries_list to get fullname
logger::log_info("{function_name}: Cleaning countries using API...final cleaning")
countries2$Country <-
  gsub("\\(.*\\)|United Republic of| State of|\\,",
       "",
       countries2$Country) # a bit of cleaning
countries2$Country <-
  str_squish(tolower(countries2$Country)) # lowercase & remove extra spaces for countries_list
countries2$entity.address.raw.edited <-
  str_squish(tolower(countries2$entity.address.raw)) # lowercase & remove extra spaces for addresses
logger::log_info("{function_name}: Cleaning countries using API...done")
logger::log_info("{function_name}: Category 2 done")

# create a list of countries_list to use to get the countries_list that were not captured using the API
logger::log_info("{function_name}: Category 3 Non ADB Member Country, Cleaned using Reg-ex Countries pattern")
pattern <-
  tolower(paste(str_squish(
    gsub(
      "\\(.*\\)|United Republic of| State of|\\,",
      "",
      countries_codes$Country
    )
  ), collapse = "|"))
# create a copy to filter it
countries2.copy <- countries2
# Using Reg-ex, Match those that were not captured using API ----
countries2.copy$Country2[countries2.copy$new_name == 'NULL'] <-
  str_extract(countries2.copy$entity.address.raw.edited[countries2.copy$new_name ==
                                                          'NULL'], pattern)
# Flag the ones that got matched as group 3
countries2.copy <- countries2.copy %>%
  filter(is.na(Country) == T) %>%
  mutate(category = ifelse(
    test = new_name == "NULL" & is.na(Country2) == F,
    yes = 3,
    no = 0
  ))
logger::log_info("{function_name}: Category 3 done")
# Putting category 2 & 3 together ----
logger::log_info("{function_name}: Putting all first 3 categories together")
countries2.copy2 <- countries2 %>% filter(is.na(Country) == F)
countries2.copy3 <- bind_rows(countries2.copy, countries2.copy2)
nrow(countries2.copy) + nrow(countries2.copy2)
nrow(countries2)
countries2.copy3 <- countries2.copy3 %>%
  mutate(country.final = coalesce(Country, Country2))
colnames(countries2.copy3)
countries2.copy3 <- countries2.copy3 %>%
  select(entity.address.raw, category, country.final)
# Putting countries2.copy3 back to debarment.df2
debarment.df2.final <- debarment.df2 %>%
  left_join(countries2.copy3, by = "entity.address.raw")
#Putting the data sets back together ----
debarment.final.temp <- debarment.df.final %>%
  filter(!entity.address.country %in% c("Non ADB Member Country", "b'None'")) %>% # filter out category 2,3
  bind_rows(debarment.df2.final)
# clean the rest of the categories
logger::log_info("{function_name}: Category 4 Other `countries_list` (MX,PH,PK,UG)")
debarment.final.temp2 <- debarment.final.temp %>%
  mutate(
    country.final2 = case_when(
      id %in% c('mex01.en.csv', 'mex02.en.csv') ~ 'Mexico',
      id == 'pakdb.en.csv' ~ 'Pakistan',
      id == 'phildb.csv' ~ 'Philippines',
      id == 'uga.en.csv' ~ 'Uganda'
    )
  ) %>%
  mutate(country.final3 = coalesce(country.final2, country.final))

# set category 4: Other countries_list (MX,PH,PK,UG)
debarment.final.temp2$category[is.na(debarment.final.temp2$category) == T] <-
  4
plyr::count(debarment.final.temp2, "category")
debarment.final.temp2$category_text <-
  recode(
    debarment.final.temp2$category,
    '0' = 'NA',
    '1' = "Has a country and cleaned",
    '2' = "Non ADB Member Country, Cleaned using address & API",
    '3' = "Non ADB Member Country, Cleaned using Regex Countries pattern",
    '4' = "Other countries (MX,PH,PK,UG)"
  )
plyr::count(debarment.final.temp2 %>% filter(category == 4),
            "country.final3")
plyr::count(debarment.final.temp2, "category_text")
# put all countries_list in sentence case
debarment.final.temp2$country <-
  str_to_title(debarment.final.temp2$country.final3)
# final cleaning
debarment.final.temp2$country <-
  gsub('\u200B', '', debarment.final.temp2$country, perl = T)
logger::log_info("{function_name}: Category 4 done")
# Flag the WB_countries
logger::log_info("{function_name}: Flagging WB_countries with procurement data")
WB_countries <- WB_countries$V1
debarment.final.temp2 <- debarment.final.temp2 %>%
  mutate(IsWB_country = ifelse(test = country %in% x,
                               TRUE, FALSE))
plyr::count(debarment.final.temp2, "IsWB_country")
x <-
  plyr::count(debarment.final.temp2, c("IsWB_country", "category_text"))
x <-
  plyr::count(debarment.final.temp2 %>% filter(IsWB_country == TRUE),
              c("country"))
sum(debarment.final.temp2$IsWB_country == T) / nrow(debarment.final.temp2) * 100
x <- plyr::count(debarment.final.temp2, "country")
# Exporting ----
logger::log_info("{function_name}: exporting to output/debarrment_cleaned.csv")
write_excel_csv(debarment.final.temp2, "output/debarrment_cleaned.csv")
logger::log_info("{function_name}: All done!")
