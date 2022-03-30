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
use $country_folder/CL_wip.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
/*
*Main filter

gen filter_ok=0
replace filter_ok=1 if year >= 2014 & year <= 2018 & bid_iswinning==3 & ca_contract_value!=.
tab year filter_ok
tab year, missing, if filter_ok==1
************************************

*Contract value
rename ca_contract_value ca_contract_value_raw
rename ca_currency ca_currency_orig

gen ca_contract_value=ca_contract_value_raw
replace ca_contract_value=ca_contract_value*778.854 if ca_currency==4
replace ca_contract_value=ca_contract_value*683.76 if ca_currency==5
replace ca_contract_value=ca_contract_value*28238.425 if ca_currency==2
replace ca_contract_value=. if ca_contract_value==0

replace ca_currency_orig=. if ca_currency_orig==1
gen ca_currency=ca_currency_orig
replace ca_currency=3 if ca_currency!=. & ca_currency!=3
label define ca_currency 3"CLP"
label val ca_currency ca_currency

sum ca_contract_value ca_contract_value_raw

gen lca_contract_value=log(ca_contract_value)
hist lca_contract_value

sum ca_contract_value

xtile ca_contract_value10=ca_contract_value if filter_ok==1, nquantiles(10)
replace ca_contract_value10=99 if ca_contract_value==.

xtile ca_contract_value5=ca_contract_value if filter_ok==1, nquantiles(5)
replace ca_contract_value5=99 if ca_contract_value==.
*/

save $country_folder/CL_wip.dta, replace
********************************************************************************
use $utility_data/wb_ppp_data.dta, clear
keep if countrycode == "CHL"
drop if ppp==.
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
keep year ppp
save $country_folder/ppp_data.dta, replace
********************************************************************************

use $country_folder/CL_wip.dta, clear
br tender_finalprice ca_contract_value bid_price *price* *value*
tab currency, m
tab tender_year, m
gen year = tender_year
merge m:1 year using $country_folder/ppp_data.dta
drop if _m==2
tabstat ppp, by(tender_year)
replace ppp=412.3604 if missing(ppp) & year==2020 | year==2019 //used 2018
br year ppp if _m==3
drop _m

rename ca_currency currency

gen tender_finalprice_ppp = ca_tender_value/ppp if ca_currency=="CLP" | missing(ca_currency)
gen bid_price_ppp =  ca_contract_value/ppp if ca_currency=="CLP" | missing(ca_currency)
gen ca_contract_value_ppp =  ca_contract_value/ppp if ca_currency=="CLP" | missing(ca_currency)

br bid_price bid_price_ppp ca_contract_value ca_contract_value_ppp tender_finalprice tender_finalprice_ppp  tender_year ppp currency  
********************************************************************************

*Buyer type
/*
decode anb_name, gen(anb_name_str)
gen anb_name_str2=lower(anb_name_str)

replace anb_name_str2 = subinstr(anb_name_str2, "Ãº", "a°", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă­", "i", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ăˇ", "a", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ăł", "o", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă©", "e", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă“", "o", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă‘", "n", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă‰", "e", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "ĂŤ", "i", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ă±", "n", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "Ăş", "u", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "iĂ", "io", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "ÂŞ", "", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "NĂ", "na", .) 
replace anb_name_str2 = subinstr(anb_name_str2, "- - -", "", .) 
replace anb_name_str2=strtrim(anb_name_str2)

gen anb_type="missing"
replace anb_type = "national authority" if anb_type=="missing" & strpos(anb_name_str2, "superintendencia") | anb_type=="missing" & strpos(anb_name_str2, "servicio nacional") | anb_type=="missing" & strpos(anb_name_str2, "ministerio") | anb_type=="missing" & strpos(anb_name_str, "unidad operativa") | anb_type=="missing" & strpos(anb_name_str2, "admin") & strpos(anb_name_str2, "fondos") | anb_type=="missing" & strpos(anb_name_str2, "nacional") | anb_type=="missing" & strpos(anb_name_str2, "gobierno central") | anb_type=="missing" & strpos(anb_name_str2, "abastecimiento") | anb_type=="missing" & strpos(anb_name_str2, "tesoreria general") | anb_type=="missing" & strpos(anb_name_str2, "departamento") | anb_type=="missing" & strpos(anb_name_str2, "depto. salud")
replace anb_type = "national banks and funds" if anb_type=="missing" & strpos(anb_name_str2, "fondo") | anb_type=="missing" & strpos(anb_name_str2, "fundacion")
replace anb_type = "regional authority" if anb_type=="missing" & strpos(anb_name_str2, "zona") & strpos(anb_name_str2, "bienestar")| anb_type=="missing" & strpos(anb_name_str2, "bdo.o'higgins") | anb_type=="missing" & strpos(anb_name_str2, "admin") & strpos(anb_name_str2, "aduana") | anb_type=="missing" & strpos(anb_name_str2, "region") | anb_type=="missing" & strpos(anb_name_str2, "servicio de salud") | anb_type=="missing" & strpos(anb_name_str2, "provincia") | anb_type=="missing" & strpos(anb_name_str2, "complejo asistencial") 
replace anb_type = "local body" if anb_type=="missing" & strpos(anb_name_str2, "hospital") | anb_type=="missing" & strpos(anb_name_str2, "servicio local") | anb_type=="missing" & strpos(anb_name_str2, "universidad") | anb_type=="missing" & strpos(anb_name_str2, "municipalidad") | anb_type=="missing" & strpos(anb_name_str2, "municipal") | anb_type=="missing" & strpos(anb_name_str2, "juzgado") | anb_type=="missing" & strpos(anb_name_str2, "jdo") | anb_type=="missing" & strpos(anb_name_str2, "tribunal") | anb_type=="missing" & strpos(anb_name_str2, "escuela") | anb_type=="missing" & strpos(anb_name_str2, "consejo") | anb_type=="missing" & strpos(anb_name_str2, "consultorio") | anb_type=="missing" & strpos(anb_name_str2, "liceo")
replace anb_type = "armed forces" if anb_type=="missing" & strpos(anb_name_str2, "carabineros") | anb_type=="missing" & strpos(anb_name_str2, "comandancia") | anb_type=="missing" & strpos(anb_name_str2, "comando") | anb_type=="missing" & strpos(anb_name_str2, "maritim") | anb_type=="missing" & strpos(anb_name_str2, "almirante") | anb_type=="missing" & strpos(anb_name_str2, "armada") | anb_type=="missing" & strpos(anb_name_str2, "maritima") | anb_type=="missing" & strpos(anb_name_str2, "jefatura") | anb_type=="missing" & strpos(anb_name_str2, "naval") | anb_type=="missing" & strpos(anb_name_str2, "fuerza") | anb_type=="missing" & strpos(anb_name_str2, "ejercito") | anb_type=="missing" & strpos(anb_name_str2, "submarino") | anb_type=="missing" & strpos(anb_name_str2, "policia") | anb_type=="missing" & strpos(anb_name_str2, "brigada") 
replace anb_type = "independent agency" if anb_type=="missing" & strpos(anb_name_str2, "academia") | anb_type=="missing" & strpos(anb_name_str2, "bienestar") | anb_type=="missing" & strpos(anb_name_str2, "direccion") | anb_type=="missing" & strpos(anb_name_str2, "bienes y servicios") | anb_type=="missing" & strpos(anb_name_str2, "instituto") | anb_type=="missing" & strpos(anb_name_str2, "comision") 
replace anb_type = "national authority" if anb_type=="missing" & strpos(anb_name_str2, "subsecretaria") | anb_type=="missing" & strpos(anb_name_str2, "servicio") 
replace anb_type = "state owned company" if anb_type=="missing" & strpos(anb_name_str2, "empresa") | anb_type=="missing" & strpos(anb_name_str2, "corporacion")
replace anb_type = "other" if anb_type=="missing" | strpos(anb_name_str2, "instituto psiqui")
replace anb_type = "" if anb_name_str2==""

tab anb_type

encode anb_type, gen(anb_type_n)
drop anb_type
rename anb_type_n anb_type


drop anb_name anb_name_str
encode anb_name_str2, gen(anb_name)
drop anb_name_str2

*/

