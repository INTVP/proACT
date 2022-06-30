local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Single bidding

sort tender_id lot_row_nr
// br source tender_id lot_row_nr tender_recordedbidscount lot_bidscount

gen singleb = 0
replace singleb=1 if lot_bidscount==1
replace singleb=. if missing(lot_bidscount)
// tab singleb if filter_ok, m

*Controls only 
// logit singleb i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
********************************************************************************
*Procedure type
// br *proc*
// tab tender_proceduretype, m

*Method 1: 
gen ca_procedure = tender_proceduretype
replace ca_procedure = "NA" if missing(ca_procedure)
encode ca_procedure, gen(ca_procedure2)
drop ca_procedure 
rename ca_procedure2 ca_procedure
// tab ca_procedure, m
label list ca_procedure2
// logit singleb ib6.ca_procedure i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Based on regressions 
*Level 1 risk - NEGOTIATED_WITHOUT_PUBLICATION
*Leve 2 risk - NA.   
 
label list ca_procedure2
cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if inlist(ca_procedure,1,3,5,6,7,8) 
replace corr_proc=1 if inlist(ca_procedure,2,4)
*replace corr_proc=99 if ca_procedure==3
// tab corr_proc if filter_ok, m

// logit singleb i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*valid R2 11.07% , 52,956 obs
********************************************************************************
*Submission period 

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
// sum submp
// hist submp
// hist submp if submp<100
// sum submp, det  
replace submp=. if submp>365 //cap ssubmission period to 1 year

// sum submp if filter_ok  //mean 87.54days
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
// tabstat submp, by(submp10) stat(min mean max)

// *compared to mean
// logit singleb ib8.submp10 i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
// *1-7
// logit singleb ib9.submp10 i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
// *1-7

gen corr_submp=0
replace corr_submp=1 if inlist(submp10,1,2,3,4,5,6,7)
replace corr_submp=99 if submp10==99
// tab submp10 corr_submp if filter_ok, missing
// tab corr_submp if filter_ok, m

// logit singleb i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Works
// tabstat submp, by(submp10) stat(min mean max)
********************************************************************************
**No cft

*Method 1 [not used]
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft if filter_ok, m
// tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing

// logit singleb i.nocft i.corr_submp i.corr_proc i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Doesn't Work

// logit singleb i.nocft##i.corr_proc i.corr_submp  i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Doesn't work
// margins , at(nocft=(0 1) corr_proc=(0 1 )) noestimcheck
// marginsplot, x(corr_proc)

/*
gen corr_nocft=nocft //[not used]
replace corr_nocft=0 if nocft==1 & !inlist(corr_proc,1,2)
tab corr_nocft corr_proc if filter_ok, m
tab nocft corr_proc if filter_ok, m

logit singleb i.corr_nocft i.corr_proc i.corr_submp  i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*/

*Method2 [USED]
cap drop nocft2
gen nocft2=0
*replace nocft2 = 1 if missing(tender_publications_firstcallfor)
replace nocft2 = 1 if missing(notice_url)

// logit singleb i.nocft2 i.corr_submp i.corr_proc i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Works 
*Use the simpler version of the variable 

drop yescft nocft 
********************************************************************************
*Decision Period 

gen decp=aw_date - bid_deadline
// sum decp
// hist decp
replace decp=0 if decp<0 & decp!=0
// count if decp==0 & filter_ok

// hist decp //mostly close to zero
// sum decp if decp>365
// br bid_deadline aw_date decp if decp>365 & !missing(decp)
replace decp=. if decp>730 //cap at 2 year
lab var decp "decision period"

xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==.
// tabstat decp if filter_ok, stat(mean median) //mean: 69.6 days media:51 days
// tabstat decp, by(decp10) stat(n min mean max)

*compared to mean (7)
// logit singleb ib7.decp10 i.nocft2 i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
* 1-2, NA high,3-6  med

