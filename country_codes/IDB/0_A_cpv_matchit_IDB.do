local country "`0'"
********************************************************************************
/*This script is early stage script that uses the ca_type to find the
 relvent cpv code using token string matching*/
********************************************************************************
*Data

import delimited using "${utility_data}/country/`country'//starting_data/idb_contracts_with_prdata_190130_forpublication.csv", encoding(UTF-8)  varnames(1) clear 
********************************************************************************
*Matching round 1

// br ca_type if !missing(ca_type) 
gen title = ca_type 
replace title = lower(ca_type)
// count if missing(title) //31,061

*charlist title  //clean all english letters some symbols
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

// br title if !missing(ca_type) 

local temp "others nec nonscheduled scheduled except miscell used misc exc and ex men boys s u"
local n_temp : word count `temp'
replace title = " " + title + " "
forval s =1/`n_temp'{
 replace title = subinstr(title, " `: word `s' of `temp'' ", " ",.)
	}

replace title = subinstr(title, "related work", " ",.)
replace title = subinstr(title, "related products", " ",.)
replace title = subinstr(title, "related product", " ",.)
replace title = subinstr(title, "related", " ",.)
replace title = subinstr(title, "similar products", " ",.)


	forval var=1/20{
replace title = subinstr(title, "  ", " ",.)
}
replace title = stritrim(title)
replace title = strtrim(title)
// unique  title

egen unqiue_id=group(title)
sort title
save "${country_folder}/`country'_full.dta", replace //391,668 obs

keep unqiue_id title
duplicates drop title, force
keep if !missing(title)
// unique  title
// unique unqiue_id
save "${country_folder}/`country'_cleaned_nodup.dta", replace //391,668 obs
*********************************************************************************
use "${country_folder}/`country'_cleaned_nodup.dta", clear

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
*********************************************************************************
*Merging back with full dataset
use "${country_folder}/`country'_full.dta", clear
merge m:1 unqiue_id using "${country_folder}/matches1.dta", generate(_m)
drop simil_token _m unqiue_id
// br title cpv_desc if !missing(code) & !missing(title)  
*dropping bad matches 
replace code=. if regex(title,"training transfer of technology")
replace cpv_desc="" if regex(title,"training transfer of technology")

*Check if the unmatched ones are matchable
// tab title  if missing(code) & !missing(title)  
replace title = subinstr(title, "on behalf of owner", " ",.)
replace title = subinstr(title, "nonresidential", " ",.)
replace title = subinstr(title, "residential", " ",.)
replace title = subinstr(title, "miscellaneous", " ",.)
replace title = stritrim(title)
replace title = strtrim(title)

egen unqiue_id=group(title)

save "${country_folder}/`country'_full2.dta", replace //391,668 obs
*********************************************************************************
* 2nd matching 
keep unqiue_id title code
keep if missing(code) | code==.
drop code
duplicates drop title, force
keep if !missing(title)
// unique  title
// unique unqiue_id
save "${country_folder}/`country'_cleaned_nodup_2.dta", replace

use "${country_folder}/`country'_cleaned_nodup_2.dta", clear
matchit unqiue_id title using "${utility_data}/cpv_code.dta" , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.25) over  
gsort - simil_token
format title cpv_descr %50s
// br title cpv_descr simil_token
*drop if simil_token<0.3

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count simil_token
save "${country_folder}/matches2.dta", replace
*********************************************************************************
*Merging back with full dataset ver 2

use "${country_folder}/`country'_full2.dta", clear
rename code code1 
rename cpv_descr cpv_descr1
merge m:1 unqiue_id using "${country_folder}/matches2.dta", generate(_m)
drop  _m
replace code1 = code if missing(code1) | code1==.
replace cpv_descr1 = cpv_descr if missing(cpv_descr1) | cpv_descr1==""
drop code cpv_descr
rename code1 cpv_code
rename cpv_descr1 cpv_descr
*********************************************************************************

// tab title if missing(cpv_code) & !missing(title)  
*********************************************************************************

*Manual matching
// br ca_type title cpv_code cpv_desc if regex(title,"construction") 

