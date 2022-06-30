local country "`0'"
********************************************************************************
/*This script prepares merges location data for the MX dataset
The locations were retreived using Here Api*/
********************************************************************************

*Data 
use "${country_folder}/`country'_wip.dta", replace
********************************************************************************

gen name = anb_name

*Cleaning name
local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace name = subinstr(name, "`v'", " ",.)
}
replace name = subinstr(name, `"""', " ",.)
replace name = subinstr(name, `"$"', " ",.) 
replace name = subinstr(name, "'", " ",.)
replace name = subinstr(name, "ʼ", " ",.)
replace name = subinstr(name, "`", " ",.) 
replace name = subinstr(name, ".", " ",.)
replace name = subinstr(name, `"/"', " ",.)
replace name = subinstr(name, `"\"', " ",.)	
replace name = subinstr(name, `"_"', " ",.)	

ereplace name = sieve(name), omit(0123456789)
replace name=lower(name) 

forval var=1/10{
replace name = subinstr(name, "  ", " ",.)
}
replace name = stritrim(name)
replace name = strtrim(name)
replace name = proper(name)
rename name buyer_name_edited
********************************************************************************

/*Checking Locations data  - Do Not run this section

use MX_locations.dta, clear
rename sublocality_level_1  buyer_district_api
rename locality buyer_city_api
rename administrative_area_level_1 buyer_state_api
rename country buyer_country_api
keep buyer_name_edited buyer_name_api_en buyer_district_api buyer_city_api buyer_state_api buyer_country_api

tab buyer_country_api
drop if buyer_country_api=="Colombia"
unique buyer_name_edited
bys buyer_name_edited: gen x = _N
br if x>1
drop x
duplicates drop

drop if missing(buyer_name_api_en)
*/
********************************************************************************

merge m:1 buyer_name_edited using "${utility_data}/country/`country'/MX_buyers_locations_api.dta"
drop buyer_name_edited
// br anb_name buyer_name_api_en buyer_district_api buyer_city_api buyer_state_api buyer_country_api
*Create location from city
// unique buyer_district_api
// unique buyer_city_api
// unique buyer_state_api
// unique buyer_country_api
*Generate geo codes
tab  buyer_state_api, m
replace buyer_state_api="Nuevo León" if buyer_state_api=="Nuevo Leon"
replace buyer_state_api="Estado de México" if buyer_state_api=="State of Mexico"
count if missing(buyer_district_api)
// tab  buyer_city_api, m
// tab  buyer_state_api, m
// tab  buyer_country_api, m
********************************************************************************

gen x = "MX" if !missing(buyer_state_api)
*Generating a new grouping for regions
gen y = .
replace y = 1 if inlist(buyer_state_api,"Baja California","Baja California Sur","Sonora","Chihuahua","Coahuila de Zaragoza","Nuevo León","Tamaulipas","Durango")
replace y = 2 if inlist(buyer_state_api,"Sinaloa","Zacatecas","San Luis Potosí","Aguascalientes","Nayarit","Guanajuato") | inlist(buyer_state_api,"Querétaro","Hidalgo","Jalisco","Colima","Michoacán")
replace y = 3 if inlist(buyer_state_api,"Estado de México","Ciudad de México","Morelos","Tlaxcala","Puebla","Veracruz") | inlist(buyer_state_api,"Guerrero","Oaxaca","Tabasco","Chiapas","Campeche","Yucatán","Quintana Roo" )
tab buyer_state_api y , m
tostring y, replace
replace y ="" if y=="."

local temp ""Baja California" "Baja California Sur" "Sonora","Chihuahua" "Coahuila de Zaragoza" "Nuevo León" "Tamaulipas" "Durango" "Sinaloa" "Zacatecas" "San Luis Potosí" "Aguascalientes" "Nayarit" "Guanajuato" "Querétaro" "Hidalgo" "Jalisco" "Colima" "Michoacán" "Estado de México" "Ciudad de México" "Morelos" "Tlaxcala" "Puebla" "Veracruz" "Guerrero" "Oaxaca" "Tabasco" "Chiapas" "Campeche" "Yucatán" "Quintana Roo""
local temp2 ""1" "2" "3" "4" "5" "6" "7" "8" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D""
local n_temp : word count `temp'
gen z=""
forval s=1/`n_temp'{
 replace z = "`: word `s' of `temp2''" if buyer_state_api=="`: word `s' of `temp''"
}

bys buyer_state_api: egen alpha = nvals(buyer_city_api)
// tab alpha //max 7
bys buyer_state_api buyer_city_api: gen yy = _n==1
gsort buyer_state_api -buyer_city_api
bys buyer_state_api yy : gen xx = _n if yy==1 & !missing(buyer_city_api)
sort buyer_state_api buyer_city_api xx 
bys buyer_state_api buyer_city_api: replace xx = xx[1]  if missing(xx)
tostring xx, replace
replace xx="" if xx=="."
// br buyer_state_api buyer_city_api yy if yy==1
// br buyer_state_api buyer_city_api x y z yy xx buyer_geocodes
cap drop buyer_geocodes
gen buyer_geocodes=x+y+z
drop _merge x y z alpha yy xx

preserve
	keep buyer_geocodes buyer_state_api
	rename buyer_geocodes geocodes
	rename buyer_state_api region
	duplicates drop 
	sort geocodes
	drop if missing(geocodes)
	export delimited "${utility_data}/country/`country'/`country'_region_labels.csv", replace
restore
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END