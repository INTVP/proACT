args = commandArgs(trailingOnly=TRUE)

#Setting Paths
setwd(args[1])
utility_data = args[2]

# setwd("C:/Ourfolders/Aly/ProACT-2020/country_codes/US")
utility_data = "C:/Ourfolders/Aly/ProACT-2020/utility_data"
#Libraries 
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
  "lfe", # Statistical models
  "foreign", #to export data frame in Stata data format
  "tidyverse", # general data wrangling
  "benford.analysis", # Benford's analysis
  "foreign" # export dta file
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


#Note - The compiled dataset was used for an earlier project - 
#most of the data preparation work such as renaming variables 
#where done in an older script. I will copy here all the relevant parts of the script 
#and leave them commented. The parts that are not commented are relevant for 
#the ProAct project

#Load Data
us_award_data_filtered <-
  read_csv(
    paste0(
    utility_data,
    "/country/US/starting_data/us_award_data_filtered.csv"
    )
  )

#Model 1
#v_corr_fv <-  felm(singleb ~  nocft + corr_proc + corr_solic + corr_overrun + corr_delay + lcv + commercial_item |
#                     msector + state_code + awarding_office_code + year | 0, 
#                   data=us_award_data_filtered, exactDOF = T)
#summary(v_corr_fv)


#summary(us_award_data_filtered$corr_proc)
#summary(us_award_data_filtered$corr_solic)

#combine procedure variables####

#Fixes tot he corr_proc and corr_solic indicators
us_award_data_filtered$corr_proc_old <-
  us_award_data_filtered$corr_proc

#summary(us_award_data_filtered$corr_proc_old)
us_award_data_filtered$corr_proc_old <-
  as.numeric(us_award_data_filtered$corr_proc_old) - 1
#summary(us_award_data_filtered$corr_proc_old)

us_award_data_filtered$corr_solic <-
  as.numeric(us_award_data_filtered$corr_solic) - 1
#summary(us_award_data_filtered$corr_solic)

#New corr_proc indicator
us_award_data_filtered$corr_proc <-
  as.factor(
    (us_award_data_filtered$corr_proc_old)/2 + (us_award_data_filtered$corr_solic)/2
    )

#summary(us_award_data_filtered$corr_proc)

#Model 2
#v_corr_fv <-  felm(singleb ~  nocft + corr_proc + corr_overrun + corr_delay + lcv + commercial_item |
#                     msector + state_code + awarding_office_code + year | 0, 
#                   data=us_award_data_filtered, exactDOF = T)
#summary(v_corr_fv)

#Benford's law####

#create filters for the applications of the law
# non-missing buyer_id
us_award_data_filtered$miss_buyerid <- 0
us_award_data_filtered$miss_buyerid[is.na(us_award_data_filtered$parent_award_agency_id)] <- 1
#summary(us_award_data_filtered$miss_buyerid)

# non-missing contract value
us_award_data_filtered$miss_cv <- 0
us_award_data_filtered$miss_cv[is.na(us_award_data_filtered$obligated_amount)] <- 1
#summary(us_award_data_filtered$miss_cv)

#at least 100 contracts

us_award_data_filtered <- 
  us_award_data_filtered %>% 
  group_by(parent_award_agency_id) %>% 
  mutate(
    ncon=n()
    )

us_award_data_filtered$con100 <- 0
us_award_data_filtered$con100[us_award_data_filtered$ncon > 100] <- 1
#summary(us_award_data_filtered$con100)

us_benford <- us_award_data_filtered %>% 
  filter(
    miss_buyerid==0&miss_cv==0&con100==1
    ) %>% 
  select(
    parent_award_agency_id,
    obligated_amount
    )
#rename(ca_value=obligated_amount)

# Function for calculation of Benford Variables
benford_f <- function(vector_in, output_name) {
  temp <- benford(
    data = c(vector_in),
    number.of.digits = 1,
    sign = "positive",
    discrete = TRUE,
    round = 3
  )[[output_name]]
  return(temp)
}

#Run the Benford script on data

buyers_proc_summary <- 
  us_benford %>%
  rename(parent_award_agency_id = 1) %>%
  rename(obligated_amount = 2) %>%
  select(1, 2)

