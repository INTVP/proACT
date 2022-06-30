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
*Filter ok main - not missing bidder name

// tab opentender
gen filter_ok=0
replace filter_ok =1 if !missing(bidder_name) & opentender=="t"

// tab filter_ok, m
// tab bid_iswinning if filter_ok, m
************************************
*Remove cancelled tenders from filter_ok

gen cancel = 0
replace cancel = 1 if !missing(tender_cancellationdate)
// tab cancel, m
replace filter_ok =0 if cancel==1
drop cancel

// count if missing(tender_publications_lastcontract) & filter_ok==1
// br bid_iswinning bidder_name bid_price tender_awarddecisiondate tender_publications_lastcontract if missing(tender_publications_lastcontract) & filter_ok==1 //0 obs with missing contract url but bidder_name is not missing
************************************
*Checking framework agreements

// tab tender_isframework if filter_ok, m
gen miss_frame = missing(tender_isframework)
// tab source if miss_frame==1 & filter_ok //missing framework agg var if source is national - so it means we don't know if its a framework agreement or not mainly this national source: "https://www.tenderned.nl "
// tab source if miss_frame==0 & filter_ok
drop miss_frame

format tender_id tender_title lot_title buyer_name bidder_name tender_isframework %15s
sort tender_id  lot_row_nr 
// br tender_id tender_lotscount lot_row_nr tender_recordedbidscount lot_bidscount  buyer_name bidder_name bidder_name tender_isframework if filter_ok
************************************
*Checking bid_isconsortium

// tab bid_isconsortium 
// tab bid_isconsortium if filter_ok, m

sort tender_id  lot_row_nr 
// br tender_id tender_lotscount lot_row_nr tender_recordedbidscount lot_bidscount  buyer_name bidder_name bidder_name bid_price tender_isframework bid_isconsortium if bid_isconsortium=="t" 
// tab tender_lotscount if missing(lot_row_nr)
********************************************************************************
// unique tender_id lot_row_nr if filter_ok
bys tender_id lot_row_nr: gen x = _N if filter_ok
format source %10s
// br source tender_id tender_lotscount lot_row_nr tender_recordedbidscount lot_bidscount  buyer_name bidder_name bidder_name bid_price tender_isframework bid_isconsortium if filter_ok & x>1
drop x
************************************
*Check tender final price - contract price

sort  tender_id lot_row_nr
format persistent_id tender_id bidder_name tender_title lot_title %15s
// br persistent* tender_id lot_row_nr tender_title lot_title bidder_name *price* if filter_ok 
*!inlist(currency,"EUR","")
// count if missing(tender_finalprice) & filter_ok
// count if missing(tender_digiwhist_price) & filter_ok
// count if missing(bid_price) & filter_ok
// count if missing(bid_digiwhist_price) & filter_ok

*Fix missing bid_price from bid_digiwhist_price
replace bid_price=bid_digiwhist_price if missing(bid_price) & bid_iswinning=="t"

*Fix currency
// tab currency if filter_ok, m
drop if !inlist(currency,"EUR","") //1 obs
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use "$utility_data/wb_ppp_data.dta", clear
keep if inlist(countryname,"EU28")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_eu.dta", replace
********************************************************************************
use"${country_folder}/`country'_wip.dta",clear
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
************************************

// br tender_finalprice  bid_price tender_estimatedprice lot_estimatedprice  currency
// tab currency if filter_ok, m
// tab source if missing(currency) & filter_ok==1 //assume EUR price for all

gen bid_price_ppp = bid_price/ppp_eur 
gen tender_finalprice_ppp=tender_finalprice/ppp_eur
gen tender_estimatedprice_ppp=tender_estimatedprice/ppp_eur
gen lot_estimatedprice_ppp=lot_estimatedprice/ppp_eur
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

// tabstat bid_price_ppp if filter_ok, m by(ca_contract_value10) stat(min max n)
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
// tab tender_addressofimplementation_n if missing(buyer_nuts)
gen buyer_nuts_handle=buyer_nuts
replace buyer_nuts_handle= tender_addressofimplementation_n if missing(buyer_nuts)
replace buyer_nuts_handle=subinstr(buyer_nuts_handle,`""NL, "',"",.)
replace buyer_nuts_handle=subinstr(buyer_nuts_handle,"NL,","",.) if regex(buyer_nuts_handle,"^NL,")
replace buyer_nuts_handle=subinstr(buyer_nuts_handle,`"""',"",.)
replace buyer_nuts_handle="" if buyer_nuts_handle=="-"
split buyer_nuts_handle, p(",")
drop buyer_nuts_handle2 buyer_nuts_handle3 buyer_nuts_handle4
// tab buyer_nuts_handle1, m
*Condense the locations
replace buyer_nuts_handle1=substr(buyer_nuts_handle1,1,3)
replace buyer_nuts_handle1="NL" if buyer_nuts_handle1=="NLZ"

gen anb_location1=buyer_nuts_handle1 if regex(buyer_nuts_handle1,"^NL") 
replace anb_location1="EXT" if regex(anb_location1,"^NL")==0 & !missing(buyer_nuts)
replace anb_location1="NA" if missing(anb_location1)
encode anb_location1, gen(anb_location)
drop anb_location1
// tab anb_location, m //better
drop buyer_nuts_handle buyer_nuts_handle1
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
*Clean Market id
// tab market_id, m
*Two product codes systems in data
gen market_id2 = market_id if inlist(market_id,"03","09","14","15","16","18","19") | inlist(market_id,"22","24","30","31","32","33","34","35","37") | inlist(market_id,"38","39","41","42","43","44","45","48","50") | inlist(market_id,"51","55","60","63","64","65","66","70") | inlist(market_id,"71","72","73","75","76","77","79","80") | inlist(market_id,"85","90","92","98","99") 
// tab market_id2, m

*replace bad codes as missing  - dropping bad codes //937 observations
rename tender_cpvs tender_cpvs_original
gen tender_cpvs= tender_cpvs_original
replace tender_cpvs = "99100000" if missing(market_id2) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(market_id2) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(market_id2) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(market_id2) & missing(tender_supplytype)
drop market_id market_id2

gen market_id=substr(tender_cpvs,1,2)

*Clean Market id
// tab market_id, m
replace market_id="NA" if missing(market_id)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
// tab market_id, m
*Use tender_cpvs as the main product code variable
************************************
*Dates

// br *publi* *dead* *date*
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen aw_date = date(tender_awarddecisiondate, "YMD") //tender_awarddecisiondate or tender_publications_firstdcontra
format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END
