local country "`0'"
********************************************************************************
/*This script is an early stage script that 
1) Adds city names to the RO data using the HERE API*/
********************************************************************************
*Data 
/*
import delimited using  "${utility_data}/country/`country'/starting_data/`country'_data.csv", encoding(UTF-8) clear
********************************************************************************
gen ted_data = (source=="http://data.europa.eu/" | source=="http://ted.europa.eu")
drop if tender_proceduretype=="OUTRIGHT_AWARD"
drop if missing(tender_publications_lastcontract) & ted_data==1
drop ted_data

save "${country_folder}/`country'_wip.dta",replace
********************************************************************************
*/
*Merging locations collected from the Here API

generate str name_string = buyer_name
replace buyer_name = ""
compress buyer_name
replace buyer_name = name_string
drop name_string

merge m:1 buyer_name using "${utility_data}/country/`country'/RO_buyers_location.dta"
cap drop _m
// br buyer_name district city county country
foreach var of varlist buyer_city buyer_nuts buyer_country buyer_mainactivities buyer_buyertype buyer_postcode {
replace `var'="" if `var'=="."
}

*Step 1 copy all available buyer information to all buyers with the same name
*Harmonize between the API ones and the given locations

*Step 1 make sure all the same buyers have the same city / country / nuts information
gsort buyer_name -buyer_city 
// br buyer_name buyer_city buyer_nuts
foreach var of varlist buyer_city buyer_nuts  buyer_country buyer_mainactivities buyer_buyertype buyer_postcode {
bys buyer_name: replace `var' = `var'[1] if missing(`var')
}

*Generate a combined city variable
rename  buyer_city buyer_city_original 
gen buyer_city = buyer_city_original
replace buyer_city = city if missing(buyer_city)

*Harmonize the newly generated city variable
tab buyer_city, m
replace buyer_city = "Zalău" if buyer_city=="Zalau"
replace buyer_city = "Wien" if buyer_city=="Viena"
replace buyer_city = "Vetiș" if buyer_city=="Vetis"
replace buyer_city = "Vermeș" if buyer_city=="Vermeş"
replace buyer_city = "Vața de Jos" if buyer_city=="Vaţa de Jos"
replace buyer_city = "Vatra Moldoviței" if buyer_city=="Vatra Moldovitei"
replace buyer_city = "Târgu Mureș" if buyer_city=="T芒rgu Mure艧"
replace buyer_city = "Târgu Mureș" if buyer_city=="Târgu-Mureș"
replace buyer_city = "Târgu Mureș" if buyer_city=="Târgu Mureş"
replace buyer_city = "Târgu Mureș" if buyer_city=="Târgu Mureş"
replace buyer_city = "Târgu Mureș" if buyer_city=="Târgu-Mureş"
replace buyer_city = "Târgu Mureș" if buyer_city=="Tg. Mures"
replace buyer_city = "Târgu Mureș" if buyer_city=="Targu Mures"
replace buyer_city = "Tamași" if buyer_city=="Tamasi"
replace buyer_city = "Vadu Crișului" if buyer_city=="Vadu Crisului"
replace buyer_city = "Tășnad" if buyer_city=="Tăşnad"
replace buyer_city = "Tăuții-Măgherăuș" if buyer_city=="Tăuţii Măgherăuş"
replace buyer_city = "Târgoviște" if buyer_city=="Târgovişte"
replace buyer_city = "Turnu Măgurele" if buyer_city=="Turnu Magurele"
replace buyer_city = "Tupilați" if buyer_city=="Tupilati"
replace buyer_city = "Trușești" if buyer_city=="Trusesti"
replace buyer_city = "Timișoara" if buyer_city=="Timisoara"
replace buyer_city = "Teleşti" if buyer_city=="Telesti"

replace buyer_city=subinstr(buyer_city,"ş","ș",.)
replace buyer_city=subinstr(buyer_city,"ţ","ț",.)

*Can't fix all of them -  fixing major cities
// tab buyer_city if regex(buyer_city,"Bu|bu")
replace buyer_city = "București" if inlist(buyer_city,"Bucharest","bucuresti","București, Romania","Bucuresti","Bucureșci","Bucuresti","Bucure?ti")
// tab buyer_city if regex(buyer_city,"Bu|bu")
bys buyer_city: gen x=_N
// tab buyer_city if x>10000
// tab buyer_city if regex(buyer_city,"luj")
replace buyer_city = "Cluj-Napoca" if inlist(buyer_city,"Cluj Napoca","Cluj","Mihai Viteazu, Cluj")
// tab buyer_city if regex(buyer_city,"Ia")
replace buyer_city = "Iași" if inlist(buyer_city,"Iasi")
replace buyer_city = "Galați" if inlist(buyer_city,"Galati","galati")
replace buyer_city = "Timișoara" if inlist(buyer_city,"timisoara")
replace buyer_city = "Târgu Mureș" if inlist(buyer_city,"Tirgu Mures","Targul Mures","targu mures")
replace buyer_city = "Târgu Jiu" if inlist(buyer_city,"targu jiu","Tg-Jiu","Targu Jiu")
replace buyer_city = "Râmnicu Vâlcea" if inlist(buyer_city,"Ramnicu Valcea","Rm.Valcea")

*Now create a standard city name - stripped of alla accents and lowercase
gen buyer_city_clean = buyer_city
do "${utility_codes}/transliteration_cleaning.do" buyer_city
rename buyer_city_clean city_clean

*Copy all nuts information for the same cities
gsort city_clean -buyer_nuts
rename buyer_nuts buyer_nuts_original
gen buyer_nuts =  buyer_nuts_original
bys city_clean: replace buyer_nuts = buyer_nuts[1] if missing(buyer_nuts)

// count if missing(buyer_city) & filter_ok
// count if missing(buyer_nuts) & filter_ok
// br buyer_city  city_clean buyer_nuts if !missing(buyer_city) & missing(buyer_nuts)

*We can use the county variable to merge but ignored for now
replace buyer_city=ustrupper(buyer_city,"ro")

*cleaning nuts a bit
replace buyer_nuts="" if inlist(buyer_nuts,"NA","RO")

drop x city_clean
foreach var of varlist city county district country {
rename `var' buyer_`var'_api
}

*Vars to use mainly
*buyer_city is the fixed city after harmonizing from api and original source
*buyer_nuts
*buyer_city_original / buyer_nuts_original are the source variables

// br buyer_name buyer_city buyer_nuts
********************************************************************************
save "${country_folder}/`country'_wip.dta",replace
********************************************************************************
*END