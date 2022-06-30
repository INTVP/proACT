local country "`0'"
********************************************************************************
/*This script organizes the risk indicators and calculates the cri.*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*most indicators already calculated in this version of the dataset

*Buyer concentraction
gen proa_ycsh4=anb_ycsh if filter_ok==1 & anb_ynrc>4 & anb_ycsh!=.
// br w_ycsh4
********************************************************************************
*Procedure Type

// tab corr_proc ca_procedure , m
********************************************************************************
*Tax haven

// tab taxhav //this one
// tab taxhav_fixed
// tab taxhav3 //no
// tab taxhav3bi //no

gen taxhav_x =.
replace taxhav_x = 0 if taxhav=="NO tax haven"
replace taxhav_x = 1 if taxhav=="domestic supplier"
replace taxhav_x = 9 if taxhav=="tax haven"
// tab taxhav taxhav_x, m
********************************************************************************
*Overrun

// sort pr_id ca_id
// br pr_id ca_id pr_finalcosts pr_donorfinancing pr_borrower_fin pr_disbursed pr_repayments ca_contract_value_original if !missing(pr_finalcosts)
*final costs are available only on the project level
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
*Not valid for the IDB data
*do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year bidder_masterid "`country'"
gen bidder_mkt_entry= .

*Generate market share {bid_price ppp version}
*Not valid for the IDB data
*do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 
gen bidder_mkt_share= .

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
*Not valid for the IDB data
*do "${utility_codes}/gen_is_capital.do" "`country'" cft_fip_city_clean 
gen is_capital= .

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
*Not valid for the IDB data
*do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
gen bidder_non_local=.
********************************************************************************
*Benford's Law 

// br anb_id anb_name ca_contract_value_original if !missing(anb_id)
save "${country_folder}/`country'_wip.dta", replace

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
	export delimited  "${country_folder}/buyers_for_R.csv", replace
	! "${R_path_local}" "${utility_codes}/benford.R" "${country_folder}"
restore

use "${country_folder}/`country'_wip.dta",  clear
gen buyer_id=anb_id
merge m:1 buyer_id using "${country_folder}/buyers_benford.dta"
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
*CRI calculation

*Indicators available: corr_proc, taxhav_x, anb_ycsh, sanct, corr_ben
*Not available indicators: singleb, decision period, submission period{only pr level}, nocft

// sum  corr_proc taxhav_x  proa_ycsh corr_ben if filter_ok==1
// tab corr_proc, m 
// tab taxhav_x, m 
// tab corr_ben, m  //rescale 
// sum proa_ycsh

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben


do $utility_codes/cri.do corr_proc taxhav_x proa_ycsh4 corr_ben_bi
rename cri cri_idb


// sum cri_idb if filter_ok==1
// hist cri_idb if filter_ok==1, title("CRI IDB, filter_ok")
// hist cri_idb if filter_ok==1, by(year, noiy title("CRI IDB (by year), filter_ok")) 
********************************************************************************
save "${country_folder}/`country'_wb_1020.dta", replace
********************************************************************************
*END