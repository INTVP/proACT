local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************

* Main Filter
/*
gen filter_ok=1
replace filter_ok=0 if ca_year<2011 & ca_year!=.
replace filter_ok=0 if ca_year>2018 & ca_year!=.

tab filter_ok

* removing cancelled records
tab cancel
replace cancel=0 if cancel==.
tab cancel

replace filter_ok=0 if cancel==1

* removing incomplete records
tab ten_status_nat
*Incomplete: ten_status_nat=="Terminado sin Liquidar" (terminated without completion)
label list ten_status_nat
replace filter_ok=0 if ten_status_nat==18
*/
************************************

*Contract value

/*
sum ca_contract_value

xtile ca_contract_value10=ca_contract_value if filter_ok==1, nquantiles(10)
replace ca_contract_value10=99 if ca_contract_value==.

xtile ca_contract_value5=ca_contract_value if filter_ok==1, nquantiles(5)
replace ca_contract_value5=99 if ca_contract_value==.
*/

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*PPP conversion

use "${utility_data}/wb_ppp_data.dta", clear
keep if countrycode == "COL"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save "${country_folder}/ppp_data.dta", replace
********************************************************************************
use "${country_folder}/`country'_wip.dta", clear

// sum ca_year cft_year year
 
rename year year_old
rename ca_year year

*br tender_finalprice ca_contract_value bid_price *price* *value*
// tab ca_curr, m
replace ca_curr=. if ca_curr==2 | ca_curr==3
merge m:1 year using "${country_folder}/ppp_data.dta"
drop if _m==2
// tabstat ppp, by(year)
replace ppp=1349.012 if missing(ppp) & year==2020 //used 2019
// br year ppp if _m==3
drop _m 

gen tender_finalprice_ppp = ten_value/ppp if ca_curr==1 | missing(ca_curr)
gen bid_price=ca_contract_value
gen bid_price_ppp =  bid_price/ppp if ca_curr==1 | missing(ca_curr)
gen ca_contract_value_ppp =  ca_contract_value/ppp if ca_curr==1 | missing(ca_curr)

// br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

*Dates

/*
decode cft_date, gen(x)
gen cft_date_n = date(x, "YMD")
format cft_date_n %d
drop cft_date x
rename cft_date_n cft_date

gen cft_year_s2 = year(cft_date)
replace ca_year = cft_year_s2 if ca_year==.
label var cft_year_s2 "call for tender year of secop 2"
tab ca_year, missing
*/

foreach var of varlist cft_deadline aw_start_date ca_sign_date ca_start_date ca_end_date ci_start_date ci_end_date cft_lastdate interest_date draft_date select_date cft_open_date aw_date  {
decode `var', gen(`var'_str)
replace `var'_str="" if `var'_str=="0" | `var'_str=="1" | `var'_str=="99" | `var'_str=="."
drop `var'
}

foreach var of varlist cft_deadline_str aw_start_date_str ca_sign_date_str ca_start_date_str ca_end_date_str ci_start_date_str ci_end_date_str cft_lastdate_str select_date_str cft_open_date_str aw_date_str {
gen `var'_2= date(`var', "YMD") 
format `var'_2 %d
}

// cft_date

// gen cft_date=date(cft_date_str, "DMY")
// format cft_date %td

rename aw_start_date_str_2 aw_start_date
rename ca_sign_date_str_2 ca_sign_date
rename ca_start_date_str_2 ca_start_date
rename ca_end_date_str_2 ca_end_date
rename ci_start_date_str_2 ci_start_date
rename ci_end_date_str_2 ci_end_date
rename cft_lastdate_str_2 cft_lastdate
rename select_date_str_2 select_date
rename cft_open_date_str_2 cft_open_date
rename aw_date_str_2 aw_date
********************************************************************************
*buyer type

// tab anb_type
// replace anb_type=99 if anb_type==.
// label define anb_type 99"missing", add
********************************************************************************
* Market

*Generated from ca_descr_l2 and item_class_code
// tab marketid
// replace marketid=999 if marketid==.
gen tender_cpvs = cpv_div + "000000" if !missing(cpv_div)
********************************************************************************
*product type

// tab ca_type
// label list ca_type
// replace ca_type=2 if ca_type==.
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END