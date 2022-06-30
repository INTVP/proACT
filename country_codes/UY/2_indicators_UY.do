local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Some variables are coming from an older version of the dataset that already had some indicators calculated dfid2_cri_uy_200212.do
********************************************************************************
*Controls only

// sum singleb anb_type ca_type_r year market_id ca_contract_value10  if filter_wb
 
// logit singleb i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
//R2: 13.57% - 610,700 obs
********************************************************************************
*Procedure type

// sum ca_procedure ca_procedure_det if filter_ok==1
*inconsistency between ca_procedure (categorized var in source files -ACCE) and national ca_procedure_det, use ca_procedure_det


*simplify national procedure types
// gen ca_proc_simp=.
// replace ca_proc_simp=1 if ca_procedure_det==1 | ca_procedure_det==9 | ca_procedure_det==15
// replace ca_proc_simp=2 if ca_procedure_det==2 | ca_procedure_det==8 | ca_procedure_det==13 | ca_procedure_det==18 | ca_procedure_det==4
// replace ca_proc_simp=3 if ca_procedure_det==6 | ca_procedure_det==5 | ca_procedure_det==7 | ca_procedure_det==10 | ca_procedure_det==11 | ca_procedure_det==16 | ca_procedure_det==17 | ca_procedure_det==12 | ca_procedure_det==19
// replace ca_proc_simp=4 if ca_procedure_det==14 | ca_procedure_det==3

label define ca_proc_simp 1"direct contracting" 2"limited" 3"open auction" 4"other" 99"missing", replace
lab values ca_proc_simp ca_proc_simp


// tab ca_proc_simp if filter_wb, m

// logit singleb ib3.ca_proc_simp i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base

cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if ca_proc_simp==3 | ca_proc_simp==4
replace corr_proc=1 if ca_proc_simp==2
replace corr_proc=2 if ca_proc_simp==1
replace corr_proc=99 if ca_proc_simp==99

// logit singleb i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*ok

gen tender_proceduretype = "OPEN" if ca_proc_simp==3
replace tender_proceduretype = "RESTRICTED" if ca_proc_simp==2
replace tender_proceduretype = "OUTRIGHT_AWARD" if ca_proc_simp==1
replace tender_proceduretype = "OTHER" if ca_proc_simp==4
*Use tender_proceduretype for output
********************************************************************************
*No cft

*nocft calc from submission period
// logit singleb i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*Works
********************************************************************************
*Submission period 

// hist submp if filter_wb

// xtile submp25=submp if filter_ok==1, nquantiles(25)
// replace submp25=99 if submp==.
cap drop corr_submp
gen corr_submp=.
replace corr_submp=0 if submp25>=19
replace corr_submp=1 if submp25>=12 & submp25<=18 & submp25!=. | submp25>=23 & submp25<=24 & submp25!=.
replace corr_submp=2 if submp25<=11 & submp25!=.
replace corr_submp=99 if submp25==99
// tab submp25 corr_submp, missing
// tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)


// logit singleb i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*great
// tabstat submp, by(submp25) stat(min mean max)
// tab submp25 corr_submp if filter_wb, m
********************************************************************************
*Decision period 

// hist decp if filter_wb
cap drop corr_decp
gen corr_decp=.
replace corr_decp=0 if decp25>=17 & decp25<=20 & decp25!=. 
replace corr_decp=2 if decp25>=1 & decp25<=9  
replace corr_decp=1 if decp25>=10 & decp25<=16 & decp25!=. | decp25>=21 & decp25!=.
replace corr_decp=99 if decp==.
// tab decp25 corr_decp, missing

// logit singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
// tabstat decp, by(decp25) stat(min mean max)
// tab decp25 corr_decp if filter_wb, m
********************************************************************************
*Tax haven

// br iso w_country 
// tab w_country if filter_wb, m
*No tax haven cases within filter_wb - skipped
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

*checking contract share
// reg w_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & w_ynrc>2 & w_ynrc!=., base
// *nocft, 1/2 corr proc
// reg w_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & w_ynrc>4 & w_ynrc!=., base
// *nocft, 1/2 corr proc
// reg w_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & w_ynrc>9 & w_ynrc!=., base
// *nocft, 1/2 corr proc
gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// sum w_ycsh4 w_ycsh
********************************************************************************
*Buyer dependence on supplier