replace cpv_code=75000000  if regex(title,"institutional strengthening") & cpv_code==.
replace cpv_descr="Administration, defence and social security services"  if regex(title,"institutional strengthening") & cpv_code==75000000

replace cpv_code=45000000  if regex(title,"general building contractors") & cpv_code==.
replace cpv_descr="Construction work"  if regex(title,"general building contractors") & cpv_code==45000000
**********************************************************************************
// preserve
// 	keep if filter_ok50==1
// 	keep if !missing(title)
// 	count if missing(cpv_code)
// 	di `r(N)'/_N
// restore

*total 31% - disreagrding missing titles (3%)
*********************************************************************************
*Adding match words from list

replace cpv_code=797100004  if regex(title,"security") & regex(title,"services") & cpv_code==.
replace cpv_descr="Security services"  if regex(title,"security services") & cpv_code==797100004

replace cpv_code=722240001  if regex(title,"consultancy services") & cpv_code==.
replace cpv_descr="Project management consultancy services"  if regex(title,"consultancy services") & cpv_code==722240001

replace cpv_code=905132008  if regex(title,"solid") & regex(title,"waste") & cpv_code==.
replace cpv_descr="Urban solid-refuse disposal services"  if regex(title,"solid") & regex(title,"waste") & cpv_code==905132008

replace cpv_code=450000007  if regex(title,"construction") & cpv_code==.
replace cpv_descr="Construction work"  if regex(title,"construction") & cpv_code==450000007

replace cpv_code=425120008  if regex(title,"air") & regex(title,"condit") & cpv_code==.
replace cpv_descr="Air-conditioning installations"  if regex(title,"air") & regex(title,"condit") & cpv_code==425120008

replace cpv_code=330000000  if regex(title,"medical") & cpv_code==.
replace cpv_descr="Medical equipments, pharmaceuticals and personal care products"  if regex(title,"medical") & cpv_code==330000000

replace cpv_code=500000005  if regex(title,"maintenance|repair") & cpv_code==.
replace cpv_descr="Repair and maintenance services"  if regex(title,"maintenance|repair") & cpv_code==500000005

replace cpv_code=805000009  if regex(title,"training") & cpv_code==.
replace cpv_descr="Training services"  if regex(title,"training") & cpv_code==805000009

replace cpv_code=430000003  if regex(title,"equip") & regex(title,"labour") & cpv_code==.
replace cpv_descr="Machinery for mining, quarrying, construction equipment"  if regex(title,"equip") & regex(title,"labour") & cpv_code==430000003

replace cpv_code=430000003  if regex(title,"equip") & cpv_code==.
replace cpv_descr="Machinery for mining, quarrying, construction equipment"  if regex(title,"equip") & cpv_code==430000003

replace cpv_code=900000007  if regex(title,"cleaning") & cpv_code==.
replace cpv_descr="Sewage-, refuse-, cleaning-, and environmental services"  if regex(title,"cleaning") & cpv_code==900000007

replace cpv_code=720000005  if regex(title,"software") & cpv_code==.
replace cpv_descr="IT services: consulting, software development, Internet and support"  if regex(title,"software") & cpv_code==720000005

replace cpv_code=480000008  if regex(title,"software") & regex(title,"package") & cpv_code==.
replace cpv_descr="Software package and information systems"  if regex(title,"software") & regex(title,"package") & cpv_code==480000008

replace cpv_code=351217005  if regex(title,"system") & regex(title,"alarm") & cpv_code==.
replace cpv_descr="Alarm systems"  if regex(title,"system") & regex(title,"alarm") & cpv_code==351217005

replace cpv_code=351200001  if regex(title,"system") & regex(title,"security") & cpv_code==.
replace cpv_descr="Surveillance and security systems and devices"  if regex(title,"system") & regex(title,"security") & cpv_code==351200001

replace cpv_code=441631128  if regex(title,"drainage") & cpv_code==.
replace cpv_descr="Drainage system"  if regex(title,"drainage") & cpv_code==441631128

replace cpv_code=310000006  if regex(title,"electric") & cpv_code==.
replace cpv_descr="Electrical machinery, apparatus, equipment and consumables; Lighting"  if regex(title,"electric") & cpv_code==310000006

