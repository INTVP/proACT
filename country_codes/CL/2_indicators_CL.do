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

* Singlebidding
/*
sum ca_nrbid
tab ca_nrbid
hist ca_nrbid, percent
*lot level; 7.07% single bidding

gen ca_nrbid_trim=ca_nrbid
replace ca_nrbid_trim=100 if ca_nrbid>=100 & ca_nrbid!=.
hist ca_nrbid_trim
lab var ca_nrbid_trim "number of bids trimmed to 100"

gen singleb=.
replace singleb=1 if ca_nrbid==1
replace singleb=0 if ca_nrbid>1 & ca_nrbid!=.
tab singleb
lab var singleb "single-bid red flag"
*7.07% single bids

gen prop_bidnr=1/(ca_nrbid*ca_nrbid)
hist prop_bidnr if filter_ok==1
*/
********************************************************************************

* Winner dependence

/*
sum ca_contract_value if filter_ok==1

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
tab filter_wy

sort w_id
egen filter_w = tag(w_id) if filter_ok==1 & w_id!=.
lab var filter_w "Marking Winners"
tab filter_w

sort w_id anb_id
egen filter_wproa = tag(w_id anb_id) if filter_ok==1 & w_id!=. & anb_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
tab filter_wproa

sort year w_id anb_id
egen filter_wproay = tag(year w_id anb_id) if filter_ok==1 & w_id!=. & anb_id!=. & year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
tab filter_wproay

tab w_ynrc if filter_wy==1
hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.
*/
********************************************************************************

* buyer spending concentration

/*
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
tab filter_proay

sort anb_id
egen filter_proa = tag(anb_id) if filter_ok==1 & anb_id!=.
lab var filter_proa "Marking PAs"
tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & anb_id!=., by(anb_id)
drop x
lab var proa_nrc "#Contracts by PAs"
sum proa_nrc
hist proa_nrc

sum proa_ynrc
tab proa_ynrc
*mainly large buyers
sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*small concentrations from the buyer's perspective
 */
********************************************************************************

* Winning probability

/*
gen filter_bid=0
replace filter_bid=1 if bid_iswinning!=1
tab filter_bid bid_iswinning, missing

gen x=0 if bid_iswinning==2
replace x=1 if bid_iswinning==3
tab x if filter_bid==1 & w_id!=. & year!=.
tab year x if filter_bid==1 & w_id!=. & year!=.

sum w_id w_id_addid

egen winprob=mean(x) if filter_bid==1 & w_id!=. & year!=., by(w_id year)
egen w_bidnr=sum(filter_bid) if filter_bid==1 & w_id!=. & year!=., by(w_id year)
sum winprob w_bidnr if filter_ok==1

sort w_id year aw_dec_date
egen filter_wy_v2 = tag(w_id year) if filter_ok==1 & w_id!=. & year!=.
lab var filter_wy_v2 "Marking Winner years (using w_id)"
tab filter_wy_v2

hist winprob if filter_ok==1
hist winprob if filter_ok==1 & w_bidnr>=3 & filter_wy_v2==1, freq
hist winprob if filter_ok==1 & w_bidnr>=5 & filter_wy_v2==1, freq
hist winprob if filter_ok==1 & w_bidnr>=10 & filter_wy_v2==1, freq
hist winprob if filter_ok==1 & w_bidnr>=10 & filter_wy_v2==1, percent
hist winprob if filter_ok==1 & w_bidnr>=20 & filter_wy_v2==1, percent
hist winprob if filter_ok==1 & w_bidnr>=50 & filter_wy_v2==1, freq

gen winprob10=winprob if w_bidnr>=10 & w_bidnr!=.
sum winprob10 if filter_ok==1

drop x
*/
********************************************************************************

* Submission period & nocft
/*
sum cft_deadline cft_date_first
gen submp =cft_deadline-cft_date_first
sum submp
replace submp=. if submp<=0
label var submp "advertisement period"

gen yescft=1
replace yescft=0 if submp <=0 | submp==.
tab yescft, missing

gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
tab nocft, missing

hist submp
hist submp if submp<365
hist submp if submp<200
hist submp if submp<100

sum submp
sum submp if submp>365
sum submp if submp>183
sum submp if submp>125
sum submp if submp>100
*take half year as an upper bound
replace submp=. if submp>183
*/
********************************************************************************

* Decision period *
/*
sum aw_dec_date cft_deadline
gen decp=aw_dec_date - cft_deadline
hist decp
sum decp
sum decp if decp <=0
*0.72% is 0
replace decp=. if decp<=0 
replace decp=. if decp>365 
lab var decp "decision period"
*/

********************************************************************************

*supplier location (city-based): sameloc
/*

decode w_city, gen(w_city_str)
decode anb_city, gen(anb_city_str)

gen sameloc=.
replace sameloc=1 if anb_city_str==w_city_str & anb_city_str!="" & w_city_str!=""
replace sameloc=0 if anb_city_str!=w_city_str & anb_city_str!="" & w_city_str!=""
replace sameloc=9 if sameloc==.
tab sameloc if filter_ok==1

drop w_city_str anb_city_str
*/
********************************************************************************

