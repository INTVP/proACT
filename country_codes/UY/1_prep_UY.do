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
*Main Filter

decode w_name, gen(w_name_str)
replace w_name_str="" if w_name_str=="."
gen filter_wb=!missing(w_name)
replace filter_wb=0 if year<2015 | ten_status==2
// tab filter_wb, m

*246k obs with missing year - get a year variable for them
*Fixing year
// br aw_dec_date cft_open_date cft_date cft_deadline * if year==.
*useless 
replace filter_wb=0 if year==.

********************************************************************************
*Check Price information
// br ca_contract_value aw_item_curr aw_item_unit_val_raw  aw_item_quantity 
*ca_contract_value= aw_item_quantity * aw_item_unit_val_raw
*Estimated: Missing
*tender_estimatedprice, lot_estimatedprice
*Actual: ca_contract_value
*Fix currency
// tab aw_item_curr if filter_wb, m

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************

*Inidcator name: PPP conversion factor, GDP (LCU per international $)
local temp ""Brazil" "Canada" "Switzerland" "United Kingdom" "Uruguay" "South Africa""
local n_temp : word count `temp'
forval s=1/`n_temp'{
use "${utility_data}/wb_ppp_data.dta", clear
keep if inlist(countryname,"`: word `s' of `temp''")
drop if ppp==.
keep year ppp
local x = lower(substr("`: word `s' of `temp''",1,2))
save "${country_folder}/ppp_data_`x'.dta", replace
}
*********************************
use "${country_folder}/`country'_wip.dta",clear

// tab year if filter_wb, m
decode aw_item_curr, gen (curr)
replace curr="UYU" if missing(curr)
replace curr="UYU" if curr=="UYI"

local temp ""br" "ca" "sw" "un" "ur" "so""
local temp2 ""BRL" "CAD" "CHF" "GBP" "UYU" "ZAR""
local n_temp : word count `temp'
gen ca_contract_value_ppp=.
forval s=1/`n_temp'{
merge m:1 year using "${country_folder}/ppp_data_`: word `s' of `temp''.dta" 
drop if _m==2
drop _m 
replace ca_contract_value_ppp=ca_contract_value/ppp if filter_wb & curr=="`: word `s' of `temp2''"
drop ppp
}
// count if missing(ca_contract_value) & filter_ok
// count if missing(ca_contract_value_ppp) & filter_ok

// br ca_contract_value_ppp ca_contract_value curr aw_item_curr if filter_wb
*Main curr variable curr
label var ca_contract_value "Contract price (LCU)"
label var ca_contract_value_ppp "Contract price (USD - ppp adjusted)"
label var curr "Currency adjusted"
********************************************************************************
*Controls 
********************************************************************************
*Contract Value

// hist ca_contract_value_ppp if filter_wb
cap drop lca_contract_value
gen lca_contract_value = log(ca_contract_value_ppp)
// hist lca_contract_value if filter_ok
xtile ca_contract_value10 = ca_contract_value_ppp if filter_wb, nq(10)
replace ca_contract_value10 = 99 if missing(ca_contract_value_ppp)
// tab ca_contract_value10 if filter_wb, m
************************************
*Buyer type