replace cpv_code=302000001  if regex(title,"computer") & cpv_code==.
replace cpv_descr="Computer equipment and supplies"  if regex(title,"computer") &cpv_code==302000001

replace cpv_code=454000001  if regex(title,"building") & cpv_code==.
replace cpv_descr="Building completion work"  if regex(title,"building") &cpv_code==454000001

replace cpv_code=792120003  if regex(title,"audit") & cpv_code==.
replace cpv_descr="Auditing services"  if regex(title,"audit") &cpv_code==792120003

replace cpv_code=452324525  if regex(title,"drain") & cpv_code==.
replace cpv_descr="Drainage works"  if regex(title,"drain") &cpv_code==452324525

replace cpv_code=336000006  if regex(title,"pharmaceutical") & cpv_code==.
replace cpv_descr="Pharmaceutical products"  if regex(title,"pharmaceutical") & cpv_code==336000006

replace cpv_code=330000000  if regex(title,"lab") & cpv_code==.
replace cpv_descr="Medical equipments, pharmaceuticals and personal care products"  if regex(title,"lab") & cpv_code==330000000

replace cpv_code=450000000  if regex(title,"water") & regex(title,"const") & cpv_code==.
replace cpv_descr="Construction work"  if regex(title,"water") & regex(title,"const") & cpv_code==450000000

replace cpv_code=798100005  if regex(title,"printing") & cpv_code==.
replace cpv_descr="Printing services"  if regex(title,"printing") & cpv_code==798100005

replace cpv_code=665122004  if regex(title,"health") & regex(title,"insurance") & cpv_code==.
replace cpv_descr="Health insurance services"  if regex(title,"health") & regex(title,"insurance") & cpv_code==665122004

replace cpv_code=336000006  if regex(title,"drugs")  & cpv_code==.
replace cpv_descr="Pharmaceutical products"  if regex(title,"drugs") & cpv_code==336000006

replace cpv_code=324000007  if regex(title,"network")  & cpv_code==.
replace cpv_descr="Networks"  if regex(title,"network") & cpv_code==324000007

replace cpv_code=421220000  if regex(title,"pump")  & cpv_code==.
replace cpv_descr="Pumps"  if regex(title,"pump") & cpv_code==421220000

replace cpv_code=555200001  if regex(title,"catering")  & cpv_code==.
replace cpv_descr="Catering services"  if regex(title,"catering") & cpv_code==555200001

replace cpv_code=391000003  if regex(title,"furniture")  & cpv_code==.
replace cpv_descr="Furniture"  if regex(title,"furniture") & cpv_code==391000003

replace cpv_code=302000001  if regex(title,"data")  & cpv_code==.
replace cpv_descr="Computer equipment and supplies"  if regex(title,"data") & cpv_code==302000001

replace cpv_code=301900007  if regex(title,"paper")  & cpv_code==.
replace cpv_descr="Various office equipment and supplies"  if regex(title,"paper") & cpv_code==301900007

replace cpv_code=905110002  if regex(title,"waste")  & cpv_code==.
replace cpv_descr="Refuse collection services"  if regex(title,"waste") & cpv_code==905110002

replace cpv_code=220000000  if regex(title,"printed")  & cpv_code==.
replace cpv_descr="Printed matter and related products"  if regex(title,"printed") & cpv_code==220000000

replace cpv_code=301000000  if regex(title,"printer")  & cpv_code==.
replace cpv_descr="Office machinery, equipment and supplies except computers, printers and furniture"  if regex(title,"printer") & cpv_code==301000000

replace cpv_code=349200002  if regex(title,"road")  & cpv_code==.
replace cpv_descr="Road equipment"  if regex(title,"road") & cpv_code==349200002

replace cpv_code=340000007  if regex(title,"transport")  & cpv_code==.
replace cpv_descr="Transport equipment and auxiliary products to transportation" if regex(title,"transport") & cpv_code==340000007

replace cpv_code=441142200  if regex(title,"pipe")  & cpv_code==.
replace cpv_descr="Concrete pipes and fittings"  if regex(title,"pipe") & cpv_code==441142200

