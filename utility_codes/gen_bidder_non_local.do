*Get number of arguments
local x "`0'"
local len_arg : word count `x'
*Get country
local country "`1'"
************************************************
* Script calculates same_location: tags contracts if buyer and bidder are in the same location based on city name and/or nuts codes
************************************************


*Working city variable
cap drop anb_city_fun
gen anb_city_fun = `2'
cap drop w_city_fun
gen w_city_fun = `3'
foreach var in w_city_fun anb_city_fun{
do "${utility_codes}/quick_location_cleaning.do" `var' "`country'"
}
cap drop anb_city_fun w_city_fun 

*Working nuts variable
if `len_arg'>3{
cap drop anb_nuts_fun
gen anb_nuts_fun = `4'
cap drop w_nuts_fun
gen w_nuts_fun = `5'

}

*Generate same location
cap drop bidder_non_local
gen bidder_non_local = 1 if filter_ok
replace bidder_non_local = 0 if filter_ok & anb_city_fun_clean==w_city_fun_clean & (!missing(anb_city_fun_clean) | !missing(w_city_fun_clean) )
replace bidder_non_local = . if missing(anb_city_fun_clean) |  missing(w_city_fun_clean) 


if `len_arg'>3 {
replace bidder_non_local = 0 if filter_ok & anb_nuts_fun==w_nuts_fun & (!missing(anb_nuts_fun) | !missing(w_nuts_fun) )
replace bidder_non_local = . if missing(anb_nuts_fun) |  missing(w_nuts_fun) 
}
cap drop anb_city_fun_clean w_city_fun_clean 
cap drop anb_nuts_fun w_nuts_fun