*aw_critcount
/*
sum aw_critcount

xtile aw_critcount10=aw_critcount if filter_ok==1, nquantiles(10)
replace aw_critcount10=99 if aw_critcount==.

xtile aw_critcount5=aw_critcount if filter_ok==1, nquantiles(5)
replace aw_critcount5=99 if aw_critcount==.
*/
********************************************************************************
* Indicator validation: singleb regressions ***

*controls only

// sum singleb anb_type lca_contract_value year marketid anb_city
// sum singleb anb_type lca_contract_value year marketid anb_city if filter_ok==1
*few missing for anb_type and anb_city (<5%)

// logit singleb lca_contract_value i.anb_type i.year i.marketid, base
// logit singleb lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
********************************************************************************

* Procedure types

// tab ca_procedure if filter_ok==1
*99.35% open, no real variance
*national procedure type is all missing-->fix at the next data update

// logit singleb ib3.ca_procedure lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*ok

/*
gen corr_proc=.
replace corr_proc=0 if ca_procedure==3
replace corr_proc=1 if ca_procedure==4
replace corr_proc=99 if corr_proc==.
tab corr_proc if filter_ok==1, missing
*/

// logit singleb i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*great
********************************************************************************
*nocft

// tab nocft if filter_ok==1
// tab ca_procedure nocft if filter_ok==1
// tab corr_proc nocft if filter_ok==1, missing
//
// logit singleb i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// *counterint.
// logit singleb i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & corr_proc==1, base
*works for risky procedure types
********************************************************************************
*advertisement period

// sum submp
// tab submp
// hist submp
// hist submp, by(ca_procedure)
*94% <=15 days
/*
xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
xtile submp25=submp if filter_ok==1, nquantiles(25)
replace submp25=99 if submp==.
*/
// tab submp5
// tab submp25
// tab submp25 nocft
// sum submp if nocft==1
*no overlaps

// tabstat submp, by(submp25) stat(min max N)
// tabstat submp, by(submp10) stat(min max N)
// tabstat submp, by(submp5) stat(min max N)

// logit singleb submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.submp5 i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.nocft#i.corr_proc i.submp10 lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// *counterint., shortest is the least risky
// logit singleb i.nocft#i.corr_proc i.submp10#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// *better, shorter periods increase risk of single bidding in case of non-competitive procedure types
// logit singleb i.nocft#i.corr_proc ib10.submp10#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base

gen corr_submp=.
replace corr_submp=0 if submp10>=7 & submp10!=. & corr_proc==1 | submp10!=. & corr_proc==0
replace corr_submp=1 if submp10>=2 & submp10<=6 & submp10!=. & corr_proc==1
replace corr_submp=2 if submp10==1 & submp10!=. & corr_proc==1
replace corr_submp=99 if submp10==99
// tab submp10 corr_submp, missing
// tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

// logit singleb i.nocft#i.corr_proc i.corr_submp lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*great
********************************************************************************
*decision making period

// sum decp
// hist decp

rename decp decp_old
gen decp=decp_old
replace decp=. if decp>183 

// xtile decp5=decp if filter_ok==1, nquantiles(5)
// replace decp5=99 if decp==.
xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==.
// xtile decp25=decp if filter_ok==1, nquantiles(25)
// replace decp25=99 if decp==.
// tab decp5
// tab decp25
// tabstat decp, by(decp25) stat(min max mean N)

// logit singleb decp i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.decp5 i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.decp10 i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb ib10.decp10 i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.decp25 i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// *as expected

gen corr_decp=0
replace corr_decp=2 if decp10<=3
replace corr_decp=1 if decp10>=4 & decp10<=6
replace corr_decp=99 if decp==.
// tab decp10 corr_decp, missing

// logit singleb i.corr_decp i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*as expected (nocft insignificant)
********************************************************************************
*aw_critcount

// sum aw_critcount
// tabstat aw_critcount, by(aw_critcount10) stat(min max N)

// logit singleb aw_critcount i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.aw_critcount5 i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.aw_critcount10 i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// *more award decision criteria increase risk of single bidding 

gen corr_awcrit=0
replace corr_awcrit=2 if aw_critcount10>=9
replace corr_awcrit=1 if aw_critcount10>=4 & aw_critcount10<=7
replace corr_awcrit=99 if aw_critcount==.
// tab aw_critcount10 corr_awcrit, missing

// logit singleb i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*ok
********************************************************************************
*Winning probability

xtile winprob5=winprob if filter_ok==1, nquantiles(5)
replace winprob5=99 if winprob==.
replace winprob5=99 if w_bidnr<3 & w_bidnr!=.
xtile winprobc10=winprob if filter_ok==1, nquantiles(10)
replace winprobc10=99 if winprob==.
replace winprobc10=99 if w_bidnr<3 & w_bidnr!=.

// tab winprob5 if filter_ok==1
// tabstat winprob if filter_ok==1, by(winprob5) stat(min mean max N)
// tab winprobc10 if filter_ok==1
// tabstat winprob if filter_ok==1, by(winprobc10) stat(min mean max N)