replace cpv_code=805210002  if regex(title,"programme")  & cpv_code==.
replace cpv_descr="Training programme services"  if regex(title,"programme") & cpv_code==805210002

replace cpv_code=796200006  if regex(title,"staff")  & cpv_code==.
replace cpv_descr="Supply services of personnel including temporary staff"  if regex(title,"staff") & cpv_code==796200006

replace cpv_code=713550001  if regex(title,"survey")  & cpv_code==.
replace cpv_descr="Surveying services"  if regex(title,"survey") & cpv_code==713550001

replace cpv_code=452113105  if regex(title,"bathroom")  & cpv_code==.
replace cpv_descr="Bathrooms construction work"  if regex(title,"bathroom") & cpv_code==452113105

replace cpv_code=240000004  if regex(title,"chemical")  & cpv_code==.
replace cpv_descr="Chemical products"  if regex(title,"chemical") & cpv_code==240000004

replace cpv_code=441140002  if regex(title,"concrete")  & cpv_code==.
replace cpv_descr="Concrete"  if regex(title,"concrete") & cpv_code==441140002

replace cpv_code=909000006  if regex(title,"sanit")  & cpv_code==.
replace cpv_descr="Cleaning and sanitation services"  if regex(title,"sanit") & cpv_code==909000006

replace cpv_code=907221005  if regex(title,"rehabilitation")  & cpv_code==.
replace cpv_descr="Industrial site rehabilitation"  if regex(title,"rehabilitation") & cpv_code==907221005

replace cpv_code=703100007  if regex(title,"rental")  & cpv_code==.
replace cpv_descr="Building rental or sale services"  if regex(title,"rental") & cpv_code==703100007

replace cpv_code=331000001  if regex(title,"sundries")  & cpv_code==.
replace cpv_descr="Medical equipments"  if regex(title,"sundries") & cpv_code==331000001

replace cpv_code=331000001  if regex(title,"fencing")  & cpv_code==.
replace cpv_descr="Road-marking equipment"  if regex(title,"fencing") & cpv_code==331000001

replace cpv_code=301220000  if regex(title,"machine") & regex(title,"cop")  & cpv_code==.
replace cpv_descr="Office-type offset printing machinery"  if regex(title,"machine") & regex(title,"cop") & cpv_code==301220000

replace cpv_code=301220000  if regex(title,"machine") & regex(title,"ray")  & cpv_code==.
replace cpv_descr="Imaging equipment for medical, dental and veterinary use"  if regex(title,"machine") & regex(title,"ray") & cpv_code==301220000

replace cpv_code=500000005  if regex(title,"renovation")  & cpv_code==.
replace cpv_descr="Repair and maintenance services"  if regex(title,"renovation") & cpv_code==500000005

replace cpv_code=336900003  if regex(title,"laborary")  & cpv_code==.
replace cpv_descr="Various medicinal products"  if regex(title,"laborary") & cpv_code==336900003

replace cpv_code=660000000  if regex(title,"financial")  & cpv_code==.
replace cpv_descr="Financial and insurance services"  if regex(title,"financial") & cpv_code==660000000

replace cpv_code=797100004  if regex(title,"security")  & cpv_code==.
replace cpv_descr="Security services"  if regex(title,"security") & cpv_code==797100004

replace cpv_code=726000006  if regex(title,"support") & regex(title,"computer")  & cpv_code==.
replace cpv_descr="Computer support and consultancy services"  if regex(title,"support") & regex(title,"computer") & cpv_code==726000006

replace cpv_code=799800007  if regex(title,"subscription") & cpv_code==.
replace cpv_descr="Subscription services"  if regex(title,"subscription") & cpv_code==799800007

replace cpv_code=443164002  if regex(title,"hardware") & cpv_code==.
replace cpv_descr="Hardware"  if regex(title,"hardware") & cpv_code==443164002

replace cpv_code=30210000  if regex(title," dell ") & cpv_code==.
replace cpv_descr="Data-processing machines (hardware)"  if regex(title," dell ") & cpv_code==30210000

