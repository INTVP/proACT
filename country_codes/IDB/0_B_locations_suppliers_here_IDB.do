*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script is early stage script that uses the HERE api and the city_api_IDB.R script to clean the city variable for suppliers*/
********************************************************************************

*Data
use $country_folder/IDB_wip.dta, clear
********************************************************************************

*Generate supplier geo codes
sort w_country w_city
br  w_country  w_city w_iso w_iso2  if !missing(w_city) | !missing(w_country)

replace w_city="" if w_city=="N/A"

br  w_country  w_city bidder_geocodes  if !missing(w_city) | !missing(w_country)

*Only one level - the cities need intensive cleaning
gen city_country= w_city + " " + w_country
replace city_country=proper(city_country)
replace city_country="" if missing(x)
replace city_country = w_city if missing(city_country) & !missing(w_city)
replace city_country=proper(city_country)

egen id_city=group(city_country)
replace id_city=0 if id_city==.
drop x
save $country_folder/IDB_wip.dta, replace

preserve
	keep city_country id_city
	drop if id_city==0
	duplicates drop id_city, force
	unique id_city
	export delimited using $country_folder/IDB_forcityapi.csv, replace 
restore
********************************************************************************
*Now run city_api_IDB.R using IDB_forcityapi.csv-- the output IDB_fromR.csv will be first imported and cleaned in Stata and then merged to the IDB_wip.dta
********************************************************************************
*Load R city cleaned data & save file
import delimited using  $country_folder/IDB_fromR.csv, delimiter(";") varnames(1) encoding(UTF-8) clear //utf8 Windows-1252
drop v1 
rename freq api_freq
drop api_freq
foreach var of varlist api_city api_district api_county api_state api_country{
replace `var'="" if `var'=="NULL" | `var'=="NA"
}
drop if api_city=="" & api_district=="" & api_county=="" & api_state=="" & api_country==""
save  $country_folder/IDB_fromR.dta, replace
********************************************************************************
*Merging back with dataset
use $country_folder/IDB_wip, clear
cap drop _m
merge m:1 id_city using $country_folder/IDB_fromR.dta

foreach var of varlist api_city api_district api_county api_state api_country{
rename `var' w_`var'
}
drop _m
********************************************************************************
save $country_folder/IDB_wip.dta, replace
********************************************************************************
*END