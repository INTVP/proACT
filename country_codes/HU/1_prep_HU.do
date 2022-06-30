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
*Generate main working filter
*Rule: Filter ok main - not missing bidder name

gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name)
// tab filter_ok, m

// tab bid_iswinning if filter_ok, m //all true
// tab bid_iswinning if filter_ok==0, m //we lose 38.8k obs due to missing bidder name
************************************

*Checking opentender
// br opentender bid_price *digiwhist*
// tabstat bid_price, by(opentender)
// tab opentender if filter_ok, m
// tab source if filter_ok & opentender=="f", m
// bys source: tab opentender if filter_ok, m
replace filter_ok=0 if opentender=="f" 
************************************

*Remove cancelled tenders from filter_ok
gen cancel = 0
replace cancel = 1 if !missing(tender_cancellationdate)
// tab cancel, m
replace filter_ok =0 if cancel==1
drop cancel

// count if missing(tender_publications_lastcontract) & filter_ok==1
// tab source if missing(tender_publications_lastcontract) & filter_ok==1
// br bid_iswinning bidder_name bid_price tender_awarddecisiondate tender_publications_lastcontract if missing(tender_publications_lastcontract) & filter_ok==1 //53k obs with missing contract url but bidder_name is not missing - national source
************************************

*Checking framework agreements
// tab tender_isframework if filter_ok, m //only 6k framework
// gen miss_frame = missing(tender_isframework)
// tab source if miss_frame==1 & filter_ok //missing framework agg var if source is national - so it means we don't know if its a framework agreement or not mainly this national source: "http://kozbeszerzes.hu/"
// tab source if miss_frame==0 & filter_ok
// drop miss_frame
************************************
*Checking bid_isconsortium

// tab bid_isconsortium 
// tab bid_isconsortium if filter_ok, m //7.6k consortiums 
//
// sort tender_id lot_row_nr
// br tender_id tender_lotscount lot_row_nr tender_recordedbidscount lot_bidscount  buyer_name bidder_name bidder_name bid_price tender_isframework bid_isconsortium if bid_isconsortium=="t"
*Seems to be recorded well

// unique tender_id lot_row_nr if filter_ok
// bys tender_id lot_row_nr: gen x = _N if filter_ok
// br tender_id tender_lotscount lot_row_nr tender_recordedbidscount lot_bidscount  buyer_name bidder_name bidder_name bid_price tender_isframework bid_isconsortium if filter_ok & x>1
// drop x
********************************************************************************
* Check tender final price - contract price

// sort  tender_id lot_row_nr
// format persistent_id tender_id bidder_name tender_title lot_title %15s
// br persistent* tender_id lot_row_nr tender_title lot_title bidder_name *price* currency if filter_ok

*Fix currency
// tab curr if filter_ok, m
drop if !inlist(curr,"","EUR","HUF")
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use "${utility_data}/wb_ppp_data.dta", clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_eu.dta", replace

use "${utility_data}/wb_ppp_data.dta", clear
keep if inlist(countryname,"Hungary")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_hu.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta",clear

*Fixing the year variable
// tab tender_year if filter_ok, m //all good

// br tender_year *publi* *dead* *date* if missing(tender_year)

*for the missing currency if source is ted then assume EUR
gen year = tender_year
merge m:1 year using "${country_folder}/ppp_data_eu.dta"
drop if _m==2
// tab year if _m==1, m //2020 no ppp data
// tabstat ppp, by(year)
replace ppp=.684051 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year
rename ppp ppp_eur

gen year = tender_year
merge m:1 year using"${country_folder}/ppp_data_hu.dta"
drop if _m==2
// tab year if _m==1, m //2020 no ppp data
// tabstat ppp, by(year)
replace ppp=140.9354 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop year _m
rename ppp ppp_huf

// br tender_finalprice  bid_price tender_estimatedprice lot_estimatedprice  currency
// tab currency, m
// tab currency if filter_ok, m
// tab source if missing(currency)
// tab source if currency=="HUF"
// tab source if currency=="EUR"
*Local source assume HUF
*Ted assume EUR

foreach var of varlist bid_price tender_finalprice tender_estimatedprice lot_estimatedprice{
gen `var'_ppp=`var'/ppp_eur if currency=="EUR"
replace `var'_ppp=`var'/ppp_eur if missing(currency) & inlist(source,"http://data.europa.eu/","http://ted.europa.eu")
replace `var'_ppp=`var'/ppp_huf if currency=="HUF"
replace `var'_ppp=`var'/ppp_huf if missing(currency) & inlist(source,"http://kozbeszerzes.hu/","http://kozbeszerzes.hu/csv")
}

