local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use "${country_folder}/`country'_wb_1020.dta", clear
********************************************************************************
*Exporting for the rev flatten tool - Creating the XX_mod.csv

drop if missing(tender_publications_lastcontract)
drop if filter_ok==0

bys tender_id: gen x=_N
// format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
// br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>5
************************************
*Generating lot number
*RULE: use tender_lotscount, if tender_lotscount==1 then lot_number is 1 for all obs with the same tender_id; if tender_lotscount>1 then we count rows as seperate lots

// count if missing(tender_lotscount)
bys tender_id: gen lot_number = _n if tender_lotscount>1
replace lot_number = 1 if missing(lot_number) & tender_lotscount==1
// br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1
// count if missing(lot_number)
************************************
*Generating  Bid number
*RULE: based on tender_id and lot_number

bys tender_id lot_number: gen bid_number=_n
// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1
************************************
*Generate tender country

gen tender_country = "`country'"
************************************
*Fix bad national procedure type

do "${utility_codes}/fix_bad_national_proc_type.do"
************************************
*Generate notice type 

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************
*Generate buyer geocodes based on buyer NUTS

gen  buyer_geocodes = buyer_nuts
replace buyer_geocodes = "`country'000" if buyer_nuts=="`country'"
replace buyer_geocodes = "`country'000" if buyer_nuts=="`country'0"
replace buyer_geocodes = "`country'000" if buyer_nuts=="`country'00"
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]"
************************************
*Generate buyer main activities

gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
*replace  buyer_mainactivities2 = `"""' + buyer_mainactivities + `"""' if missing(buyer_mainactivities)
drop buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities
************************************
*Manually fixing implementation NUTS

gen impl_nuts = tender_addressofimplementation_n
replace impl_nuts = "" if impl_nuts=="00"
replace impl_nuts = "GR000" if impl_nuts=="GR"
replace impl_nuts = "IT000" if impl_nuts=="IT"
replace impl_nuts = "`country'000" if impl_nuts=="`country'"
replace impl_nuts = "`country'000" if impl_nuts=="`country'0"
replace impl_nuts = "`country'000" if impl_nuts=="`country'00"
replace impl_nuts = "TR000" if impl_nuts=="TR"
*tab impl_nuts, m
gen tender_addressofimplementation_c = substr(impl_nuts,1,2)
gen  tender_addressofimplementation2 = "["+ `"""' + impl_nuts + `"""' +"]"
drop tender_addressofimplementation_n
rename tender_addressofimplementation2 tender_addressofimplementation_n


gen bidder_nuts_len = length(bidder_nuts)
// tab bidder_nuts_len, m
// tab bidder_nuts  if  bidder_nuts_len==2
gen bidder_geocodes =  bidder_nuts

*Fix Greece
replace bidder_geocodes = subinstr(bidder_geocodes,"GR","EL",.)
replace bidder_geocodes = bidder_geocodes + "000" if bidder_nuts_len==2
replace bidder_geocodes = bidder_geocodes + "00" if bidder_nuts_len==3
replace bidder_geocodes = bidder_geocodes + "0" if bidder_nuts_len==4
// tab bidder_geocodes

replace bidder_geocodes = bidder_nuts + "0" if bidder_nuts_len==4
replace bidder_geocodes = "EL300" if bidder_nuts_len==3
replace bidder_geocodes = bidder_nuts + "000" if bidder_nuts_len==2

replace  bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"
************************************
// *Export previosly sanctioned and has sanction - even if no sanction data 
// *required for reverse flatten tool
//
// gen bidder_previousSanction = "false"
// gen bidder_hasSanction = "false"
// gen sanct_startdate = ""
// gen sanct_enddate = ""
// gen sanct_name = ""
************************************
*Variable Renaming 

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
************************************
*Product codes

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************
*Tender title

// br tender_title lot_title
gen title = lot_title
replace title = tender_title if missing(title)
************************************
*Lots count

// br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
replace bids_count = tender_recordedbidscount if missing(bids_count)
************************************
*Generate indicaotr type variables

gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLIC`country'ION"
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
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_D`country'E_MISSING"

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"

************************************
*Check if the binary variables have true/false values instead of t/f or True/False
// bidder_hasSanction bidder_previousSanction 
foreach var of varlist bid_iswinning {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************
*Check id variables aren't empty "."

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}

// br  buyer_id bidder_id
************************************
*Calcluating indicators

// tab nocft , m
// tab singleb , m
// tab taxhav2 , m
// tab corr_decp, m
// tab corr_submp , m
// tab corr_proc, m

*For indicators with 1 category - transformed to the integrity version

foreach var of varlist nocft singleb taxhav2 corr_submp corr_decp corr_proc {
// tab `var', m
gen ind_`var'_val = 0
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_corr_ben_val = .

// tab ind_nocft_val  nocft, m
// tab ind_singleb_val  singleb, m
// tab ind_taxhav2_val  taxhav2, m
// tab ind_corr_submp_val  corr_submp, m

*Contract Share
// sum w_ycsh4
gen ind_csh_val = w_ycsh4*100
replace ind_csh_val = 100-ind_csh_val

************************************
*Transparency Indicators

// br tender_addressofimplementation_n tender_nationalproceduretype tender_publications_firstdcontra
// gen title =lot_title
// replace title = tender_title if missing(title)
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =lot_bidscount
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var')
}
cap drop  impl proc aw_date2  bids
************************************
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

*Keeping variables required for the reverse flatten tool

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_nationalproceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title  tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

*bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name 
************************************
*Ordering variables required for the reverse flatten tool

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_nationalproceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title  tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

********************************************************************************
export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace
********************************************************************************
*Clean up
copy "${country_folder}/`country'_wb_1020.dta" "${utility_data}/country/`country'/`country'_wb_1020.dta", replace
local files : dir  "${country_folder}" files "*.dta"
foreach file in `files' {
cap erase "${country_folder}/`file'"
}
cap erase "${country_folder}/buyers_for_R.csv"
********************************************************************************
*END