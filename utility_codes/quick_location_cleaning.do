local country "`2'"

gen `1'_clean = `1'

local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace `1'_clean = subinstr(`1'_clean, "`v'", " ",.)
}
replace `1'_clean = subinstr(`1'_clean, `"""', " ",.)
replace `1'_clean = subinstr(`1'_clean, `"$"', " ",.) 
replace `1'_clean = subinstr(`1'_clean, "'", " ",.)
replace `1'_clean = subinstr(`1'_clean, "ʼ", " ",.)
replace `1'_clean = subinstr(`1'_clean, "`", " ",.) 
replace `1'_clean = subinstr(`1'_clean, ".", " ",.)
replace `1'_clean = subinstr(`1'_clean, `"/"', " ",.)
replace `1'_clean = subinstr(`1'_clean, `"\"', " ",.)	
replace `1'_clean = subinstr(`1'_clean, `"_"', " ",.)	

if inlist("`country'","PY","UG"){
replace `1'_clean = ustrregexra(`1'_clean,"DISTRITO|MUNICIPIO","")
do "${utility_codes}/transliteration_cleaning.do" `1'
}

ereplace `1'_clean = sieve(`1'_clean), omit(0123456789)
replace `1'_clean=ustrlower(`1'_clean) 

forval var=1/10{
replace `1'_clean = subinstr(`1'_clean, "  ", " ",.)
}
replace `1'_clean = stritrim(`1'_clean)
replace `1'_clean = strtrim(`1'_clean)

*unique  `1'_clean

