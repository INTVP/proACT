*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script is early stage script that uses the tender/contract titles to find the
 relvent cpv code using token string matching*/
********************************************************************************

*Data
*Using dataset coming out of 0_A_cpv_manual_ID.R - dfid_indonesia_cricpv200708.csv

import delimited using $country_folder/dfid_indonesia_cricpv200708.csv, encoding(UTF-8) clear
********************************************************************************

br ten_title_orig ten_title 
decode ten_title_orig, gen (ten_title_str)
sort ten_title_str
br ten_title_str cpv_code

rename cpv_code cpv_code_manual
************************************

*counts
unique ten_title_str   // from original titles 638,762
unique ten_title_str if !missing(cpv_code_manual)  //Nori found cpvs for 321,357
unique ten_title_str if missing(cpv_code_manual)  //Missing cpvs for 317,405

*missing rate
count if missing(cpv_code_manual)
local product_code = `r(N)'/_N
di `product_code'  //50.3%
************************************

*Step 1: Cleaning tender title

gen ten_description_edit = ten_title_str
keep if ten_description_edit!="NA" 
keep if ten_description_edit!="" 
replace ten_description_edit=lower(ten_description_edit)

*Replace Circumflex character // Â Ê Î Ô Û â ê î ô û Č
local temp "Â Ê Î Ô Û â ê î ô û Č č ě ř Ě ž ň Ř"
local temp2 "a e i o u a e i o u c c e r e z n r"
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
 
replace ten_description_edit = subinstr(ten_description_edit, `"""', "",.)
replace ten_description_edit = subinstr(ten_description_edit, `"$"', "",.) 
replace ten_description_edit = subinstr(ten_description_edit, "'", "",.)
replace ten_description_edit = subinstr(ten_description_edit, "ʼ", "",.)
replace ten_description_edit = subinstr(ten_description_edit, "`", "",.) 
replace ten_description_edit = subinstr(ten_description_edit, ".", "",.)
replace ten_description_edit = subinstr(ten_description_edit, `"/"', " ",.)
replace ten_description_edit = subinstr(ten_description_edit, `"\"', "",.)	
replace ten_description_edit = subinstr(ten_description_edit, `"_"', " ",.)	

*charlist ten_description_edit 
forval var=1/8{
replace ten_description_edit = subinstr(ten_description_edit, "  ", " ",.)
}

ereplace ten_description_edit = sieve(ten_description_edit), omit(0123456789)


*Remove words that are not helpful for the matching
local temp "motor metode instalasi supply pasokan pcs piece pieces potongan bagian ltrs liters liter year yearly tahun tahunan biannual annual assorted framework kerangka division divisi contract kontrak purchase membeli provision ketentuan procurement pengadaan pembelian various berbagai phase tahap notice memperhatikan kilogram kilograms using menggunakan and dan the itu kgs bid tawaran at di kg no of dari a"
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}

local temp "january february march april may june july august september october november december jan feb mar apr jun jul sept aug oct nov dec"
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}
	
local temp "januari februari maret april mungkin juni juli agustus september oktober november desember jan feb mar apr jun jul sept agu okt nov des"
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}

local temp ""abt jl" "jl" "abt""
local n_temp : word count `temp'
replace ten_description_edit = " " + ten_description_edit + " "
forval s =1/`n_temp'{
 replace ten_description_edit = subinstr(ten_description_edit, " `: word `s' of `temp'' ", " ",.)
	}
		
replace ten_description_edit = stritrim(ten_description_edit)
replace ten_description_edit = strtrim(ten_description_edit)
format ten_description_edit ten_title_str  %40s
br ten_description_edit ten_title_str
************************************

unique ten_description_edit
unique ten_title_str

egen unqiue_id=group(ten_description_edit)
sort unqiue_id
save $country_folder/ID_ten_full.dta, replace

keep unqiue_id ten_description_edit cpv_code_manual
keep if missing(cpv_code_manual)
drop cpv_code_manual
duplicates drop ten_description_edit, force
unique  ten_description_edit
unique unqiue_id
save $country_folder/ID_ten_cleaned_nodup.dta, replace

********************************************************************************
*Preparing cpv data
clear all
import delimited $utility_data/country/ID/CPV_list_indonesian.csv, clear varnames(1)
drop cpv_descr
*rename cpv_desc_id cpv_descr
rename cpv_desc_id_google cpv_descr
drop cpv_desc_id

format cpv_descr %45s
br code cpv_descr
replace cpv_descr = subinstr(cpv_descr, " dan ", " ",.)
replace cpv_descr = subinstr(cpv_descr, " atau ", " ",.)
replace cpv_descr = lower(cpv_descr)

local temp "№ « » ‹ › Þ þ ð º ° ª ¡ ¿ ¢ £ € ¥ ƒ ¤ © ® ™ • § † ‡ ¶ & “ ” ¦ ¨ ¬ ¯ ± ² ³ ´ µ · ¸ ¹ º ¼ ½ ¾"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace cpv_descr = subinstr(cpv_descr, "`: word `s' of `temp''", "",.)
	}
local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace cpv_descr = subinstr(cpv_descr, "`v'", "",.)
}
 
