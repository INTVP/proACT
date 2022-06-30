setup_config <- function(log_file) {
  #' Configuration function
  #' @param log_file character. The name of the log file
  #'
  #' @description Setting up configuration and logging for the current session.
  #' @keywords configuration linux
  #' @export
  #' @return NULL
  #' @usage
  #' setup_logging()
  #' @examples
  #' config <- setup_logging()
  #'
  function_name <- "setup_logging"

  config <-
    properties::read.properties(paste0("configuration//runtime.txt"))
  if (dir.exists('logs')) {
    log_info("{function_name}: logging directory exists")

  } else {
    dir.create('logs')
    log_info("{function_name}: Creating logs directory")
  }
  #
  if (config$log_to_file) {
    log_file <-
      paste0(getwd(),
             config$log_dir,
             log_file,
             format(Sys.time(), "%Y%m%d_%H%M%S"),
             ".log")
    log_info("{function_name}: set up logging into file: {log_file}")
    log_appender(
      appender_tee(
        log_file,
        append = TRUE,
        max_lines = Inf,
        max_bytes = 5000000,
        max_files = 1L
      )
    )
  }
  return(config)
}

get_url <- function(x, language = "en", api_key) {
  #' @title Get URL
  #' @description generate a url for HERE api geo mapping
  #'
  #' @param x character. Address name to be sent to the API.
  #' @param language character. The language of returned result. Default is 'en'
  #' @param api_key character.Your Nokia HERE API Key
  #' @return list. The request body to be sent to \link{response_url}
  #' @export
  #'
  # generate a url for HERE api geo mapping
  language <- tolower(language)

  base_url <- "https://geocoder.ls.hereapi.com/6.2/geocode.json"
  # print(x)
  output <- httr::GET(base_url,
                      query = list(
                        language = lang,
                        apiKey = api_key,
                        searchtext = x
                      ))
  return(output)
}
response_url <- function(x) {
  #' @title Response URL
  #' @description Generate response URL acquired from HERE API Geo-mapping.
  # get the response of the link
  output <- httr::content(x)
  return(output)
}

