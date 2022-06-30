*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script merges both buyers_loc_1 & buyers_loc_2 to ID_wip.dta after cpv codes have been added
buyers_loc_1 - comes from an api search using the buyer name
buyers_loc_2 - comes from a manual location search*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Merging with Dataset

*Extracting buyer names to find locations
decode(anb_name), gen(anb_name_str)

cap drop _m
merge m:1  anb_name_str using "${utility_data}/country/ID/buyer_loc_1.dta", gen(_m)
// br anb_name_str buyer_name_api_en buyer_loc_4 buyer_loc_3 buyer_loc_2 buyer_loc_1 buyer_postal_code buyer_loc_5 if _m==3
drop if _m==2
drop _m

foreach var of varlist buyer_name_api_en buyer_loc_4 buyer_loc_3 buyer_loc_2 buyer_loc_1 buyer_postal_code {
rename `var' `var'_1
}
merge m:1  anb_name_str using "${utility_data}/country/ID/buyers_final2.dta", gen(_m)
drop _m country
// br anb_name_str buyer_name_api_en buyer_loc_4 buyer_loc_3 buyer_loc_2 buyer_loc_1 buyer_postal_code country if _m==3

foreach var of varlist buyer_name_api_en buyer_loc_4 buyer_loc_3 buyer_loc_2 buyer_loc_1 buyer_postal_code {
rename `var' `var'_2
}

// tab buyer_loc_1_1
// tab buyer_loc_1_2
gen buyer_loc_1 = ""
replace buyer_loc_1 = buyer_loc_1_1
replace buyer_loc_1 = buyer_loc_1_2 if missing(buyer_loc_1)
label var buyer_loc_1 "Province"

// tab buyer_loc_2_1
// tab buyer_loc_2_2
replace buyer_loc_2_2 = subinstr(buyer_loc_2_2,",","",.)
gen buyer_loc_2 = ""
replace buyer_loc_2 = buyer_loc_2_1
replace buyer_loc_2 = buyer_loc_2_2 if missing(buyer_loc_2)

// tab buyer_loc_3_1
// tab buyer_loc_3_2
gen buyer_loc_3 = ""
replace buyer_loc_3 = buyer_loc_3_1
replace buyer_loc_3 = buyer_loc_3_2 if missing(buyer_loc_3)

gen buyer_loc_4 = ""
replace buyer_loc_4 = buyer_loc_4_1
replace buyer_loc_4 = buyer_loc_4_2 if missing(buyer_loc_4)

gen buyer_postal_code = .
replace buyer_postal_code = buyer_postal_code_1
replace buyer_postal_code = buyer_postal_code_2 if missing(buyer_postal_code)

gen buyer_name_api_en = ""
replace buyer_name_api_en = buyer_name_api_en_1
replace buyer_name_api_en =   if missing(buyer_name_api_en)

drop buyer_loc_1_1 buyer_loc_1_2 buyer_loc_2_1 buyer_loc_2_2 buyer_loc_3_1 buyer_loc_3_2 buyer_loc_4_1 buyer_loc_4_2 buyer_postal_code_1 buyer_postal_code_2 buyer_name_api_en_1 buyer_name_api_en_2

drop anb_name 

rename anb_name_str buyer_name
replace buyer_name=proper(buyer_name)
replace buyer_name_api_en=proper(buyer_name_api_en)

// br *buyer* if !missing(buyer_name)
********************************************************************************
*Main location variable

// br  buyer_name  buyer_loc_1 buyer_loc_2 buyer_loc_3 buyer_loc_4 buyer_loc_5 buyer_postal_code
// tab buyer_loc_1, m //province - Level 1
// tab buyer_loc_2, m // Regency/City - Level 2
// tab buyer_loc_3, m //District - Level 3
// tab buyer_loc_4, m //Village/subDistrict - Level 4
// tab buyer_loc_5, m

// br *loc* if missing(buyer_loc_1)