cap drop  corr_decp
gen corr_decp=0
replace corr_decp=1 if inlist(decp10,3,4,5,6)
replace corr_decp=2 if inlist(decp10,1,2,99)
*replace corr_decp=99 if decp25==99
// tab decp10 corr_decp if filter_ok, missing
// tab corr_decp if filter_ok

// logit singleb i.corr_decp i.nocft2 i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Valid!
// tabstat decp, by(decp10) stat(min mean max)
********************************************************************************
*Tax haven

// tab bidder_country, m 
gen iso = bidder_country
merge m:1 iso using "${utility_data}/FSI_wide_200812_fin.dta"
lab var iso "supplier country ISO"
drop if _merge==2
drop _merge
gen sec_score = sec_score2009 if tender_year<=2009
replace sec_score = sec_score2011 if (tender_year==2010 | tender_year==2011) & sec_score==.
replace sec_score = sec_score2013 if (tender_year==2012 | tender_year==2013) & sec_score==.
replace sec_score = sec_score2015 if (tender_year==2014 | tender_year==2015) & sec_score==.
replace sec_score = sec_score2017 if (tender_year==2016 | tender_year==2017) & sec_score==.
replace sec_score = sec_score2019 if (tender_year==2018 | tender_year==2019 | tender_year==2020) & sec_score==.
lab var sec_score "supplier country Secrecy Score (time varying)"
// sum sec_score
drop sec_score1998-sec_score2019
// tab bidder_country if missing(sec_score), missing
drop iso

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="LT" | bidder_country==""
// tab fsuppl, missing

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
// tab taxhav, missing
// tab bidder_country if taxhav==1 & fsuppl==1
replace taxhav = 0 if inlist(bidder_country,"US") //removing the US

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
// lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"

gen taxhav3= fsuppl
replace taxhav3 = 2 if fsuppl==1 & taxhav==1
// lab var taxhav3 "Tax haven supplier, 3 categories  (time varying)"
// tab taxhav3 if filter_ok, m

// logit singleb i.taxhav i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
// *+ve & significant - Works
// logit singleb i.taxhav2 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
// *+ve & significant - Works (higher coef.)
// logit singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
// *Works, +ve & significant - Works (even higher coef.)
// *Use taxhav2 for CRI
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

// unique buyer_masterid
// unique buyer_id
// unique buyer_name
// count if missing(buyer_masterid) & filter_ok==1
// count if missing(buyer_id) & filter_ok==1
// count if missing(buyer_name) & filter_ok==1

sort buyer_masterid buyer_id
format buyer_masterid buyer_id buyer_name %20s
// br buyer_masterid buyer_id buyer_name

// unique bidder_masterid
// unique bidder_id
// unique bidder_name
// count if missing(bidder_masterid) & filter_ok==1
// count if missing(bidder_id) & filter_ok==1
// count if missing(bidder_name) & filter_ok==1

sort bidder_masterid bidder_id
format bidder_masterid bidder_id bidder_name %20s
// br bidder_masterid bidder_id bidder_name