buyers_proc_summary <- 
  buyers_proc_summary %>%
  group_by(
    parent_award_agency_id
    ) %>%
  summarise(
    MAD_conformitiy = benford_f(vector_in=obligated_amount,"MAD.conformity"),
    MAD = benford_f(vector_in=obligated_amount,"MAD")
    )

#Merge Benford results 

us_award_data_filtered <-
  merge(us_award_data_filtered,
        buyers_proc_summary,
        by = 'parent_award_agency_id',
        all.x = TRUE)

us_award_data_filtered$MAD_conformitiy <-
  as.factor(us_award_data_filtered$MAD_conformitiy)

#Model 3
#v_corr_fv2 <-  felm(singleb ~  nocft + corr_proc + MAD_conformitiy + corr_overrun + corr_delay + lcv + commercial_item |
#                      msector + state_code + awarding_office_code + year | 0, 
#                    data=us_award_data_filtered, exactDOF = T)
#summary(v_corr_fv2)

us_award_data_filtered$MAD10[!is.na(us_award_data_filtered$MAD)] <-
  factor(cut(
    rank(us_award_data_filtered$MAD[!is.na(us_award_data_filtered$MAD)], ties.method = "first"),
    quantile(
      rank(us_award_data_filtered$MAD[!is.na(us_award_data_filtered$MAD)], ties.method = "first"),
      prob = seq(0, 1, length = 11),
      type = 5,
      na.rm = FALSE
    ),
    include.lowest = TRUE,
    labels = c(1:10),
    exclude = NULL
  ))

us_award_data_filtered %>%
  group_by(MAD10) %>%
  summarise(mean = mean(MAD, na.rm = TRUE), N = n())

us_award_data_filtered$MAD10 [is.na(us_award_data_filtered$MAD)] <- 99

us_award_data_filtered$MAD10 <- as.factor(us_award_data_filtered$MAD10)

#Model 4
#v_corr_fv2 <-  felm(singleb ~  nocft + corr_proc + MAD10 + corr_overrun + corr_delay + lcv + commercial_item |
#                      msector + state_code + awarding_office_code + year | 0, 
#                    data=us_award_data_filtered, exactDOF = T)
#summary(v_corr_fv2)

#Creating Benford's indicator

us_award_data_filtered$corr_ben <- 0
us_award_data_filtered$corr_ben [us_award_data_filtered$MAD10==10] <- 1
us_award_data_filtered$corr_ben [us_award_data_filtered$MAD10==9] <- 1
summary(us_award_data_filtered$corr_ben )

#Model 5
#v_corr_fv2 <-  felm(singleb ~  nocft + corr_proc + corr_ben + corr_overrun + corr_delay + lcv + commercial_item |
#                      msector + state_code + awarding_office_code + year | 0, 
#                    data=us_award_data_filtered, exactDOF = T)
#summary(v_corr_fv2)

#buyer concentration Indicator
#length(is.na(us_award_data_filtered$recipient_duns))
#length(is.na(us_award_data_filtered$recipient_parent_duns))
buyer_bidder <- as.data.frame(
  us_award_data_filtered %>%
    group_by(awarding_office_code, recipient_duns, year) %>%
    summarise(agg_value = sum(obligated_amount))) %>%
  filter(is.na(year) == FALSE)

buyer <- as.data.frame(
  us_award_data_filtered %>%
    group_by(awarding_office_code, year) %>%
    summarise(agg_value = sum(obligated_amount))) %>%
  filter(is.na(year) == FALSE)

buyer_conc_df <-
  merge(
    buyer_bidder,
    buyer,
    by = c('awarding_office_code', 'year'),
    all.x = TRUE
  )

#Calculating buyer spending concentration 
buyer_conc_df$share <-
  buyer_conc_df$agg_value.x / buyer_conc_df$agg_value.y

buyer_conc_df <-
  buyer_conc_df %>% 
  select(
    awarding_office_code, 
    recipient_duns, 
    year, 
    share
    )

