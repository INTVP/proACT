local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip", clear
********************************************************************************
* supplier dependence on a buyer (including filter_ok throughout which also removes cancelled tenders)

// egen x=nvals(w_name)
// tab x
// drop x

// egen x=nvals(anb_name)
// tab x
// drop x

*buyer dependence
// sum ca_contract_value

// egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_id_addid!=. & year!=., by (w_id_addid year) 
// lab var w_yam "By Winner-year: Spending amount"

// egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & anb_id_addid!=. & w_id_addid!=. & year!=., by(anb_id_addid w_id_addid year)
// lab var proa_w_yam "By PA-year-supplier: Amount"

// gen w_ycsh=proa_w_yam/w_yam 
// lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

// egen w_mycsh=max(w_ycsh), by(w_id_addid year)
// lab var w_mycsh "By Win-year: Max share received from one buyer"
	
// gen x=1
// egen w_ynrc=total(x) if filter_ok==1 & w_id_addid!=. & year!=., by(w_id_addid year)
// drop x
// lab var w_ynrc "#Contracts by Win-year"

// gen x=1
// egen proa_ynrc=total(x) if filter_ok==1 & anb_id_addid!=. & year!=., by(anb_id_addid year)
// drop x
// lab var proa_ynrc "#Contracts by PA-year"

// sort w_id_addid year aw_date
// egen filter_wy = tag(w_id_addid year) if filter_ok==1 & w_id_addid!=. & year!=.
// lab var filter_wy "Marking Winner years"
// tab filter_wy

// sort w_id_addid
// egen filter_w = tag(w_id_addid) if filter_ok==1 & w_id_addid!=.
// lab var filter_w "Marking Winners"
// tab filter_w

// tab w_ynrc if filter_wy==1
// hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.


* buyer spending concentration

// egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_id_addid!=. & year!=., by(anb_id_addid year) 
// lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
// gen proa_ycsh=proa_w_yam/proa_yam 
// lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
// egen proa_mycsh=max(proa_ycsh), by(anb_id_addid year)
// lab var proa_mycsh "By PA-year: Max share spent on one supplier"

// gsort anb_id_addid +year +aw_date
// egen filter_proay = tag(anb_id_addid year) if filter_ok==1 & anb_id_addid!=. & year!=.
// lab var filter_proay "Marking PA years"
// tab filter_proay

// sort anb_id_addid
// egen filter_proa = tag(anb_id_addid) if filter_ok==1 & anb_id_addid!=.
// lab var filter_proa "Marking PAs"
// tab filter_proa

// gen x=1
// egen proa_nrc=total(x) if filter_ok==1 & anb_id_addid!=., by(anb_id_addid)
// drop x
// lab var proa_nrc "#Contracts by PAs"
// sum proa_nrc
// hist proa_nrc

// sum proa_ynrc
// tab proa_ynrc
// *mainly large buyers
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
// hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
// hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*small concentrations from the buyer's perspective
********************************************************************************
*Submission period

// sum cft_deadline cft_date_first cft_date_last aw_date ca_signdate

cap drop submp
gen submp =cft_deadline-cft_date_first
// tab submp 
*0.33% negative or 0 values
replace submp=. if submp<=0
label var submp "advertisement period"

// hist submp
// hist submp if submp<365
// hist submp if submp<200
// hist submp if submp<100

// sum submp
// sum submp if submp>365
// sum submp if submp>183
// sum submp if submp>125
// sum submp if submp>100
*take half year as an upper bound
replace submp=. if submp>183
********************************************************************************
*Nocft
cap drop yescft nocft
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft, missing

gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing
********************************************************************************
* Decision period * OUT 
cap drop decp
// sum aw_date cft_deadline

*aw_date is probably not ok
gen decp=aw_date - cft_deadline
// sum decp
*97.3% is <=0
replace decp=. if decp<=0 
lab var decp "decision period"
********************************************************************************
*Procedure type 

