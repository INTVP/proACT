*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/GE_wb_0920.dta, clear
********************************************************************************

*Calcluating indicators
tab nocft , m
tab singleb , m 
tab taxhav2 , m
tab corr_decp, m
************************************

foreach var of varlist nocft singleb taxhav2 corr_decp {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  //tax haven undefined
}
tab ind_nocft_val  nocft, m
tab ind_singleb_val  singleb, m
tab ind_taxhav2_val  taxhav2, m
replace ind_taxhav2_val = . if ind_taxhav2_val==9
************************************

*For indicators with categories
tab corr_proc, m
tab corr_submp, m
tab corr_ben, m
foreach var of varlist corr_proc corr_submp  corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_submp_val  corr_submp, m
tab ind_corr_ben_val  corr_ben, m

*Contract Share
sum w_ycsh4
gen ind_csh_val = w_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
************************************
 
*Transparency
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =tender_recordedbidscount
foreach var of varlist buyer_name tender_title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids

local list ind_nocft_val ind_singleb_val ind_taxhav2_val ind_corr_decp_val ind_corr_proc_val ind_corr_submp_val ind_corr_ben_val ind_csh_val ind_tr_buyer_name_val ind_tr_tender_title_val ind_tr_bidder_name_val ind_tr_tender_supplytype_val ind_tr_bid_price_val ind_tr_impl_val ind_tr_proc_val ind_tr_bids_val ind_tr_aw_date2_val

foreach var of varlist `list' {
replace `var' = 9999 if filter_ok==0
}
********************************************************************************

save $country_folder/GE_wb_0920.dta,replace 
********************************************************************************
*Exporting for the rev flatten tool\
use $country_folder/GE_wb_0920.dta,clear

drop if missing(tender_publications_lastcontract)
************************************

bys tender_id: gen x=_N
format tender_title bidder_name  tender_publications_lastcontract  %15s
br x tender_id bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1

br x tender_id bid_iswinning tender_isframe bid_iscons tender_publications_lastcontract  if x>2
//duplicates bec data contains losing bidders

*Only exporting winning bidders, review : now we export all 
*Generate lot number
bys tender_id: gen lot_number=1

*Create bid numbers
bys tender_id lot_number: gen bid_number=_n
br x tender_id lot_number bid_number bid_iswinning if x>1

gen tender_country = "GE"

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
replace notice_url = tender_publications_lastcontract if !missing(tender_publications_lastcontract) & missing(notice_url)

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************

*rename buyer_NUTS3 buyer_geocodes
gen  buyer_geocodes = "["+ `"""' + buyer_NUTS3 + `"""' +"]"
*replace  buyer_geocodes = `"""' + buyer_NUTS3 + `"""' if missing(buyer_NUTS3)

gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
*replace  buyer_mainactivities2 = `"""' + buyer_mainactivities + `"""' if missing(buyer_mainactivities)
drop buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities


tostring tender_addressofimplementation_n, replace
replace tender_addressofimplementation_n="" if tender_addressofimplementation_n=="."
gen tender_addressofimplementation_c = substr(tender_addressofimplementation_n,1,2) 
replace  tender_addressofimplementation_n = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]"

gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]"
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
************************************

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

br tender_title lot_title
gen title = lot_title
replace title = tender_title if missing(title)
************************************

br tender_recordedbidscount lot_bidscount
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
************************************

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
br  buyer_id bidder_id

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city_api buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city_api buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************
*Implementing some fixes

foreach var in tender_addressofimplementation_n bidder_geocodes buyer_geocodes{
replace `var' = "" if `var'==`"[""]"'
}

keep if !missing(bid_iswinning)
********************************************************************************

export delimited $country_folder/GE_mod.csv, replace
********************************************************************************
*END