us_award_data_filtered_try <-
  merge(
    us_award_data_filtered,
    buyer_conc_df,
    by = c('awarding_office_code', 'recipient_duns', 'year'),
    all.x = TRUE
  )

#Model 6
#v_corr_fv3 <-  felm(share ~ singleb  + nocft + corr_proc + corr_ben + corr_overrun + corr_delay + lcv + commercial_item |
#                      msector + state_code + awarding_office_code + year | 0, 
#                    data=us_award_data_filtered_try, exactDOF = T)
#summary(v_corr_fv3)

list.vars <-
  c(
    "awarding_office_code",
    "recipient_duns",
    "year",
    "parent_award_agency_id",
    "award_id_piid",
    "parent_award_agency_name",
    "parent_award_id",
    "obligated_amount",
    "current_total_value_of_award",
    "awarding_agency_code",
    "awarding_agency_name",
    "awarding_sub_agency_code",
    "awarding_sub_agency_name",
    "awarding_office_name",
    "recipient_name",
    "cage_code",
    "recipient_parent_name",
    "recipient_parent_duns",
    "recipient_country_code",
    "recipient_country_name",
    "recipient_address_line_1",
    "recipient_address_line_2",
    "recipient_city_name",
    "recipient_state_code", 
    "recipient_state_name",
    "recipient_zip_4_code",
    "recipient_congressional_district",
    "recipient_phone_number",
    "recipient_fax_number",
    "primary_place_of_performance_country_code",
    "primary_place_of_performance_country_name",
    "primary_place_of_performance_city_name",
    "primary_place_of_performance_county_name",
    "primary_place_of_performance_state_code",
    "primary_place_of_performance_state_name",
    "primary_place_of_performance_zip_4",
    "primary_place_of_performance_congressional_district",
    "award_type",
    "award_description",
    "product_or_service_code",
    "product_or_service_code_description",
    "naics_code",
    "naics_description",
    "country_of_product_or_service_origin_code",
    "country_of_product_or_service_origin",
    "solicitation_procedures_code",
    "solicitation_procedures",
    "number_of_offers_received",
    "singleb",
    "prop_bidnr",
    "corr_proc",
    "corr_solic",
    "nocft",
    "overrun",
    "delay",
    "commercial_item",
    "state_code",
    "unid_foreign_comp",
    "w_foreign",
    "msector",
    "lcv",
    "cv5",
    "corr_overrun",
    "corr_delay",
    "corr_ben",
    "share",
    'solicitation_procedures_code',
    'extent_competed_code'
  )

#Creating Export for reverse flatten tool

export <- 
  us_award_data_filtered_try %>% 
  select(list.vars)
rm(
  buyer,
  buyer_bidder,
  buyer_conc_df,
  buyers_proc_summary,
  us_award_data_filtered,
  us_award_data_filtered_try,
  us_benford
)
export[export==''] <- NA
#readr::write_csv(export, 'US_input.csv', na = '.')

# check <- read_csv('US_input.csv')
# check_cri <- check %>% select(singleb,corr_proc,nocft,corr_ben,corr_overrun,corr_delay)
# check_cri$singleb <- as.numeric(check_cri$singleb)
# check_cri$corr_proc <- as.numeric(check_cri$corr_proc)
# check_cri$nocft <- as.numeric(check_cri$nocft)
# 
# check_cri$na_count <- apply(check_cri[,1:6], 1, function(x) sum(is.na(x)))
# summary(check_cri)
# check_cri <- check_cri %>% 
#   #unfactor() %>% 
#   mutate(corr_overrun=replace(corr_overrun, corr_overrun==9, NA)) %>%
#   mutate(corr_delay=replace(corr_delay , corr_delay ==9, NA)) %>%
#   replace(is.na(.), 0) %>% 
#   #replace(9, 0) %>% 
#   mutate(cri=Reduce("+",.[1:6])) %>% 
#   mutate(cri = as.double(cri))%>% 
#   mutate(denom=(6-as.numeric(na_count))) %>% 
#   mutate(cri_us=cri/denom)
# 
# summary(check_cri$cri_us)

export$tender_country <- "US"
export$buyer_country <- "US" 
export$tender_supplytype <- NA

