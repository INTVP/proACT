local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Fixes the US output from R
2) Adds competition indicators
3) Exports select variable for the reverse flatten tool*/
********************************************************************************
*Data

import delimited using "${utility_data}/country/`country'/starting_data/`country'_mod.csv", encoding(UTF-8)  varnames(1) clear 
********************************************************************************

*Replacing NAs
ds,has(type string)
return list
foreach var in `r(varlist)'{
replace `var' = "" if `var'=="NA"
}

*Generate tender year
cap drop tender_year
gen tender_year = ""
foreach var in tender_publications_firstdcontra tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_publications_firstcallfor {
replace tender_year = substr(`var',1,4) if missing(tender_year)
}
destring tender_year, replace

*Destring price var
destring bid_priceusd, replace

*Generate submp and dec p
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
replace aw_date = date(tender_publications_firstdcontra, "YMD") if missing(aw_date)

*Submission period
gen submp = bid_deadline - first_cft_pub
replace submp=. if submp<=0
replace submp=. if submp>365 

*Decision period
gen decp=aw_date - bid_deadline
replace decp=0 if decp<0 & decp!=0
replace decp=. if decp>730 
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*New indicators market entry 
gen filter_ok=1
*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" lot_productcode tender_year bidder_masterid "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_priceusd 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
*No buyer_city
// do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city 
gen is_capital = .

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
// do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city
gen bidder_non_local = .
********************************************************************************
*Competition Indicators

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"

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
cap drop filter_ok tender_year
cap drop bid_deadline first_cft_pub aw_date

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype source tender_publications_notice_type tender_publications_firstcallfor notice_url tender_publications_award_type tender_publications_firstdcontra buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceusd bid_price bid_pricecurrency lot_productcode lot_localproductcode_type lot_localproductcode title lot_estimatedpriceusd lot_estimatedprice lot_est_pricecurrency ind_corr_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 


drop if missing(bidder_masterid)

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