replace cpv_code=794000008  if regex(title,"business") & cpv_code==.
replace cpv_descr="Business and management consultancy and related services"  if regex(title,"business") & cpv_code==794000008

replace cpv_code=904000001  if regex(title,"sewage") & cpv_code==.
replace cpv_descr="Sewage services"  if regex(title,"sewage") & cpv_code==904000001

replace cpv_code=665100008  if regex(title,"insurance") & cpv_code==.
replace cpv_descr="Insurance services"  if regex(title,"insurance") & cpv_code==665100008

replace cpv_code=451110008  if regex(title,"debris") & cpv_code==.
replace cpv_descr="Demolition, site preparation and clearance work"  if regex(title,"debris") & cpv_code==451110008

replace cpv_code=150000008  if regex(title,"food") & cpv_code==.
replace cpv_descr="Food, beverages, tobacco and related products"  if regex(title,"food") & cpv_code==150000008

replace cpv_code=325000008  if regex(title,"communic") & cpv_code==.
replace cpv_descr="Telecommunications equipment and supplies"  if regex(title,"communic") & cpv_code==325000008

replace cpv_code=336000006  if regex(title,"drug") & regex(title,"order") & cpv_code==.
replace cpv_descr="Pharmaceutical products"  if regex(title,"drug") & regex(title,"order")  & cpv_code==336000006

replace cpv_code=336000006  if regex(title,"pharma") & cpv_code==.
replace cpv_descr="Pharmaceutical products"  if regex(title,"pharma") & cpv_code==336000006

replace cpv_code=553200009  if regex(title,"meal") & cpv_code==.
replace cpv_descr="Meal-serving services"  if regex(title,"meal") & cpv_code==553200009

replace cpv_code=983410005  if regex(title," accomm") & cpv_code==.
replace cpv_descr="Accommodation services"  if regex(title," accomm") & cpv_code==983410005

replace cpv_code=551200007  if regex(title,"conference") & cpv_code==.
replace cpv_descr="Hotel meeting and conference services"  if regex(title,"conference") & cpv_code==551200007

replace cpv_code=146220007  if regex(title,"steel") & cpv_code==.
replace cpv_descr="Steel"  if regex(title,"conference") & cpv_code==146220007

replace cpv_code=343500005  if regex(title,"tyres") & cpv_code==.
replace cpv_descr="Tyres for heavy/light duty vehicles"  if regex(title,"tyres") & cpv_code==343500005

replace cpv_code=452626409  if regex(title,"bushing") & cpv_code==.
replace cpv_descr="Environmental improvement works"  if regex(title,"bushing") & cpv_code==452626409

replace cpv_code=804100001  if regex(title,"school") & regex(title,"delivery") & cpv_code==.
replace cpv_descr="Various school services"  if regex(title,"school")  & regex(title,"delivery") & cpv_code==804100001

replace cpv_code=452142002  if regex(title,"school") & cpv_code==.
replace cpv_descr="Construction work for school buildings"  if regex(title,"school") & cpv_code==452142002

replace cpv_code=80000000  if regex(title,"educat") & cpv_code==.
replace cpv_descr="Education and training services"  if regex(title,"educat") & cpv_code==80000000

replace cpv_code=301927008  if regex(title,"stationery") & cpv_code==.
replace cpv_descr="Stationery"  if regex(title,"stationery") & cpv_code==301927008

replace cpv_code=349282000  if regex(title,"fence") & cpv_code==.
replace cpv_descr="Fences"  if regex(title,"fence") & cpv_code==349282000

replace cpv_code=454300000  if regex(title,"floor") & cpv_code==.
replace cpv_descr="Floor and wall covering work"  if regex(title,"floor") & cpv_code==454300000

replace cpv_code=452130003  if regex(title,"warehouse") & cpv_code==.
replace cpv_descr="Construction work for commercial buildings, warehouses and industrial buildings, buildings relating to transport"  if regex(title,"warehouse") & cpv_code==452130003

replace cpv_code=09100000  if regex(title,"fuel") & cpv_code==.
replace cpv_descr="Fuels"  if regex(title,"fuel") & cpv_code==09100000