// tab ca_procedure, missing
********************************************************************************
*Single bidding
local country "IN"

// sum ca_nrbid
// hist ca_nrbid, percent
// tab ca_nrbid
*100% is single bid

// tab lot_nrbid
*31.34%
cap drop singleb
gen singleb=.
replace singleb=1 if lot_nrbid==1
replace singleb=0 if lot_nrbid>1 & lot_nrbid!=.
// tab singleb
lab var singleb "single-bid red flag"
*31.34% single bids

cap drop prop_bidnr
gen prop_bidnr=1/(lot_nrbid*lot_nrbid)
// hist prop_bidnr if filter_ok==1
********************************************************************************
*Signature period

// sum aw_date ca_signdate
// gen signp= ca_signdate - aw_date
// hist signp
// sum signp
// sum signp if signp>365
// sum signp if signp>183
// sum signp if signp>125
// sum signp if signp>100
// replace signp=. if signp<=0 
// replace signp=. if signp>183 
// lab var signp "contract signature period"
********************************************************************************
*tender corrections count

// tab nr_correct
*99.52 - 0 values
********************************************************************************
*tender description length/lot_description_length

// sum tender_description_length lot_description_length
//
// xtile ten_descr5=tender_description_length if filter_ok==1, nquantiles(5)
// replace ten_descr5=99 if tender_description_length==.
//
// xtile lot_descr5=lot_description_length if filter_ok==1, nquantiles(5)
// replace lot_descr5=99 if lot_description_length==.
//
// tabstat tender_description_length, by(ten_descr5) stat(min max N)
// tabstat lot_description_length, by(lot_descr5) stat(min max N)
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators market entry 
decode w_id_addid, gen(bidder_masterid)
*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" cpv_code year bidder_masterid "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 

*No location information
*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
*do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city buyer_nuts  tender_addressofimplementation_n

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
*do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
cap drop bidder_non_local  is_capital
gen bidder_non_local=.
gen is_capital =.
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************

*Benford's law export
decode anb_id_addid, gen(buyer_masterid)

preserve
    *rename xxxx buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_masterid: gen count = _N
    keep if count >100
    keep buyer_masterid ca_contract_value
	order buyer_masterid ca_contract_value
	export delimited  "${country_folder}/buyers_for_R.csv", replace
	! "${R_path_local}" "${utility_codes}/benford.R" "${country_folder}"
restore

************************************************
use "${country_folder}/buyers_benford.dta", clear
rename buyer_id buyer_masterid
save "$country_folder/buyers_benford.dta", replace
************************************************	
local country "IN"

use "${country_folder}/`country'_wip.dta", clear
decode anb_id_addid, gen(buyer_masterid)
merge m:1 buyer_masterid using "${country_folder}/buyers_benford.dta"
drop if _m==2
drop _m

//
// br anb_id_addid MAD MAD_conformitiy
// tab MAD_conformitiy, m
// tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — 0.0041436 to 0.0054673
Acceptable conformity — 0.0061921 to 0.0112735
Marginally acceptable conformity — 0.012357 to 0.0149695
Nonconformity — greater than 0.0153679
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
********************************************************************************
*CRI components validation

*controls only

// sum singleb ca_contract_value w_ycsh proa_ycsh submp yescft nocft ca_procedure ten_descr5
*decp, nr_correct, lot_descr5 OUT

// sum year anb_type ca_type
*marketid too detailed - description
cap drop ca_contract_value10
xtile ca_contract_value10 = ca_contract_value, nq(10)
replace ca_contract_value10=99 if missing(ca_contract_value)

// sum singleb year anb_type ca_type ca_contract_value10
// sum singleb year anb_type ca_type ca_contract_value10 if filter_ok==1
*many missings in anb_type and ca_type, somewhat less in singleb
replace anb_type=99 if anb_type==.
replace ca_type=99 if ca_type==.

