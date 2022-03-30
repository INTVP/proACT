
*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data
use $country_folder/KE_wip.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
/*
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
replace

merge m:1 buyer_masterid using $country_folder/buyers_benford.dta"
drop _m

br buyer_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — na
Acceptable conformity — 0.0073424 to 0.0073424
Marginally acceptable conformity — 0.0121942 to 0.0147684
Nonconformity — greater than 0.0177069
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)

gen corr_ben2=0 if corr_ben==2 | corr_ben==0
replace corr_ben2=1 if corr_ben==1
replace corr_ben2=99 if corr_ben==. | corr_ben==99

********************************************************************************

*Single Bidding
gen singleb=0 
replace singleb=1 if tender_indicator_integrity_singl==0
replace singleb=. if tender_indicator_integrity_singl==.
********************************************************************************

*Tender Description Length
gen corr_descl=0 if tender_description_length>0
replace corr_descl=1 if tender_description_length==0
********************************************************************************

*Sign Period
gen signp=ca_sign_date - aw_dec_date

gen corr_signp=1
replace corr_signp=0 if signp>=5 & signp<=47
replace corr_signp=99 if signp==.
********************************************************************************

*Decision Period
gen corr_decp=2 if tender_indicator_integrity_decis==0
replace corr_decp=1 if tender_indicator_integrity_decis==50
replace corr_decp=0 if tender_indicator_integrity_decis==100
********************************************************************************

*Submission Period
gen submp =cft_deadline-cft_date_first
replace submp=. if submp<=0
label var submp "advertisement period"
replace submp=. if submp>183
sum submp

gen corr_submp=1 if tender_indicator_integrity_adver==0
replace corr_submp=0 if tender_indicator_integrity_adver==100
replace corr_submp=99 if tender_indicator_integrity_adver==.
********************************************************************************

*Procedure Type
gen corr_proc=1 if tender_indicator_integrity_proce==0
replace corr_proc=0 if tender_indicator_integrity_proce==100
replace corr_proc=99 if tender_indicator_integrity_proce==.
********************************************************************************

*No cft                                                                   
gen nocft=1 if submp==.
replace nocft=0 if submp!=.
tab nocft
********************************************************************************
*/

*Final Best Regression
logit singleb i.corr_ben i.corr_descl i.corr_signp i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.ca_type i.anb_loc i.marketid if filter_ok==1, base
********************************************************************************

save $country_folder/wb_ke_cri201113.dta, replace
********************************************************************************
*END