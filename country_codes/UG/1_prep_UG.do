*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares IE data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
use $country_folder/UG_cpv_fixed_200613.dta, clear
********************************************************************************

*Var transformations 


tab anb_country
tab anb_city
tab anb_loc

*Buyer name 

gen anb_name_str=lower(buyer_name)
replace anb_name_str = subinstr(anb_name_str, "commmision", "commmission", .) 
drop anb_name_str

************************************

*Buyer type
replace buyer_buyertype = "NATIONAL_AUTHORITY" if buyer_buyertype=="" & strpos(anb_name_str, "national") | buyer_buyertype=="" & strpos(anb_name_str, "ministry") | buyer_buyertype=="" & strpos(anb_name_str, "authority") | buyer_buyertype=="" & strpos(anb_name_str, "parliament") 
replace buyer_buyertype = "NATIONAL_AGENCY" if buyer_buyertype=="" & strpos(anb_name_str, "commission") | buyer_buyertype=="" & strpos(anb_name_str, "office") | buyer_buyertype=="" & strpos(anb_name_str, "agency") | buyer_buyertype=="" & strpos(anb_name_str, "directorate") | buyer_buyertype=="" & strpos(anb_name_str, "courts") 
replace buyer_buyertype = "PUBLIC_BODY" if buyer_buyertype=="" & strpos(anb_name_str, "uganda development bank") | buyer_buyertype=="" & strpos(anb_name_str, "bank of uganda")
replace buyer_buyertype = "REGIONAL_AUTHORITY" if buyer_buyertype=="" & strpos(anb_name_str, "regional")
replace buyer_buyertype = "NATIONAL_AUTHORITY" if buyer_buyertype=="" & strpos(anb_name_str, "police") | buyer_buyertype=="" & strpos(anb_name_str, "prison")
replace buyer_buyertype = "REGIONAL_AUTHORITY" if buyer_buyertype=="" & strpos(anb_name_str, "local") | buyer_buyertype=="" & strpos(anb_name_str, "university") | buyer_buyertype=="" & strpos(anb_name_str, "hospital") | buyer_buyertype=="" & strpos(anb_name_str, "municipal") | buyer_buyertype=="" & strpos(anb_name_str, "school")
replace buyer_buyertype = "REGIONAL_AUTHORITY" if buyer_buyertype=="" & strpos(anb_name_str, "centre") |buyer_buyertype=="" & strpos(anb_name_str, "company") | buyer_buyertype=="" & strpos(anb_name_str, "institute") | buyer_buyertype=="" & strpos(anb_name_str, "institute") | buyer_buyertype=="" & strpos(anb_name_str, "cooperation") | buyer_buyertype=="" & strpos(anb_name_str, "holdings") | buyer_buyertype=="" & strpos(anb_name_str, "limited") | buyer_buyertype=="" & strpos(anb_name_str, "ltd") 
replace buyer_buyertype = "NATIONAL_AGENCY" if buyer_buyertype=="" & strpos(anb_name_str, "uganda") | buyer_buyertype=="" & strpos(anb_name_str, "inspectorate") | buyer_buyertype=="" & strpos(anb_name_str, "council") 
replace buyer_buyertype = "OTHER" if buyer_buyertype==""
replace buyer_buyertype = "" if anb_name_str==""
tab buyer_buyertype
encode buyer_buyertype, gen(anb_type)


*Bidder id
encode bidder_masterid, gen(w_id)
************************************

*Create tender final price

bys tender_id: ereplace tender_finalprice=total(bid_price) if bid_iswinning=="t"
sort tender_id tender_finalprice
bys tender_id: replace tender_finalprice=tender_finalprice[1] if tender_finalprice==.
sum tender_finalprice
sum tender_finalprice if tender_finalprice==0 //228,260
tab bid_iswinning if tender_finalprice==0 //t
tab tender_proceduretype if tender_finalprice==0 //only few cases
************************************

*Create contract value from bid_price
gen ca_contract_value=bid_price
gen lca_contract_value=log(ca_contract_value)
hist lca_contract_value // normal

xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)
************************************

*Market id

gen marketid = substr(tender_cpvs,1,2)
tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid
************************************

*Create filter ok
gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name)
*Filtering out contracts with very high values
count if tender_finalprice>10000000 & filter_ok
tab filter_ok, m  //441,248, 58.41% of observations
************************************

*Dates
gen bid_deadline = date(tender_biddeadline, "YMD")
gen first_cft_pub = date(tender_publications_firstcallfor, "YMD")
gen last_cft_pub = date(tender_publications_lastcallfor, "YMD")
format bid_deadline first_cft_pub %d

sum bid_deadline first_cft_pub last_cft_pub
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

*Market id
gen marketid = substr(tender_cpvs,1,2)
tab marketid
encode marketid, gen(marketid2)
drop marketid
rename marketid2 marketid


tab marketid
tab marketid if filter_ok==1, missing
replace marketid=99 if marketid==.

egen x= nvals(marketid)
tab x
drop x
*33
************************************

*Prices ppp adjustments

save $country_folder/UG_wip.dta, replace


use $utility_data/wb_ppp_data.dta, clear
keep if countrycode == "UGA"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save $country_folder/ppp_data.dta, replace

use $country_folder/UG_wip.dta, clear
br tender_finalprice ca_contract_value bid_price *price* *value*
tab currency, m
tab tender_year, m
gen year = tender_year
merge m:1 year using $country_folder/ppp_data.dta
drop if _m==2
tabstat ppp, by(year)
replace ppp=1277.77 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year

gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="UGX" | missing(currency)
gen bid_price_ppp =  bid_price/ppp if currency=="UGX" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="UGX" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="UGX" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="UGX" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="UGX" | missing(currency)

br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
************************************

save $country_folder/UG_wip.dta, replace