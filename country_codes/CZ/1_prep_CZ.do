*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
import delimited using  $utility_data/country/AT/starting_data/CZ_data.csv, encoding(UTF-8) clear
********************************************************************************

*Gen filter_ok
gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name)

tab filter_ok, m
************************************

tab bid_iswinning if filter_ok, m

br tender_id bid_price bidder_name if filter_ok==0 & !missing(bid_price)
br tender_id tender_lotscount lot_bidscount if tender_id=="378a6c22-0ad0-463d-80df-61197c4b80ae" //framework agreement
br tender_id tender_lotscount lot_bidscount bidder_name bid_price if tender_isframeworkagreement=="t" 
*Framework agreements can have 1 lot but awarded to several bidders so they will appear as duplicates 
*The obs with missing framework agreement are all coming from the national source "https://vestnikverejnychzakazek.cz "
br tender_id tender_lotscount lot_row_nr lot_bidscount bidder_name bid_price if tender_isframeworkagreement=="" & filter_ok==1
************************************

*consurtiums
tab bid_isconsortium , m
br tender_id tender_lotscount lot_bidscount bidder_name bid_price if bid_isconsortium=="t" & filter_ok==1
*Consortiums also appear as duplicates

*Conclusion: duplicate tender_ids are probably either consortiums, or framework agreements

gen x = 0
replace x = 1 if bid_isconsortium=="t" | missing(bid_isconsortium) | tender_isframeworkagreement=="t"

unique tender_id lot_row_nr 
unique tender_id lot_row_nr if filter_ok & x==0
bys tender_id lot_row_nr: gen y=_N
br tender_id tender_lotscount lot_row_nr lot_bidscount bidder_name bid_price filter_ok x y if filter_ok==1 & x==0 & y>1

br if tender_id=="02e1ef19-8e17-4f4a-b6cb-298a13385643"
drop x y 

tab opentender, m
tab bid_iswinning, m
************************************
  
gen cancel = 0
replace cancel = 1 if !missing(tender_cancellationdate)
tab cancel, m

replace filter_ok =0 if cancel==1
************************************

unique tender_id lot_row_nr if filter_ok
************************************
*Checking structure

sort tender_id lot_row_nr
br persistent_id tender_id lot_row_nr source opentender *title* *

*same tender_id & lot_row_nr -- if duplicates check bidder_name, if different then it means that the same lot was awarded to two bidders
bys tender_id lot_row_nr: gen x=_N
format bidder_name source %15s
br tender_id lot_row_nr x  bidder_name bid_price source opentender bid_iswinning *title* * if x>1

br *url* *pub* if tender_id=="0a9a28c0-4dfb-4705-98d3-ec5d2cc299f8"
drop x cancel

bys tender_id: gen x=_N
br x tender_id lot_row_nr *title* *bidder* bid_price source notice_url tender_publications_lastcontract if x>1 

br x tender_id lot_row_nr bid_iswinning if x>1 

br if tender_id=="e7de1bc2-9bba-4e9d-a721-267985c41111"
************************************

count if missing(tender_publications_lastcontract) & filter_ok //only 122 obs within filter_ok looks good
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
tab curr if filter_ok
save $country_folder/CZ_wip.dta
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use $utility_data/wb_ppp_data, clear
keep if inlist(countryname,"Czech Republic")
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_czk.dta

use $utility_data/wb_ppp_data, clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_eu.dta
********************************************************************************
use $country_folder/CZ_wip.dta,clear
*for the missing currency if source is ted then assume EUR, if source is national assume CZK
gen year = tender_year
merge m:1 year using $country_folder/ppp_data_czk.dta
drop if _m==2
tab year if _m==1, m //2020 no ppp data
tabstat ppp, by(year)
replace ppp=12.44317 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year
rename ppp ppp_czk

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
replace bid_price_ppp = bid_price/ppp_czk if currency=="CZK"
replace bid_price_ppp = bid_price/ppp_czk if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen tender_finalprice_ppp=tender_finalprice
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if currency=="EUR"
replace tender_finalprice_ppp = tender_finalprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)
replace tender_finalprice_ppp = tender_finalprice/ppp_czk if currency=="CZK"
replace tender_finalprice_ppp = tender_finalprice/ppp_czk if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen tender_estimatedprice_ppp=tender_estimatedprice
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if currency=="EUR"
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_czk if currency=="CZK"
replace tender_estimatedprice_ppp = tender_estimatedprice/ppp_czk if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)


gen lot_estimatedprice_ppp=lot_estimatedprice
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if currency=="EUR"
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_eur if inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_czk if currency=="CZK"
replace lot_estimatedprice_ppp = lot_estimatedprice/ppp_czk if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen curr_ppp = ""
replace curr_ppp = "International Dollars" if !missing(bid_price_ppp) | !missing(tender_finalprice_ppp) | !missing(tender_estimatedprice_ppp) | !missing(lot_estimatedprice_ppp)
replace curr_ppp = currency if !inlist(currency,"CZK","EUR")
********************************************************************************

*Preparing Controls 
*contract value, buyer type, tender year, market id, contract supply type, Locations
************************************

*Contract Value
hist bid_price_ppp if filter_ok
hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp)
gen lca_contract_value = log(bid_price_ppp)
hist lca_contract_value if filter_ok

xtile ca_contract_value10 = bid_price_ppp if filter_ok, nq(10)
replace ca_contract_value10=99 if missing(bid_price_ppp)
************************************

*Buyer type
tab buyer_buyertype, m
gen buyer_type = buyer_buyertype
replace buyer_type="NA" if missing(buyer_type)
encode buyer_type, gen(anb_type)
drop buyer_type
tab anb_type, m
************************************

*Location 
br *imp* *city*
tab tender_addressofimplementation_n, m
tab buyer_city, m
tab buyer_nuts, m
gen anb_location1 = buyer_nuts
replace anb_location1="NA" if missing(anb_location1)
encode anb_location1, gen(anb_location)
drop anb_location1
tab anb_location, m
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

*Dates
br *publi* *dead* *date*
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save $country_folder/CZ_wip.dta , replace
********************************************************************************
*END
