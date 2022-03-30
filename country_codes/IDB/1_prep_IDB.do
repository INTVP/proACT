*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares data for Risk indicator calculation
1) Creates main filter to be used throught analysis
3) Structures/prepares other control variables 
*/
********************************************************************************

*Data 
use $country_folder/IDB_wip.dta, clear
********************************************************************************

*Sector Harmonization

*Sectors
count if missing(pr_majorsectors)
count if missing(ca_majorsectors)
tab pr_majorsectors, m
tab ca_majorsectors, m
tabmiss pr_majorsectors ca_majorsectors
tab ca_majorsectors pr_majorsectors

gen sector = pr_majorsectors 
replace sector = ca_majorsectors if sector==""
local temp ""AG-" "AG$" "^AS-" "^AS$" "^DU" "^ED" "^ED$" "^EN-" "EN$" "^FM" "^IN$" "^IS" "^PA" "^PS" "^RM" "^SA" "^ST" "^TR-" "^TR$" "^TU" "^OT$""
local temp2 ""AGRICULTURE AND RURAL DEVELOPMENT" "AGRICULTURE AND RURAL DEVELOPMENT" "WATER SUPPLY AND SANITATION" "WATER SUPPLY AND SANITATION" "URBAN DEVELOPMENT AND HOUSING" "EDUCATION" "EDUCATION" "ENERGY" "ENERGY" "FINANCIAL MARKETS" "INDUSTRY" "SOCIAL INVESTMENT" "ENVIRONMENT AND NATURAL DISASTERS" "PRIVATE FIRMS AND SME DEVELOPMENT" "REFORM / MODERNIZATION OF THE STATE" "HEALTH" "SCIENCE AND TECHNOLOGY" "TRANSPORTATION" "TRANSPORTATION" "SUSTAINABLE TOURISM" "OTHER""
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace sector = "`: word `s' of `temp2''"  if regexm(sector,"`: word `s' of `temp''")==1
	}
	
tab sector, m
*Harmonization
replace sector="WATER SUPPLY AND SANITATION" if sector=="WATER AND SANITATION"
replace sector="URBAN DEVELOPMENT AND HOUSING" if sector=="URBAN DEVELOPMENT"
replace sector="TRANSPORTATION" if sector=="TRANSPORT"
replace sector="MISCELLANEOUS" if inlist(sector,"RI-RCC","TD","TD-EIP","TD-TAA","TD-TFL","OTHER")
replace sector="ENVIRONMENT AND NATURAL DISASTERS" if sector=="ENVIRONMENT"
replace sector = proper(sector)
tab sector, m
************************************

*Info about dataset from previous work
*contract level data w/ project level data 
*1 row 1 contract
sort pr_id pr_operations ca_id operation 
br pr_id pr_operations ca_id operation 
sort ca_id
br ca_id w_name anb_name pr_*

count if missing(pr_id)
count if missing(ca_id)
unique ca_id // Nr of contracts
br pr_id ca_id if missing(pr_id)
unique pr_id ca_id //360,349

*Orgnaization names: anb_name, w_name
*Location: anb_country pr_country
*prices: ca_contract_value_original
*Types: ca_supplytype, ca_type
*Dates: ca_signdate
************************************

*Add uncategorized codes for the missing entries
count if missing(cpv_code)
desc *supply* 
tab ca_supplytype if missing(cpv_code), m
*1 CONSULTING SERVICES
*2 GOODS & WORKS
gen supply_type=""
replace supply_type="Services" if regex(title,"services") | ca_supplytype==1

replace supply_type="Works" if regex(title,"work|publishing|repairing|construction|forging|drawing|water sewer|sewerage|drilling|building contractors|welding repair|highway|freight transportation|reporting|water supply|printing|protection|forestry|logging|advertising|administration of human resources|typesetting|photography|bookbinding|transportation|environmental quality|landscape counseling planning|mining|production|wildlife conservation|manpower programs|inspection|brokers service|travel agencies|data processing preparation|bookkeeping|admin of general economic programs|management public relations|commercial art graphic design") & missing(supply_type)

replace supply_type="Goods" if regex(title,"goods|products|machinery|equipment|tool|supplies|furniture|appliances|office machines|environmental quality housing|components") & missing(supply_type)
replace supply_type="Goods" if missing(supply_type) & !missing(title)

tab supply_type ca_supplytype, m

replace cpv_code = "983900003" if missing(cpv_code) & supply_type=="Services"
replace cpv_code = "99300000" if missing(cpv_code) & supply_type=="Works"
replace cpv_code = "99100000" if missing(cpv_code) & supply_type=="Goods"
replace cpv_code = "99000000" if missing(cpv_code) & supply_type==""
gen cpv2=substr(cpv_code,1,2)
tab cpv2, m
drop cpv2
rename supply_type ca_supplytype_mod
label var ca_supplytype_mod "A manually modified supply type based on ca_supplytype"
************************************

*Generate filter_ok
tab year, m
tab year if !missing(w_name), m
gen filter_ok=0
replace filter_ok=1 if !missing(w_name) //Main filter
tab year if filter_ok, m
************************************

*year variable 
tab year if filter_ok, m
************************************

*Prices
br  *value* 

lab var ca_contract_value "Contract value - PPP adjusted"
lab var ca_contract_value_original "Original contract value reported"
br ca_contract_value_original ca_contract_value *country* 

*Prices are already adjusted 
*ca_contract_value is the final adjusted contract values
xtile ca_contract_value10 = ca_contract_value if filter_ok, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)
************************************

*supply type
br *type*
ca_type
tab ca_supplytype if filter_ok==1, m
tab ca_type if filter_ok==1, m //many categories
********************************************************************************

save $country_folder/IDB_wip.dta , replace
********************************************************************************
*END