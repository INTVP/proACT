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
*Variable renaming
 
cap drop tender_nationalproceduretype
decode ca_procedure_nat, gen(tender_nationalproceduretype)
 
cap drop tender_proceduretype
decode ca_procedure, gen(tender_proceduretype)
 
cap drop tender_supplytype
decode ca_type, gen(tender_supplytype)

cap drop buyer_name
decode anb_name, gen(buyer_name)

cap drop bidder_name
decode w_name, gen(bidder_name)

cap drop buyer_buyertype
decode anb_type, gen(buyer_buyertype)
 
rename lot_nrbid lot_bidscount

cap drop tender_id
decode ten_id, gen(tender_id)

decode source, gen(source2)
drop source
rename source2 source


rename aw_date tender_awarddecisiondate
rename ca_signdate tender_contractsignaturedate
rename cft_deadline tender_biddeadline
rename cft_date_first tender_publications_firstcallfor
gen tender_publications_firstdcontra=tender_awarddecisiondate

// rename anb_type_str buyer_buyertype
// rename ca_proc_simp_str tender_proceduretype
// rename ca_type_str tender_supplytype
************************************
rename cpv_code lot_productCode
replace lot_productCode = "" if lot_productCode == "."
replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype) | tender_supplytype=="OTHER"
gen lot_localProductCode =  lot_productCode
replace lot_localProductCode = substr(lot_localProductCode,1,8)
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************
gen tender_country = "IN"
************************************************
*Fix bad national procedure type

do "${utility_codes}/fix_bad_national_proc_type.do"
************************************************
local country "IN"
cap drop title
rename ten_title_original title
replace title = proper(title)
************************************
*Create notice type for tool
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(tender_biddeadline) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_firstdcontra) 
************************************
*Renaming price variables
rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen lot_est_pricecurrency  = currency
gen ten_est_pricecurrency = currency
************************************
// br tender_recordedbidscount lot_bidscount 
gen bids_count = lot_bidscount
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
decode bid_iswinning, gen(bid_iswinning2)
drop bid_iswinning
rename bid_iswinning2 bid_iswinning 
foreach var of varlist  bid_iswinning {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}

*Checking ids to be used

foreach var of varlist buyer_masterid bidder_masterid  {
tostring `var', replace
replace `var' = "" if `var'=="."
}

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

*year-month-day as a string 
gen cft_date_first =  tender_publications_firstcallfor
gen pub_awarddate = tender_publications_firstdcontra
foreach var of varlist cft_date_first tender_biddeadline tender_awarddecisiondate tender_contractsignaturedate pub_awarddate {
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
cap drop tender_publications_firstcallfor tender_publications_firstdcontra
rename cft_date_first tender_publications_firstcallfor
rename pub_awarddate tender_publications_firstdcontra
************************************
*Calcluating indicators

foreach var of varlist singleb corr_submp  {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  
}
gen ind_taxhav2_val = .
gen ind_nocft_val = .
gen ind_corr_decp_val = .

foreach var of varlist corr_proc corr_ben {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}


************************************
*Contract Share
// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency Indicators

gen impl = .
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_awarddecisiondate
gen bids = bids_count


foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2 {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl bids proc aw_date2
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
*******************************************************************************
*Fixing variables for the rev flatten tool\
use "${country_folder}/`country'_wb_2011.dta", clear
sort tender_id 

drop if filter_ok==0
drop if missing(bidder_name)
drop if missing(bidder_name) | bidder_name=="N/A"
drop if missing(buyer_masterid)
************************************

bys tender_id: gen x=_N
format title  bidder_name  %15s

************************************
gen lot_number = 1 
************************************
*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra buyer_masterid  buyer_name  buyer_buyertype bidder_masterid  bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_taxhav2_val ind_taxhav2_type ind_nocft_val ind_nocft_type decp ind_corr_decp_val ind_corr_decp_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital ind_tr_impl_val ind_tr_impl_type


order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra buyer_masterid  buyer_name  buyer_buyertype bidder_masterid  bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_taxhav2_val ind_taxhav2_type ind_nocft_val ind_nocft_type decp ind_corr_decp_val ind_corr_decp_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_impl_val ind_tr_impl_type ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

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