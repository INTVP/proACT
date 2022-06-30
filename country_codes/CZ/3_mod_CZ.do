local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use"${country_folder}/`country'_wb_1020.dta", clear
********************************************************************************
*Fixing variables for reverse tool
********************************************************************************
* Generate tender country

gen tender_country = "CZ"
************************************************

*Fix bad national procedure type

do "${utility_codes}/fix_bad_national_proc_type.do"
************************************************
*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)

// br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************************

*rename buyer_NUTS3 buyer_geocodes
// tab buyer_nuts, m

gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]"
************************************************

gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
drop buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities
************************************************

*Fixing IMPL nuts
// tab tender_addressofimplementation_n, m

replace tender_addressofimplementation_n = "" if tender_addressofimplementation_n=="00"
gen imp_nuts = tender_addressofimplementation_n
split imp_nuts, p(",")

foreach var of varlist imp_nuts1-imp_nuts20 {
local i = `i' + 1
gen imp_nuts_len`i'=length(`var')
}
forval x = 1/20 {
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' if imp_nuts_len`x'==0
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' + "0000" if imp_nuts_len`x'==1
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' + "000" if imp_nuts_len`x'==2
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' + "00" if imp_nuts_len`x'==3
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' + "0" if imp_nuts_len`x'==4
bys imp_nuts_len`x': replace imp_nuts`x' = imp_nuts`x' if imp_nuts_len`x'==5
}
format tender_addressofimplementation_n imp_nuts %10s
// br tender_addressofimplementation_n imp_nuts imp_nuts*
drop imp_nuts
gen imp_nuts=""
forval j = 1/20{ 
    replace imp_nuts = imp_nuts + imp_nuts`j' + "," if !missing(imp_nuts`j') 
} 
format tender_addressofimplementation_n imp_nuts %10s
gen impl_nuts_len = length(tender_addressofimplementation_n)
// br tender_addressofimplementation_n imp_nuts imp_nuts* if impl_nuts_len>5
drop imp_nuts1-imp_nuts_len20  impl_nuts_len

*Manual fixes
replace imp_nuts="CZ000" if inlist(imp_nuts,"CZZ00,","CZZZ0,")
tab imp_nuts, m
replace imp_nuts = substr(imp_nuts, 1, length(imp_nuts) - 1) if substr(imp_nuts, -1, 1) ==  ","

gen tender_addressofimplementation_c = substr(imp_nuts,1,2) 
gen  tender_addressofimplementation2 = "["+ `"""' + imp_nuts + `"""' +"]"
drop tender_addressofimplementation_n
rename tender_addressofimplementation2 tender_addressofimplementation_n
// tab tender_addressofimplementation_n, m
// tab tender_addressofimplementation_c, m
drop imp_nuts

*Fixing Bidder nuts
tab bidder_nuts, m
replace bidder_nuts="" if bidder_nuts=="00"
replace bidder_nuts = "CZ000" if inlist(bidder_nuts,"CZZ00","CZZ00","CZZZZ")

gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]"
************************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
gen lot_est_pricecurrency = currency
************************************************

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************************

// br tender_title lot_title
gen title = lot_title
replace title = tender_title if missing(title)
************************************************

// br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
*replace bids_count = tender_recordedbidscount if missing(bids_count)
************************************************

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
************************************************

foreach var of varlist bid_iswinning  {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
// br  buyer_id bidder_id

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}
************************************************
*Calcluating indicators

// tab nocft2 , m
// tab singleb , m 
// tab taxhav2 , m
// tab corr_decp, m
// tab corr_submp , m
// tab corr_proc, m
// tab corr_ben, m

*For indicators with 1 category
foreach var of varlist nocft2 singleb taxhav2 corr_submp {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}

*For indicators with categories
foreach var of varlist corr_proc corr_decp  corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

*Contract Share
// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************************

*Transparency
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =bids_count
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids
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
save "${country_folder}/`country'_wb_1020.dta", replace
********************************************************************************
*Fixing variables for the rev flatten tool\
local country "CZ"
use "${country_folder}/`country'_wb_1020.dta", clear
sort tender_id lot_row_nr

// tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)

// tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
// br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
drop if missing(buyer_name)

bys tender_id: gen x=_N
format tender_title  bidder_name  tender_publications_lastcontract  %15s
// br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
// count if missing(tender_lotscount)
cap drop lot_number
gen lot_number = 1 if tender_isframework=="t" & missing(lot_row_nr)
replace lot_number = lot_row_nr if tender_isframework=="t" & !missing(lot_row_nr)
bys tender_id: replace lot_number=_n if tender_isframework!="t"
// count if missing(lot_number)

sort  tender_id   lot_number
// br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
************************************************
*Bid number: Rule;

bys tender_id lot_number: gen bid_number=_n
// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK

// unique tender_id lot_number bid_number
************************************************

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency  lot_productCode lot_localProductCode_type lot_localProductCode title lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 
 

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency  lot_productCode lot_localProductCode_type lot_localProductCode title lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 
 
assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
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