// logit singleb i.ca_contract_value10 i.anb_type i.year i.ca_type, base
// logit singleb i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*number of obs = 147,560, Pseudo R2 = 0.1966
********************************************************************************
*procedure types

// tab ca_procedure
// tab ca_procedure_nat

gen ca_proc_simp=.
replace ca_proc_simp=1 if ca_procedure_nat==19 | ca_procedure_nat>=73 & ca_procedure_nat<=84 | ca_procedure_nat>=86 & ca_procedure_nat<=91
replace ca_proc_simp=2 if ca_procedure_nat==14 | ca_procedure_nat==15 | ca_procedure_nat==17 | ca_procedure_nat>=29 & ca_procedure_nat<=42| ca_procedure_nat==45 | ca_procedure_nat==46 | ca_procedure_nat==61 | ca_procedure_nat==62 | ca_procedure_nat==64
replace ca_proc_simp=3 if ca_procedure_nat>=5 & ca_procedure_nat<=7 | ca_procedure_nat==12 | ca_procedure_nat==13 | ca_procedure_nat==16 | ca_procedure_nat==18 | ca_procedure_nat==20 | ca_procedure_nat==21 | ca_procedure_nat==23 | ca_procedure_nat==27 | ca_procedure_nat==28 | ca_procedure_nat==43 | ca_procedure_nat==44 | ca_procedure_nat>=47 & ca_procedure_nat<=58 | ca_procedure_nat==60 | ca_procedure_nat==63 | ca_procedure_nat==65 | ca_procedure_nat==66
replace ca_proc_simp=4 if ca_procedure_nat>=9 & ca_procedure_nat<=11 | ca_procedure_nat>=24 & ca_procedure_nat<=26 | ca_procedure_nat==59 | ca_procedure_nat>=67 & ca_procedure_nat<=69 | ca_procedure_nat==85 | ca_procedure_nat==96
replace ca_proc_simp=99 if ca_procedure_nat==. | ca_procedure_nat>=93 & ca_procedure_nat<=95

replace ca_type=2 if ca_procedure_nat==22 & ca_type==.
replace ca_type=1 if ca_procedure_nat>=70 & ca_procedure_nat<=72 | ca_procedure_nat==92 & ca_type==.
replace ca_type=3 if ca_procedure_nat==98 & ca_type==.

label define ca_proc_simp 1"direct" 2"limited" 3"open" 4"other", replace
label val ca_proc_simp ca_proc_simp
// tab ca_proc_simp

// logit singleb ib3.ca_procedure i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
// logit singleb ib3.ca_proc_simp i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base

gen corr_proc=.
replace corr_proc=0 if ca_proc_simp==3
replace corr_proc=1 if ca_proc_simp==2 | ca_proc_simp==4
replace corr_proc=2 if ca_proc_simp==1
replace corr_proc=99 if ca_proc_simp==99 |  corr_proc==. 
// tab ca_proc_simp corr_proc, missing

// logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*ok
********************************************************************************
*nocft

// tab nocft if filter_ok==1
*79.4% of the contracts had no call for tenders
// tab ca_procedure nocft if filter_ok==1
// tab corr_proc nocft if filter_ok==1

// logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*counterint.
// logit singleb i.nocft#i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
// logit singleb i.nocft#ib3.ca_procedure i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*works for competitve procedures

gen nocftcomp=99
replace nocftcomp=0 if nocft==0 & corr_proc==0
replace nocftcomp=1 if nocft==1 & corr_proc==0
// tab nocftcomp nocft, missing

// logit singleb i.nocftcomp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*still opposite

egen nocftproc=group(ca_procedure nocft), label missing
replace nocftproc=99 if ca_procedure==.
// tab nocftproc
// tab nocftproc if filter_ok==1 & singleb!=.

// logit singleb ib3.nocftcomp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*doesn't work

// ttest singleb if filter_ok==1, by(nocft)
*positive, significant
********************************************************************************
*tender description length

// sum tender_description_length lot_description_length