// logit singleb winprob i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.winprob5 i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
// logit singleb i.winprobc10 i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*as expected, positive relationship

gen corr_wpr=.
replace corr_wpr=0 if winprobc10>=1 & winprobc10<=6
replace corr_wpr=1 if winprobc10>=7 & winprobc10<=8
replace corr_wpr=2 if winprobc10>=9
replace corr_wpr=99 if winprobc10==99
*I keep low winning probabilities as non-risky even if they are significant predictors as theoretically they are unlikely to mean real risk
// tab corr_wpr if filter_ok==1

// logit singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*great
********************************************************************************
* Supplier dependence on buyer

// tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
// ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
*negative sign.

// reg w_ycsh singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
// reg w_ycsh singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
// *mostly works, except nocft, corr_decp

// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
*not too strong spike at the top
********************************************************************************
* Buyer spending concentration

// tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
// *negative, significant
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
// *negative, significant

// reg proa_ycsh singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
// reg proa_ycsh singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*mostly works, except nocft and corr_submp
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" cpv_div year w_id "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" ca_contract_value_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
do "${utility_codes}/gen_is_capital.do" "`country'" anb_city anb_region

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
*no supplier city information
*do "${utility_codes}/gen_bidder_non_local.do" "`country'" anb_city w_city
gen bidder_non_local=.
********************************************************************************

*Benford's law export
/*
preserve
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys anb_id: gen count = _N
    keep if count >100
    keep anb_id ca_contract_value
	order anb_id ca_contract_value
    export delimited  "${country_folder}/buyers_for_R.csv", replace
    ! "$R_path_local" "${utility_codes}/benford.R" "${country_folder}" 
restore

merge m:1 anb_id using "${country_folder}/buyers_benford.dta"
drop _m

// br anb_id MAD MAD_conformitiy
// tab MAD_conformitiy, m
// tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — 0.003583 to 0.0058504
Acceptable conformity — 0.0060427 to 0.0119378
Marginally acceptable conformity — 0.0120295 to 0.0149513
Nonconformity — greater than 0.0150152
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)

*putting back the interaction term(no big change so the above can stay without interaction)
// logit singleb i.corr_ben i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base

gen corr_ben2=0 if corr_ben==2 | corr_ben==0
replace corr_ben2=1 if corr_ben==1
replace corr_ben2=99 if corr_ben==. | corr_ben==99

// logit singleb i.corr_ben2 i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base

// reg proa_ycsh singleb i.corr_ben2 i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*/
********************************************************************************
* Final best regression and valid red flags

// logit singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft#i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1, base
*12.24% explanatory power
// reg proa_ycsh singleb i.corr_wpr i.corr_awcrit i.corr_decp i.corr_submp i.nocft i.corr_proc lca_contract_value i.anb_type i.year i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
********************************************************************************
* CRI generation

// sum singleb corr_wpr corr_awcrit corr_decp corr_submp nocft corr_proc proa_ycsh if filter_ok==1
*few missing for corr_submp and corr_proc

// tab singleb if filter_ok==1
// tab corr_wpr if filter_ok==1
// *needs binarisation
// tab corr_awcrit if filter_ok==1
// *needs binarisation
// tab corr_decp if filter_ok==1
// *needs binarisation
// tab corr_submp if filter_ok==1
// *needs binarisation
// tab nocft if filter_ok==1 & corr_proc==1
// tab corr_proc if filter_ok==1

// gen corr_wpr_bi=corr_wpr
// replace corr_wpr_bi=corr_wpr/2 if corr_wpr<99
// tab corr_wpr_bi corr_wpr, missing

// gen corr_awcrit_bi=corr_awcrit
// replace corr_awcrit_bi=corr_awcrit/2 if corr_awcrit<99
// tab corr_awcrit_bi corr_awcrit, missing

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
// tab corr_decp_bi corr_decp

gen corr_subm_bi=99
replace corr_subm_bi=corr_submp/2 if corr_submp!=99
// tab corr_subm_bi corr_submp

gen nocft_nocomp=.
replace nocft_nocomp=0 if nocft==0 & corr_proc==1
replace nocft_nocomp=1 if nocft==1 & corr_proc==1
// tab nocft nocft_nocomp, missing

gen proa_ycsh9=proa_ycsh if filter_ok==1 & proa_ynrc>9 & proa_ycsh!=.
// sum proa_ycsh9 proa_ycsh

do "${utility_codes}/cri.do" singleb corr_decp_bi corr_subm_bi nocft_nocomp corr_proc proa_ycsh9 
rename cri cri_cl

// sum cri_cl if filter_ok==1
// hist cri_cl if filter_ok==1
// hist cri_cl if filter_ok==1, by(year)
// hist cri_cl if filter_ok==1 & cri_cl>0.5
// hist cri_cl if filter_ok==1 & cri_cl>0.55
// hist cri_cl if filter_ok==1 & cri_cl>0.6, freq
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END