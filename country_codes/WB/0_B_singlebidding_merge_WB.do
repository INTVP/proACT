*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script - adds historical singlebidding data to the current dataset
*/
********************************************************************************

*Data 
import delimited using https://s3.eu-central-1.amazonaws.com/digiwhist-data/CSV/AT_data.csv, encoding(UTF-8) clear
********************************************************************************

use $country_folder/WB_wip.dta, clear
merge m:1 pr_id tenderid using $utility_data/country/WB/wbdata_to_website_170522_historical_singlebidding.dta
drop if _m==2
br pr_id tenderid ca_id ca_nrbidsrec ca_nrbidscons ca_bids singleb if _m==3

********************************************************************************
save $country_folder/WB_wip.dta, replace
********************************************************************************
*END
