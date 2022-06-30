#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("country_code must be supplied", call.=FALSE)
} else {
  message(sprintf("collecting bidder names for %s", args[1]))
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
function_name <- "collect_bidder_names"
country_code <- args[1]

global_functions <- source("codes/functions/functions.R")
log_file <- 'debarment'
config <- setup_config(log_file = log_file)
logger::log_info("{function_name}: running {log_file} for {country_code}")

# Collecting bidder names ----
logger::log_info("{function_name}: Loading bidder names")
file <- sprintf("../utility_data/country/%s/%s_mod.csv", country_code, country_code)
df <- read_csv(file, col_types = cols(.default = col_character()), show_col_types = FALSE, col_select = "bidder_name")
logger::log_info("{function_name}: collecting bidder names")
df <- plyr::count(df, "bidder_name")
logger::log_info("{function_name}: exporting bidder names")
write_excel_csv(df, sprintf("input/bidder_names/%s_bidders.csv", country_code))
logger::log_info("{function_name}: exporting bidder names done")
