local country "`0'"
********************************************************************************
/*This script is early stage script that uses the tender/contract titles to find the
 relevant cpv code using token string matching*/
********************************************************************************

*Data
use "${utility_data}/country/`country'/starting_data/dfid2_cri_in200301.dta", clear
********************************************************************************

// br ca_item_class_id
decode ca_item_class_id, gen(product_code)
sort source
// br ca_item_class_id product_code source
drop ca_item_class_id
*if source==1 then ca_item_class_id contains cpv code otherwise it's text
gen cpv_source1 = product_code if source==1

*Take title from source ==2 & any title if available
decode ten_title, gen(ten_title_original)
drop ten_title
// br ten_title_original product_code if source==2
*I'll use product_code as it seems more focused on the product
gen title = product_code if source==2
********************************************************************************

*Cleaning title

// charlist title  //all english letters

local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace title = subinstr(title, "`v'", " ",.)
}
replace title = subinstr(title, `"""', " ",.)
replace title = subinstr(title, `"$"', " ",.) 
replace title = subinstr(title, "'", " ",.)
replace title = subinstr(title, "ʼ", " ",.)
replace title = subinstr(title, "`", " ",.) 
replace title = subinstr(title, ".", " ",.)
replace title = subinstr(title, `"/"', " ",.)
replace title = subinstr(title, `"\"', " ",.)	
replace title = subinstr(title, `"_"', " ",.)	

ereplace title = sieve(title), omit(0123456789)
replace title=lower(title) 
// br title if !missing(title) 

local temp "na miscellaneous null multi mgmt of in all and other etc nil n a"
local n_temp : word count `temp'
replace title = " " + title + " "
forval s =1/`n_temp'{
 replace title = subinstr(title, " `: word `s' of `temp'' ", " ",.)
	}
forval var=1/20{
replace title = subinstr(title, "  ", " ",.)
}
replace title = stritrim(title)
replace title = strtrim(title)
// unique  title

egen unqiue_id=group(title)
sort title
********************************************************************************
save "${country_folder}/IN_full.dta", replace 
********************************************************************************
keep unqiue_id title
duplicates drop title, force
keep if !missing(title)
// unique  title
// unique unqiue_id
********************************************************************************
save  "${country_folder}/IN_cleaned_nodup.dta", replace 
********************************************************************************
use "${country_folder}/IN_cleaned_nodup.dta", replace

matchit unqiue_id title using "${utility_data}/cpv_code.dta" , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
// br title cpv_descr simil_token
drop if simil_token<0.3

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save "${country_folder}/matches1.dta", replace
********************************************************************************
*Merging back with full dataset
use "${country_folder}/IN_full.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches1.dta", generate(_m)
drop simil_token _m unqiue_id

// count if missing(code)
// di `r(N)'/_N  //half matched - needs a 2nd round
*further cleaing

replace title = subinstr(title, "sbu g l kolkata", " ",.)
replace title = subinstr(title, "sbu g l", " ",.)
replace title = subinstr(title, "g l", " ",.)
replace title = subinstr(title, "division", " ",.)
replace title = subinstr(title, "prcessing", "processing",.)
replace title = subinstr(title, "amc", " ",.)
replace title = subinstr(title, "others", " ",.)
replace title = subinstr(title, "ssi", " ",.)
replace title = subinstr(title, "stp", " ",.)
replace title = subinstr(title, "sump", " ",.)
replace title = subinstr(title, "supplt", " ",.)
replace title = subinstr(title, "xeroxing", "xerox",.)
forval var=1/20{
replace title = subinstr(title, "  ", " ",.)
}
replace title = stritrim(title)
replace title = strtrim(title)
rename code code1
rename cpv_descr cpv_descr1

egen unqiue_id=group(title)

save "${country_folder}/IN_full.dta", replace
********************************************************************************
* 2nd matching 
keep unqiue_id title code 
keep if missing(code) | code==.
drop code
duplicates drop title, force
keep if !missing(title)
// unique  title
// unique unqiue_id
save "${country_folder}/IN_cleaned_nodup_2.dta", replace
********************************************************************************

use "${country_folder}/IN_cleaned_nodup_2.dta", clear
matchit unqiue_id title using "$utility_data/cpv_code.dta" , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
// br title cpv_descr simil_token
drop if simil_token<0.3

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count simil_token
save "${country_folder}/matches2.dta", replace
********************************************************************************
*Merging back with full dataset 

use "${country_folder}/IN_full.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches2.dta", generate(_m)
drop  _m
replace code1 = code if missing(code1) | code1==.
replace cpv_descr1 = cpv_descr if missing(cpv_descr1) | cpv_descr1==""
drop code cpv_descr
rename code1 cpv_code
rename cpv_descr1 cpv_descr

// br title if missing(cpv_code) & !missing(title)  
********************************************************************************
*Merging back the source 1 cpvs

tostring cpv_code, gen(cpv_code1)
drop cpv_code
rename cpv_code1 cpv_code

*Removing matches if nr of words is more than 90th percentile
gen nrwords =  wordcount(title)
sum nrwords, d
format title %20s
*br title cpv_desc nrwords if nrwords<`r(p90)'
replace cpv_code ="" if nrwords>=`r(p90)'
replace cpv_descr ="" if nrwords>=`r(p90)'
drop nrwords
********************************************************************************
save "${country_folder}/`country'_wip", replace
********************************************************************************
*END