gen buyer_province=buyer_loc_1
replace buyer_province="Special Region of Yogyakarta " if buyer_province=="DAERAH ISTIMEWA YOGYAKART"
replace buyer_province="Special Region of Yogyakarta " if buyer_province=="Daerah Istimewa Yogyakarta"
replace buyer_province="Jakarta" if buyer_province=="Daerah Khusus Ibukota Jakarta"
replace buyer_province="" if buyer_province=="Federal Territory of Kuala Lumpur"
replace buyer_province="West Java" if buyer_province=="Jawa Barat"
replace buyer_province="Central Java" if buyer_province=="Jawa Tengah"
replace buyer_province="East Java" if buyer_province=="Jawa Timur"
replace buyer_province="West Kalimantan" if buyer_province=="Kalimantan Barat"
replace buyer_province="South Kalimantan" if buyer_province=="Kalimantan Selatan"
replace buyer_province="Central Kalimantan" if buyer_province=="Kalimantan Tengah"
replace buyer_province="East Kalimantan" if buyer_province=="Kalimantan Timur"
replace buyer_province="North Kalimantan" if buyer_province=="Kalimantan Utara"
replace buyer_province="East Kalimantan" if buyer_province=="Kalimantan Wétan"
replace buyer_province="Bangka Belitung Islands" if buyer_province=="Kepulauan Bangka Belitung"
replace buyer_province="Riau" if buyer_province=="Kepulauan Riau"
replace buyer_province="Jakarta" if buyer_province=="Kota Jakarta Pusat"
replace buyer_province="Jakarta" if buyer_province=="Kota Jakarta Selatan"
replace buyer_province="Banten" if buyer_province=="Kota Tangerang"
replace buyer_province="Special Region of Yogyakarta " if buyer_province=="Kota Yogyakarta"
replace buyer_province="" if buyer_province=="North Carolina"
replace buyer_province="West Nusa Tenggara" if buyer_province=="Nusa Tenggara Barat"
replace buyer_province="East Nusa Tenggara " if buyer_province=="Nusa Tenggara Tim."
replace buyer_province="East Nusa Tenggara " if buyer_province=="Nusa Tenggara Timur"
replace buyer_province="" if buyer_province=="Oregon"
replace buyer_province="" if buyer_province=="Pahang"
replace buyer_province="West Papua" if buyer_province=="Papua Barat"
replace buyer_province="" if buyer_province=="Sarawak"
replace buyer_province="Banten" if buyer_province=="Tangerang"
replace buyer_province="" if buyer_province=="Wilayah Persekutuan Putrajaya"
replace buyer_province="North Maluku" if buyer_province=="Maluku Utara"
replace buyer_province="West Sulawesi" if buyer_province=="Sulawesi Barat"
replace buyer_province="South Sulawesi" if buyer_province=="Sulawesi Selatan"
replace buyer_province="Central Sulawesi" if buyer_province=="Sulawesi Tengah"
replace buyer_province="South East Sulawesi" if buyer_province=="Sulawesi Tenggara"
replace buyer_province="North Sulawesi" if buyer_province=="Sulawesi Utara"
replace buyer_province="West Sumatra" if buyer_province=="Sumatera Barat"
replace buyer_province="South Sumatra" if buyer_province=="Sumatera Selatan"
replace buyer_province="North Sumatra" if buyer_province=="Sumatera Utara"
replace buyer_province="North Sumatra" if buyer_province=="Sumatera Utara"

replace buyer_province="East Nusa Tenggara" if buyer_province=="East Nusa Tenggara "
replace buyer_province="Special Capital Region of Jakarta" if buyer_province=="Jakarta"
replace buyer_province="Special Region of Yogyakarta" if buyer_province=="Special Region of Yogyakarta" | buyer_province=="Special Region of Yogyakarta "

// tab buyer_province, m
// unique buyer_province


