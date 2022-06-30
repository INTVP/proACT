local country "`0'"
********************************************************************************
/*This script is early stage script that uses the tender/contract titles to find the
 relevant cpv code using token string matching*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Using matchit

egen unqiue_id=group(title)
// sort title
save "${country_folder}/`country'_wip.dta", replace 
********************************************************************************

keep unqiue_id title cpv 
duplicates drop title, force
keep if !missing(title)
keep if missing(cpv)
drop cpv 
// unique  title
// unique unqiue_id
save "${country_folder}/MX_cleaned_nodup.dta", replace
********************************************************************************

matchit unqiue_id title using "${utility_data}/country/`country'/cpv_spanish.dta" , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
// br title cpv_descr simil_token
drop if simil_token<0.4

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save "${country_folder}/matches1.dta", replace
********************************************************************************
*Merging back with full dataset

use "${country_folder}/`country'_wip.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches1.dta", generate(_m)
drop simil_token _m unqiue_id

// count if missing(code)
// di `r(N)'/_N  //77%
// br title cpv
*Giving similar titles the same cpv code
cap drop X
bys title: gen X = _N
format title %20s
// br title cpv X if X>1
gsort title -cpv
bys title: replace cpv = cpv[1] if missing(cpv) & !missing(title)
drop X

// br title cpv code
tostring(code), gen(code_str)
gen code_len = length(code_str)
gen code_2 = substr(code_str,1,2)
// tab code_len if code_2=="31"  //for the len 8 add 0 at the beg
replace code_str = "0" + code_str if code_len==8 & code_2=="31"
drop code_len code_2
********************************************************************************
*Merging cpv and code_str

// br title cpv code_str if !missing(cpv) | !missing(code_str)
*cpv has the priority if conflicting
replace cpv = code_str if missing(cpv) & !missing(code_str)
drop code code_str cpv_descr

replace title = stritrim(title)
replace title = strtrim(title)

egen unqiue_id=group(title)

save "${country_folder}/`country'_wip.dta", replace  
********************************************************************************
* 2nd matching 
keep unqiue_id title cpv 
duplicates drop title, force
keep if !missing(title)
keep if cpv=="."
drop cpv 
unique title
unique unqiue_id
save "${country_folder}/MX_cleaned_nodup_2.dta", replace //328,104 
********************************************************************************

use "${country_folder}/MX_cleaned_nodup_2.dta", clear

matchit unqiue_id title using "${utility_data}/country/`country'/cpv_spanish.dta" , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
// br title cpv_descr simil_token
drop if simil_token<0.4

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save "${country_folder}/matches2.dta", replace
********************************************************************************
*Merging back with full dataset ver 2
use "${country_folder}/`country'_wip.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches2.dta", generate(_m)
drop simil_token _m unqiue_id
// br title cpv code if !missing(code)
tostring(code), gen(code_str)
*Merging cpv and code_str
replace cpv="" if cpv=="."
replace code_str="" if code_str=="."
replace cpv = code_str if missing(cpv) & !missing(code_str)
*Fixing 03/30 and 09/90
gen code_len = length(cpv)
gen code_1= substr(code_str,1,1)
sort cpv
// tab code_len if code_1=="3"
// tab code_len if code_1=="9" 
*for the length 8 add 0 at the beg
replace cpv = "0" + cpv if code_len==8 & inlist(code_1,"3","9")
drop code cpv_descr code_len code_1

*Merging cpv and code_str
// br title cpv code_str if !missing(cpv) | !missing(code_str)
*cpv has the priority if conflicting
replace cpv = code_str if missing(cpv) & !missing(code_str)
cap drop code code_str 
cap drop cpv_descr
********************************************************************************
*Fixes

// br aw_item_class_id cpv if !missing(aw_item_class_id)
// tab  cpv if !missing(aw_item_class_id)  //03 and 09 are fixed
// tab  cpv   //03 and 09 are fixed
gen cpv_div = substr(cpv,1,2)
tab cpv_div //91 93 are bad
// br  aw_item_class_id cpv if cpv_div=="91"
replace cpv = "0" + cpv if inlist(cpv_div,"91","93")
replace cpv = substr(cpv,1,8) if inlist(cpv_div,"91","93")
gen length_cpv=length(cpv)
// br  aw_item_class_id cpv length_cpv if regex(cpv,"^3") & missing(aw_item_class_id)
// tab cpv_div if !missing(aw_item_class_id)  //looks like 03 is fixed in the matching
drop length_cpv cpv_div

*Fix the uncategorized
decode ca_type, gen(ca_type_str)
replace cpv = "99100000" if missing(cpv) & ca_type_str=="goods"
replace cpv = "99200000" if missing(cpv) & ca_type_str=="services"
replace cpv = "99300000" if missing(cpv) & ca_type_str=="works"
replace ca_type_str="" if ca_type_str=="NA"
replace cpv = "99000000" if missing(cpv) & missing(ca_type_str)
// count if missing(cpv) //should always be zero at the end
gen length_cpv=length(cpv)
// tab length_cpv //8s and 9s
drop length_cpv ca_type_str
// br aw_item_class_id cpv
label var cpv "Harmonized and Matched cpv codes"

********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END