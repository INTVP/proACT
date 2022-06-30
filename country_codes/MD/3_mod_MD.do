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
gen tender_country = "MD"

************************************************
*Fix bad national procedure type
*No national procedure type variable
// do "${utility_codes}/fix_bad_national_proc_type.do"
rename tender_proceduretype tender_nationalproceduretype_bad

cap drop tender_proceduretype
gen tender_proceduretype = "OPEN" if regexm(tender_nationalproceduretype_bad,"^Licita")
replace tender_proceduretype = "OTHER" if regexm(tender_nationalproceduretype_bad,"^Cerere")

gen tender_nationalproceduretype = "Licitaţie publică" if regexm(tender_nationalproceduretype_bad,"^Licita")
replace tender_nationalproceduretype = "Cererea Ofertelor De Prețuri" if regexm(tender_nationalproceduretype_bad,"^Cerere")
************************************************
*Fixing Title

// cap drop title
// replace tender_title=ustrlower(tender_title)
// replace lot_title=ustrlower(lot_title)
// gen same=(tender_title==lot_title)
// replace same=0 if missing(tender_title)
// // br tender_title lot_title 
// // br tender_title lot_title if same==1
// gen miss_tentitle=missing(tender_title)
// gen miss_lottitle=missing(lot_title)
// gen state = 1 if miss_tentitle==0 &  miss_lottitle==0
// replace state = 2 if miss_tentitle==0 &  miss_lottitle==1
// replace state = 3 if miss_tentitle==1 &  miss_lottitle==0
// replace state = 4 if miss_tentitle==1 &  miss_lottitle==1
// gen title=""
// bys state: replace title = tender_title + " - " + lot_title if state==1
// bys state: replace title = tender_title if state==2
// bys state: replace title = lot_title if state==3
// bys state: replace title ="" if state==4
// replace title= tender_title if same==1 & !missing(tender_title)
// // br tender_title lot_title title state 
// drop miss_tentitle miss_lottitle state same
gen title = lot_title
replace title = subinstr(title,`"""',"",.)
replace title =  subinstr(title,"„","",.)
replace title = proper(title)

foreach var of varlist title {
replace `var' = ustrregexra(`var',"[^\x00-\x7F]","",0) //regex for corrupt characters
replace `var' = ustrregexra(`var',",","",0) 
replace `var' = ustrregexra(`var',"\\s+","") 
}
************************************
*Generating missing variables

gen notice_url = .
cap drop source
gen source = "https://opencontracting.eprocurement.systems/downloads"
gen tender_publications_firstdcontra =.
gen tender_publications_lastcontract =.
************************************
*Dates

// br  ten_startdate_str ten_enddate_str con_startdate_str con_signdate_str tender_biddeadline
foreach var of varlist ten_startdate_str ten_enddate_str con_startdate_str con_signdate_str {
	cap drop h
	gen h = date(`var', "YMD")
	cap drop `var'
	rename h `var'
}
foreach var of varlist ten_startdate_str ten_enddate_str con_startdate_str con_signdate_str tender_biddeadline {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx="0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen `var'_str = yearx + "-" + monthx + "-" + dayx
	replace `var'_str ="" if `var'_str ==".-0.-0."
	drop dayx monthx yearx len_mon len_day
	drop `var'
	rename `var'_str `var'
}
cap drop tender_publications_firstcallfor
cap drop tender_biddeadline
cap drop tender_awarddecisiondate
cap drop tender_contractsignaturedate
ren ten_startdate_str tender_publications_firstcallfor
ren ten_enddate_str tender_biddeadline
ren con_startdate_str tender_awarddecisiondate    
ren con_signdate_str tender_contractsignaturedate
************************************
*Create notice type for tool

cap drop tender_publications_notice_type tender_publications_award_type
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(tender_biddeadline) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_contractsignaturedate) | !missing(tender_publications_firstdcontra)
************************************
*Renaming price variables
replace curr = upper(curr)
rename bid_price_ppp bid_priceUsd
gen bid_pricecurrency  = curr
************************************ 
*Checking product codes

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
// br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

// br tender_recordedbidscount lot_bidscount
gen bids_count = bid_number
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
// br buyer_name bidder_name title
foreach var of varlist buyer_name bidder_name title {
replace `var' = ustrregexra(`var',"[^\x00-\x7F]","",0) //regex for corrupt characters
replace `var' = ustrregexra(`var',"\?","",0)
replace `var' = ustrupper(`var')
}

foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
***********************************
* Locations
foreach var of varlist buyer_city  {
replace `var' = ustrregexra(`var',"[^\x00-\x7F]","",0) //regex for corrupt characters
replace `var' = ustrregexra(`var',"\?","",0)
replace `var' = ustrupper(`var')
}

replace bidder_country = "MK" if bidder_country=="MKD"
replace buyer_country = "MK" if buyer_country=="MKD"

replace bidder_country = "TR" if bidder_country=="TUR"
replace buyer_country = "TR" if buyer_country=="TUR"

// tab buyer_country
// tab bidder_country
gen buyer_geocodes = .
gen bidder_geocodes = . 
gen tender_addressofimplementation_n = .
gen tender_addressofimplementation_c = .
***********************************
// rename buyer_buyertype buyer_type_str
// rename buyer_type buyer_buyertype

cap drop tender_supplytype
rename ca_type_str tender_supplytype
***********************************
*Calcluating indicators

*For indicators with 1 category
foreach var of varlist corr_proc nocft singleb corr_ben {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}

gen ind_taxhav_val = .

foreach var of varlist corr_submp corr_decp {
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
gen aw_date2 = tender_contractsignaturedate
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
*Prep for Reverse tool
drop if filter_ok==0
drop if missing(bidder_name)

// bys tender_id: gen x=_N
************************************
*Generating LOT NUMBER

// ren contract_id lot_number
bys tender_id: gen lot_number = _n 

*Generating BID NUMBER
cap drop bid_number
bys tender_id lot_number: gen bid_number=_n

// sort tender_id lot_number bid_number 
// unique tender_id lot_number bid_number 
************************************
*FIXING ESTIMATED PRICE VARIABLE TO USE

keep tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype source tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

order tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype source tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

// drop notice_url tender_publications_firstdcontra tender_publications_lastcontract buyer_geocodes tender_addressofimplementation_c tender_addressofimplementation_n bidder_geocodes 

foreach var of varlist tender_id lot_number bid_number {
tostring `var', replace
}

foreach var of varlist buyer_city buyer_name bidder_name title {
replace `var' = ustrregexra(`var',"[^\x00-\x7F]","",0) //regex for corrupt characters
replace `var' = ustrregexra(`var',",","",0) 
replace `var' = ustrtrim(`var')

}

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************
// save "${utility_data}/country/`country'/`country'_mod.dta", replace
export excel using "${utility_data}/country/`country'/`country'_mod.xlsx", firstrow(var) replace
// import excel using "${utility_data}/country/`country'/`country'_mod.xlsx", firstr clear
// export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace delimiter(tab)
// unicode convertfile "${utility_data}/country/`country'/`country'_mod.csv" "${utility_data}/country/`country'/`country'_mod2.csv", dstencoding(UTF-8)  srccall(escape) dstcall(escape) replace
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