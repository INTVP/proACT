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

* Buyer geocode 

*anb_iso2
gen buyer_geocodes = anb_iso2
replace buyer_geocodes="CD" if buyer_geocodes=="ZR"

replace buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]"
replace buyer_geocodes = "" if buyer_geocodes==`"[""]"'
// tab buyer_geocodes, m
*********************************

*Bidder Geocodes

gen x = w_iso2 
// tab w_country if missing(w_iso2)
replace x="MK" if w_country=="YUGOSLAVIA"
gen bidder_geocodes= x  if !missing(x)
cap drop x
// tab bidder_geocodes, m
replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"
replace bidder_geocodes = "" if bidder_geocodes==`"[""]"'
tab bidder_geocodes, m
************************************
*Implemenation location

// desc pr_country pr_iso3
gen impl_geocodes = substr(pr_iso3,1,2)

// tab impl_geocodes, m
replace impl_geocodes = "["+ `"""' + impl_geocodes + `"""' +"]"
replace impl_geocodes = "" if impl_geocodes==`"[""]"'
// tab impl_geocodes, m
gen tender_addressofimplementation_c = substr(pr_iso3,1,2)
gen  tender_addressofimplementation_n = impl_geocodes
********************************************************************************
*Fixing variables for reverse tool
cap drop tender_country
gen tender_country = pr_country
replace tender_country = proper(tender_country)
replace tender_country = "" if inlist(tender_country,"Central America","Central American Sub-Region","Regional","Regional Support")
replace tender_country = anb_country if missing(tender_country)
replace tender_country = proper(tender_country)
replace tender_country = "" if inlist(tender_country,"Central America","Central American Sub-Region","Regional","Regional Support")
replace tender_country = proper(tender_country)
// br tender_country *country*  if missing(tender_country)
// tab tender_country, m

*Run country to iso code on tender_country
gen iso=tender_country
do $utility_codes/country-to-iso.do iso
replace iso = "" if inlist(iso,"Central America","Central American Sub-Region","Regional","Regional Support")
// tab iso

rename iso tender_country_iso
replace tender_country = "" if missing(tender_country_iso)
// tab tender_country if missing(tender_country_iso)
// tab tender_country_iso, m
************************************
*Types of publications

gen tender_publications_notice_type = "" 
drop tender_publications_notice_type
gen tender_publications_award_type = "CONTRACT_AWARD" 
gen source = "https://www.iadb.org/en/iadb_projects/form/search_awarded_contracts" if !missing(tender_publications_award_type)
************************************
// br ca_contract_value* ppp
rename ca_contract_value bid_priceUsd
gen bid_pricecurrency="National currency" if !missing(ca_contract_value_original)
************************************

rename cpv_code lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

*For title using ca_type
// br *title*
replace title = proper(title)
************************************

*Fix dates for export
cap drop x
gen x = date(ca_signdate,"DMY")
format x %td
drop ca_signdate
rename x ca_signdate


foreach var of varlist ca_signdate {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx = "0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen `var'_str = yearx + "-" + monthx + "-" + dayx
	drop dayx monthx yearx len_mon len_day
	drop `var'
	rename `var'_str `var'
}
foreach var of varlist  ca_signdate {
replace `var'="" if `var'==".-.-."
replace `var'="" if `var'==".-0.-0."
}


************************************

// tab ca_procedure, m
gen tender_nationalproceduretype = ""
replace ca_procedure="INTERNATIONAL_COMPETITIVE_BIDDING" if  ca_procedure=="ICB"
replace ca_procedure="NATIONAL_COMPETITIVE_BIDDING" if  ca_procedure=="NCB"
*replace ca_procedure="DESIGN_CONTEST" if  ca_procedure=="DC"

*Expand the WB data standard for these procedure types
************************************

*Using the  generated id for buyers
tostring anb_id, replace
replace anb_id= "IDB" +anb_id
replace anb_id="" if anb_id=="IDB."
tostring w_id, replace
replace w_id= "IDB" +w_id if !missing(w_id)
replace w_id="" if w_id=="IDB."
// br anb_id w_id

// count if missing(w_id) & filter_ok==1
// count if missing(anb_id) & filter_ok==1 & !missing(anb_name)

replace anb_id="" if missing(anb_name)

foreach var of varlist anb_name w_name {
replace `var' = ustrupper(`var')
}
************************************

gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"

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
* Calcluating indicators

// tab taxhav_x , m
// tab corr_proc, m
// tab corr_ben, m
*For indicators with 1 category

foreach var of varlist  corr_proc taxhav_x   {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
*For indicators with categories
************************************

foreach var of varlist corr_ben  {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
// tab ind_corr_ben_val  corr_ben if filter_ok==1, m
************************************
 
// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Creating missing indicators
   
gen ind_singleb_val=.
gen ind_nocft_val=.
gen ind_corr_submp_val=.
gen ind_corr_decp_val=.
gen submp = .
gen dec_p = . 
************************************
 
*Transparency
gen impl= pr_country
gen proc = ca_procedure
gen aw_date2 = pr_signdate1
gen bids = ""
gen value = ca_contract_value_original

foreach var of varlist anb_name title w_name ca_supplytype  value impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids value
************************************
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = .

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
*Fixes

replace ca_supplytype_mod=upper(ca_supplytype_mod)
replace ca_supplytype_mod="SUPPLIES" if ca_supplytype_mod=="GOODS"
// tab ca_supplytype_mod, m
************************************
*Clean buyer and bidder name from a wierd symbols
// br w_name if ustrregexm(w_name,"[^\x00-\x7F]+")  //regex for non-ASCI characters
// br anb_name if ustrregexm(anb_name,"[^\x00-\x7F]+")
replace anb_name = subinstr(anb_name, "¿", "",.)
replace w_name = subinstr(w_name, "¿", "",.)
 

*To replace the first sting into upper
generate str80 title2 = substr(title,2,.)
generate str80 title3 = substr(title,1,1)
replace title3=proper(title3)
gen title4 = title3 + title2
format title* %10s
// br title title2 title3 title4 if missing(title)
drop  title title2 title3
rename title4 title 

foreach var in buyer_geocodes tender_country_iso tender_addressofimplementation_n tender_addressofimplementation_c w_iso2 bidder_geocodes {
replace `var' = "1A" if `var' == "XK"
replace `var' = "CD" if `var' == "ZR"
replace `var' = "UK" if `var' == "GB"
replace `var' = subinstr(`var',"ZR","CD",.)
replace `var' = subinstr(`var',"XK","1A",.)
replace `var' = subinstr(`var',"GB","UK",.)
}
********************************************************************************
save "${country_folder}/`country'_wb_1020.dta", replace
********************************************************************************
*Ready for export!
*Variable Selection 

keep if filter_ok==1
************************************

// sort pr_id ca_id 
// unique   pr_id ca_id  if filter_ok
bys pr_id ca_id : gen x=_N if filter_ok
// br pr_id ca_id x anb_name w_name bid_price* if x>1


// br pr_id ca_id x anb_name w_name bid_price* * if x>1 & added_dec=="2019oct" 
*There is a problem with the merge there are duplicates in the data dropping
drop if x==1 & added_dec=="2019oct"&  missing(ca_contract_value_original) & missing(anb_name)
drop if x>1 & added_dec=="2019oct" & missing(ca_contract_value_original) & missing(anb_name)
drop  x

bys pr_id ca_id : gen x=_N if filter_ok
// br pr_id ca_id x added_dec anb_name w_name bid_price* * if x>1
*Duplicating anb_name and anb_id for the data
gsort ca_id -anb_name
foreach var of varlist ind_corr_ben_val ind_tr_anb_name_val ind_tr_impl_val{
bys ca_id: replace `var'=`var'[1]
} 

gsort ca_id -anb_name
foreach var of varlist anb_name anb_id anb_iso2 buyer_geocodes tender_addressofimplementation_c tender_addressofimplementation_n tender_country anb_country title{
bys ca_id: replace `var'=`var'[1] if missing(`var') 
} 
// br ca_id anb_name anb_id  w_name bid_priceUsd if x>1

gen lot_id=1
bys ca_id lot_id : gen bid_number=_n if filter_ok
// unique ca_id lot_id bid_number
************************************
*Fixing the anb_id

// count if missing(anb_id)
// count if missing(anb_name)
replace anb_name = ustrupper(anb_name)
drop if missing(anb_name)
replace w_name = ustrupper(w_name)
drop if missing(w_name)

// cap drop x
// egen x = group(ca_id) if filter_ok & missing(anb_name) 
// replace x=x+750 if !missing(x)
// tostring x , replace
// replace x="" if x=="."
// replace x="IDB" + x if !missing(x)
// replace anb_id = x if missing(anb_id) & filter_ok
// sort ca_id lot_id bid_number
// br ca_id lot_id bid_number anb_id anb_name x 
// drop x
************************************
rename ca_id tender_id 

keep tender_id lot_id bid_number tender_country_iso ca_signdate tender_nationalproceduretype ca_procedure ca_supplytype_mod source tender_publications_award_type anb_id anb_iso2 buyer_geocodes anb_name  tender_addressofimplementation_c tender_addressofimplementation_n w_id w_iso2 bidder_geocodes  w_name bid_priceUsd ca_contract_value_original bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type submp ind_corr_submp_val ind_corr_submp_type dec_p ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_taxhav_x_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital  
************************************

order tender_id lot_id bid_number tender_country_iso ca_signdate tender_nationalproceduretype ca_procedure ca_supplytype_mod source tender_publications_award_type anb_id anb_iso2 buyer_geocodes anb_name  tender_addressofimplementation_c tender_addressofimplementation_n w_id w_iso2 bidder_geocodes  w_name bid_priceUsd ca_contract_value_original bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type submp ind_corr_submp_val ind_corr_submp_type dec_p ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_taxhav_x_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 
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