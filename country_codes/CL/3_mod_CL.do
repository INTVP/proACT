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
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
*Fixing variables for reverse tool
********************************************************************************
*Generate tender country

gen tender_country = "CL"
************************************

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date_first)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(aw_date)

// br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************
*Buyer type for reverse flatten tool

gen buyer_buyertype = "NATIONAL_AUTHORITY" if anb_type=="national authority"
replace buyer_buyertype = "NATIONAL_AGENCY" if anb_type=="independent agency"
replace buyer_buyertype = "REGIONAL_AUTHORITY" if anb_type=="regional authority"
replace buyer_buyertype = "REGIONAL_AGENCY" if anb_type=="local body"
replace buyer_buyertype = "PUBLIC_BODY" if anb_type=="armed forces"
replace buyer_buyertype = "OTHER" if anb_type=="national banks and funds" | anb_type=="other"| anb_type=="state owned company"
************************************
*year-month-day as a string 

foreach var of varlist cft_date_first cft_date_last aw_date cft_deadline {
	gen `var'_2 = date(`var',"DMY")
	drop `var'
	rename `var'_2 `var'
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

rename aw_date tender_awarddecisiondate
rename cft_deadline tender_biddeadline
rename cft_date_first tender_publications_firstcallfor
gen tender_publications_firstdcontra=tender_awarddecisiondate
************************************
* Buyer locations

*Generating a nuts like variable
gen x = "CL" if !missing(anb_city)
replace x ="" if x=="."
*Generating a new grouping for regions
gen y = .
replace y = 1 if inlist(anb_region,"Arica and Parinacota Region","Tarapaca","Antofagasta","Atacama","Coquimbo")
replace y = 2 if inlist(anb_region,"Valparaiso","O'Higgins","Maule","Biobio","Santiago Metropolitan","Santiago Metropolitan Region")
replace y = 3 if inlist(anb_region,"Araucania","Los Rios","Los Lagos","Aysen","Magallanes")
tab anb_region y , m
tostring y, replace
replace y ="" if y=="."


gen z=1 if anb_region=="Arica and Parinacota Region" | anb_region=="Valparaiso" | anb_region=="Araucania"
replace z=2 if anb_region=="Tarapaca" | anb_region=="O'Higgins" | anb_region=="Los Rios"
replace z=3 if anb_region=="Antofagasta" | anb_region=="Maule" | anb_region=="Los Lagos"
replace z=4 if anb_region=="Atacama" | anb_region=="Biobio" | anb_region=="Aysen"
replace z=5 if anb_region=="Coquimbo" | anb_region=="Santiago Metropolitan" | anb_region=="Magallanes"
replace z=6 if anb_region=="Santiago Metropolitan Region"
tostring z, replace
replace z ="" if z=="."

//
// local temp ""Arica and Parinacota Region" "Tarapaca" "Antofagasta" "Atacama" "Coquimbo" "Valparaiso" "O'Higgins" "Maule" "Biobio" "Santiago Metropolitan" "Santiago Metropolitan Region" "Araucania" "Los Rios" "Los Lagos" "Aysen" "Magallanes""
// local temp2 ""1" "2" "3" "4" "5" "1" "2" "3" "4" "5" "6" "1" "2" "3" "4" "5""
// local n_temp : word count `temp'
// gen z=""
// forval s=1/`n_temp'{
//  replace z = "`: word `s' of `temp2''" if anb_region=="`: word `s' of `temp''"
// }
// bys anb_region: egen alpha = nvals(anb_citystr)
// tab alpha //max 7
// bys anb_region anb_citystr: gen yy = _n==1

// gsort anb_region -anb_citystr
// bys anb_region yy : gen xx = _n if yy==1 & !missing(anb_citystr)
// sort anb_region anb_citystr xx 
// bys anb_region anb_citystr: replace xx = xx[1]  if missing(xx)
// tostring xx, replace
// replace xx="" if xx=="."
// br anb_region anb_citystr yy if yy==1


gen buyer_geocodes=x+y+z
replace buyer_geocodes = subinstr(buyer_geocodes, ".", "", .)
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]" if !missing(buyer_geocodes)

gen tender_addressofimplementation_n = buyer_geocodes
gen tender_addressofimplementation_c = "CL" if !missing(anb_city)

gen buyer_country = tender_addressofimplementation_c

cap drop _merge 
cap drop x 
cap drop y 
cap drop z 
cap drop alpha 
cap drop yy 
cap drop xx

replace anb_city =proper(anb_city)
************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
gen bid_pricecurrency  = currency

************************************

generate lot_productCode =  cpv_div + "000000" if !missing(cpv_div)
gen lot_localProductCode =  tender_unspsc_original
gen lot_localProductCode_type = "UNSPSC" if !missing(lot_localProductCode)
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
foreach var of varlist bid_iswinning {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}

foreach var of varlist anb_city {
replace `var' = proper(`var')
}

foreach var of varlist anb_name w_name {
replace `var' = ustrupper(`var')
}

rename anb_id_addid buyer_masterid
rename anb_id buyer_id
rename w_id_addid bidder_masterid
rename w_id bidder_id
foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
************************************
*Calcluating indicators

cap drop nocft
gen nocft = nocft_nocomp

foreach var of varlist singleb corr_proc nocft  {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  //tax haven undefined
}
gen ind_corr_ben_val = .
gen ind_taxhav_val = .

foreach var of varlist corr_submp corr_decp {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

*Contract Share

// sum proa_ycsh9
gen ind_csh_val = proa_ycsh9*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency

cap drop impl
gen impl= tender_addressofimplementation_n
gen aw_date2 = tender_awarddecisiondate
gen bids = ca_nrbid
gen title = .
gen tender_supplytype = .
gen proc = ca_procedure

rename anb_name buyer_name
rename w_name bidder_name
gen bid_price=ca_contract_value 

foreach var of varlist buyer_name title bidder_name bid_price tender_supplytype impl proc bids aw_date2 {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids 
************************************
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = ca_nrbid

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
* Adding all missing variables

// gen bidder_geocodes = .
// gen tender_addressofimplementation_c = .
// gen tender_addressofimplementation_n = .
//
// gen buyer_mainactivities2 = .
//
// gen lot_estimatedpriceUsd = .
// gen tender_estimatedpriceUsd = .
// gen ten_est_pricecurrency = .
//
// gen tender_nationalproceduretype = .
gen tender_proceduretype=ca_procedure

gen source="https://www.mercadopublico.cl/"
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*Fixing variables for the rev flatten tool\

rename ten_id tender_id
sort tender_id lot_row_nr
************************************

// tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)
// tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
// br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
drop if missing(bidder_masterid)
drop if missing(buyer_masterid)

drop if filter_ok==0
************************************

bys tender_id: gen x=_N
// format tender_title  bidder_name  tender_publications_lastcontract  %15s
// br x ten_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
*count if missing(tender_lotscount)
gen lot_number = lot_row_nr
bys tender_id: replace lot_number=_n if missing(lot_number)

sort  tender_id  lot_number
// br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
************************************
*Bid number: Rule;

bys tender_id lot_number: gen bid_number=_n
// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype   tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra  tender_awarddecisiondate buyer_masterid buyer_id anb_city buyer_geocodes buyer_name buyer_buyertype buyer_country tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype   tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra  tender_awarddecisiondate buyer_masterid buyer_id anb_city buyer_geocodes buyer_name buyer_buyertype buyer_country tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

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
********************************************************************************