*Use buyer_id and bidder_id
egen w_yam=sum(bid_price) if filter_ok==1 & !missing(bidder_masterid) & !missing(tender_year), by (bidder_masterid tender_year) 
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

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & !missing(buyer_masterid) & !missing(tender_year), by(buyer_masterid tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort bidder_masterid tender_year aw_date
egen filter_wy = tag(bidder_masterid tender_year) if filter_ok==1 & !missing(bidder_masterid) & !missing(tender_year)
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort bidder_masterid
egen filter_w = tag(bidder_masterid) if filter_ok==1 & !missing(bidder_masterid)
lab var filter_w "Marking Winners"
// tab filter_w

sort bidder_masterid buyer_masterid
egen filter_wproa = tag(bidder_masterid buyer_masterid) if filter_ok==1 & !missing(buyer_masterid) & !missing(bidder_masterid) 
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort tender_year bidder_masterid buyer_masterid
egen filter_wproay = tag(tender_year bidder_masterid buyer_masterid) if filter_ok==1 & !missing(buyer_masterid) & !missing(bidder_masterid)  &  !missing(tender_year)
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay

// *checking contract share
// reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>2 & w_ynrc!=., base
// *taxhav, nocft, sub
// reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base
// *taxhav, nocft,
// reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>9 & w_ynrc!=., base
*nocft
gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// sum w_ycsh4 w_ycsh
********************************************************************************
*Buyer dependence on supplier

egen proa_yam=sum(bid_price) if filter_ok==1 & !missing(buyer_masterid) & !missing(tender_year), by(buyer_masterid tender_year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
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

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & !missing(buyer_masterid) , by(buyer_masterid)
drop x
lab var proa_nrc "#Contracts by PAs"
// sum proa_nrc
// hist proa_nrc

// sum proa_ynrc
// tab proa_ynrc
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
// hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
// hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*validation 

// reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>2 & proa_ynrc!=., base
// *singl,dec,sub,proc
// reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
// *singl,dec,sub,proc
// reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>9 & proa_ynrc!=., base
// *singl,dec,sub,proc,taxhav

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year bidder_masterid "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city buyer_nuts  tender_addressofimplementation_n

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
********************************************************************************
*Benford's
// br buyer_name  buyer_id buyer_masterid
rename buyer_id buyer_id_old
save "${country_folder}/`country'_wip.dta", replace

preserve
    rename buyer_masterid buyer_id //buyer id variable
    rename bid_price ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
	keep if !missing(buyer_id)
    bys buyer_id: gen count = _N
    keep if count >100
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
	export delimited  "${country_folder}/buyers_for_R.csv", replace
	! "${R_path_local}" "${utility_codes}/benford.R" "${country_folder}"
restore
************************************************
use "${country_folder}/buyers_benford.dta", clear
// decode buyer_id, gen (buyer_id2)
// drop buyer_id
rename buyer_id buyer_masterid
save "${country_folder}/buyers_benford.dta", replace
************************************************
use "${country_folder}/`country'_wip.dta", clear
rename buyer_id_old buyer_id
merge m:1 buyer_masterid using "${country_folder}/buyers_benford.dta"
drop if _m==2
drop _m

// br buyer_masterid MAD MAD_conformitiy if !missing(MAD)
// tab MAD_conformitiy, m
// tabstat MAD, by(MAD_conformitiy) stat(min mean max)
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

// logit singleb i.corr_ben i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*works!
// tab corr_ben if filter_ok, m
// tabstat MAD if filter_ok, by(corr_ben) stat(min mean max)
********************************************************************************
*Overrun payments_sum

gen roverrun=(payments_sum-ca_contract_value)/ca_contract_value
********************************************************************************
*No  delay, or sanctions
*Check delay 
// count if missing(lot_updatedcompletiondate) //all missing
*Add sanctions - no sanctions
********************************************************************************
*Final best regressions

// logit singleb i.corr_ben i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*R2 16.81%, ~52k obs

// reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base
*taxhav, nocft

// reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
*singl,dec,sub,proc
********************************************************************************
*CRI generation

// sum singleb nocft2 corr_proc corr_submp corr_decp  taxhav2  proa_ycsh corr_ben  if filter_ok==1
// tab singleb, m
// tab nocft2, m
// tab corr_proc, m  
// tab corr_submp, m 
// tab corr_decp, m //rescale
// tab taxhav2, m
// tab corr_ben, m

gen corr_dec_bi=99
replace corr_dec_bi=corr_decp/2 if corr_decp!=99
tab corr_dec_bi corr_decp

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben

do "${utility_codes}/cri.do" singleb nocft2 corr_proc corr_subm corr_dec_bi taxhav2 proa_ycsh4 corr_ben_bi
rename cri cri_lt

// sum cri_lt if filter_ok==1
// hist cri_lt if filter_ok==1, title("CRI LT, filter_ok")
// hist cri_lt if filter_ok==1, by(tender_year, noiy title("CRI LT (by year), filter_ok"))  // you should look into 2017 and 2017 - spike in cri==1 weird
********************************************************************************

save "${country_folder}/`country'_wb_2012.dta", replace
********************************************************************************
*END