local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data 

import delimited using  "${utility_data}/country/`country'/starting_data/`country'_data.csv", encoding(UTF-8) clear
********************************************************************************
*Create tender final price

bys tender_id: ereplace tender_finalprice=total(bid_price) if bid_iswinning=="t"
sort tender_id tender_finalprice
bys tender_id: replace tender_finalprice=tender_finalprice[1] if tender_finalprice==.
// sum tender_finalprice
// sum tender_finalprice if tender_finalprice==0 //15,763
// tab bid_iswinning if tender_finalprice==0 //t
// tab tender_proceduretype if tender_finalprice==0 //mostly open and outright award
************************************
*Create contract value from bid_price

gen ca_contract_value=bid_price
gen lca_contract_value=log(ca_contract_value)
// hist lca_contract_value // normal

xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
use "${utility_data}/wb_ppp_data.dta", clear
keep if countrycode == "EMU"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save "${country_folder}/ppp_data.dta", replace
********************************************************************************
use"${country_folder}/`country'_wip.dta", clear
// br tender_finalprice ca_contract_value bid_price *price* *value*
// tab currency, m
// tab tender_year, m
gen year = tender_year
merge m:1 year using "${country_folder}/ppp_data.dta"
drop if _m==2
// tabstat ppp, by(year)
replace ppp=0.684051 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year

gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="EUR" | missing(currency)
gen bid_price_ppp =  bid_price/ppp if currency=="EUR" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="EUR" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="EUR" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="EUR" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="EUR" | missing(currency)

// br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************
*Market id

replace tender_cpvs = "99100000" if missing(tender_cpvs) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) & missing(tender_supplytype)

gen marketid = substr(tender_cpvs,1,2)
// tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid
*destring marketid, replace
************************************
*Create filter ok

gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name) & bid_iswinning!="f"
// count if tender_finalprice>10000000 & filter_ok
// tab filter_ok, m  //1,161,033
// count if filter_ok
// di `r(N)'/_N  
************************************
*Dates

gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen last_cft_pub = date(tender_publications_lastcallfor, "YMD")
format bid_deadline first_cft_pub last_cft_pub %d

gen aw_date = date(tender_publications_firstdcontra, "YMD")
gen ca_date = date(tender_awarddecisiondate, "YMD")
format aw_date ca_date first_cft_pub %d
label var aw_date "award date - from publication first contract date"
label var ca_date "award decision date"
************************************
*Supply type

encode tender_supplytype, gen(ca_type)
replace ca_type=. if tender_supplytype==""
// tab ca_type, m
replace ca_type=99 if ca_type==.
************************************
*Buyer type

// tab buyer_buyertype, m
encode buyer_buyertype, gen(anb_type)
replace anb_type=. if buyer_buyertype==""
// tab anb_type, m
replace anb_type=9 if anb_type==.
************************************
*Buyer Location

// tab buyer_nuts, m
gen anb_nuts2 = substr(buyer_nuts,1,2)
replace buyer_nuts="" if anb_nuts2!="PT"
gen buyer_nuts2 = substr(buyer_nuts,1,3)
encode buyer_nuts2,gen(anb_loc)
replace anb_loc=999 if anb_loc==.
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END