new_country <- function(x, address) {
  # takes the response link and returns the captured country name when available
  #' @description Parse \link{response_url} to a cleaned country name if available.
  #'
  #' @param x list. The returned list (JSON) from \link{get_url}.
  #' @param address character. the original address used in \link{response_url}.
  check <- x
  print(paste("input:", address, sep = " "))
  if (length(check[[1]][["Response"]][["View"]]) > 0 |
      length(check[["Response"]][["View"]]) > 0) {
    try(country <-
          check[[1]][["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["Country"]])

    if (is.null(country) == TRUE | length(country) == 0) {
      try(country <-
            check[["Response"]][["View"]][[1]][["Result"]][[1]][["Location"]][["Address"]][["Country"]])
      return(country)
    }
  }
}

clean_countries <- function(.data) {
  #' Clean countries
  #'
  #' @param .data data.frame. The data frame containing country strings
  #'
  #' @return data.frame. countries with cleaned names
  #' @export
  #'
  #' @examples
  function_name <- 'clean_countries'
  .data <- countries
  logger::log_info("{function_name}: cleaning countries...")
  countries$entity.address.country.clean[grepl(
    'brazil',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'brazil'
  countries$entity.address.country.clean[grepl(
    '\\bes\\b',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'spain'
  countries$entity.address.country.clean[grepl(
    'chinese',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'china'
  # Removing extra terms, such as Republic, Democratic, etc..
  regex_p <-
    "\\brep\\.?\b|(\\bdemocratic\\b)|(\\barab\\b)|(\\bsocialist\\b)|(\\bpeoples\\b)|\\brepublic(a)?\\b|(bolivariana de)|(\\bof\\b)|(\\bthe\\b)|(\\bdemocratic\\b)|(\\brep\\b)|, rep\\. of"
  countries$entity.address.country.clean[grepl(regex_p, countries$entity.address.country.clean)]
  countries$entity.address.country.clean[grepl(regex_p, countries$entity.address.country.clean)] <-
    gsub(regex_p, "", countries$entity.address.country.clean[grepl(regex_p, countries$entity.address.country.clean)])

  countries$entity.address.country.clean[grepl(
    'united (arab)? emirates',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'united arab emirates'
  countries$entity.address.country.clean[grepl(
    'dominican',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'dominican republic'
  countries$entity.address.country.clean[grepl(
    'hong kong',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'hong kong'
  countries$entity.address.country.clean[grepl(
    'kyrgyz',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'kyrgyzstan'
  countries$entity.address.country.clean[grepl(
    'morroco',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'morocco'
  countries$entity.address.country.clean[grepl(
    'rahman colony',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'bangladesh'
  countries$entity.address.country.clean[grepl(
    'russia',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'russian federation'
  countries$entity.address.country.clean[grepl(
    'ukrain',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'ukraine'
  countries$entity.address.country.clean[grepl(
    '\\buk\\b',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'united kingdom'
  countries$entity.address.country.clean[grepl(
    '\\busa\\b',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'united states'
  countries$entity.address.country.clean[grepl(
    'viet nam',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    'vietnam'
  countries$entity.address.country.clean[grepl(
    'none|unknown',
    countries$entity.address.country.clean,
    perl = T,
    ignore.case = T
  )] <-
    NA
  return(countries)
}

cleaning_bidders <- function(df, var_name, country_code, type) {
  #' Cleaning debarred bidders
  #'
  #' @param df data.frame. The debarment data set or bidder names data set containing `bidder_name`
  #' @param var_name character. Variable name of `bidder_name`
  #' @param countrycode ISO-2 country code. Used to apply country-specific fixes
  #' @param trpe character. Either debarment or procurement. This define which country specific codes will apply.
  #' @return debarment or bidder names data.frame with `bidder_name_edited` cleaned
  #' @export
  #'
  #' @examples
  function_name <- 'cleaning_bidders'

  df$bidder_name_edited <- tolower(df[[var_name]])
  if (var_name == 'entity.name') {
    logger::log_info("{function_name}: cleaning countries...")

    pattern <-
      "\\(?Reg.*|\\(?Fiscal Code.*|\\(?KvK.*|\\(?N\\°.*|\\*\\d{1,3}|\\(THE\\)|MUMBAI|GHAZIABAD|\\(INDIA\\)|\\(bangladesh.*|tbilisi|\\*|Turkey|\\/|b\\'|reef$"
    df$bidder_name_edited <-
      gsub(pattern,
           "",
           df$bidder_name_edited,
           perl = T,
           ignore.case = T)
    df$bidder_name_edited[grepl('nihon kohden deutschland', df$bidder_name_edited)] <-
      "nihon kohden deutschland gmbh"

  }
  mod_file <- sprintf(
    "codes/functions/country_specific/bidder_cleaning/%s_%s_cleaning.R",
    country_code,
    type
  )
  is_country_specific_modifications <-
    file.exists(mod_file)
  if (is_country_specific_modifications) {
    logger::log_info("{function_name}: country modification exists for {type} {country_code}")
    logger::log_info("{function_name}: Applying country modifications for {type} {country_code}")
    source(mod_file,
           local = TRUE)
  } else {
    logger::log_info("{function_name}: country modification does not exists for {type} {country_code}")

  }


  logger::log_info("{function_name}: Processing standard cleaning...")
  df$bidder_name_edited <-
    str_squish(df$bidder_name_edited)
  df$bidder_name_edited <-
    gsub("\"", "", df$bidder_name_edited)
  df$bidder_name_edited <-
    gsub("http\\S+\\s*", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\.", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\„", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\“", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\‚", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\‘", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\»", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\«", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\›", "", df$bidder_name_edited, perl = TRUE)
  df$bidder_name_edited <-
    gsub("\\‹", "", df$bidder_name_edited, perl = TRUE)
  logger::log_info("{function_name}: Processing standard cleaning done")
  return(df)

}

fix_legal_forms <-
  function(df, legalforms, country_code, type = 'debarment') {
    #' Fix legal forms
    #'
    #' @param df data.frame. The debarment data set or bidder names data set containing `bidder_name_edited`
    #' from \link{cleaning_debarred_bidders}
    #' @param legalforms data.frame. the legal forms data set
    #' @param countrycode ISO-2 country code. Used to apply country-specific fixes
    #'
    #' @return debarment or bidder names data.frame with `bidder_name_edited` cleaned
    #' @export
    #'
    #' @examples
    function_name <- "fix_legal_forms"
    df$bidder_name_edited <-
      str_squish(df$bidder_name_edited)
    if (country_code %in% c("IDB", "WB")) {
      logger::log_info(
        "{function_name}: Fixing legal forms for {country_code} using all countries' legal forms"
      )
      legalforms_full <-
        lapply(company_legalforms, function(x)
          unique(x[!is.na(x)]))
      legalforms_full <- unique(purrr::flatten(legalforms_full[-1]))
      legalforms_full <- unlist(legalforms_full)
      legalforms <- tolower(legalforms_full)
    } else {
      logger::log_info("{function_name}: Fixing legal forms for {country_code}")
      company_legalforms <- company_legalforms %>%
        filter(Country == country_of_interest) %>%
        select_if(function(x)
          ! (all(is.na(x)) | all(x == "")))
      legalforms <- tolower(company_legalforms[,-1])
    }
    legalforms <- stri_trans_general(legalforms, "latin-ascii")
    legalforms <- gsub("\\.", "", legalforms)
    legalforms <- unique(legalforms)
    legalforms <-
      as.data.frame(legalforms) %>% mutate_all(as.character)
    legalforms <-
      legalforms %>% mutate(has_space = str_count(legalforms, "\\s")) %>% arrange(desc(has_space))
    legalforms <- as.character(legalforms[, 1])

    legalforms <- unique(legalforms)


    for (legalform in legalforms) {
      if (sapply(strsplit(legalform, " "), length) > 1) {
        logger::log_info("{function_name}: legal forms has space: {legalform}")
        # print(paste("has space:", legalform))
        # reg-ex pattern
        legalform_2 <- paste("\\b", legalform, "\\b(?!-)", sep = "")
        legalform_2 <- gsub("\\s", "\\\\s?", legalform_2)
        legalform_2 <- gsub("&", "(&|_)", legalform_2)

        # remove spaces and add brackets
        legalform_new <-
          paste("(", gsub("\\s", "", legalform), ")", sep = "")
        df$bidder_name_edited <- gsub(legalform_2,
                                      toupper(legalform_new),
                                      df$bidder_name_edited,
                                      perl = TRUE)
        # if it starts with a form, remove that
        legalform_new_strat <- paste("^", legalform_2, sep = "")
        # df$bidder_name_edited <- gsub(legalform_new_strat,
        #                               toupper(legalform_new),
        #                               df$bidder_name_edited)
        df$bidder_name_edited <- gsub(legalform_new_strat,
                                      "",
                                      df$bidder_name_edited,
                                      perl = T)

      } else {
        logger::log_info("{function_name}: legal forms has NO space: {legalform}")
        # print(paste("has NO space:", legalform))
        # reg-ex pattern

        legalform_2 <- paste("\\b", legalform, "\\b(?!-)", sep = "")
        # remove spaces and add brackets
        legalform_new <-
          paste("(", gsub("\\s|[[punct:]]", "", legalform), ")", sep = "")
        df$bidder_name_edited <- gsub(legalform_2,
                                      legalform_new,
                                      df$bidder_name_edited,
                                      perl = TRUE)
        # if it starts with a form, remove that
        legalform_new_strat <- paste("^", legalform_2, sep = "")
        # df$bidder_name_edited <- gsub(legalform_new_strat,
        #                               toupper(legalform_new),
        #                               df$bidder_name_edited)
        df$bidder_name_edited <- gsub(legalform_new_strat,
                                      "",
                                      df$bidder_name_edited,
                                      perl = T)
      }

    }

    legalforms_noSpace <-  gsub("\\s", "", legalforms)
    legalforms_noSpace <- unique(legalforms_noSpace)

    # change everything back to lowercase
    df$bidder_name_edited <-
      tolower(df$bidder_name_edited)
    df$bidder_name_edited <-
      str_squish(df$bidder_name_edited)
    mod_file <- sprintf(
      "codes/functions/country_specific/legal_forms/%s_%s_cleaning.R",
      country_code,
      type
    )
    is_country_specific_modifications <-
      file.exists(mod_file)
    if (is_country_specific_modifications) {
      logger::log_info("{function_name}: country modification exists for {type} {country_code}")
      logger::log_info("{function_name}: Applying country modifications for {type} {country_code}")
      source(mod_file,
             local = TRUE)
    } else {
      logger::log_info("{function_name}: country modification does not exists for {type} {country_code}")

    }

    return(df)
  }