export$notice_url <- NA
export$source <- "https://www.usaspending.gov"

#summary(as.factor(us_award_data_filtered_try$type_of_contract_pricing))


export$tender_publications_notice_type<- NA
export$tender_publications_award_type<- "CONTRACT_AWARD"

export$bid_price <- export$obligated_amount
export$buyer_name<- export$awarding_agency_name
export$bidder_name<- export$recipient_name
export$bidder_masterid<- export$recipient_duns
export$bidder_id <- export$bidder_masterid
export$buyer_masterid<- export$awarding_office_code
export$buyer_id <- export$buyer_masterid
export$curr <- "USD"
export$lot_est_pricecurrency <- "USD"
export$bid_pricecurrency <- "USD"

#summary(as.factor(us_award_data_filtered_try$award_or_idv_flag))
export$buyer_postcode<- export$primary_place_of_performance_zip_4
export$buyer_city <- export$primary_place_of_performance_city_name
export$buyer_geocodes<- export$primary_place_of_performance_state_code
export$bidder_geocodes<- export$recipient_state_code

 
export$bidder_city <- export$recipient_city_name
export$buyer_mainactivities <- "NA"
export$lot_estimatedprice <-  "NA"
export$title <- export$award_description
export$tender_awarddecisiondate<-  "NA"
export$tender_contractsignaturedate<-  "NA"
export$tender_publications_lastcontract<-  "NA"
export$tender_biddeadline<-  "NA"
export$tender_publications_firstcallfor<-  "NA"
export$tender_publications_firstdcontra<-  "NA"
export$tender_supplytype <- "NA"
export$buyer_buyertype <- "NA"
export$tender_addressofimplementation_c <- "US"
export$tender_addressofimplementation_n <- "NA"
export$bids_count <- export$number_of_offers_received

export$tender_cpvs <- export$product_or_service_code
export$lot_localProductCode <- export$product_or_service_code
export$lot_localProductCode_type <- "PSC"


export$tender_finalprice <- export$obligated_amount
export$tender_id <- export$award_id_piid
export$lot_number <- export$award_id_piid
export$export_tender_proceduretype <-
  paste0(
    as.character(export$extent_competed_code),
    "-",
    as.character(export$solicitation_procedures_code)
  )
export$tender_nationalproceduretype<- export$extent_competed_code

#summary(as.factor(export$export_tender_proceduretype))


export$anb_type <- NA
export$curr_ppp <- "International Dollars"
export$tender_year <- export$year
export$ca_type <- NA
export$market_id <- substr(export$tender_cpvs,1,2)

#table(export$market_id)
#View(us_award_data_filtered_try$product_or_service_code)

#Merging PSC to CPV code transformation

list.of.divisions <-
  read_delim(
    paste0(utility_data,'/country/US/cpv_divisions.txt'),
    col_types = cols(.default = col_character()),
    delim = ','
  )

export$tender_cpvs <- NA
for (index in 1:nrow(list.of.divisions)) {
  export$tender_cpvs[grepl(pattern = list.of.divisions$REGEX[index],
                           export$product_or_service_code,
                           perl = T)] <-
    list.of.divisions$CPV[index]
}

export$tender_cpvs[is.na(export$tender_cpvs)] <- "99"
export$tender_cpvs <- paste(export$tender_cpvs,'000000',sep = '')
#table(export$tender_cpvs, useNA = 'always')
export$market_id <- substr(export$tender_cpvs,1,2)

#Indicators
#table(export$corr_proc) #0,0.5,1
export$corr_proc <- as.numeric(export$corr_proc)
export$corr_proc[export$corr_proc==1] <- 0
export$corr_proc[export$corr_proc==2] <- 0.5
export$corr_proc[export$corr_proc==3] <- 1
#table(export$corr_proc)

#table(export$singleb)#0,1
export$singleb <- as.numeric(export$singleb)
#table(export$singleb)#0,1

#max(export$share,na.rm = T)
export$share[export$share<0] <- NA
#min(export$share,na.rm = T)

#table(export$nocft)#0,1
#export$nocft <- as.numeric(export$nocft)+1
#table(export$nocft)#0,1

