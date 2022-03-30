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
use $utility_data/country/WB/starting_data/WB_data_parsed_191025_publication.dta, clear
********************************************************************************

*Matching
br *title* if !missing(ca_title) & !missing(cft_title)
gen title = ca_title 
replace title = cft_title if missing(title)
count if missing(title) //155,804
*tab sector if missing(title), m

*Cleaning the title variable 

*keep if !missing(title)
replace title=lower(title)
*charlist title

*Replace Actute character //  Á É Í Ó Ú á é í ó ú Ý ý
local temp "Á É Í Ó Ú á é í ó ú Ý ý ń"
local temp2 "a e i o u a e i o u y y n"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Grave character // À È Ì Ò Ù à è ì ò ù
local temp "À È Ì Ò Ù à è ì ò ù ș"
local temp2 "a e i o u a e i o u s"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Circumflex character // Â Ê Î Ô Û â ê î ô û Č
local temp "Â Ê Î Ô Û â ê î ô û Č č ě ř Ě ž ň Ř"
local temp2 "a e i o u a e i o u c c e r e z n r"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Tilde character // Ã Ñ Õ ã ñ õ 
local temp "Ã Ñ Õ ã ñ õ"
local temp2 "a n o a n o"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Umlaut character // Ä Ë Ï Ö Ü Ÿ ä ë ï ö ü ÿ
local temp "Ä Ë Ï Ö Ü Ÿ ä ë ï ö ü ÿ"
local temp2 "a e i o u y a e i o u y"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace other special character // Ç ç Œ œ Ø ø Å å Æ æ Š š Ž ž
local temp "Ç ç Œ œ Ø ø Å å Æ æ Š š Ž ž Ł ł Ż ń ď ů ș ț" 
local temp2 "c c oe oe o o a a ae ae s s z z l l z n d u s t"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

local temp "№ « » ‹ › Þ þ ð º ° ª ¡ ¿ ¢ £ € ¥ ƒ ¤ © ® ™ • § † ‡ ¶ & “ ” ¦ ¨ ¬ ¯ ± ² ³ ´ µ · ¸ ¹ º ¼ ½ ¾"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace title = subinstr(title, "`: word `s' of `temp''", "",.)
	}
local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace title = subinstr(title, "`v'", "",.)
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

charlist title 
ereplace title = sieve(title), omit(0123456789)

local temp "january february march april may june july august september october november december jan feb apr jun jul sept aug oct nov dec"
local n_temp : word count `temp'
replace title = " " + title + " "
forval s =1/`n_temp'{
 replace title = subinstr(title, " `: word `s' of `temp'' ", " ",.)
	}
	
replace title="" if title=="small contracts award dircqsindvsss"	

local temp "motor general method installation supply pairs pcs pieces piece ltrs liters year yearly biannual annual assorted framework agreement division amendment contract acquisition small compact review purchase provision procurement delivery various phase notice other using item signed with items lote lots lot and the kgs bid spi from for mt m at kg km no on of to a"
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
br title if !missing(title)
unique  title

egen unqiue_id=group(title) //97,303
sort title

********************************************************************************
save $country_folder/WB_full.dta, replace
********************************************************************************
keep unqiue_id title
duplicates drop title, force
keep if !missing(title)
unique  title
unique unqiue_id
save $country_folder/WB_cleaned_nodup.dta, replace
********************************************************************************

use $country_folder/WB_cleaned_nodup.dta, replace

matchit unqiue_id title using $utility_data/cpv_code.dta , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
br title cpv_descr simil_token

gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
drop count
save $coutnry_folder/matches1.dta, replace
********************************************************************************

*Merging back with full dataset
use $country_folder/WB_full.dta, replace
merge m:1 unqiue_id using $country_folder/matches1.dta, generate(_m)
*drop unqiue_id
drop simil_token _m
format title cpv_desc %40s
br title cpv_desc if !missing(code) & !missing(title)  

*dropping bad matches 
replace code=. if title=="rehabilitation roads foot paths stormwater drain system central park lake tsivi in tskaltubo town"
replace cpv_desc="" if title=="rehabilitation roads foot paths stormwater drain system central park lake tsivi in tskaltubo town"

replace code=793414000 if title=="public awareness"
replace cpv_desc="advertising campaign services" if title=="public awareness"

replace code=. if code==34220004
replace cpv_desc="" if cpv_desc=="lac"
********************************************************************************

*More cleaning for better matching
br title  if missing(code) & !missing(title)  

local temp "upgrading assistance complete completion complex component compra de gprocurement head hgjbi hgjbc revised hh yr"
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
br title if !missing(title)
unique  title
drop unqiue_id
egen unqiue_id=group(title)
sort title
cd "C:\Our folders\Aly\WB portals\data fixes\WB"
save $country_folder/WB_full.dta, replace
********************************************************************************
* 2nd matching 
keep unqiue_id title code
drop if !missing(code)
drop code
duplicates drop title, force
keep if !missing(title)
unique  title
unique unqiue_id
save $country_folder/WB_cleaned_nodup_2.dta, replace
********************************************************************************