// tabstat tender_description_length, by(ten_descr5) stat(min max N)
// tabstat lot_description_length, by(lot_descr5) stat(min max N)

// logit singleb i.ten_descr5 i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*shorter or no description increase singleb

// gen corr_desc=0
// replace corr_desc=1 if ten_descr5<=2
// replace corr_desc=99 if tender_description_length==.

// logit singleb i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*ok
********************************************************************************
*buyer spending concentration

sort w_id_addid anb_id_addid
egen filter_wproa = tag(w_id_addid anb_id_addid) if filter_ok==1 & w_id_addid!=. & anb_id_addid!=.
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort year w_id_addid anb_id_addid
egen filter_wproay = tag(year w_id_addid anb_id_addid) if filter_ok==1 & w_id_addid!=. & anb_id_addid!=. & year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
tab filter_wproay

// tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
*positive, significant
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*positive, significant

// reg proa_ycsh singleb i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
// reg proa_ycsh singleb i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*singleb works
********************************************************************************
*supplier dependence on buyer

// tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
// ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
*negative insign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
*pos. insign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
*pos. sign.

// reg w_ycsh singleb i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
// reg w_ycsh singleb i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*works for all, except singleb

// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
********************************************************************************
*advertisement period

// sum submp 
// sum submp if filter_ok
// tab submp
// hist submp if filter_ok
// hist submp if filter_ok==1 & submp<50
// hist submp if filter_ok==1 & submp<40, discrete xlabel(0(5)40)
*peaks at 7 and 14 and at 21 days
// hist submp if filter_ok==1 & submp<50, by(ca_procedure)
*strange, negotiated without publication has submission period...

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
replace submp10=99 if submp10==.

// tab submp5
// tab submp10
// tab submp10 nocft
// sum submp if nocft==1
*no overlaps

// tabstat submp, by(submp10) stat(min max N)
// tabstat submp, by(submp5) stat(min max N)
*1-9 categories are between 1-29days

gen submp3=.
replace submp3=1 if submp<7 & submp!=.
replace submp3=2 if submp>=7 & submp<21 & submp!=.
replace submp3=3 if submp>=21 & submp!=.
replace submp3=99 if submp==.
// tab submp3 if filter_ok,m 

// logit singleb submp i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
// logit singleb ib3.submp3 i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*lowest category works!
// logit singleb ib4.submp5 i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
// logit singleb ib5.submp10 i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
// logit singleb i.submp5#i.corr_proc i.corr_desc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*no clear pattern

gen corr_submp=submp3
replace corr_submp=0 if submp3==2 | submp3==3
// tab submp3 corr_submp

// logit singleb i.corr_submp i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
********************************************************************************
*** final best regression and valid red flags

// logit singleb i.corr_ben i.corr_submp i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1, base
*26.23% explanatory power

// reg proa_ycsh singleb i.corr_ben i.corr_submp i.corr_desc i.corr_proc i.ca_contract_value10 i.anb_type i.year i.ca_type if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
*all works except corr_descr, 28.84% expl. power
********************************************************************************
*CRI generation

// sum singleb corr_submp corr_proc corr_desc corr_ben proa_ycsh if filter_ok==1
*nocft is not valid, but we keep it in as the data is imperfect for validation
// *corr_ben is partially valid on single bidding and fully valid in spending concentratoin regressions
// tab singleb, m
// tab corr_desc, m
// tab corr_proc, m //binarisation
// tab corr_ben, m //binarisation
// tab corr_submp, m

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
// tab corr_proc_bi corr_proc

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh

do "${utility_codes}/cri.do" singleb corr_proc_bi corr_submp corr_ben_bi proa_ycsh4
rename cri cri_in


sum cri_in if filter_ok==1
// hist cri_in if filter_ok==1, title("CRI IN, filter_ok")
// hist cri_in if filter_ok==1, by(year, noiy title("CRI IN (by year), filter_ok")) 
********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END