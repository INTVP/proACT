********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
********************************************************************************

*Gen filter_ok
gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name)
import delimited using  "${utility_data}/country/MT/MT_data.csv", encoding(UTF-8) clear


************************************
bys persistent_id  tender_id lot_row_nr: gen x=_N
count if x > 1
assert r(N) == 566 //566 observations, this happens because....?

count if missing(tender_publications_lastcontract) & filter_ok //only 0 obs within filter_ok looks good
************************************

*Check tender final price - contract price
sort  tender_id lot_row_nr
format persistent_id tender_id bidder_name tender_title lot_title %15s
*Estimated:
*tender_estimatedprice, lot_estimatedprice
*Actual:
*tender_finalprice, bid_price
*Fix currency

save "${country_folder}/MT_wip.dta", replace

********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)

use "${utility_data}/wb_ppp_data.dta", clear

keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp

save "${country_folder}/ppp_data_eu.dta", replace // it seems inefficient so save this only to merge it later, unless it is also used elsewhere. If it is not, I'd suggest saving it as a tempfile instead.

********************************************************************************
use "${country_folder}/MT_wip.dta",clear

gen year = tender_year
replace ppp=.684051 if missing(ppp) & year==2020 //used 2019
rename ppp ppp_eur

merge m:1 year using "${country_folder}/ppp_data_eu.dta", keep(1 3) nogen // removing non-matched observations from using data because...?
************************************

gen bid_price_ppp=bid_price
replace bid_price_ppp = bid_price/ppp_eur if currency=="EUR"
replace bid_price_ppp = bid_price/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen tender_finalprice_ppp=tender_finalprice
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if currency=="EUR"
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen tender_estimatedprice_ppp=tender_estimatedprice
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if currency=="EUR"
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen lot_estimatedprice_ppp=lot_estimatedprice
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if currency=="EUR"
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen curr_ppp = ""
replace curr_ppp = "International Dollars" if !missing(bid_price_ppp) | !missing(tender_finalprice_ppp) | !missing(tender_estimatedprice_ppp) | !missing(lot_estimatedprice_ppp)
replace curr_ppp = currency if !inlist(currency,"EUR")

********************************************************************************
*Preparing Controls 
*contract value, buyer type, tender year, market id, contract supply type
************************************

*Contract Value

xtile ca_contract_value100 = bid_price_ppp if filter_ok==1, nq(100)
replace ca_contract_value100=999 if missing(ca_contract_value) & filter_ok==1
************************************

*Buyer type
gen buyer_type = buyer_buyertype
replace buyer_type="NA" if missing(buyer_type)
encode buyer_type, gen(anb_type)
drop buyer_type
************************************

*Tender year
************************************

*Contract type
gen supply_type = tender_supplytype
replace supply_type="NA" if missing(tender_supplytype)
encode supply_type, gen(ca_type)
drop supply_type
************************************

*Market ids [+ the missing cpv fix]
replace tender_cpvs = "99100000" if missing(tender_cpvs) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) & missing(tender_supplytype)
gen market_id=substr(tender_cpvs,1,2)
replace market_id="NA" if missing(tender_cpvs)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
************************************

*Buyer locations
gen buyer_location = buyer_nuts
replace buyer_location= "Missing" if missing(buyer_location)
encode buyer_location,gen(buyer_location2)
drop buyer_location
rename buyer_location2 buyer_location
************************************

*Dates
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
format bid_deadline first_cft_pub aw_date %d

********************************************************************************

save "${country_folder}/MT_wip.dta", replace

********************************************************************************
*END