tab anb_type
************************************

*Buyer Location
/*

decode anb_city, gen(anb_city_str)
gen anb_city_str2=lower(anb_city_str)

replace anb_city_str2 = subinstr(anb_city_str2, "Ăş", "u", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "Ă±", "n", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "Ă©", "e", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "Ă­", "i", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "Ăˇ", "a", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "Ăł", "o", .)
replace anb_city_str2 = subinstr(anb_city_str2, "Ă‘", "n", .) 
replace anb_city_str2 = subinstr(anb_city_str2, "no hay informacion", "", .) 
replace anb_city_str2=strtrim(anb_city_str2)

drop anb_city anb_city_str
encode anb_city_str2, gen(anb_city)
drop anb_city_str2
*/
tab anb_city
************************************

*Bidder Location
/*

decode w_city, gen(w_city_str)
gen w_city_str2=lower(w_city_str)

replace w_city_str2 = subinstr(w_city_str2, "Ă‘", "n", .) 
replace w_city_str2 = subinstr(w_city_str2, "Ă±", "n", .) 
replace w_city_str2 = subinstr(w_city_str2, "Ă©", "e", .) 
replace w_city_str2 = subinstr(w_city_str2, "Ă­", "i", .) 
replace w_city_str2 = subinstr(w_city_str2, "Ăł", "o", .) 
replace w_city_str2 = subinstr(w_city_str2, "no hay informacion", "", .) 
replace w_city_str2=strtrim(w_city_str2) 

drop w_city w_city_str
encode w_city_str2, gen(w_city)
drop w_city_str2
*/
************************************

*Dates
/*

*dates
tab year
*discrepancy in 2013, 2019 incomplete year

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

decode aw_dec_date, gen(aw_dec_date1)
gen aw_dec_date_n = date(aw_dec_date1, "YMD")
format aw_dec_date_n %d
drop aw_dec_date aw_dec_date1
rename aw_dec_date_n aw_dec_date

decode cft_deadline, gen(cft_deadline1)
gen cft_deadline_n = date(cft_deadline1, "YMD")
format cft_deadline_n %d
drop cft_deadline cft_deadline1
rename cft_deadline_n cft_deadline

sum cft_date_first cft_date_last aw_date aw_dec_date cft_deadline
*2.5% missing in cft_date_first, cft_date_last and aw_date  
*0.03% missing in aw_dec_date and cft_deadline

gen year_alt = year(cft_deadline)
replace year = year_alt if year==.
tab year
*/
************************************

*Market
/*

*marketid 
*UNSPSC - https://api.mercadopublico.cl/documentos/Documentaci%C3%B3n%20API%20Mercado%20Publico%20-%20Licitaciones.pdf
decode ca_item_class_id, gen(ca_item_class_id_str)
gen marketid = substr(ca_item_class_id_str,1,2)
replace marketid =. if ca_item_class_id_str==""

gen marketid_l3 = substr(ca_item_class_id_str,1,4)
replace marketid_l3 =. if ca_item_class_id_str==""

encode marketid, gen(marketid_n)
drop marketid
rename marketid_n marketid
*/

tab marketid
********************************************************************************

save $country_folder/CL_wip.dta , replace
********************************************************************************
*END