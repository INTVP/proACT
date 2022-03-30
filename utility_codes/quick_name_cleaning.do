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

ereplace `1'_clean = sieve(`1'_clean), omit(0123456789)
replace `1'_clean=lower(`1'_clean) 

*Removing lone letters
*br `1'_clean if regex(`1'_clean," [a-z] ")
forval s = 1/122{
replace `1'_clean = regexr(`1'_clean," [a-z] "," ")
}
replace `1'_clean = " " + `1'_clean + " "
forval s = 1/2{
replace `1'_clean = regexr(`1'_clean," [a-z] "," ")
}
*Removing 2 letter words
replace `1'_clean = " " + `1'_clean + " "
forval s = 1/12{
replace `1'_clean = regexr(`1'_clean," [a-z][a-z] "," ")
}

forval var=1/10{
replace `1'_clean = subinstr(`1'_clean, "  ", " ",.)
}
replace `1'_clean = stritrim(`1'_clean)
replace `1'_clean = strtrim(`1'_clean)
unique  `1'_clean

