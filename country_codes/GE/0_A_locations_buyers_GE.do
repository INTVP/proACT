*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script is an early stage script that 
1) cleans the city names
2) sends city names to 0_B_locations_GE.R to standardize the city names using the HERE API*/
********************************************************************************

*Data 
import delimited using  $utility_data/country/AT/starting_data/GE_data.csv, encoding(UTF-8) clear
********************************************************************************

*Standardizing city name

gen city_edit=buyer_city
replace city_edit=lower(city_edit)

format buyer_city city_edit %25s
br buyer_city city_edit

*Replace other special character with empty 
*charlist city_edit 
local stop " "." "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "_" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace city_edit = subinstr(city_edit, "`v'", " ",.)
}
replace city_edit = subinstr(city_edit, "  ", " ",.)
replace city_edit = subinstr(city_edit, "–", " ",.)
replace city_edit = subinstr(city_edit, "—", " ",.)
replace city_edit = subinstr(city_edit, "'", "",.)
replace city_edit = subinstr(city_edit, "ʼ", "",.)
replace city_edit = subinstr(city_edit, `"""', "",.)
replace city_edit = subinstr(city_edit, `"/"', " ",.)
replace city_edit = subinstr(city_edit, `"\"', "",.)
replace city_edit = subinstr(city_edit, `"$"', "",.) 
replace city_edit = subinstr(city_edit, "`", "",.) 

br buyer_city city_edit if regexm(city_edit,"[0-9]")==1 //a few observations contain zip code

replace city_edit = stritrim(city_edit)
replace city_edit = strtrim(city_edit)

gen city_country = city_edit + " " + buyer_country if buyer_country!="NA"
format buyer_city city_edit city_country %25s
br buyer_city city_edit city_country
 
unique buyer_city city_edit
unique  city_edit
unique  city_country

*Here you output the file for R Api

egen id_city=group(city_country)
replace id_city=0 if id_city==.

*Exporting csv for R API city cleaning

preserve
	keep city_country id_city
	unique id_city
	export excel using $country_folder/GE_city.xlsx, replace firstrow(variables)
restore

save $country_folder/GE_wip.dta, replace
********************************************************************************
*Now run 0_B_locations_buyers_GE.R using GE_city.xlsx as an input file.
********************************************************************************
*After Running 0_B_locations_GE.R and using GE_city_fromAPI.csv as an input file, run the following script

*Load R city cleaned data & save file

import delimited using $country_folder/GE_city_fromAPI.csv, delimiter(";") varnames(1) encoding(UTF-8) clear //utf8 Windows-1252

drop v1 city_country
rename freq api_freq
foreach var of varlist api_city api_district api_county api_state api_country {
replace `var'="NA" if `var'=="NA" | `var'=="NULL" | `var'==""
}
save $country_folder/GE_city_fromAPI, replace
****************************************************************************
*Merging back with dataset

use $country_folder/GE_wip.dta, clear
merge m:1 id_city using $country_folder/GE_city_fromAPI

format buyer_city buyer_country city_edit api_city api_district api_county api_state api_country %25s
sort id_city
br buyer_city buyer_country city_edit id_city api*
drop _m id_city 
*drop city_edit city_country id_city api_freq
foreach var of varlist api_city api_district api_county api_state api_country{
replace `var' = "" if regex(buyer_city,"Georgia")
}

replace api_city="" if api_city=="NA"
replace api_district="" if api_district=="NA"
replace api_county="" if api_county=="NA"
replace api_state="" if api_state=="NA"
replace api_country="" if api_country=="NA"
replace api_country = buyer_country
drop api_state id_city _m city_country city_edit api_freq

rename buyer_city buyer_city_original
rename api_city buyer_city_api
rename api_district buyer_district_api
rename api_county buyer_county_api
rename api_country buyer_country_api
br buyer_city* buyer_country buyer_*

replace buyer_country_api = "GE" if buyer_county_api=="Acharis Avtonomiuri Respublika" & missing(buyer_country_api)

tab buyer_district_api
tab buyer_city_api
tab buyer_county_api
tab buyer_country_api

*Adding NUTS codes 
gen buyer_NUTS1 = "GE0" if buyer_country_api=="GE"
gen buyer_NUTS3 = "GE011" if buyer_county_api=="Tbilisi"
replace buyer_NUTS3 = "GE021" if buyer_county_api=="Acharis Avtonomiuri Respublika"
replace buyer_NUTS3 = "GE022" if buyer_county_api=="Guria"
replace buyer_NUTS3 = "GE023" if buyer_county_api=="Imereti"
replace buyer_NUTS3 = "GE024" if buyer_county_api=="Racha-Lechkhumi Da Kvemo Svaneti"
replace buyer_NUTS3 = "GE025" if buyer_county_api=="Samegrelo-Zemo Svaneti"
replace buyer_NUTS3 = "GE026" if buyer_county_api=="Samtskhe-Javakheti"

replace buyer_NUTS3 = "GE031" if buyer_county_api=="Kvemo Kartli"
replace buyer_NUTS3 = "GE032" if buyer_county_api=="Shida Kartli"
replace buyer_NUTS3 = "GE033" if buyer_county_api=="Kakheti"
replace buyer_NUTS3 = "GE034" if buyer_county_api=="Mtskheta-Mtianeti"

replace buyer_NUTS3 = "GEZZZ" if buyer_county_api=="Apkhazetis Avtonomiuri Respublika"

gen buyer_NUTS2 = "GE01" if buyer_NUTS3=="GE011"
replace buyer_NUTS2 = "GE02" if regex(buyer_NUTS3,"GE02") & buyer_NUTS2==""
replace buyer_NUTS2 = "GE03" if regex(buyer_NUTS3,"GE03") & buyer_NUTS2==""
replace buyer_NUTS2 = "GEZZ" if buyer_NUTS3=="GEZZZ" & buyer_NUTS2==""

tab buyer_NUTS3
********************************************************************************

save $country_folder/GE_wip.dta, replace
********************************************************************************
*END