#table(export$corr_ben)#0,1
export$corr_ben <- as.numeric(export$corr_ben)
#table(export$corr_ben)#0,1

#table(export$corr_overrun)
export$corr_overrun[export$corr_overrun=="9"] <- NA
export$corr_overrun <- as.numeric(export$corr_overrun)-1
#table(export$corr_overrun) #0,1

export$ind_singleb_val <- NA
export$ind_singleb_val[export$singleb==0] <- 100
export$ind_singleb_val[export$singleb==1] <- 0
#table(export$ind_singleb_val)

export$ind_nocft_val <- NA
export$ind_nocft_val[export$nocft==0] <- 100
export$ind_nocft_val[export$nocft==1] <- 0
#table(export$ind_nocft_val)

export$ind_corr_ben_val <- NA
export$ind_corr_ben_val[export$corr_ben==0] <- 100
export$ind_corr_ben_val[export$corr_ben==1] <- 0
#table(export$ind_corr_ben_val)

export$ind_corr_overrun_val <- NA
export$ind_corr_overrun_val[export$corr_overrun==0] <- 100
export$ind_corr_overrun_val[export$corr_overrun==1] <- 0
#table(export$ind_corr_overrun_val)

export$ind_corr_delay_val <- NA
export$ind_corr_delay_val[export$corr_delay==0] <- 100
export$ind_corr_delay_val[export$corr_delay==1] <- 0
#table(export$ind_corr_delay_val)


export$ind_corr_proc_val <- NA
export$ind_corr_proc_val[export$corr_proc==0] <- 100
export$ind_corr_proc_val[export$corr_proc==0.5] <- 50
export$ind_corr_proc_val[export$corr_proc==1] <- 0
#table(export$ind_corr_proc_val)

export$ind_csh_val <- 100-export$share*100
#summary(export$ind_csh_val)

export$tender_title <- export$title

export$ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
export$ind_singleb_type = "INTEGRITY_SINGLE_BID"
export$ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
export$ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
export$ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
export$ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
export$ind_corr_ben_type = "INTEGRITY_BENFORD"
export$ind_csh_type = "INTEGRITY_WINNER_SHARE"
export$ind_roverrun2_type =  "INTEGRITY_COST_OVERRUN"
export$ind_delay_type =  "INTEGRITY_DELAY"

export$ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
export$ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
export$ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
export$ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
export$ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
export$ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
export$ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
export$ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
export$ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"

export$bidder_previousSanction = "false"
export$bidder_hasSanction = "false"
export$sanct_startdate = ""
export$sanct_enddate = ""
export$sanct_name = ""

#table(export$extent_competed_code)
export$tender_proceduretype <- NA
export$tender_proceduretype[export$extent_competed_code=='A'] <- "OPEN"
export$tender_proceduretype[export$extent_competed_code=='B'] <- "RESTRICTED"
export$tender_proceduretype[export$extent_competed_code=='C'] <- "OUTRIGHT_AWARD"
export$tender_proceduretype[export$extent_competed_code=='D'] <- "RESTRICTED"
export$tender_proceduretype[export$extent_competed_code=='E'] <- "CONCESSION"
export$tender_proceduretype[export$extent_competed_code=='F'] <- "OPEN"
export$tender_proceduretype[export$extent_competed_code=='G'] <- "RESTRICTED"
export$tender_proceduretype[export$extent_competed_code=='NDO'] <- "RESTRICTED"
export$tender_proceduretype[export$extent_competed_code=='CDO'] <- "OPEN"
export$tender_proceduretype[export$extent_competed_code=='NA'] <- NA
export$tender_proceduretype[is.na(export$extent_competed_code)] <- NA

#table(export$export_tender_proceduretype)

export$bid_number <- 1
export$ind_taxhav2_val <- NA

export$ind_tr_title_val <- export$tender_title

export$ind_tr_title_val[is.na(export$tender_title)] <- 0 
export$ind_tr_title_val[!is.na(export$tender_title)] <- 100

export$ind_tr_proc_val[is.na(export$tender_nationalproceduretype)] <- 0 
export$ind_tr_proc_val[!is.na(export$tender_nationalproceduretype)] <- 100

