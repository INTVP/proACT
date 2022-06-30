local country = "`0'"
********************************************************************************
/*This script is early stage script that uses the tender description to find the
 relvent cpv code using token string matching*/
********************************************************************************
*Data

import delimited "${country_folder}/`country'_wip.csv", varnames(1) encoding(UTF-8) clear
********************************************************************************
*Matching tender decription to cpv code

gen miss_cpv=missing(cpv_code)
// tab miss_cpv if !missing(planb_descr)
// count if missing(planb_descr)
// count if missing(aw_title)

// gen ten_description = planb_descr
// replace ten_description= aw_title if missing(ten_description)
// count if !missing(ten_description)
// format  planb_descr_str aw_title_str ten_description %25s
// br planb_descr_str aw_title_str ten_description

gen  ten_description =  tender_title_orig
replace ten_description= lot_title if missing(ten_description)

replace ten_description = stritrim(ten_description)
replace ten_description = strtrim(ten_description)

********************************************************************************

*Step 1: Cleaning the ten description variable

gen ten_description_edit = ten_description
keep if ten_description_edit!="NA" 
keep if ten_description_edit!="" 
replace ten_description_edit=lower(ten_description_edit)
*Replace Actute character //  Á É Í Ó Ú á é í ó ú Ý ý
local temp "Á É Í Ó Ú á é í ó ú Ý ý ń"
local temp2 "a e i o u a e i o u y y n"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Grave character // À È Ì Ò Ù à è ì ò ù
local temp "À È Ì Ò Ù à è ì ò ù ș"
local temp2 "a e i o u a e i o u s"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}


*Replace Circumflex character // Â Ê Î Ô Û â ê î ô û Č
local temp "Â Ê Î Ô Û â ê î ô û Č č ě ř Ě ž ň Ř"
local temp2 "a e i o u a e i o u c c e r e z n r"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Tilde character // Ã Ñ Õ ã ñ õ 
local temp "Ã Ñ Õ ã ñ õ"
local temp2 "a n o a n o"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Umlaut character // Ä Ë Ï Ö Ü Ÿ ä ë ï ö ü ÿ
local temp "Ä Ë Ï Ö Ü Ÿ ä ë ï ö ü ÿ"
local temp2 "a e i o u y a e i o u y"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace other special character // Ç ç Œ œ Ø ø Å å Æ æ Š š Ž ž
local temp "Ç ç Œ œ Ø ø Å å Æ æ Š š Ž ž Ł ł Ż ń ď ů ș ț" 
local temp2 "c c oe oe o o a a ae ae s s z z l l z n d u s t"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

local temp "№ « » ‹ › Þ þ ð º ° ª ¡ ¿ ¢ £ € ¥ ƒ ¤ © ® ™ • § † ‡ ¶ & “ ” ¦ ¨ ¬ ¯ ± ² ³ ´ µ · ¸ ¹ º ¼ ½ ¾"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, "`: word `s' of `temp''", "",.)
	}
local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace ten_description_edit = subinstr(ten_description_edit, "`v'", "",.)
}
// charlist ten_description_edit 
 
