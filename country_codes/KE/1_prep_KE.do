*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
use $utility_data/country/KE/starting_data/wb_ke_cri201113.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************

/*
*Create filter ok

cap drop filter_ok 
gen filter_ok = 0 
replace filter_ok = 1 if !missing(bidder_name)
tab filter_ok

************************************

*Contract value
gen ca_contract_value=tender_finalprice
gen lca_contract_value=log(tender_finalprice)


save $country_folder/KE_wip.dta, replace
********************************************************************************
use $utility_data/wb_ppp_data.dta, clear
keep if countrycode == "KEN"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save $country_folder/ppp_data.dta, replace
********************************************************************************

use  $country_folder/KE_wip.dta,clear

br tender_finalprice ca_contract_value bid_price *price* *value*
tab currency, m
tab tender_year, m
gen year = tender_year
merge m:1 year using $country_folder/ppp_data.dta
drop if _m==2
tabstat ppp, by(year)
replace ppp=41.08591 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop _m year

gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="KES" | missing(currency)
gen bid_price_ppp =  bid_price/ppp if currency=="KES" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="KES" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="KES" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="KES" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="KES" | missing(currency)

br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

*Dates

gen ca_sign_date=date(tender_contractsignaturedate, "YMD")
format ca_sign_date %td
gen aw_dec_date=date(tender_awarddecisiondate, "YMD")
format aw_dec_date %td
gen cft_deadline=date(tender_biddeadline, "YMD")
format cft_deadline %td
gen cft_date_first=date(tender_publications_firstcallfor, "YMD")
format cft_date_first %td
************************************

*Buyer Type
encode buyer_buyertype, gen(anb_type) 
************************************

* Year
gen year=tender_year 
************************************

*Supply Type
encode tender_supplytype, gen(ca_type) 
************************************

*Buyer Location 
encode buyer_nuts, gen(anb_loc) 
************************************

*Market 
gen t_cpv2 = substr(tender_cpvs,1,2)
tab t_cpv2
encode t_cpv2, gen(marketid)
********************************************************************************
*/

save $country_folder/KE_wip.dta , replace
********************************************************************************
*END

