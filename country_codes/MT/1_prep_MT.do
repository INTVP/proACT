********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
import delimited using  $utility_data/country/AT/starting_data/MT_data.csv, encoding(UTF-8) clear
********************************************************************************

*Gen filter_ok
gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name)

tab filter_ok, m

tab opentender, m
tab bid_iswinning, m
tab bid_iswinning if filter_ok, m
************************************
unique persistent_id tender_id lot_row_nr if filter_ok
bys persistent_id  tender_id lot_row_nr: gen x=_N
br persistent_id  tender_id lot_row_nr tender_title lot_title bidder_name bid_price bid_iswinning x if x>1
*566 observations

count if missing(tender_publications_lastcontract) & filter_ok //only 0 obs within filter_ok looks good
************************************

*Check tender final price - contract price
sort  tender_id lot_row_nr
format persistent_id tender_id bidder_name tender_title lot_title %15s
br persistent* tender_id lot_row_nr tender_title lot_title bidder_name *price* if filter_ok
*Estimated:
*tender_estimatedprice, lot_estimatedprice
*Actual:
*tender_finalprice, bid_price
*Fix currency
tab curr if filter_ok, m
tab source if missing(currency) //missing source is ted so we assume its EUR
save $country_folder/MT_wip.dta, replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use $utility_data/wb_ppp_data.dta, clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_eu.dta, replace
********************************************************************************
use $country_folder/MT_wip.dta,clear

gen year = tender_year
merge m:1 year using $country_folder/ppp_data_eu.dta
drop if _m==2
tab year if _m==1, m //2020 no ppp data
tabstat ppp, by(year)
replace ppp=.684051 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year
rename ppp ppp_eur
************************************
br tender_finalprice  bid_price tender_estimatedprice lot_estimatedprice  currency
tab currency, m

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
tab curr_ppp if filter_ok, m

********************************************************************************
*Preparing Controls 
*contract value, buyer type, tender year, market id, contract supply type
************************************

*Contract Value
hist bid_price_ppp if filter_ok
hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp)
gen lca_contract_value = log(bid_price_ppp)
hist lca_contract_value if filter_ok

xtile ca_contract_value100 = bid_price_ppp if filter_ok==1, nq(100)
replace ca_contract_value100=999 if missing(ca_contract_value) & filter_ok==1
************************************

*Buyer type
tab buyer_buyertype, m
gen buyer_type = buyer_buyertype
replace buyer_type="NA" if missing(buyer_type)
encode buyer_type, gen(anb_type)
drop buyer_type
tab anb_type, m
************************************

*Tender year
tab tender_year, m
************************************

*Contract type
tab tender_supplytype, m
gen supply_type = tender_supplytype
replace supply_type="NA" if missing(tender_supplytype)
encode supply_type, gen(ca_type)
drop supply_type
tab ca_type, m
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
tab market_id, m
************************************

*Buyer locations
tab buyer_nuts, m
gen buyer_location = buyer_nuts
replace buyer_location= "Missing" if missing(buyer_location)
encode buyer_location,gen(buyer_location2)
drop buyer_location
rename buyer_location2 buyer_location
tab buyer_location, m
************************************

*Dates
br *publi* *dead* *date*
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save $country_folder/MT_wip.dta , replace
********************************************************************************
*END