*validation 
// reg proa_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & proa_ynrc>2 & proa_ynrc!=., base
// *nocft, 1/2 corr sub
// reg proa_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & proa_ynrc>4 & proa_ynrc!=., base
// *nocft, 1/2 corr sub
// reg proa_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & proa_ynrc>9 & proa_ynrc!=., base
// *nocft, 1/2 corr sub
gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
tostring w_id_gen, replace
rename w_id_gen bidder_masterid
do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs year bidder_masterid "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" ca_contract_value_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
*do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city buyer_nuts  tender_addressofimplementation_n

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
*do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
*No location data
gen is_capital = .
gen bidder_non_local = .
********************************************************************************
*Benford's - Not valid
/*
count if missing(anb_id)
count if missing(procEnt_id)
count if missing(anb_bcu_id)
sort anb_id
br anb_id procEnt_id anb_bcu_id anb_name
*anb_id is the most complete
br anb_id ca_contract_value
decode anb_id,gen(anb_id_str)
drop anb_id
replace anb_id_str="" if anb_id_str=="."
rename anb_id_str anb_id
drop count

********************************************************************************
save $country_folder/UY_wip.dta, replace
********************************************************************************
preserve
    rename anb_id buyer_id //buyer id variable
    *rename bid_price ca_contract_value //bid price variable
    keep if filter_wb==1 
    keep if !missing(ca_contract_value)
	keep if !missing(buyer_id)
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
************************************************
use $country_folder/buyers_benford
decode buyer_id, gen (buyer_id2)
drop buyer_id
rename buyer_id2 anb_id
save $country_folder/buyers_benford.dta, replace
************************************************
use $country_folder/UY_wip.dta, clear
merge m:1 anb_id using $country_folder/buyers_benford.dta
drop if _m==2
drop _m

br anb_id MAD MAD_conformitiy if !missing(MAD)
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
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


logit singleb i.corr_ben i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*doesn't work
tabstat MAD, by(MAD_conformitiy) stat(min mean max)

xtile ben=MAD if filter_wb==1, nquantiles(10)
replace ben=99 if MAD==. 
tabstat MAD if filter_wb, stat(mean median) //mean .0103336 median .0079134
tabstat MAD, by(ben) stat(min max)

*compared to mean
logit singleb ib7.ben  i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*5
*compared to median
logit singleb ib5.ben  i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base

tab MAD_conformitiy if inlist(ben,5) 
*Not valid
*/
********************************************************************************
*Final Regressions

// logit singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb, base
*R2: 18.12% 610.7k obs

// reg w_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & w_ynrc>4 & w_ynrc!=., base

// reg proa_ycsh singleb i.corr_decp i.corr_submp  i.nocft i.corr_proc i.anb_type i.ca_type_r i.year i.market_id  i.ca_contract_value10 if filter_wb & proa_ynrc>9 & proa_ynrc!=., base
********************************************************************************

*No overrun, delay, or sanctions
********************************************************************************
*CRI calculation

// sum singleb nocft corr_proc  corr_submp corr_decp  proa_ycsh if filter_ok==1
// tab singleb, m
// tab nocft, m
// tab corr_proc, m  //rescale
// tab corr_submp, m //rescale
// tab corr_decp, m //rescale
// cap drop corr_decp_bi corr_proc_bi corr_submp_bi

cap drop corr_decp_bi
gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
// tab corr_decp_bi corr_decp

cap drop corr_proc_bi
gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
// tab corr_proc_bi corr_proc

cap drop corr_submp_bi
gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
// tab corr_submp_bi corr_submp

do "${utility_codes}/cri.do" singleb nocft corr_proc_bi corr_submp_bi corr_decp_bi proa_ycsh4
rename cri cri_uy

// sum cri_uy if filter_ok==1
// hist cri_uy if filter_ok==1, title("CRI UY, filter_ok")
// hist cri_uy if filter_ok==1, by(year, noiy title("CRI UY (by year), filter_ok")) 
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END