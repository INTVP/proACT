*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds. (limited)*/
********************************************************************************

*Data
use $country_folder/JM_wip.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. 
********************************************************************************

*Benford's law export
preserve
    *rename xxxx buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_masterid: gen count = _N
    keep if count >100
    keep buyer_masterid ca_contract_value
	order buyer_masterid ca_contract_value
    export delimited  $country_folder/buyers_for_R.csv, replace
    * set directory 
    ! cd $country_folder
	//Make sure to change path to the local path of Rscript.exe
    ! "C:/Program Files/R/R-3.6.0/bin/x64/Rscript.exe" $utility_codes/benford.R
restore
	
	
merge m:1 buyer_masterid using $country_folder/buyers_benford.dta
drop _m

br buyer_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — na
Acceptable conformity — 0.0092339 to 0.0092339
Marginally acceptable conformity — 0.0128744 to 0.0146329
Nonconformity — greater than 0.0151865
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
********************************************************************************

*Single Bidding

gen singleb=0 
replace singleb=1 if tender_indicator_integrity_singl==0
replace singleb=. if tender_indicator_integrity_singl==.
********************************************************************************

*No cft

gen nocft=0 if tender_indicator_integrity_call_==100
********************************************************************************

*Decision Period

gen corr_decp=1 if tender_indicator_integrity_decis==0
replace corr_decp=0 if tender_indicator_integrity_decis==100
********************************************************************************

*Submission Period

gen corr_submp=1 if tender_indicator_integrity_adver==0
replace corr_submp=0 if tender_indicator_integrity_adver==100
replace corr_submp=99 if tender_indicator_integrity_adver==.
********************************************************************************

*Procedure Type

gen corr_proc=1 if tender_indicator_integrity_proce==0
replace corr_proc=0 if tender_indicator_integrity_proce==100
replace corr_proc=99 if tender_indicator_integrity_proce==.
********************************************************************************

save $country_folder/wb_jm_cri201114.dta , replace
********************************************************************************
*END