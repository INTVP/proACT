local country "`0'"
********************************************************************************
/*This script - adds historical singlebidding data to the current dataset*/
********************************************************************************

*Data 
import delimited using https://s3.eu-central-1.amazonaws.com/digiwhist-data/CSV/AT_data.csv, encoding(UTF-8) clear
use "${country_folder}/`country'_wip.dta", clear

********************************************************************************

cap drop _m
merge m:1 pr_id tenderid using "${utility_data}/country/`country'/wbdata_to_website_170522_historical_singlebidding.dta"
drop if _m==2
cap drop _m
// br pr_id tenderid ca_id ca_nrbidsrec ca_nrbidscons ca_bids singleb if _m==3

********************************************************************************
save "${country_folder}//`country'_wip.dta", replace
********************************************************************************
*END
