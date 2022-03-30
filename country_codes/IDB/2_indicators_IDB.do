*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script organizes the risk indicators and calculates the cri.*/
********************************************************************************

*Data
use $country_folder/IDB_wip.dta, clear
********************************************************************************
*most indicators already calculated in this version of the dataset

*Buyer concentraction
gen proa_ycsh4=anb_ycsh if filter_ok==1 & anb_ynrc>4 & anb_ycsh!=.
br w_ycsh4
********************************************************************************

*Procedure Type
tab corr_proc ca_procedure , m
********************************************************************************
*Tax haven
tab taxhav //this one
tab taxhav_fixed
tab taxhav3 //no
tab taxhav3bi //no

label list taxhav
gen taxhav_x =.
replace taxhav_x = 0 if taxhav==1
replace taxhav_x = 1 if taxhav==2
replace taxhav_x = 9 if taxhav==3
tab taxhav taxhav_x, m
********************************************************************************
*Overrun
sort pr_id ca_id
br pr_id ca_id pr_finalcosts pr_donorfinancing pr_borrower_fin pr_disbursed pr_repayments ca_contract_value_original if !missing(pr_finalcosts)
*final costs are available only on the project level
********************************************************************************

*Benford's Law 
br anb_id anb_name ca_contract_value_original if !missing(anb_id)
save $country_folder/IDB_wip.dta, replace

preserve
    keep ca_contract_value_original anb_id filter_ok
	rename anb_id buyer_id //buyer id variable
    rename ca_contract_value_original ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_id: gen count = _N
    keep if count >100
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
    export delimited  $country_folder/buyers_for_R.csv, replace
    * set directory 
    ! cd $country_folder
	//Make sure to change path to the local path of Rscript.exe
    ! "C:/Program Files/R/R-3.6.0/bin/x64/Rscript.exe" $utility_codes/benford.R
restore

use $country_folder/IDB_wip.dta, clear
gen buyer_id=anb_id
merge m:1 buyer_id using $country_folder/buyers_benford.dta
drop if _m==2
replace MAD_conformitiy="" if buyer_id==.
replace MAD=. if buyer_id==.
drop _m buyer_id

*Theoretical mad values and conformity
/*Close conformity — 0.000 to 0.004
Acceptable conformity — 0.004 to 0.008
Marginally acceptable conformity — 0.008 to 0.012
Nonconformity — greater than 0.012
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
tab corr_ben, m
****************************************************************************
save $country_folder/IDB_wip, replace
****************************************************************************
*CRI calculation

*Indicators available: corr_proc, taxhav_x, anb_ycsh, sanct, corr_ben
*Not available indicators: singleb, decision period, submission period{only pr level}, nocft

sum  corr_proc taxhav_x  proa_ycsh corr_ben if filter_ok==1
tab corr_proc, m 
tab taxhav_x, m 
tab corr_ben, m  //rescale 
sum proa_ycsh

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben


do $utility_codes/cri.do corr_proc taxhav_x proa_ycsh4 corr_ben_bi
rename cri cri_idb


sum cri_idb if filter_ok==1
hist cri_idb if filter_ok==1, title("CRI IDB, filter_ok")
hist cri_idb if filter_ok==1, by(year, noiy title("CRI IDB (by year), filter_ok")) 
********************************************************************************

save $country_folder/IDB_wb_1020.dta, replace
********************************************************************************
*END


