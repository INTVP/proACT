local country "`0'"
********************************************************************************
/*This script prepares IE data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data 
use  "${country_folder}/`country'_wip.dta",  clear
********************************************************************************
*Var transformations 


// tab anb_country
// tab anb_city
// tab anb_loc

*Buyer name 
gen anb_name = ustrlower(buyer_name)
replace anb_name = subinstr(anb_name, "commmision", "commmission", .) 

************************************

*Buyer type
cap drop buyer_buyertype
gen buyer_buyertype = ""
replace buyer_buyertype = "NATIONAL_AUTHORITY" if ustrregexm(anb_name, "ministry|authority|parliament", 1)
replace buyer_buyertype = "NATIONAL_AGENCY" if ustrregexm(anb_name, "commission|office|agency|directorate|courts", 1)
replace buyer_buyertype = "PUBLIC_BODY" if ustrregexm(anb_name, "uganda development bank|bank of uganda", 1)
replace buyer_buyertype = "REGIONAL_AUTHORITY" if ustrregexm(anb_name, "regional|local|university|hospital|municipal|school|centre|company|institute|cooperation|holdings|limited|ltd", 1)
replace buyer_buyertype = "NATIONAL_AUTHORITY" if ustrregexm(anb_name, "police|prison", 1)
replace buyer_buyertype = "NATIONAL_AGENCY" if ustrregexm(anb_name, "uganda|inspectorate|council", 1)
replace buyer_buyertype = "OTHER" if missing(buyer_buyertype)
replace buyer_buyertype = "" if  missing(anb_name)

// tab buyer_buyertype
encode buyer_buyertype, gen(anb_type)


*Bidder id
// encode bidder_masterid, gen(w_id)
************************************
*Create tender final price

bys tender_id: ereplace tender_finalprice=total(bid_price) if bid_iswinning=="t"
sort tender_id tender_finalprice
bys tender_id: replace tender_finalprice=tender_finalprice[1] if tender_finalprice==.
// sum tender_finalprice
// sum tender_finalprice if tender_finalprice==0 //228,260
// tab bid_iswinning if tender_finalprice==0 //t
// tab tender_proceduretype if tender_finalprice==0 //only few cases
************************************

*Create contract value from bid_price
gen ca_contract_value=bid_price
gen lca_contract_value=log(ca_contract_value)
// hist lca_contract_value // normal

xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)
************************************
*Market id
replace tender_cpvs = cpv_global if tender_cpvs=="99000000," & cpv_global!="."
drop cpv_nori_str cpv_global miss_cpv 
gen marketid = substr(tender_cpvs,1,2)
tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid
************************************

*Create filter ok
gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name)
************************************

*Dates
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen last_cft_pub = date(tender_publications_lastcallfor, "YMD")
format bid_deadline first_cft_pub %d

// sum bid_deadline first_cft_pub last_cft_pub
************************************

*Supply type
encode tender_supplytype, gen(ca_type)
*replace ca_type=. if tender_supplytype==""
*tab ca_type, m
*was not available on source
************************************

*Buyer type
tab anb_type, m
************************************

*Buyer Location
tab buyer_nuts, m
encode buyer_nuts,gen(anb_loc)
************************************
*Prices ppp adjustments

save "${country_folder}/UG_wip.dta", replace


use "${utility_data}/wb_ppp_data.dta", clear
keep if countrycode == "UGA"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save "${country_folder}/ppp_data.dta", replace

use "${country_folder}/UG_wip.dta", clear
// br tender_finalprice ca_contract_value bid_price *price* *value*
// tab currency, m
// tab tender_year, m
gen year = tender_year
merge m:1 year using $country_folder/ppp_data.dta
drop if _m==2
// tabstat ppp, by(year)
replace ppp=1277.77 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m year

gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="UGX" | missing(currency)
gen bid_price_ppp =  bid_price/ppp if currency=="UGX" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="UGX" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="UGX" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="UGX" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="UGX" | missing(currency)

// br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END