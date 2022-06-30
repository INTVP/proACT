args = commandArgs(trailingOnly=TRUE)
setwd(args[1])

print("Running code")

# Code to get structured cities for the IDB data

# Packages 
# Load and Install libraries ----

# FIRST: check if pacman is installed. 
# This package installs and loads other packages
if (!require(pacman)) {
  install.packages("pacman", dependencies = TRUE)
}

# SECOND: list all other packages that will be used
# Add libraries as needed here.
# Please also add the reason why this library is added
packages <- c(
  "tidyverse"
)  

# THIRD: installing and loading the packages
# The following lines checks if the libraries are installed.
# If installed, they will be loaded.
# If not, they will be installed then loaded.
p_load(
  packages, 
  character.only = TRUE, 
  depencies = TRUE
)

options(warn=0) # suppress warnings OFF

#library("dplyr", lib.loc="~/R/win-library/3.6")

# Load the data for the analysis
df_city <-
  read_csv(
    'IDB_forcityapi.csv',
    col_names = TRUE 
    )


# city cleaning =====================================================================
# Functions for geo encoding
#___________________________________________________________________________________
# generate a url for HERE api geo mapping
get_url <- function(x, language = tolower('en')) {
  # generate a url for HERE api geo mapping
  apiKey <- ''  #enter apiKey
  
  base_url <- "https://geocoder.ls.hereapi.com/search/6.2/geocode.json"
  print(x)
  output <- httr::GET(base_url,
                      query = list(language = language,
                                   apiKey = api_key,
                                   searchtext = x))
  return(output)
}
#___________________________________________________________________________________
# get the respose of the link
response_url <- function(x) {
  # get the respose of the link
  output <- httr::content(x)
  return(output)
}
#___________________________________________________________________________________
# takes the response link and returns the captured city name when available
new_city <- function(x, address) {
  # takes the response link and returns the captured city name when available
  check <- x
  print(paste("input:",address, sep = " "))
  if (length(check[["Response"]][["View"]])>0) {
    try(city <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["City"]])
    
    if (is.null(city)==TRUE | length(city)==0) {
      address <- gsub('[[:digit:]]', '', address)
      print(address)
      check <- get_url(address)
      check <- response_url(check)
      try(city <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["City"]])
      print(paste('using city level try 2 value:', city, sep = " "))
      return(city)
    } else {
      print(paste('using city level value:',city,sep = " "))
      return(city)
    }
    
  } else {
    address <- gsub('[[:digit:]]', '', address)
    print(address)
    check <- get_url(address)
    check <- response_url(check)
    if (length(check[["Response"]][["View"]])>0) {
      try(city <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["City"]])
      print(paste('using city level try 3 value:', city, sep = " "))
      return(city)
    } else {
      print(paste("ERROR:",address,"NOT FOUND", sep = " "))
      return(paste("ERROR:",address,"NOT FOUND", sep = " "))
    }
  }
  
}
#___________________________________________________________________________________
# takes the response link and returns the captured district name when available
new_district <- function(x, address) {
  # takes the response link and returns the captured city name when available
  check <- x
  print(paste("input:",address, sep = " "))
  if (length(check[["Response"]][["View"]])>0) {
    try(district <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["District"]])
    
    if (is.null(district)==TRUE | length(district)==0) {
      address <- gsub('[[:digit:]]', '', address)
      print(address)
      check <- get_url(address)
      check <- response_url(check)
      try(district <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["District"]])
      print(paste('using city level try 2 value:', district, sep = " "))
      return(district)
    } else {
      print(paste('using city level value:',district,sep = " "))
      return(district)
    }
    
  } else {
    address <- gsub('[[:digit:]]', '', address)
    print(address)
    check <- get_url(address)
    check <- response_url(check)
    if (length(check[["Response"]][["View"]])>0) {
      try(district <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["District"]])
      print(paste('using city level try 3 value:', district, sep = " "))
      return(district)
    } else {
      print(paste("ERROR:",address,"NOT FOUND", sep = " "))
      return(paste("ERROR:",address,"NOT FOUND", sep = " "))
    }
  }
  
}
#___________________________________________________________________________________
# takes the response link and returns the captured county name when available
new_county <- function(x, address) {
  # takes the response link and returns the captured city name when available
  check <- x
  print(paste("input:",address, sep = " "))
  if (length(check[["Response"]][["View"]])>0) {
    try(county <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["County"]])
    
    if (is.null(county)==TRUE | length(county)==0) {
      address <- gsub('[[:digit:]]', '', address)
      print(address)
      check <- get_url(address)
      check <- response_url(check)
      try(county <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["County"]])
      print(paste('using city level try 2 value:', county, sep = " "))
      return(county)
    } else {
      print(paste('using city level value:',county,sep = " "))
      return(county)
    }
    
  } else {
    address <- gsub('[[:digit:]]', '', address)
    print(address)
    check <- get_url(address)
    check <- response_url(check)
    if (length(check[["Response"]][["View"]])>0) {
      try(county <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["County"]])
      print(paste('using city level try 3 value:', county, sep = " "))
      return(county)
    } else {
      print(paste("ERROR:",address,"NOT FOUND", sep = " "))
      return(paste("ERROR:",address,"NOT FOUND", sep = " "))
    }
  }
  
}
#___________________________________________________________________________________
# takes the response link and returns the captured state name when available
new_state <- function(x, address) {
  # takes the response link and returns the captured city name when available
  check <- x
  print(paste("input:",address, sep = " "))
  if (length(check[["Response"]][["View"]])>0) {
    try(state <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["State"]])
    
    if (is.null(state)==TRUE | length(state)==0) {
      address <- gsub('[[:digit:]]', '', address)
      print(address)
      check <- get_url(address)
      check <- response_url(check)
      try(state <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["State"]])
      print(paste('using city level try 2 value:', state, sep = " "))
      return(state)
    } else {
      print(paste('using city level value:',state,sep = " "))
      return(state)
    }
    
  } else {
    address <- gsub('[[:digit:]]', '', address)
    print(address)
    check <- get_url(address)
    check <- response_url(check)
    if (length(check[["Response"]][["View"]])>0) {
      try(state <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["State"]])
      print(paste('using city level try 3 value:', state, sep = " "))
      return(state)
    } else {
      print(paste("ERROR:",address,"NOT FOUND", sep = " "))
      return(paste("ERROR:",address,"NOT FOUND", sep = " "))
    }
  }
  
}
#___________________________________________________________________________________
# takes the response link and returns the captured country name when available
new_country <- function(x, address) {
  # takes the response link and returns the captured country name when available
  check <- x
  print(paste("input:",address, sep = " "))
  if (length(check[[1]][["Response"]][["View"]])>0|length(check[["Response"]][["View"]])>0) {
    try(country <- check[[1]][["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["Country"]])
    
    if (is.null(country)==TRUE | length(country)==0) {
      try(country <- check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["Country"]])
      return(country)
    }
  }
}


#___________________________________________________________________________________
# the distribution
cities <- plyr::count(df_city,c("city_country", "id_city"))

#_______________________________________________________________________________________________
#_______________________________________________________________________________________________
# geo mapping the city[county] names using HERE API

# getting the base URL
# countrycode <- 'en'
cities$base_url <- NA 
cities$base_url <-lapply(X = cities$city_country,FUN = get_url)

# Requesting the API city name
cities$response <- NA
cities$response <- lapply(X = cities$base_url,FUN = response_url)

# Extracting the name of the city
cities$new_name <- NA
cities$new_name <- mapply(FUN = new_city,
                          x = cities[,'response'],
                          address = cities[,"city_country"])
cities$new_name <- as.character(cities$new_name)

cities$district <- NA
cities$district <- mapply(FUN = new_district,
                          x = cities[,'response'],
                          address = cities[,"city_country"])
cities$district <- as.character(cities$district)

cities$county <- NA
cities$county <- mapply(FUN = new_county,
                        x = cities[,'response'],
                        address = cities[,"city_country"])
cities$county <- as.character(cities$county)

cities$state <- NA
cities$state <- mapply(FUN = new_state,
                       x = cities[,'response'],
                       address = cities[,"city_country"])
cities$state <- as.character(cities$state)

cities$country <- NA
cities$country <- mapply(FUN = new_country,
                         x = cities[,'response'],
                         address = cities[,"city_country"])
cities$country <- as.character(cities$country)

cities_out <- cities %>% select(-base_url,-response)
cities_out <- rename(cities_out, api_city = new_name)
cities_out <- rename(cities_out, api_district = district)
cities_out <- rename(cities_out, api_county = county)
cities_out <- rename(cities_out, api_state = state)
cities_out <- rename(cities_out, api_country = country)

cities_out <- cities_out %>% filter(city_country!="")

#Replace Errors with NA -- they will be replaced with the city_edit anyway - no new information available
cities_out$api_city[grepl("^ERROR", cities_out$api_city)] <- NA
cities_out$api_district[grepl("^ERROR", cities_out$api_district)] <- NA
cities_out$api_county[grepl("^ERROR", cities_out$api_county)] <- NA
cities_out$api_state[grepl("^ERROR", cities_out$api_state)] <- NA

#Set working directory
#setwd()
write.csv2(cities_out,"IDB_fromR.csv", fileEncoding = "UTF-8")

