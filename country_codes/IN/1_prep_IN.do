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
use $country_folder/IN_wip.dta, clear
********************************************************************************

*Filter ok 
gen filter_ok=1
replace filter_ok=0 if year<2012 | year>2018 & year!=. | bid_iswinning!=1
tab filter_ok
tab year, missing, if filter_ok==1
************************************

*Dates

decode cft_date_first, gen(cft_date_first1)
gen cft_date_first_n = date(cft_date_first1, "YMD")
format cft_date_first_n %d
drop cft_date_first cft_date_first1
rename cft_date_first_n cft_date_first

decode cft_date_last, gen(cft_date_last1)
gen cft_date_last_n = date(cft_date_last1, "YMD")
format cft_date_last_n %d
drop cft_date_last cft_date_last1
rename cft_date_last_n cft_date_last

decode aw_date, gen(aw_date1)
gen aw_date_n = date(aw_date1, "YMD")
format aw_date_n %d
drop aw_date aw_date1
rename aw_date_n aw_date

decode cft_deadline, gen(cft_deadline1)
gen cft_deadline_n = date(cft_deadline1, "YMD")
format cft_deadline_n %d
drop cft_deadline cft_deadline1
rename cft_deadline_n cft_deadline

decode ca_signdate, gen(ca_signdate1)
gen ca_signdate_n = date(ca_signdate1, "YMD")
format ca_signdate_n %d
drop ca_signdate ca_signdate1
rename ca_signdate_n ca_signdate

sum cft_date_first cft_date_last aw_date cft_deadline ca_signdate year
************************************

*Contract value
sum ca_contract_value
rename ca_contract_value ca_contract_value_raw
rename currency currency_orig

gen ca_contract_value=ca_contract_value_raw
replace ca_contract_value = ca_contract_value*75.8234 if currency==1
replace currency=2 if currency==1

sum ca_contract_value ca_contract_value_raw

gen lca_contract_value=log(ca_contract_value)
hist lca_contract_value
********************************************************************************
save $country_folder/IN_wip.dta, replace
********************************************************************************
*PPP conversion

use $utility_data/wb_ppp_data.dta, clear
keep if countrycode == "IND"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save $country_folder/ppp_data.dta
********************************************************************************

use $country_folder/IN_wip.dta, clear
br tender_finalprice ca_contract_value bid_price *price* *value*
rename currency_orig currency
tab currency, m
tab tender_year, m
gen year = tender_year
merge m:1 year using  $country_folder/ppp_data.dta
drop if _m==2
tabstat ppp, by(year)
br year ppp if _m==3
drop _m year

rename currency_orig currency
gen tender_finalprice=.
gen tender_estimatedprice=.
gen lot_estimatedprice=.
gen lot_updatedprice=.
gen bid_price=ca_contract_value

gen bid_price_ppp =  bid_price/ppp if currency=="INR" | missing(currency)
gen tender_finalprice_ppp = tender_finalprice/ppp if currency=="INR" | missing(currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if currency=="INR" | missing(currency)
gen tender_estimatedprice_ppp = tender_estimatedprice/ppp if currency=="INR" | missing(currency)
gen lot_estimatedprice_ppp = lot_estimatedprice/ppp if currency=="INR" | missing(currency)
gen lot_updatedprice_ppp = lot_updatedprice/ppp if currency=="INR" | missing(currency)

br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

save $country_folder/IN_wip.dta , replace
********************************************************************************
*END