/*
decode anb_name, gen(anb_name_str)

gen anb_type="missing"
replace anb_type = "national authority" if anb_type=="missing" & strpos(anb_name_str, "direccion") | anb_type=="missing" & strpos(anb_name_str, "administracion nacional") | anb_type=="missing" & strpos(anb_name_str, "inst") | anb_type=="missing" & strpos(anb_name_str, "ministerio") | anb_type=="missing" & strpos(anb_name_str, "dir.") | anb_type=="missing" & strpos(anb_name_str, "tesorer")  | anb_type=="missing" & strpos(anb_name_str, "camara") | anb_type=="missing" & strpos(anb_name_str, "direc.") | anb_type=="missing" & strpos(anb_name_str, "secretar") | anb_type=="missing" & strpos(anb_name_str, "poder") | anb_type=="missing" & strpos(anb_name_str, "presidencia") | anb_type=="missing" & strpos(anb_name_str, "reguladora") | anb_type=="missing" & strpos(anb_name_str, "estado mayor")  | anb_type=="missing" & strpos(anb_name_str, "inspeccion general") | anb_type=="missing" & strpos(anb_name_str, "de la nacion") | anb_type=="missing" & strpos(anb_name_str, "corte") | anb_type=="missing" & strpos(anb_name_str, "agencia nacional") 
replace anb_type = "national banks and funds" if anb_type=="missing" & strpos(anb_name_str, "banco") | strpos(anb_name_str, "fiscali")
replace anb_type = "regional authority" if anb_type=="missing" & strpos(anb_name_str, "departamental") | anb_type=="missing" & strpos(anb_name_str, "intendencia") | anb_type=="missing" & strpos(anb_name_str, "red de atencion") | anb_type=="missing" & strpos(anb_name_str, "regional") 
replace anb_type = "local body" if anb_type=="missing" & strpos(anb_name_str, "hospital") | anb_type=="missing" & strpos(anb_name_str, "facultad") | anb_type=="missing" & strpos(anb_name_str, "auxiliar") | anb_type=="missing" & strpos(anb_name_str, "consejo") | anb_type=="missing" & strpos(anb_name_str, "universidad") | anb_type=="missing" & strpos(anb_name_str, "universitario")
replace anb_type = "armed forces" if anb_type=="missing" & strpos(anb_name_str, "comando") | anb_type=="missing" & strpos(anb_name_str, "jefatura") | anb_type=="missing" & strpos(anb_name_str, "guardia") | anb_type=="missing" & strpos(anb_name_str, "militar") | anb_type=="missing" & strpos(anb_name_str, "fuerzas armadas") 
replace anb_type = "independent agency" if anb_type=="missing" & strpos(anb_name_str, "administracion") | strpos(anb_name_str, "junta") | anb_type=="missing" & strpos(anb_name_str, "consejo") | anb_type=="missing" & strpos(anb_name_str, "tribunal") | anb_type=="missing" & strpos(anb_name_str, "oficial") | anb_type=="missing" & strpos(anb_name_str, "comision") | anb_type=="missing" & strpos(anb_name_str, "navegacion") 
replace anb_type = "other" if anb_type=="missing"
tab anb_type

encode anb_type, gen(anb_type_n)
drop anb_type
rename anb_type_n anb_type
*/

// tab anb_type, m  //use this for the regression

decode anb_type, gen (buyer_type_temp)
gen buyer_type="NATIONAL_AUTHORITY" if buyer_type_temp=="national authority"
replace buyer_type="NATIONAL_AGENCY" if buyer_type_temp=="independent agency"
replace buyer_type="REGIONAL_AUTHORITY" if buyer_type_temp=="regional authority"
replace buyer_type="REGIONAL_AGENCY" if buyer_type_temp=="local body"
replace buyer_type="PUBLIC_BODY" if buyer_type_temp=="armed forces"
replace buyer_type="OTHER" if buyer_type_temp=="national banks and funds" | buyer_type_temp=="other"
drop buyer_type_temp
// tab buyer_type, m  //use this for the output
************************************
*Location  -  no location data
************************************
*Tender year

// tab year, m
************************************
*Contract type

// tab ca_type if filter_wb, m
decode ca_type,gen (supply_type)
replace supply_type="NA" if missing(supply_type)
encode supply_type, gen(ca_type_r)
label var ca_type_r "Supply type to be used in regression"
drop supply_type
// tab ca_type_r if filter_wb, m // use this for the regression
************************************
*Supply Type

gen supply_type="SERVICES" if ca_type==3
replace supply_type="SUPPLIES" if ca_type==2
replace supply_type="WORKS" if ca_type==4
// tab supply_type ca_type, m
// tab supply_type , m //use this for the output
gen tender_supplytype = supply_type
************************************

*Market ids [+ the missing cpv fix]
rename cpv_div tender_cpvs
replace tender_cpvs = "99100000" if missing(tender_cpvs) & supply_type=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(tender_cpvs) & supply_type=="SERVICES"
replace tender_cpvs = "99300000" if missing(tender_cpvs) & supply_type=="WORKS"
replace tender_cpvs = "99000000" if missing(tender_cpvs) 

gen market_id=substr(tender_cpvs,1,2)
*Clean Market id
// tab market_id, m
replace market_id="NA" if missing(market_id)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
// tab market_id, m
********************************************************************************

save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END