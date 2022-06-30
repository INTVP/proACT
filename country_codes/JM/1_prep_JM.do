local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data
use "${utility_data}/country/`country'/starting_data/JM.flatten.2020.07.20_merged.dta", clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. 
********************************************************************************
cap drop tender_year 
gen tender_year = year
********************************************************************************
*Create filter ok

gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name)
// tab filter_ok
************************************
*Contract Value

gen ca_contract_value=tender_finalprice
gen lca_contract_value=log(tender_finalprice)

xtile ca_contract_value10=ca_contract_value, nquantiles(10)
replace ca_contract_value10=99 if ca_contract_value==.
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
use "${utility_data}/wb_ppp_data.dta", clear
keep if countrycode == "JAM"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save "${country_folder}/ppp_data.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta", clear
// br tender_finalprice ca_contract_value bid_price *price* *value*
// tab currency, m
// tab tender_year, m
merge m:1 year using "${country_folder}/ppp_data.dta"
drop if _m==2
// tabstat ppp, by(year)
// br year ppp if _m==3
replace ppp=73.20271 if missing(ppp) & year==2020 //used 2019
drop _m 

gen bid_priceUsd =  bid_price/ppp if currency=="JMD" | missing(currency)
gen lot_estimatedpriceUsd = lot_estimatedprice/ppp if currency=="JMD" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="JMD" | missing(currency)
gen tender_estimatedpriceUsd = tender_estimatedprice/ppp if currency=="JMD" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="JMD" | missing(currency)
gen tender_finalpriceUsd = tender_finalprice/ppp if currency=="JMD" | missing(currency)

// br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

encode buyer_buyertype, gen(anb_type) 
************************************

encode tender_supplytype, gen(ca_type) 
 ************************************
 
encode buyer_nuts, gen(anb_loc) 
************************************

encode biddertype, gen(w_type) 
************************************
*marketid 

gen t_cpv2 = substr(tender_cpvs,1,2)
// tab t_cpv2
encode t_cpv2, gen(marketid)
************************************
*Dates

// br *publi* *dead* *date*
gen bid_deadline = date(tender_biddeadline, "YMD")
// gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
// replace aw_date = date(tender_publications_firstdcontra, "YMD") if missing(aw_date)

format bid_deadline aw_date %d
********************************************************************************

save ${country_folder}/`country'_wip.dta , replace
********************************************************************************
*END

