local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data 

use "${utility_data}/country/`country'/starting_data/ebrd_gpa_moldova_alldata_181121.dta", clear
********************************************************************************
*checking variables and finding correspondence to the DW var names

// tab procurementmethod
*sum tender_id

rename supplytype tender_supplytype
// tab tender_supplytype

ren ten_enddate tender_biddeadline
ren ten_startdate tender_publications_firstcallfor
ren advp_days submp

gen tender_awarddecisiondate = .
ren con_startdate tender_contractsignaturedate
ren decp_days decp

ren bidder_nr bid_number

ren procurementmethod tender_proceduretype

// ren procuringentityid buyer_masterid
tostring procuringentityid, replace force format(%24.0g)
gen buyer_masterid = "MD" + procuringentityid if !missing(procuringentityid)
gen buyer_id = buyer_masterid

rename procuringentityname buyer_name
rename anb_address_raw buyer_city
gen buyer_country = "MD"

ren buyertype_raw buyer_buyertype 

rename suppliersid bidder_masterid
gen bidder_id = bidder_masterid

ren w_country bidder_country
ren awards0suppliers0addressstre bidder_address 
ren suppliersname bidder_name
ren contract_value bid_price
ren contract_valuecurr curr 

ren cpv tender_cpvs

gen bid_iswinning = "t"

*ren tender_title title
ren title lot_title 
************************************
// tab filter_ok, m
// tab bid_iswinning if filter_ok, m

// tab curr if filter_ok
save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)

use "${utility_data}/wb_ppp_data", clear
keep if inlist(countryname,"Moldova")
drop if ppp==.
keep year ppp
save "${country_folder}/ppp_data_mdl.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta", clear

merge m:1 year using "${country_folder}/ppp_data_mdl.dta"
drop if _merge==2
// tab year if _merge==1, m //2020 no ppp data
// tabstat ppp, by(year)
replace ppp=5.823962 if missing(ppp) & year==2020 //used 2019
replace ppp=5.823962 if missing(ppp) & year==2021 //used 2019
// br year ppp if _merge==3
drop _merge
rename ppp ppp_mdl

gen bid_price_ppp=bid_price
replace bid_price_ppp = bid_price/ppp_mdl if curr=="mdl"
*replace bid_price_ppp = bid_price/ppp_hrk if !inlist(source,"http://data.europa.eu/","http://ted.europa.eu") & missing(currency)

gen curr_ppp = "International Dollars"
********************************************************************************
*Preparing Controls 
*Contract value, buyer type, tender year, market id, contract supply type

*Contract Value
// hist bid_price_ppp if filter_ok
// hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
// hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp)
gen lca_contract_value = log(bid_price_ppp)
// hist lca_contract_value if filter_ok

*Contract value as 10 categories
xtile cvalue10=bid_price_ppp if filter_ok==1, nquantiles(10)
replace cvalue10=99 if bid_price_ppp==.
************************************
*Buyer type

// tab buyer_buyertype, m
gen buyer_type = buyer_buyertype

replace buyer_type="" if missing(buyer_type)
replace buyer_type="NATIONAL_AGENCY" if buyer_type=="national authority"
replace buyer_type="REGIONAL_AUTHORITY" if buyer_type=="regional or local authority"
replace buyer_type="OTHER" if buyer_type=="hospital" | buyer_type=="other"
// tab buyer_type, m  //use this for the output
cap drop buyer_buyertype
gen buyer_buyertype = buyer_type
cap drop anb_type
encode buyer_type, gen(anb_type)
drop buyer_type
// tab anb_type, m
************************************
*Tender year

gen tender_year = year
// tab tender_year, m
************************************
*Contract type

// tab tender_supplytype, m
*gen supply_type = tender_supplytype
*replace supply_type="NA" if missing(tender_supplytype)
*encode tender_supplytype, gen(ca_type)
*drop supply_type
*
cap drop ca_type
gen ca_type = string(tender_supplytype, "%9.0f" )
replace ca_type="SUPPLIES" if ca_type=="2"
replace ca_type="SERVICES" if ca_type=="1"
replace ca_type="WORKS" if ca_type=="3"
// tab ca_type, m
gen ca_type_str = ca_type

encode ca_type,gen(ca_type2)
drop ca_type
ren ca_type2 ca_type
*tab ca_type, m
************************************
*Market ids [+ the missing cpv fix]

replace tender_cpvs = "99100000" if missing(tender_cpvs) & ca_type_str=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & ca_type_str=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & ca_type_str=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) & missing(ca_type_str)

gen market_id=substr(tender_cpvs,1,2)
replace market_id="NA" if missing(tender_cpvs)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
// tab market_id, m
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END