local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Single bidding

// br *bid*
cap drop singleb
gen singleb=.
replace singleb=1 if ca_nrbid==1
replace singleb=0 if ca_nrbid>1 & ca_nrbid!=.
// tab singleb
lab var singleb "single-bid red flag"
// tab singleb if filter_ok, m

*Controls only 
// logit singleb i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
//R2: 10.71% - 667,004 obs
********************************************************************************
*Procedure type

// br *proc*
// tab tender_proceduretype, m

*Thresholds from dfid_id_cri_191219
label list ca_procedure
cap drop  corr_proc
gen corr_proc=.
replace corr_proc=0 if ca_procedure==5 //restricted
replace corr_proc=1 if ca_procedure==2 //open
replace corr_proc=2 if ca_procedure==4 //outright award
replace corr_proc=99 if ca_procedure==. |  corr_proc==. //other and missing
// tab corr_proc ca_procedure

// logit singleb i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Old thresholds are not good on open types after we added more controls 

*Calculating new thresholds
decode ca_procedure, gen(ca_procedure2)
replace ca_procedure2 = "NA" if missing(ca_procedure2)
encode ca_procedure2, gen(ca_procedure3)
drop ca_procedure2 
rename ca_procedure3 ca_procedure_v2
// tab ca_procedure_v2, m
label list ca_procedure3
// logit singleb ib2.ca_procedure i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Based on regressions 
*Level 1 risk - OTHER, OUTRIGHT_AWARD
 
label list ca_procedure3
cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if inlist(ca_procedure_v2,2,5) 
replace corr_proc=1 if inlist(ca_procedure_v2,3,4)
replace corr_proc=99 if ca_procedure_v2==1
// tab ca_procedure_v2 corr_proc if filter_ok, m

// logit singleb i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*valid R2 11.83% , 666,353 obs
cap drop ca_procedure_v2
********************************************************************************
*Submission period [old thresholds work from dfid_id_cri_191219.do]

// sum cft_deadline cft_date_first
gen submp =cft_deadline-cft_date_first
// sum submp
replace submp=. if submp<=0

replace submp=. if submp>365 //cap ssubmission period to 1 year
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.

gen corr_submp=.
replace corr_submp=0 if submp10>=8 
replace corr_submp=1 if submp10>=3 & submp10<=7 
replace corr_submp=2 if submp10==1 & submp10!=. 
replace corr_submp=99 if submp10==99


// logit singleb i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*OK
// tab submp10 corr_submp  if filter_ok
// tabstat submp if filter_ok, by(submp10) stat(min mean max)
********************************************************************************
**No cft

// logit singleb i.nocft i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*Doesn't work

// logit singleb i.nocft##i.corr_proc i.corr_submp  i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
* works
// margins , at(nocft=(0 1) corr_proc=(0 1 )) noestimcheck
// marginsplot, x(corr_proc)

gen corr_nocft=nocft 
replace corr_nocft=0 if nocft==1 & !inlist(corr_proc,1)
// tab corr_nocft corr_proc if filter_ok, m
// tab nocft corr_proc if filter_ok, m

// logit singleb i.corr_nocft i.corr_proc i.corr_submp  i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*ok - made corr_proc less significant 

*Method2 [USED]
cap drop nocft2
gen nocft2=0
*replace nocft2 = 1 if missing(tender_publications_firstcallfor)
replace nocft2 = 1 if cft_url==1

// logit singleb i.nocft2 i.corr_submp i.corr_proc i.anb_location i.ca_contract_value10  i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Works much better
*Use the simpler version of the variable 
drop corr_nocft
drop yescft nocft
rename nocft2 nocft 
********************************************************************************
*Decision period [old thresholds work from dfid_id_cri_191219]

// sum aw_dec_date cft_deadline
gen decp=aw_dec_date - cft_deadline
// hist decp
// sum decp
replace decp=. if decp<=0 
replace decp=. if decp>365 

lab var decp "decision period"


xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==.

gen corr_decp=0
replace corr_decp=2 if decp10==1
replace corr_decp=1 if decp10>=2 & decp10<=4
replace corr_decp=2 if decp10==99

// tab decp10 corr_decp, missing

// logit singleb i.corr_decp i.nocft2 i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*OK
// tab corr_decp if filter_ok, m
// tab decp10 corr_decp  if filter_ok
// tabstat decp if filter_ok, by(decp10) stat(min mean max)
********************************************************************************

*Tax haven - supplier country not available
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

*Calculations copied from  dfid_id_cri_191219
// sum ca_contract_value if filter_ok==1

egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_id!=. & year!=., by (w_id year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & anb_id!=. & w_id!=. & year!=., by(anb_id w_id year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(w_id year)
lab var w_mycsh "By Win-year: Max share received from one buyer"
	
gen x=1
egen w_ynrc=total(x) if filter_ok==1 & w_id!=. & year!=., by(w_id year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & anb_id!=. & year!=., by(anb_id year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort w_id year aw_dec_date
egen filter_wy = tag(w_id year) if filter_ok==1 & w_id!=. & year!=.
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort w_id
egen filter_w = tag(w_id) if filter_ok==1 & w_id!=.
lab var filter_w "Marking Winners"
// tab filter_w

sort w_id anb_id
egen filter_wproa = tag(w_id anb_id) if filter_ok==1 & w_id!=. & anb_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort year w_id anb_id
egen filter_wproay = tag(year w_id anb_id) if filter_ok==1 & w_id!=. & anb_id!=. & year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay

// tab w_ynrc if filter_wy==1
// hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.


*checking contract share
// reg w_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>2 & w_ynrc!=., base
// *singleb, nocft, sub, proc
// reg w_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base
// *singleb, nocft, sub, proc
// reg w_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>9 & w_ynrc!=., base
// *singleb, nocft, proc
gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// sum w_ycsh4 w_ycsh4
********************************************************************************
* buyer spending concentration

egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_id!=. & year!=., by(anb_id year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_id year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_id +year +aw_dec_date
egen filter_proay = tag(anb_id year) if filter_ok==1 & anb_id!=. & year!=.
lab var filter_proay "Marking PA years"
// tab filter_proay

sort anb_id
egen filter_proa = tag(anb_id) if filter_ok==1 & anb_id!=.
lab var filter_proa "Marking PAs"
// tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & anb_id!=., by(anb_id)
drop x
lab var proa_nrc "#Contracts by PAs"
// sum proa_nrc
// hist proa_nrc

// sum proa_ynrc
// tab proa_ynrc
*mainly large buyers
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
// hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
// hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*small concentrations from the buyer's perspective

// reg proa_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>2 & proa_ynrc!=., base
*dec,sub
// reg proa_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
// *dec,sub
// reg proa_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>9 & proa_ynrc!=., base
// *dec,sub

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh4
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year w_id "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
do "${utility_codes}/gen_is_capital.do" "`country'" buyer_province

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
// do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
// no supplier location
gen bidder_non_local = .
********************************************************************************
*Benford's

sort anb_id //this id is denerated
// br buyer_name  anb_id anb_id_addid
decode anb_id_addid, gen(anb_id_addid2)
replace anb_id_addid2="" if anb_id_addid2=="."
drop anb_id_addid
rename anb_id_addid2 anb_id_addid

// count if missing(anb_id_addid)
// count if missing(anb_id)

gen anb_id2="ID" + string(anb_id) if !missing(anb_id)
drop anb_id
rename anb_id2 anb_id
save "${country_folder}/`country'_wip.dta", replace

preserve
    rename anb_id buyer_id //buyer id variable
    *rename ca_contract_value ca_contract_value //bid price variable
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
use "${country_folder}/buyers_benford.dta"
// decode buyer_id, gen (buyer_id2)
// drop buyer_id
rename buyer_id anb_id
save "${country_folder}/buyers_benford.dta", replace
************************************************
use "${country_folder}/`country'_wip.dta", clear
merge m:1 anb_id using "${country_folder}/buyers_benford.dta"
drop if _m==2
drop _m

// br anb_id MAD MAD_conformitiy if !missing(MAD)
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

// logit singleb i.corr_ben i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base

replace corr_ben=0 if corr_ben==1
*works!
// tab corr_ben if filter_ok, m
// tabstat MAD if filter_ok, by(corr_ben) stat(min mean max)
********************************************************************************
*No overrun, delay, or sanctions
*Check delay - no completion date
*Overrun - need an actual end cost
********************************************************************************
*Final best regressions

// logit singleb i.corr_ben  i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok, base
*R2 15.70%, ~666,353 obs

// reg w_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base
*singleb, nocft, sub, proc

// reg proa_ycsh singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
*dec,sub
********************************************************************************
*CRI generation

// sum singleb nocft2 corr_proc corr_submp corr_decp  proa_ycsh corr_ben  if filter_ok==1
// tab singleb, m
// tab nocft2, m
// tab corr_proc, m  
// tab corr_submp, m //rescale
// tab corr_decp, m //rescale
// tab corr_ben, m //rescale

cap drop corr_submp_bi
gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
// tab corr_submp_bi corr_submp

gen corr_dec_bi=99
replace corr_dec_bi=corr_decp/2 if corr_decp!=99
// tab corr_dec_bi corr_decp

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

do "${utility_codes}/cri.do" singleb nocft corr_proc corr_submp_bi corr_dec_bi proa_ycsh4 corr_ben_bi
rename cri cri_id

// sum cri_id if filter_ok==1
// hist cri_id if filter_ok==1, title("CRI ID, filter_ok")
// hist cri_id if filter_ok==1, by(tender_year, noiy title("CRI ID (by year), filter_ok"))  
********************************************************************************
save "${country_folder}/ID_wb_2012.dta", replace
********************************************************************************
*END