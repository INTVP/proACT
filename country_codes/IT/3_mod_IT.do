local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************
*Data

use "${country_folder}/`country'_wb_2011.dta", clear
********************************************************************************
*Prep for Reverse tool
********************************************************************************
*Generate tender_country

gen tender_country = "IT"
************************************************

*Fix bad national procedure type

do "${utility_codes}/fix_bad_national_proc_type.do"
************************************************
*Fixing Title

cap drop title
replace tender_title=lower(tender_title)
replace lot_title=lower(lot_title)
gen same=(tender_title==lot_title)
replace same=0 if missing(tender_title)
// br tender_title lot_title 
// br tender_title lot_title if same==1
gen miss_tentitle=missing(tender_title)
gen miss_lottitle=missing(lot_title)
gen state = 1 if miss_tentitle==0 &  miss_lottitle==0
replace state = 2 if miss_tentitle==0 &  miss_lottitle==1
replace state = 3 if miss_tentitle==1 &  miss_lottitle==0
replace state = 4 if miss_tentitle==1 &  miss_lottitle==1
gen title=""
bys state: replace title = tender_title + " - " + lot_title if state==1
bys state: replace title = tender_title if state==2
bys state: replace title = lot_title if state==3
bys state: replace title ="" if state==4
replace title= tender_title if same==1 & !missing(tender_title)
// br tender_title lot_title title state 
drop miss_tentitle miss_lottitle state same
replace title = subinstr(title,`"""',"",.)
replace title =  subinstr(title,"„","",.)
replace title = proper(title)
************************************
*Create notice type for tool

cap drop tender_publications_notice_type tender_publications_award_type
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************
*Create the correct nuts variables 

*Buyer NUTS
// tab  buyer_nuts if filter_ok, m
gen nutscode = buyer_nuts
merge m:1 nutscode using "${utility_data}/nuts_map.dta"
drop if _m==2
// tab buyer_nuts if _m==1 //4 unique bad codes (17 obs)
// tab buyer_nuts if missing(description)
// tab tender_year if missing(description)
// tab buyer_nuts if !missing(description)
// replace buyer_nuts=""  if _m==1 
replace buyer_nuts=""  if buyer_nuts=="00"
drop description nutscode _merge

*Bidder NUTS
// tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using "${utility_data}/nuts_map.dta"
drop if _m==2
// tab bidder_nuts if _m==1 //- replace to missing
// replace bidder_nuts="" if _m==1
replace bidder_nuts=""  if bidder_nuts=="00"
// tab bidder_nuts if _m==3
drop description nutscode _merge

*Address of Implementation
// tab tender_addressofimplementation_n if filter_ok
gen nutscode = tender_addressofimplementation_n
merge m:1 nutscode using "${utility_data}/nuts_map.dta"
drop if _m==2
// tab tender_addressofimplementation_n if _m==1  // bad codes - replace to missing
replace tender_addressofimplementation_n=""  if tender_addressofimplementation_n=="00"
// replace tender_addressofimplementation_n="" if _m==1
drop description nutscode _merge


gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]" if !missing(buyer_nuts)
gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]" if !missing(bidder_nuts)
gen  impl_nuts = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]" if !missing(tender_addressofimplementation_n)
gen tender_addressofimplementation_c=substr(tender_addressofimplementation_n,1,2)
rename tender_addressofimplementation_n impl_nuts_original
rename impl_nuts tender_addressofimplementation_n

format  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n %10s
// br  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n
************************************
*Buyer main acticities structure

// tab buyer_mainactivities if filter_ok, m
replace buyer_mainactivities = "["+ `"""' + buyer_mainactivities + `"""' +"]" if !missing(buyer_mainactivities)
************************************
*Renaming price variables

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
************************************ 
*Checking product codes

gen market_id_star=substr(tender_cpvs,1,2)
// tab market_id_star if filter_ok, m //good
drop market_id_star
split tender_cpvs, p(",")
drop tender_cpvs2-tender_cpvs90
rename tender_cpvs1 lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
// br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

// br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
replace bids_count = tender_recordedbidscount if missing(bids_count)
************************************

gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"

gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"


gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"
************************************

foreach var of varlist  bid_iswinning {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}

*Checking ids to be used

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
// br  buyer_id bidder_id

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}

// br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
*Check if titles/names start with "" or []
foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************
// tab tender_proceduretype
// tab tender_supplytype
************************************
*Calcluating indicators

*For indicators with 1 category
foreach var of varlist singleb taxhav2 {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}

gen ind_corr_ben_val = .

*For indicators with categories

foreach var of varlist corr_proc corr_submp corr_decp nocft {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

*Contract Share
// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency

gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =bids_count
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids
********************************************************************************
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = bids_count

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*Export for Reverse tool


drop if filter_ok==0

bys tender_id: gen x=_N
************************************

*Generating LOT NUMBER

format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
*br x tender_id lot_row_nr tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1 & missing(lot_row_nr)

*If x>1 & lot_row_nr is missing and tender_framework is t then consider it one lot
gen lot_number= lot_row_nr
replace lot_number = 1 if tender_isframe=="t" & missing(lot_number) & x>1

*br x tender_id lot_row_nr tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1 & missing(lot_row_nr)

*If x>1 & lot_number is missing and tender_framework is f or missing then consider it several lots (checked a few links and its tru)
bys tender_id: replace lot_number = _n if inlist(tender_isframe,"f","") & missing(lot_number) & x>1

replace lot_number=1 if x==1 & missing(lot_number)
count if missing(lot_number)
************************************
*Generating BID NUMBER

bys tender_id lot_number: gen bid_number=_n

sort tender_id lot_number bid_number 
// unique tender_id lot_number bid_number 
************************************
*FIXING ESTIMATED PRICE VARIABLE TO USE
*MAIN : lot_estimatedprice
*br tender_estimatedpriceUsd tender_estimatedprice  lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
replace lot_estimatedpriceUsd=tender_estimatedpriceUsd if lot_number==1 & missing(lot_estimatedpriceUsd)
gen lot_est_pricecurrency=currency
************************************

keep tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline  tender_nationalproceduretype tender_proceduretype tender_supplytype source tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital  

order tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline  tender_nationalproceduretype tender_proceduretype tender_supplytype source tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital  

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************

export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace
********************************************************************************
*Clean up
copy "${country_folder}/`country'_wb_2011.dta" "${utility_data}/country/`country'/`country'_wb_2011.dta", replace
local files : dir  "${country_folder}" files "*.dta"
foreach file in `files' {
cap erase "${country_folder}/`file'"
}
cap erase "${country_folder}/buyers_for_R.csv"
********************************************************************************
*END