charlist cpv_descr 

/*Identifying common words to drop from list
freqindex cpv_descr, simil(token)
gsort - freq
list grams if _n<=10
format grams %40s
I identified words with a freq>40*/

local temp "layanan and services untuk pekerjaan peralatan jasa perangkat konstruksi mesin work of lunak for construction equipment sistem paket yang produk pemasangan perbaikan bagian pemeliharaan air or listrik pengembangan alat software gas kapal dengan parts terkait dari jalan komputer bahan lampu manajemen installation kertas minyak instalasi maintenance konsultasi development udara lainnya bangunan vehicles api kabel kereta pesawat data repair machinestransportasi kendaraan tanah rumah jaringan radio pipa machinery gigi video batu kontrol products telepon apparatus works"
local n_temp : word count `temp'
replace cpv_descr = " " + cpv_descr + " "
forval s =1/`n_temp'{
 replace cpv_descr = subinstr(cpv_descr, " `: word `s' of `temp'' ", " ",.)
	}
replace cpv_descr = stritrim(cpv_descr)
replace cpv_descr = strtrim(cpv_descr)
drop if missing(cpv_descr)
	
unique code
keep code cpv_descr
duplicates drop cpv_descr , force
save $utility_data/country/ID/cpv_code.dta, replace
********************************************************************************

*Step 2: Matching

use $country_folder/ID_ten_cleaned_nodup.dta, clear
matchit unqiue_id ten_description_edit using $utility_data/country/ID/cpv_code.dta , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(minsimple) g(simil_token) stopw swt(0.9) time flag(10) t(0.5) over  
*scoring minsimple gives a match of 1 if small word exist in long text. - creates many matches 870k

gsort - simil_token
format ten_description_edit cpv_descr %50s
br ten_description_edit cpv_descr simil_token

*keeping score == 1
keep if simil_token==1
gsort unqiue_id -simil_token
*bys unqiue_id: gen count=_n

*If tender is matched to more than 1 cpv, tender takes more than 1 cpv
bys unqiue_id: gen count=_N
egen group = group(unqiue_id) if count>1
su group , meanonly
gen code_new=""
forvalues i = 1/`r(max)' {
 levelsof code if group==`i'
 replace code_new ="`r(levels)'" if group == `i' & missing(code_new)
 }
format code_new %20s
br unqiue_id group ten_description_edit code_new

tostring code,gen(code_str)
replace code_new = code_str if missing(code_new)
br unqiue_id group ten_description_edit code*
gen code_new2 = code_new
format code_new2 %20s
replace code_new2 = stritrim(code_new2)
replace code_new2 = strtrim(code_new2)
replace code_new2 = subinstr(code_new2," ","  ",.)
replace code_new2 = subinstr(code_new2,"  ",",",.)

duplicates drop unqiue_id, force
drop simil_token count group code_new code code_str 
rename code_new2 cpv_code
********************************************************************************

*Trying to determine the most frequent cpv
split cpv_code, p(,)
forvalues i =1/35{
replace cpv_code`i'=substr(cpv_code`i',1,2)
}

