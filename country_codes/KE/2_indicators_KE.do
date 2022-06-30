local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

sort buyer_masterid buyer_id
format buyer_masterid buyer_id buyer_name %20s

sort bidder_masterid bidder_id
format bidder_masterid bidder_id bidder_name %20s

*Use buyer_id and bidder_id
egen w_yam=sum(bid_price) if filter_ok==1 & !missing(bidder_masterid) & tender_year!=., by (bidder_masterid tender_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(bid_price) if filter_ok==1 & !missing(buyer_masterid) & !missing(bidder_masterid) & !missing(tender_year), by(buyer_masterid bidder_masterid tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(bidder_masterid tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

cap drop x
gen x=1
egen w_ynrc=total(x) if filter_ok==1 & !missing(bidder_masterid) & !missing(tender_year), by(bidder_masterid tender_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

cap drop x
gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & !missing(buyer_masterid) & !missing(tender_year), by(buyer_masterid tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort bidder_masterid tender_year aw_date
egen filter_wy = tag(bidder_masterid tender_year) if filter_ok==1 & !missing(bidder_masterid) & !missing(tender_year)
lab var filter_wy "Marking Winner years"

sort bidder_masterid
egen filter_w = tag(bidder_masterid) if filter_ok==1 & !missing(bidder_masterid)
lab var filter_w "Marking Winners"

sort bidder_masterid buyer_masterid
egen filter_wproa = tag(bidder_masterid buyer_masterid) if filter_ok==1 & !missing(buyer_masterid) & !missing(bidder_masterid) 
lab var filter_wproa "Marking Winner-buyer pairs"

sort tender_year bidder_masterid buyer_masterid
egen filter_wproay = tag(tender_year bidder_masterid buyer_masterid) if filter_ok==1 & !missing(buyer_masterid) & !missing(bidder_masterid)  &  !missing(tender_year)
lab var filter_wproay "Marking Winner-buyer pairs"

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
********************************************************************************
*Buyer dependence on supplier

egen proa_yam=sum(bid_price) if filter_ok==1 & !missing(buyer_masterid) & !missing(tender_year), by(buyer_masterid tender_year) 
lab var proa_yam "By PA-year: Spending amount"

cap drop proa_ycsh
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(buyer_masterid tender_year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort buyer_masterid +tender_year +aw_date
egen filter_proay = tag(buyer_masterid tender_year) if filter_ok==1 &  !missing(buyer_masterid)  & !missing(tender_year)
lab var filter_proay "Marking PA years"
// tab filter_proay

sort buyer_masterid
egen filter_proa = tag(buyer_masterid) if filter_ok==1 & !missing(buyer_masterid) 
lab var filter_proa "Marking PAs"
// tab filter_proa
cap drop x
gen x=1
egen proa_nrc=total(x) if filter_ok==1 & !missing(buyer_masterid) , by(buyer_masterid)
drop x
lab var proa_nrc "#Contracts by PAs"

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year bidder_masterid "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city buyer_nuts

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
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
*/
cap drop corr_ben
rename corr_ben2 corr_ben
replace corr_ben = 2 if corr_ben == 1 
********************************************************************************
/*
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
*/
*Submission Period
// gen submp =cft_deadline-cft_date_first
// replace submp=. if submp<=0
// label var submp "advertisement period"
// replace submp=. if submp>183
// sum submp

cap drop corr_submp
gen corr_submp=0
replace corr_submp=1 if submp>=22
replace corr_submp=. if missing(submp)

/*
********************************************************************************
*/
*Procedure Type
// gen corr_proc=1 if tender_indicator_integrity_proce==0
// replace corr_proc=0 if tender_indicator_integrity_proce==100
// replace corr_proc=99 if tender_indicator_integrity_proce==.

gen decp=aw_date - bid_deadline
replace decp=0 if decp<0 & decp!=0
replace decp=. if decp>730 //cap at 2 year
lab var decp "decision period"

cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if inlist(tender_proceduretype,"APPROACHING_BIDDERS","OPEN","RESTRICTED")
replace corr_proc=1 if inlist(tender_proceduretype,"DPS_PURCHASE","OUTRIGHT_AWARD","OTHER")

********************************************************************************
/*
*No cft                                                                   
gen nocft=1 if submp==.
replace nocft=0 if submp!=.
tab nocft
********************************************************************************
*/

*Final Best Regression
// logit singleb i.corr_ben i.corr_descl i.corr_signp i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.ca_type i.anb_loc i.marketid if filter_ok==1, base
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END