replace ten_description_edit = subinstr(ten_description_edit, `"""', "",.)
replace ten_description_edit = subinstr(ten_description_edit, `"$"', "",.) 
replace ten_description_edit = subinstr(ten_description_edit, "'", "",.)
replace ten_description_edit = subinstr(ten_description_edit, "ʼ", "",.)
replace ten_description_edit = subinstr(ten_description_edit, "`", "",.) 
replace ten_description_edit = subinstr(ten_description_edit, ".", "",.)
replace ten_description_edit = subinstr(ten_description_edit, `"/"', " ",.)
replace ten_description_edit = subinstr(ten_description_edit, `"\"', "",.)	
replace ten_description_edit = subinstr(ten_description_edit, `"_"', " ",.)	

// charlist ten_description_edit 
forval var=1/8{
replace ten_description_edit = subinstr(ten_description_edit, "  ", " ",.)
}

ereplace ten_description_edit = sieve(ten_description_edit), omit(0123456789)

*removing stop words
replace ten_description_edit = subinstr(ten_description_edit, "cert ", "",.)
replace ten_description_edit="ticket" if regexm(ten_description_edit,"air ticket for")
replace ten_description_edit="ticket" if regexm(ten_description_edit,"airticketing")
replace ten_description_edit=subinstr(ten_description_edit,"servicing","service",.)

local temp "motor method installation supply pairs pcs pieces piece ltrs liters year yearly biannual annual assorted framework division contract purchase provision procurement various phase notice using and the kgs bid at kg no of a"
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}


local temp "january february march april may june july august september october november december jan feb apr jun jul sept aug oct nov dec"
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}


replace ten_description_edit = stritrim(ten_description_edit)
replace ten_description_edit = strtrim(ten_description_edit)
format ten_description_edit ten_description %40s
// br ten_description_edit ten_description

split ten_description_edit, p(" for " " in " " to ")
// format ten_description_edit* %19s
// br ten_description_edit*


// unique  ten_description_edit
// unique  ten_description_edit1
// unique ten_description

egen unqiue_id=group(ten_description_edit1)
// sort unqiue_id

save "${country_folder}/UG_ten_full.dta", replace

keep unqiue_id ten_description_edit1
duplicates drop ten_description_edit1, force
// unique  ten_description_edit1
// unique unqiue_id

save "${country_folder}/UG_ten_cleaned_nodup.dta", replace

matchit unqiue_id ten_description_edit1 using "${utility_data}/cpv_code.dta", idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.5) over  

// gsort - simil_token
// format ten_description_edit cpv_descr %50s
// br ten_description_edit cpv_descr simil_token

drop if simil_token<0.61

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save "${country_folder}/matches.dta", replace

*Merging back with full dataset
use "${country_folder}/UG_ten_full.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches.dta", generate(_m)
drop unqiue_id
drop ten_description_edit2-ten_description_edit9
drop simil_token _m
*******************************************************************************
*Matching 2nd time
* generate a new id and Drop the ones that we're already matched and repeat matching
rename code code_step1
rename cpv_descr cpv_descr_step1
egen unqiue_id=group(ten_description_edit1)
sort unqiue_id
save "${country_folder}/UG_ten_full_forstep2.dta", replace

*prepare data for matching
drop if !missing(code)
keep unqiue_id ten_description_edit1
duplicates drop ten_description_edit1, force
// unique  ten_description_edit1
// unique unqiue_id
save "${country_folder}/UG_ten_cleaned_nodup_forstep2.dta", replace

use "${country_folder}/UG_ten_cleaned_nodup_forstep2.dta", clear
matchit unqiue_id ten_description_edit1 using "${utility_data}/cpv_code.dta", idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.5) over  

gsort - simil_token
// format ten_description_edit cpv_descr %50s
// br ten_description_edit cpv_descr simil_token

drop if simil_token<0.55

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save "${country_folder}/matches_step2.dta", replace

*Merging back with full dataset
use "${country_folder}/UG_ten_full_forstep2.dta", replace
merge m:1 unqiue_id using "${country_folder}/matches_step2.dta", generate(_m)
replace code_step1=code if missing(code_step1)
replace cpv_descr_step1=cpv_descr if missing(cpv_descr_step1)
drop unqiue_id
drop simil_token _m
drop code cpv_descr

rename code_step1 code
rename cpv_descr_step1 cpv_descr

*Fixing variable names
rename cpv_code cpv_nori
rename code cpv_aly
rename ca_descr_cpv cpv_desc_nori
rename cpv_descr cpv_desc_aly

gen miss_cpv_nori=missing(cpv_nori)
gen miss_cpv_aly=missing(cpv_aly)
// tab miss_cpv_nori miss_cpv_aly if filter_ok==1

format cpv_desc_nori cpv_desc_aly %25s
*common between nori and aly
// br ten_description cpv_nori cpv_desc_nori cpv_aly cpv_desc_aly if  miss_cpv_nori==0 & miss_cpv_aly==0
// br ten_description cpv_nori cpv_desc_nori cpv_aly cpv_desc_aly if  miss_cpv_nori==0 & miss_cpv_aly==1
// br ten_description cpv_nori cpv_desc_nori cpv_aly cpv_desc_aly if  miss_cpv_nori==1 & miss_cpv_aly==0


tostring cpv_nori,gen(cpv_nori_str)
tostring cpv_aly,gen(cpv_aly_str)
drop cpv_nori cpv_aly
gen cpv_global = cpv_nori_str
replace cpv_global=cpv_aly_str if cpv_global=="."
gen cpv_desc_global = cpv_desc_nori
replace cpv_desc_global=cpv_desc_aly if cpv_desc_global==""

format cpv_desc_global %25s
// br planb_descr aw_title ten_description cpv_global cpv_desc_global cpv_nori cpv_desc_nori cpv_aly cpv_desc_aly 

*Manual Additions

cap drop ten_description cpv_aly_str cpv_desc_aly   miss_cpv_nori miss_cpv_aly cpv_desc_nori
// br ten_description_edit ten_description_edit1 if cpv_global=="."
*a lot of advert and advertisments-fix it
replace cpv_global="793410006"  if regex(ten_description_edit1,"advert") & cpv_global=="."
replace cpv_desc_global="advertising services"  if regex(ten_description_edit1,"advert") & cpv_global=="793410006"

replace cpv_global="551100004"  if regex(ten_description_edit1,"accommodation|accomodation") & cpv_global=="."
replace cpv_desc_global="hotel accommodation services"  if regex(ten_description_edit1,"accommodation|accomodation") & cpv_global=="551100004"

replace cpv_global="224590002"  if regex(ten_description_edit1,"airticket|airtime") & cpv_global=="."
replace cpv_desc_global="tickets"  if regex(ten_description_edit1,"airticket|airtime") & cpv_global=="224590002"

replace cpv_global="351134003"  if regex(ten_description_edit1,"protective wear") & cpv_global=="."
replace cpv_desc_global="protective and safety clothing"  if regex(ten_description_edit1,"protective wear") & cpv_global=="351134003"

replace cpv_global="322500000"  if regex(ten_description_edit1,"smartphone") & cpv_global=="."
replace cpv_desc_global="mobile telephones"  if regex(ten_description_edit1,"smartphone") & cpv_global=="322500000"

replace cpv_global="301251208"  if regex(ten_description_edit1,"tonner") & cpv_global=="."
replace cpv_desc_global="toner for photocopiers"  if regex(ten_description_edit1,"tonner") & cpv_global=="301251208"

replace cpv_global="324131002"  if regex(ten_description_edit1,"wireless router") & cpv_global=="."
replace cpv_desc_global="network routers"  if regex(ten_description_edit1,"wireless router") & cpv_global=="324131002"

*For switching motor vehicles" that should be service
replace cpv_global="501000006"  if regex(ten_description_edit1,"vehicle") & regex(ten_description_edit1,"service") & cpv_global=="."
replace cpv_desc_global="repair maintenance and associated services of vehicles and related equipment"  if regex(ten_description_edit1,"vehicle service") & cpv_global=="501000006"


// br ten_description_edit ten_description_edit1 cpv_global cpv_desc_global if cpv_global =="."

// count if cpv_global=="." & filter_ok==1
// local miss_cpv `r(N)'
// count if filter_ok==1
// local total `r(N)'
// di `miss_cpv'/`total' //improved to 30% missing from 48% missing

cap drop drop planb_descr aw_title 
cap drop ten_description_edit1 ten_description_edit 
cap drop cpv_nori_str cpv_code_str miss_cpv
cap drop check
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*Clean up 

erase "${country_folder}/UG_ten_full.dta"
erase "${country_folder}/UG_ten_cleaned_nodup.dta"
erase "${country_folder}/matches.dta"
erase "${country_folder}/UG_ten_full_forstep2.dta"
erase "${country_folder}/UG_ten_cleaned_nodup_forstep2.dta"
erase "${country_folder}/matches_step2.dta"
********************************************************************************
*END