rename cpv_code cpv_code_full
reshape long cpv_code, i(unqiue_id ten_description_edit cpv_descr cpv_code_full) j(cpv_code_new)
drop if missing(cpv_code)
rename cpv_code_new z
bys unqiue_id cpv_code: gen x=_N
bys unqiue_id : gen y=_N
br unqiue_id cpv_code y z x  if y>1
gsort unqiue_id -x
drop z
bys unqiue_id: gen z=_n
keep if z ==1
drop x y z
br 
rename cpv_code cpv_code_main
drop cpv_descr

*Then filtering based on length
*gen len=length(ten_description_edit)

save $country_folder/matches.dta, replace
********************************************************************************

*Merging back with full dataset
use $country_folder/ID_ten_full.dta, replace
merge m:1 unqiue_id using $country_folder/matches.dta, generate(_m)
drop _m
br ten_title_orig ten_description_edit ten_title_str cpv_code_manual cpv_code_main cpv_code_full

gen cpv_code_matchit = cpv_code_main + "000000" if !missing(cpv_code_main)
gen comma = regex(cpv_code_full,",")
replace cpv_code_matchit = cpv_code_full if comma!=1
drop comma
destring cpv_code_matchit, replace
br cpv_code_manual cpv_code_matchit
replace cpv_code_manual=0 if missing(cpv_code_manual)
replace cpv_code_matchit=0 if missing(cpv_code_matchit)
gen cpv_code = cpv_code_manual+cpv_code_matchit
replace cpv_code=. if cpv_code==0
drop ten_title ten_description_edit cpv_code_manual unqiue_id cpv_code_main cpv_code_matchit

********************************************************************************

*Fixing the cpv code

format  cpv_code %24.0g
format  cpv_code_full %10s
gen comma=strpos(cpv_code_full, ",")
tostring cpv_code, gen (cpv_code_str)
replace cpv_code_str="" if cpv_code_str=="."
replace cpv_code_full="" if cpv_code_full=="."
*replace cpv_code_str = cpv_code_full if comma==0 
*replace cpv_code_str = string(cpv_code) if missing(cpv_code_str) 
drop comma

rename cpv_code cpv_code_matched
rename cpv_code_str cpv_code

*to fix cpv code
gen cpv_code2=substr(cpv_code,1,8)
rename cpv_code cpv_code_ver
rename cpv_code2 cpv_code

merge m:1 cpv_code using $utility_data/country/ID/cpv_str_9.dta, gen(match_9)
drop if match_9==2

merge m:1 cpv_code using $utility_data/country/ID/cpv_str_8.dta, gen(match_8)
drop if match_8==2

replace cpv_code=cpv_code_full if match_8==1 & match_9==1 & !missing(cpv_code_full)

replace cpv_code="03111000" if  cpv_code=="31100004"
replace cpv_code="39162110" if  cpv_code=="39162201"
replace cpv_code="45221000" if  cpv_code=="45221001"
replace cpv_code="45231300" if  cpv_code=="45231302"
replace cpv_code="45232000" if  cpv_code=="45232099"
replace cpv_code="45241400" if  cpv_code=="45241401"
replace cpv_code="45252120" if  cpv_code=="45252128"
replace cpv_code="66171000" if  cpv_code=="66171001"
replace cpv_code="66171000" if  cpv_code=="66171001"
replace cpv_code="71310000" if  cpv_code=="71310003"
replace cpv_code="71311000" if  cpv_code=="71311001"
replace cpv_code="71530000" if  cpv_code=="71530003"
replace cpv_code="73210000" if  cpv_code=="73210003"
replace cpv_code="79314000" if  cpv_code=="79314003"
replace cpv_code="90910000" if  cpv_code=="90910003"
replace cpv_code="091112208" if  cpv_code=="91112208"

split cpv_code, p(",")
drop cpv_code2-cpv_code14 cpv_code
rename cpv_code1 cpv_code

replace cpv_code="0" + cpv_code if match_8==1 & match_9==1 & !missing(cpv_code)

br  *cpv* *title* match_8 match_9 if match_8==1 & match_9==1 & !missing(cpv_code)
drop match_9 match_8 cpv_code_ver 
*cpv_code now contains the best cpv code -  harmonized

********************************************************************************
save $country_folder/ID_wip.dta, replace
********************************************************************************
*END