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
*Gen filter_ok

replace bidder_name="" if bidder_name=="."
replace bid_iswinning="" if bid_iswinning=="."
gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name)

// tab filter_ok, m
// tab bid_iswinning if filter_ok, m
************************************

// unique tender_id lot_row_nr if filter_ok
******************************************
// count if missing(tender_publications_lastcontract) & filter_ok // 0 obs within filter_ok looks good
******************************************
*Check tender final price - contract price

sort  tender_id lot_row_nr
format persistent_id tender_id bidder_name tender_title lot_title %15s
// br persistent* tender_id lot_row_nr tender_title lot_title bidder_name *price* if filter_ok

*Fix currency
// tab curr if filter_ok, m
// br bid_price source curr if filter_ok
save "${country_folder}/`country'_wip.dta",replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use "${utility_data}/wb_ppp_data.dta", clear
keep if inlist(countryname,"Romania")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_ro.dta", replace

use "${utility_data}/wb_ppp_data.dta", clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_eu.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta", clear
*for the missing currency if source is ted then assume EUR, if source is national assume RO
// tab source if cur=="." & filter_ok
gen year = tender_year
// tab year, m
merge m:1 year using "${country_folder}/ppp_data_ro.dta"
drop if _m==2
// tab year if _m==1, m //2020 no ppp data
// tabstat ppp, by(year)
replace ppp=1.69524 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year
rename ppp ppp_ro

gen year = tender_year
merge m:1 year using "${country_folder}/ppp_data_eu.dta"
drop if _m==2
// tab year if _m==1, m //2020 no ppp data
// tabstat ppp, by(year)
replace ppp=.684051 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year
rename ppp ppp_eur
********************************************************************************
// br tender_finalprice  bid_price tender_estimatedprice lot_estimatedprice  currency
// tab currency, m

gen bid_price_ppp=bid_price
replace bid_price_ppp = bid_price/ppp_eur if currency=="EUR"
replace bid_price_ppp = bid_price/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."
replace bid_price_ppp = bid_price/ppp_ro if currency=="RON"
replace bid_price_ppp = bid_price/ppp_ro if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."

gen tender_finalprice_ppp=tender_finalprice
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if currency=="EUR"
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."
replace tender_finalprice_ppp = tender_finalprice/ppp_ro if currency=="RON"
replace tender_finalprice_ppp = tender_finalprice/ppp_ro if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."

gen tender_estimatedprice_ppp=tender_estimatedprice
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if currency=="EUR"
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_ro if currency=="RON"
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_ro if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."


gen lot_estimatedprice_ppp=lot_estimatedprice
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if currency=="EUR"
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_ro if currency=="RON"
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_ro if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & currency=="."

gen curr_ppp = ""
replace curr_ppp = "International Dollars" if !missing(bid_price_ppp) | !missing(tender_finalprice_ppp) | !missing(tender_estimatedprice_ppp) | !missing(lot_estimatedprice_ppp)
replace curr_ppp = currency if !inlist(currency,"RON","EUR")
********************************************************************************
*Preparing Controls 
*contract values, buyer type, Locations, tender year, market id, contract supply type, 
*******************************
*Contract Value

// hist bid_price_ppp if filter_ok
// hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
// hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp)
gen lca_contract_value = log(bid_price_ppp)
// hist lca_contract_value if filter_ok

xtile ca_contract_value10 = bid_price_ppp if filter_ok, nq(10)
replace ca_contract_value10=99 if missing(bid_price_ppp)
************************************
*Buyer type

// tab buyer_buyertype, m
replace buyer_buyertype="" if buyer_buyertype=="."
gen buyer_type = buyer_buyertype
replace buyer_type="NA" if missing(buyer_type)
encode buyer_type, gen(anb_type)
drop buyer_type
// tab anb_type, m
************************************
*Location 

// br *imp* *city*
// tab tender_addressofimplementation_n, m
// tab buyer_city, m
// tab buyer_nuts
// count if buyer_city=="."
// count if buyer_nuts=="."
************************************
*Location data 
gen anb_location1="NA" if missing(buyer_nuts)
replace anb_location1="EXT" if regex(buyer_nuts,"^RO")==0 & !missing(buyer_nuts)
replace anb_location1=buyer_nuts if regex(buyer_nuts,"^RO") & !missing(buyer_nuts)
encode anb_location1, gen(anb_location)
drop anb_location1
// tab anb_location, m
************************************
*Tender year

// tab tender_year if filter_ok, m
drop if tender_year==.
************************************
*Contract type

// tab tender_supplytype, m
replace tender_supplytype="" if tender_supplytype=="."
gen supply_type = tender_supplytype
replace supply_type="NA" if missing(tender_supplytype)
encode supply_type, gen(ca_type)
drop supply_type
// tab ca_type, m
************************************
*Market ids [+ the missing cpv fix]

replace tender_cpvs="" if tender_cpvs=="."
count if tender_cpvs==""
replace tender_cpvs = "99100000" if missing(tender_cpvs) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) & missing(tender_supplytype)
gen market_id=substr(tender_cpvs,1,2)
// tab market_id, m
*These market divisions don't belong to the CPV2008
replace market_id = "" if inlist(market_id,"01","02", "05", "10", "11", "12")
replace market_id = "" if inlist(market_id, "13", "17", "20", "21", "23", "25", "26")
replace market_id = "" if inlist(market_id,"27", "28", "29", "3.", "36", "40", "4.")
replace market_id = "" if inlist(market_id,"46", "52", "54", "6.", "61", "62", "67")
replace market_id = "" if inlist(market_id,"74", "78", "81", "91", "93", "95", "99", "CP")

replace market_id="NA" if missing(market_id)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
// tab market_id, m
************************************
*Dates

// br *publi* *dead* *date*
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
*Decision date is split between  tender_awarddecisiondate for ted and tender_contractsignaturedate for national
gen aw_date = tender_awarddecisiondate
replace aw_date=tender_contractsignaturedate if aw_date=="."
replace aw_date=tender_publications_firstdcontra if aw_date=="."
replace aw_date="" if aw_date=="."

gen aw_date2 = date(aw_date, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
drop aw_date
rename aw_date2 aw_date
format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END
