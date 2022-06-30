*Get number of arguments passed to create the nuts code as a concat of args passed: max 3 nuts vars
local x "`0'"
local len_arg : word count `x'
*Get country
local country "`1'"
************************************************
* Script calculates is_capital: tags contracts in the capital city/region
************************************************

cap drop is_capital
gen is_capital = 0

*Harmonize NUTS variable 
cap drop nuts
if `len_arg'==3 {
	gen nuts = `3' 
}
if `len_arg'==4 {
	gen nuts = `3' + " " + `4' 
}
if `len_arg'==5{
	gen nuts = `3' + " " + `4' + " " + `5'
}

*Capture the search keywords from capital_cities_nuts.csv
preserve 
	import delimited "${utility_data}/capital_cities_nuts.csv", clear varnames(1) encoding("UTF-8")
	keep if country=="`country'"
	if "`country'" == "WB"{
	do "${utility_codes}/quick_location_cleaning.do" capital "`country'"
	drop capital 
	rename capital_clean capital
	}
	levelsof capital,local(capitals_keywords)
	levelsof nuts,local(nuts_keywords)
restore

*Loop over keywords and flag contracts if in capital

*Nuts Search
if !inlist("`country'","PY","WB","CL","GE","CO","MD","MX","US"){

foreach keyword in `nuts_keywords'{
di "Searching for `keyword'"
replace is_capital = 1 if ustrregexm(nuts,"`keyword'" , 1)
}

}
*************************
*City Search

foreach keyword in `capitals_keywords'{
di "Searching for `keyword'"
replace is_capital = 1 if ustrregexm(`2',"`keyword'" , 1) & !missing(`2')
}

if inlist("`country'","PY","CL","CO"){

foreach keyword in `capitals_keywords'{
di "Searching for `keyword'"
replace is_capital = 1 if ustrregexm(`3',"`keyword'" , 1) & !missing(`3')
}

}

cap drop nuts
*tab is_capital, m
