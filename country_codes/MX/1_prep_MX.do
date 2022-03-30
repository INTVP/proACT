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
use $country_folder/MX_wip.dta, replace
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
*Contract values

xtile ca_contract_value10 = ca_contract_value if filter_ok, nq(10)
replace ca_contract_value10 = 99 if missing(ca_contract_value) & filter_ok==1
************************************
*Fixing price currencies
use $utility_data/wb_ppp_data.dta, clear
keep if countryname == "Mexico"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save $country_folder/ppp_data.dta, replace
********************************************************************************
use $country_folder/MX_wip.dta,clear
br *value* *price*
*ca_contract_value ca_item_unitprice_orig
*aw_curr ca_currency ci_currency
tab aw_curr, m
tab ca_currency, m
tab ci_currency, m
*Assuming all MXN

tab year, m
merge m:1 year using $country_folder/ppp_data.dta
drop if _m==2
tabstat ppp, by(year) m
br year ppp if _m==3
drop _m
br year ppp


gen ca_contract_value_ppp = ca_contract_value/ppp
gen ca_item_unitprice_ppp = ca_item_unitprice_orig/ppp
br ppp ca_contract_value ca_contract_value_ppp ca_item_unitprice_orig ca_item_unitprice_ppp
************************************

*Main Filter
/*
gen filter_ok=1
replace filter_ok=0 if year<2012 & year!=. 
tab filter_ok
*/
************************************
*buyer type

/*
tab anb_type if filter_ok==1
decode anb_type, gen(anb_type_n)
replace anb_type_n="Administraciخ Pݢlica Federal" if anb_type_n=="APF"
replace anb_type_n="Gobierno Estatal" if anb_type_n=="GE"
replace anb_type_n="Gobierno Municipal" if anb_type_n=="GM"
encode anb_type_n, gen(anb_type_nn)
drop anb_type_n
drop anb_type
rename anb_type_nn anb_type
tab anb_type
*/
********************************************************************************
save $country_folder/MX_wip.dta, replace
********************************************************************************
*END