replace cpv_code=09134100  if regex(title,"diesel") & cpv_code==.
replace cpv_descr="Diesel oil"  if regex(title,"diesel") & cpv_code==09134100

replace cpv_code=249511006  if regex(title,"lubric") & cpv_code==.
replace cpv_descr="Lubricants"  if regex(title,"lubric") & cpv_code==249511006

replace cpv_code=442212007  if regex(title,"doors") & cpv_code==.
replace cpv_descr="Doors"  if regex(title,"doors") & cpv_code==442212007

replace cpv_code=453143107  if regex(title,"cabling") & cpv_code==.
replace cpv_descr="Installation of cable laying"  if regex(title,"cabling") & cpv_code==453143107

replace cpv_code=452332221  if regex(title,"asphalt") & cpv_code==.
replace cpv_descr="Paving and asphalting works"  if regex(title,"asphalt") & cpv_code==452332221

replace cpv_code=331400003  if regex(title,"strip |blood ") & cpv_code==.
replace cpv_descr="Medical consumables"  if regex(title,"strip |blood ") & cpv_code==331400003

replace cpv_code=791000005  if regex(title,"legal") & cpv_code==.
replace cpv_descr="Legal services"  if regex(title,"legal") & cpv_code==791000005

replace cpv_code=793420003  if regex(title,"marketing") & cpv_code==.
replace cpv_descr="Marketing services"  if regex(title,"marketing") & cpv_code==793420003

replace cpv_code=341000008  if regex(title,"vehicle") & cpv_code==.
replace cpv_descr="Motor vehicles"  if regex(title,"vehicle") & cpv_code==341000008

replace cpv_code=331100004  if regex(title,"x-ray|xray") & cpv_code==.
replace cpv_descr="Imaging equipment for medical, dental and veterinary use"  if regex(title,"x-ray|xray") & cpv_code==331100004

replace cpv_code=323220006  if regex(title,"multimedia") & cpv_code==.
replace cpv_descr="Multimedia equipment"  if regex(title,"multimedia") & cpv_code==323220006

replace cpv_code=302000001  if regex(title,"media") & cpv_code==.
replace cpv_descr="Computer equipment and supplies"  if regex(title,"media") & cpv_code==302000001

replace cpv_code=331510003  if regex(title,"oxygen") & cpv_code==.
replace cpv_descr="Radiotherapy devices and supplies"  if regex(title,"oxygen") & cpv_code==331510003

replace cpv_code=341444318  if regex(title,"suction") & cpv_code==.
replace cpv_descr="Suction-sweeper vehicles"  if regex(title,"suction") & cpv_code==341444318

************************************
*Make sure the matched cpv entries include 03 and 09 - fixing a cpv matching error

// br title sector cpv_code cpv_descr 
drop cpv_descr
tostring cpv_code, gen(cpv_code2)
drop cpv_code
rename cpv_code2 cpv_code

replace cpv_code="" if cpv_code=="."
cap drop len
gen len = length(cpv_code)
// tab len, m
sort cpv_code
// br cpv_code if length(cpv_code)==8 //replace these with o in the begninning
gen cpv2=substr(cpv_code,1,2)
// tab cpv2 if len==8
// br cpv_code title if len==8  & cpv2=="92"

*Fixes
replace cpv_code="0" + cpv_code if len==8 & inlist(cpv2,"31","32","33","34","91","92")
replace cpv_code="14820000" if title=="flat glass"
replace cpv_code="16000000" if title=="farm machinery equipment"
replace cpv_code="45000000" if title=="heavy construction building" | title=="heavy construction" | title=="single family housing construction"

drop len cpv2
drop unqiue_id

********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*Clean up
cap erase "${country_folder}//`country'_full.dta"
cap erase "${country_folder}//`country'_full2.dta"
cap erase "${country_folder}//matches1.dta"
cap erase "${country_folder}//matches2.dta"
cap erase "${country_folder}//`country'_cleaned_nodup.dta"
cap erase "${country_folder}//`country'_cleaned_nodup_2.dta"
********************************************************************************
*END