// sort source
// br  source currency bid_price bid_price_ppp tender_finalprice tender_finalprice_ppp tender_estimatedprice tender_estimatedprice_ppp lot_estimatedprice  lot_estimatedprice_ppp ppp_huf ppp_eur

// count if missing(bid_price) & filter_ok
// count if missing(bid_price_ppp) & filter_ok //OK!

gen curr_ppp = ""
replace curr_ppp = "International Dollars" if !missing(bid_price_ppp) | !missing(tender_finalprice_ppp) | !missing(tender_estimatedprice_ppp) | !missing(lot_estimatedprice_ppp)
********************************************************************************

*Preparing Controls 
*contract value, buyer type, tender year, market id, contract supply type, Locations
************************************
*Contract Value

// hist bid_price_ppp if filter_ok
// hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
// hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp) & bid_price_ppp!=.
gen lca_contract_value = log(bid_price_ppp)
// hist lca_contract_value if filter_ok
xtile ca_contract_value10 = bid_price_ppp if filter_ok, nq(10)
replace ca_contract_value10 = 99 if missing(bid_price_ppp)
// tab ca_contract_value10 if filter_ok, m

// tabstat bid_price_ppp if filter_ok, m by(ca_contract_value10) stat(min max n)
replace filter_ok=0 if bid_price_ppp<=100 //removed 5k very low values
drop ca_contract_value10
xtile ca_contract_value10 = bid_price_ppp if filter_ok, nq(10)
replace ca_contract_value10 = 99 if missing(bid_price_ppp)
// tab ca_contract_value10 if filter_ok, m
************************************
*Buyer type

// tab buyer_buyertype, m
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
// tab buyer_nuts, m
************************************

*Fixing Nuts for regression
/*
gen len_nuts=length(buyer_nuts)
tab len_nuts, m
gen buyer_nuts2=buyer_nuts
replace buyer_nuts2 = buyer_nuts + "000" if len_nuts==2
replace buyer_nuts2 = buyer_nuts + "00" if len_nuts==3
replace buyer_nuts2 = buyer_nuts + "0" if len_nuts==4
tab buyer_nuts2 , m
*/

gen anb_location= buyer_nuts
gen x=regexm(anb_location, "HU")
// tab x
replace anb_location="EXT" if x==0 & !missing(buyer_nuts)
replace anb_location="HU" if anb_location=="HUZ"
replace anb_location="NA" if missing(buyer_nuts)
// tab anb_location, m
drop x
replace anb_location=substr(anb_location, 1, 4)
// tab anb_location, m
encode anb_location, gen(anb_location_t)
drop anb_location
rename anb_location_t anb_location
// tab anb_location, m
************************************
*Tender year

// tab tender_year, m
************************************
*Contract type

// tab tender_supplytype, m
gen supply_type = tender_supplytype
replace supply_type="NA" if missing(tender_supplytype)
encode supply_type, gen(ca_type)
drop supply_type
// tab ca_type, m
************************************
*Market ids [+ the missing cpv fix]

gen market_id=substr(tender_cpvs,1,2)
// tab market_id, m
gen market_id2 = market_id if inlist(market_id,"03","09","14","15","16","18","19") | inlist(market_id,"22","24","30","31","32","33","34","35","37") | inlist(market_id,"38","39","41","42","43","44","45","48","50") | inlist(market_id,"51","55","60","63","64","65","66","70") | inlist(market_id,"71","72","73","75","76","77","79","80") | inlist(market_id,"85","90","92","98","99") 
// tab market_id2, m
gen tender_cpvs_fixed= tender_cpvs if !missing(market_id2)
replace tender_cpvs_fixed = "99100000" if missing(tender_cpvs_fixed) & tender_supplytype=="SUPPLIES"
replace tender_cpvs_fixed = "99200000" if missing(tender_cpvs_fixed) & tender_supplytype=="SERVICES"
replace tender_cpvs_fixed = "99300000" if missing(tender_cpvs_fixed) & tender_supplytype=="WORKS"
replace tender_cpvs_fixed = "99000000" if missing(tender_cpvs_fixed) & missing(tender_supplytype)
drop market_id market_id2
gen market_id=substr(tender_cpvs_fixed,1,2)
*Clean Market id
// tab market_id, m
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
*Award date
//tender_awarddecisiondate or tender_publications_firstdcontra or tender_publications_firstdcontra
gen aw_date = date(tender_awarddecisiondate, "YMD") 
replace aw_date = date(tender_contractsignaturedate, "YMD") if missing(aw_date)
replace aw_date = date(tender_publications_firstdcontra, "YMD") if missing(aw_date)

format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END