export$ind_tr_bids_val[is.na(export$bids_count)] <- 0 
export$ind_tr_bids_val[!is.na(export$bids_count)] <- 100

export$ind_tr_aw_date2_val <- 0 

export <- export %>% arrange(tender_id,lot_number,bid_number)

vars <-
  c(
    "tender_id",
    "lot_number",
    "bid_number",
    "tender_country",
    "tender_awarddecisiondate",
    "tender_contractsignaturedate",
    "tender_biddeadline",
    "tender_nationalproceduretype",
    "tender_proceduretype",
    "tender_supplytype",
    "source",
    "tender_publications_notice_type",
    "tender_publications_firstcallfor",
    "notice_url",
    "source",
    "tender_publications_award_type",
    "tender_publications_firstdcontra",
    "tender_publications_lastcontract",
    "buyer_masterid",
    "buyer_id",
    "buyer_city",
    "buyer_postcode",
    "buyer_country",
    "buyer_geocodes",
    "buyer_name",
    "buyer_buyertype",
    "buyer_mainactivities",
    "tender_addressofimplementation_c",
    "tender_addressofimplementation_n",
    "bidder_masterid",
    "bidder_id",
    "bidder_country",
    "bidder_city",
    "bidder_geocodes",
    "bidder_name",
    "bid_priceUsd",
    "bid_price",
    "bid_pricecurrency",
    "bidder_previousSanction",
    "bidder_hasSanction",
    "sanct_startdate",
    "sanct_enddate",
    "sanct_name",
    "lot_productCode",
    "lot_localProductCode_type",
    "lot_localProductCode",
    "title",
    "bids_count",
    "lot_estimatedpriceUsd",
    "lot_estimatedprice",
    "lot_est_pricecurrency",
    "ind_corr_nocft_val",
    "ind_nocft_type",
    "ind_singleb_val",
    "ind_singleb_type",
    "ind_taxhav2_val",
    "ind_taxhav2_type",
    "decp",
    "ind_corr_decp_val",
    "ind_corr_decp_type",
    "ind_corr_proc_val",
    "ind_corr_proc_type",
    "submp",
    "ind_corr_submp_val",
    "ind_corr_submp_type",
    "ind_corr_ben_val",
    "ind_corr_ben_type",
    "ind_csh_val",
    "ind_csh_type",
    "ind_corr_overrun_val",
    "ind_roverrun2_type",
    "ind_corr_delay_val",
    "ind_delay_type",
    "overrun",
    "delay",
    "ind_tr_buyer_name_val",
    "ind_tr_buyer_name_type",
    "ind_tr_title_val",
    "ind_tr_tender_title_type",
    "ind_tr_bidder_name_val",
    "ind_tr_bidder_name_type",
    "ind_tr_tender_supplytype_val",
    "ind_tr_tender_supplytype_type",
    "ind_tr_bid_price_val",
    "ind_tr_bid_price_type",
    "ind_tr_impl_val",
    "ind_tr_impl_type",
    "ind_tr_proc_val",
    "ind_tr_proc_type",
    "ind_tr_bids_val",
    "ind_tr_bids_type",
    "ind_tr_aw_date2_val",
    "ind_tr_aw_date2_type",
    "tender_year"
  )

export$bid_priceUsd <- export$bid_price
export$lot_productCode <- (export$tender_cpvs)


export$lot_estimatedpriceUsd <- NA
export$ind_corr_nocft_val <- export$ind_nocft_val
export$ind_corr_decp_val <- NA
export$ind_corr_submp_val <- NA
export$decp <- NA
export$submp <- NA

export$ind_tr_buyer_name_val <- 100
export$ind_tr_bidder_name_val <- 100
export$ind_tr_tender_supplytype_val <- NA
export$ind_tr_bid_price_val <- 100

export$ind_tr_impl_val <- 0


export$bidder_country <- (export$recipient_country_code)
export_vf <- 
  export %>% 
  select(vars)

#length(is.na(export_vf$title))
#summary(is.na(export_vf$title))

write_csv(export_vf, 'US_wip.csv')
#END