gen x = "ID" if !missing(buyer_province)
*Generating a new grouping for regions
gen y =""
replace y="1" if inlist(buyer_province,"Aceh","Bangka Belitung Islands","Banten","Bengkulu","Jambi","Lampung")
replace y="1" if inlist(buyer_province,"North Sumatra","Riau","Riau Islands","South Sumatra","Special Capital Region of Jakarta","West Java","West Sumatra")
replace y="2" if inlist(buyer_province,"Bali","Central Java","Central Kalimantan","East Java","East Kalimantan","North Kalimantan")
replace y="2" if inlist(buyer_province,"South Kalimantan","West Kalimantan","West Nusa Tenggara")
replace y="2" if buyer_province == "Special Region of Yogyakarta"
replace y="3" if inlist(buyer_province,"Central Sulawesi","Maluku","North Maluku","North Sulawesi","South East Sulawesi","South Sulawesi")
replace y="3" if inlist(buyer_province,"West Papua","West Sulawesi","Papua","East Nusa Tenggara","Gorontalo")
tab buyer_province y, m

gen z=""
replace z="1" if buyer_province=="Aceh"
replace z="2" if buyer_province=="Bangka Belitung Islands"
replace z="3" if buyer_province=="Banten"
replace z="4" if buyer_province=="Bengkulu"
replace z="5" if buyer_province=="Jambi"
replace z="6" if buyer_province=="Lampung"
replace z="7" if buyer_province=="North Sumatra"
replace z="8" if buyer_province=="Riau"
replace z="9" if buyer_province=="Riau Islands"
replace z="A" if buyer_province=="South Sumatra"
replace z="B" if buyer_province=="Special Capital Region of Jakarta"
replace z="C" if buyer_province=="West Java"
replace z="D" if buyer_province=="West Sumatra"


replace z="1" if buyer_province=="Bali"
replace z="2" if buyer_province=="Central Java"
replace z="3" if buyer_province=="Central Kalimantan"
replace z="4" if buyer_province=="East Java"
replace z="5" if buyer_province=="East Kalimantan"
replace z="6" if buyer_province=="North Kalimantan"
replace z="7" if buyer_province=="South Kalimantan"
replace z="8" if buyer_province=="West Kalimantan"
replace z="9" if buyer_province=="West Nusa Tenggara"
replace z="A" if buyer_province=="Special Region of Yogyakarta"

replace z="1" if buyer_province=="Central Sulawesi"
replace z="2" if buyer_province=="Maluku"
replace z="3" if buyer_province=="North Maluku"
replace z="4" if buyer_province=="North Sulawesi"
replace z="5" if buyer_province=="South East Sulawesi"
replace z="6" if buyer_province=="South Sulawesi"
replace z="7" if buyer_province=="West Papua"
replace z="8" if buyer_province=="West Sulawesi"
replace z="9" if buyer_province=="Papua"
replace z="A" if buyer_province=="East Nusa Tenggara"
replace z="B" if buyer_province=="Gorontalo"

// tab  buyer_province if missing(z) & !missing(buyer_province) //good
/*
*Some provinces have more than 55 cities - so a one code system will not work
gen buyer_city=buyer_loc_2
bys buyer_province: egen alpha = nvals(buyer_city)
tab alpha //max 7
bys buyer_province buyer_city: gen yy = _n==1
gsort buyer_province -buyer_city
bys buyer_province yy : gen xx = _n if yy==1 & !missing(buyer_city)
sort buyer_province buyer_city xx 
bys buyer_province buyer_city: replace xx = xx[1]  if missing(xx)
tostring xx, replace
replace xx="" if xx=="."
br buyer_province buyer_city yy if yy==1
br buyer_province buyer_city x y z yy xx 

local temp ""
local temp2 ""
local n_temp : word count `temp'
gen z=""
forval s=1/`n_temp'{
 replace z = "`: word `s' of `temp2''" if buyer_state_api=="`: word `s' of `temp''"
}
drop x-xx
*/

gen buyer_geocodes=x+y+z
drop x z y

preserve
	keep buyer_geocodes buyer_province
	rename buyer_geocodes geocodes
	rename buyer_province region
	duplicates drop 
	drop if missing(geocodes)
	export delimited "${utility_data}/country/`country'/`country'_region_labels.csv", replace
restore
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END