use $country_folder/WB_cleaned_nodup_2.dta, clear
matchit unqiue_id title using $utility_data/cpv_code.dta , idusing(code) txtusing(cpv_descr) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.2) over  
gsort - simil_token
format title cpv_descr %50s
br title cpv_descr simil_token
gsort unqiue_id -simil_token
bys unqiue_id: gen count=_n
keep if count==1
gsort -simil_token
br
drop count
save $country_folder/matches2.dta, replace
********************************************************************************

*Merging back with full dataset ver 2
use $country_folder/WB_full.dta, replace
rename code code1 
rename cpv_descr cpv_descr1
merge m:1 unqiue_id using $country_folder/matches2.dta, generate(_m)
drop simil_token _m

replace code1 = code if missing(code1) | code1==.
replace cpv_descr1 = cpv_descr if missing(cpv_descr1) | cpv_descr1==""
drop code cpv_descr

rename code1 cpv_code
rename cpv_descr1 cpv_descr
********************************************************************************
*Removing matches if nr of words is more than 99th percentile
gen nrwords =  wordcount(title)
sum nrwords, d
format title %20s
*br title cpv_desc nrwords if nrwords>`r(p99)' & !missing(cpv_desc)
replace cpv_code =. if nrwords>=`r(p99)'
replace cpv_descr ="" if nrwords>=`r(p99)'
drop nrwords
********************************************************************************

*Manual matching
replace cpv_code=793410006  if regex(title,"advert") & cpv_code==.
replace cpv_descr="advertising services"  if regex(title,"advert") & cpv_code==793410006

replace cpv_code=551100004  if regex(title,"accommodation|accomodation") & cpv_code==.
replace cpv_descr="hotel accommodation services"  if regex(title,"accommodation|accomodation") & cpv_code==551100004

replace cpv_code=224590002  if regex(title,"airticket|airtime") & cpv_code==.
replace cpv_descr="tickets"  if regex(title,"airticket|airtime") & cpv_code==224590002

*replace code=351134003  if regex(title,"protective wear") & code==.
*replace cpv_descr="protective and safety clothing"  if regex(title,"protective wear") & code==351134003

replace cpv_code=322500000  if regex(title,"smartphone") & cpv_code==.
replace cpv_descr="mobile telephones"  if regex(title,"smartphone") & cpv_code==322500000

replace cpv_code=301251208  if regex(title,"tonner") & cpv_code==.
replace cpv_descr="toner for photocopiers"  if regex(title,"tonner") & cpv_code==301251208

replace cpv_code=324131002  if regex(title,"router") & cpv_code==.
replace cpv_descr="network routers"  if regex(title,"router") & cpv_code==324131002

*For switching motor vehicles" that should be service
replace cpv_code=501000006  if regex(title,"vehicle") & regex(title,"service") & cpv_code==.
replace cpv_descr="repair maintenance and associated services of vehicles and related equipment"  if regex(title,"vehicle") & regex(title,"service")  & cpv_code==501000006

replace cpv_code=75000000  if regex(title,"institutional strengthening") & cpv_code==.
replace cpv_descr="Administration, defence and social security services"  if regex(title,"institutional strengthening") & cpv_code==75000000

replace cpv_code=45000000  if regex(title,"general building contractors") & cpv_code==.
replace cpv_descr="Construction work"  if regex(title,"general building contractors") & cpv_code==45000000

replace cpv_code=33600000  if regex(title,"pharmaceuticals") & cpv_code==.
replace cpv_descr="Pharmaceutical products"  if regex(title,"pharmaceuticals") & cpv_code==33600000

********************************************************************************
preserve
	keep if !missing(ca_source)
	*keep if !missing(title)
	count if missing(cpv_code)
	di `r(N)'/_N
restore
drop  unqiue_id sector
********************************************************************************

*Adding match words from a 2nd list

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

/*replace cpv_code=91340007  if regex(title,"gas")  & cpv_code==.
replace cpv_descr=""  if regex(title,"gas") & cpv_code==91340007*/

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

********************************************************************************
*Make sure the matched cpv entries include 03 and 09
tostring cpv_code, gen(cpv_code2)
drop cpv_code
rename cpv_code2 cpv_code
format cpv_code cpv_descr %20s
br cpv_code cpv_descr
replace cpv_code="" if cpv_code=="."
cap drop len
gen len = length(cpv_code)
tab len, m
sort cpv_code
br cpv_code if len==7 //replace these with o in the begninning
replace cpv_code="0" + cpv_code if len==7
gen cpv2=substr(cpv_code,1,2)
tab cpv2 if len==8, m
replace cpv_code="0" + cpv_code if len==8 & inlist(cpv2,"31","32","34","91","92","93")
drop cpv2 len
gen cpv2=substr(cpv_code,1,2)
tab cpv2, m
drop cpv2
********************************************************************************

save $country_folder//WB_wip.dta, replace
********************************************************************************
*END
