local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data 

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Create tender final price

bys tender_id: ereplace tender_finalprice=total(bid_price) if bid_iswinning=="t"
sort tender_id tender_finalprice
bys tender_id: replace tender_finalprice=tender_finalprice[1] if tender_finalprice==.
************************************
*Create contract value from bid_price
cap drop ca_contract_value lca_contract_value ca_contract_value10
gen ca_contract_value=bid_price if bid_iswinning=="t"
gen lca_contract_value=log(ca_contract_value)
// hist lca_contract_value // normal

xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=999 if missing(ca_contract_value)
************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
use "${utility_data}/wb_ppp_data.dta", clear
keep if countryname == "Georgia"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save "${country_folder}/ppp_data.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta",clear
// br tender_finalprice ca_contract_value bid_price *price* *value*
// tab currency, m
// tab tender_year, m
gen year = tender_year
merge m:1 year using "${country_folder}/ppp_data.dta"
drop if _m==2
// tabstat ppp, by(year)
replace ppp=0.8595273 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year

gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="GEL" | missing(currency)
gen bid_price_ppp =  bid_price/ppp if currency=="GEL" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="GEL" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="GEL" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="GEL" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="GEL" | missing(currency)

// br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
************************************
*Market id

gen marketid = substr(tender_cpvs,1,2) if tender_maincpv=="t"
// tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid
*destring marketid, replace
label list marketid2
// br tender_cpvs if marketid==46
************************************
*Create filter ok

gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name) & !missing(tender_publications_lastcontract) &  bid_iswinning=="t"

*Filtering out contracts with very high values
// count if tender_finalprice>10000000 & filter_ok
replace filter_ok=0 if tender_finalprice>=10000000 & filter_ok //losing 159 contracts
// tab filter_ok, m  //202,299
// count if filter_ok
// di `r(N)'/_N  // 38.8% of observations
************************************
*Dates

gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_publications_firstdcontra, "YMD")

format aw_date bid_deadline first_cft_pub %d
************************************
*Buyer type

// tab buyer_buyertype, m
gen buyer_type = buyer_buyertype
replace buyer_type = "NATIONAL_AUTHORITY" if buyer_type == "NATIONAL_AGENCY"
replace buyer_type = "OTHER" if buyer_type == "EUROPEAN_AGENCY"
replace buyer_type = "REGIONAL_AUTHORITY" if buyer_type == "REGIONAL_AGENCY"
replace buyer_type = "OTHER" if buyer_type == "UTILITIES"
encode buyer_type, gen(anb_type)
drop buyer_type
// tab anb_type, m
************************************
*Buyer Location

// tab buyer_county_api, m
replace buyer_county_api= "Missing" if missing(buyer_county_api)
encode buyer_county_api,gen(buyer_location)
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END
