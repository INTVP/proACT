local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*CRI components
*12 components - proc, decp, submp, nocft, singleb, taxhav, supplier share, benford, selection method, award criteria count, contract modification, published documents
********************************************************************************
*Procedure type

// tab tender_proceduretype, missing
// tab tender_nationalproceduretype, missing
********************************************************************************
*Submission period
*submission period = bid deadline -first or last call for tender

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
// sum submp
// hist submp
// hist submp, by(tender_proceduretype)
// sum submp, det  

// sum submp if submp>365
// sum submp if submp>183
// sum submp if submp>125
// sum submp if submp>100

replace submp=. if submp>183
********************************************************************************
*decision period = contract award or similar - deadline

// sum aw_date ca_date bid_deadline

gen decp=aw_date - bid_deadline
replace decp=. if decp<=0
// sum decp
// hist decp

// sum decp if decp>365
// sum decp if decp>183
// sum decp if decp>100
// hist decp if decp<365
// hist decp if decp<183
// tab decp if decp>365 //take one year as an upper bound

replace decp=. if decp>365
lab var decp "decision period"
********************************************************************************
*singlebidding

// sum tender_recordedbidscount lot_bidscount if filter_ok==1
gen singleb=.
replace singleb=0 if lot_bidscount!=1 & lot_bidscount!=.
replace singleb=1 if lot_bidscount==1
tab singleb
tab singleb if filter_ok , missing  //42.99% singlebidding
********************************************************************************
*no/yes cft

*gen yescft=(!missing(notice_url))
*tab yescft if filter_ok, m
*Don't use the notice url but sub period to determine if a cft was published
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft if filter_ok, m

// tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing
********************************************************************************
*Tax haven

gen iso = bidder_country
do "${utility_codes}/country-to-iso.do" iso
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
// tab bidder_country, missing

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="ES" | bidder_country==""
// tab fsuppl, missing

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
// tab taxhav, missing
// tab bidder_country if taxhav==1 & fsuppl==1
replace taxhav = 0 if bidder_country=="US" //removing the US

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"
// tab taxhav2, missing
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

// sum ca_contract_value if filter_ok==1
rename bidder_name bidder_name_orig
gen bidder_name=lower(bidder_name_orig)

egen w_id_gen=group(bidder_name)
label var w_id_gen "generated company ID"

rename buyer_name buyer_name_orig
gen buyer_name=lower(buyer_name_orig)

egen anb_id_gen=group(buyer_name)
label var anb_id_gen "generated buyer ID"

rename buyer_id buyer_id_orig
rename anb_id_gen buyer_id

egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_id_gen!=. & tender_year!=., by (w_id_gen tender_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & buyer_id!=. & w_id_gen!=. & tender_year!=., by(buyer_id w_id_gen tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(w_id_gen tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

gen x=1
egen w_ynrc=total(x) if filter_ok==1 & w_id_gen!=. & tender_year!=., by(w_id_gen tender_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & buyer_id!=. & tender_year!=., by(buyer_id tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort w_id_gen tender_year aw_date
egen filter_wy = tag(w_id_gen tender_year) if filter_ok==1 & w_id_gen!=. & tender_year!=.
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort w_id_gen
egen filter_w = tag(w_id_gen) if filter_ok==1 & w_id_gen!=.
lab var filter_w "Marking Winners"
// tab filter_w

sort w_id_gen buyer_id
egen filter_wproa = tag(w_id_gen buyer_id) if filter_ok==1 & w_id_gen!=. & buyer_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort tender_year w_id_gen buyer_id
egen filter_wproay = tag(tender_year w_id_gen buyer_id) if filter_ok==1 & w_id_gen!=. & buyer_id!=. & tender_year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay
********************************************************************************
* buyer spending concentration

egen proa_yam=sum(ca_contract_value) if filter_ok==1 & buyer_id!=. & tender_year!=., by(buyer_id tender_year) 
lab var proa_yam "By PA-tender_year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-tender_year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(buyer_id tender_year)
lab var proa_mycsh "By PA-tender_year: Max share spent on one supplier"

gsort buyer_id +tender_year +aw_date
egen filter_proay = tag(buyer_id tender_year) if filter_ok==1 & buyer_id!=. & tender_year!=.
lab var filter_proay "Marking PA tender_years"
// tab filter_proay

sort buyer_id
egen filter_proa = tag(buyer_id) if filter_ok==1 & buyer_id!=.
lab var filter_proa "Marking PAs"
// tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_id!=., by(buyer_id)
drop x
lab var proa_nrc "#Contracts by PAs"
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
//     rename bid_price ca_contract_value //bid price variable
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
rename buyer_id buyer_masterid
save "$country_folder/buyers_benford.dta", replace
************************************************
use "${country_folder}/`country'_wip.dta", clear
rename buyer_id_old buyer_id
merge m:1 buyer_masterid using "${country_folder}/buyers_benford.dta"
drop if _m==2
drop _m

// br buyer_id MAD MAD_conformitiy
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
********************************************************************************
*published documents
// tab tender_documents_count
*67.98% has 0 published documents
********************************************************************************
*CRI components validation

*controls only

// sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid
// sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid if filter_ok==1
*1,760,300
*all variables have missings, half of buyer type is missing 
replace anb_type=9 if anb_type==.
replace ca_type=99 if ca_type==.
replace anb_loc=999 if anb_loc==.

// tab anb_loc if filter_ok==1

// logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid, base
// logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************
*procedure types

// tab tender_proceduretype
// tab tender_proceduretype if filter_ok==1
encode tender_proceduretype,gen(ca_procedure)

// logit singleb i.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_proc=.
replace corr_proc=0 if ca_procedure<=3 | ca_procedure==10 | ca_procedure==13
replace corr_proc=1 if ca_procedure==4 | ca_procedure==7 | ca_procedure==9 | ca_procedure==12
replace corr_proc=2 if ca_procedure==5 | ca_procedure==6 | ca_procedure==8 | ca_procedure==11
replace corr_proc=99 if ca_procedure==. |  corr_proc==. 
tab ca_procedure corr_proc, missing

// logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*nocft

// tab nocft if filter_ok==1
*80% of the contracts had no call for tenders
// tab ca_procedure nocft if filter_ok==1
// tab corr_proc nocft if filter_ok==1

// logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*as expected
********************************************************************************
*selection method

// tab tender_selectionmethod if filter_ok==1
// tab tender_selectionmethod ca_procedure if filter_ok==1, missing
// encode tender_selectionmethod,gen(ten_select)
// replace ten_select=99 if ten_select==.
//
// logit singleb i.ten_select i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
//
// gen corr_crit=.
// replace corr_crit=0 if ten_select==2
// replace corr_crit=1 if ten_select==1
// replace corr_crit=99 if ten_select==99
//
// logit singleb i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// *ok
********************************************************************************
*advertisement period

// sum submp
// tab submp
// hist submp

// hist submp, by(ca_procedure)
*dps, outright award and inovation partnership has only 1-2 observations   

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

// logit singleb submp i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp5 i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp10 i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib6.submp10 i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp10#i.corr_proc i.nocft i.corr_crit ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp5#i.corr_proc i.nocft i.corr_crit ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_submp=.
replace corr_submp=0 if submp10>=6 & submp10!=99 
replace corr_submp=1 if submp10<=5 & submp10!=99 
replace corr_submp=99 if submp10==99 | submp10==.
// tab submp10 corr_submp, missing
// tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

// logit singleb i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*decision making period

// sum decp
// hist decp

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.
xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==. | decp10==.
// tab decp5
// tab decp10
// tabstat decp, by(decp10) stat(min max mean N)
// tabstat decp, by(decp5) stat(min max mean N)

// logit singleb decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.decp5 i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.decp10 i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib5.decp10 i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib4.decp5 i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_decp=.
replace corr_decp=0 if decp10>=6 & decp10!=99
replace corr_decp=1 if decp10>=3 & decp10<=5 & decp10!=99
replace corr_decp=2 if decp10<=2 & decp10!=99
replace corr_decp=99 if decp==. | corr_decp==.

// logit singleb i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*award criteria count
// tab tender_awardcriteria_count
// *59.45% 0
//
// xtile ten_awcrit5=tender_awardcriteria_count if filter_ok==1, nquantiles(5)
// replace ten_awcrit5=99 if tender_awardcriteria_count==.
//
// xtile ten_awcrit3=tender_awardcriteria_count if filter_ok==1, nquantiles(3)
// replace ten_awcrit3=99 if tender_awardcriteria_count==.
//
// logit singleb tender_awardcriteria_count i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.ten_awcrit5 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.ten_awcrit3 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// *more specificatons decrease singlebidding risk
********************************************************************************
*contract modification

// tab tender_corrections_count if filter_ok==1
// *little variance, 99.16% of tenders have no modification
//
// *published documents
// tab tender_documents_count
// *67.98% has 0 published documents
//
// gen ten_doc4=0 if tender_documents_count==0
// replace ten_doc4=1 if tender_documents_count==1
// replace ten_doc4=2 if tender_documents_count>=2 & tender_documents_count<=8
// replace ten_doc4=3 if tender_documents_count>=8
// replace ten_doc4=99 if tender_documents_count==.
//
// gen ten_doc3=0 if tender_documents_count==0
// replace ten_doc3=1 if tender_documents_count==1
// replace ten_doc3=2 if tender_documents_count>=2
// replace ten_doc3=99 if tender_documents_count==.
//
// logit singleb i.ten_doc4 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib3.ten_doc4 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.ten_doc3 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib2.ten_doc3 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
//
// gen corr_doc=1 if ten_doc3==0
// replace corr_doc=0 if ten_doc3!=0 & ten_doc3!=99
// replace corr_doc=99 if ten_doc3==99
//
// logit singleb i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************
*benford's law

// logit singleb i.corr_ben i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib2.corr_ben i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_ben2=0 if corr_ben==2 | corr_ben==0
replace corr_ben2=2 if corr_ben==1
replace corr_ben2=99 if corr_ben==. | corr_ben==99
cap drop corr_ben
rename corr_ben2 corr_ben
// logit singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*tax haven

// tab taxhav if filter_ok==1
// tab taxhav2 if filter_ok==1
// tab taxhav2 if filter_ok==1 & fsuppl==1

// ttest singleb if filter_ok==1 & fsuppl==1, by(taxhav2)
*negative, sign

// ttest corr_proc if filter_ok==1 & fsuppl==1, by(taxhav2)
*negative, sign

// ttest w_mycsh if filter_ok==1 & fsuppl==1 & filter_wy==1 & w_ynrc>2 & w_ynrc!=., by(taxhav2)
*positive, insignificant, few obs
********************************************************************************
*supplier dependence on buyer

// tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
// ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
// *negative sign.

// reg w_ycsh singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
// reg w_ycsh singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*singleb, corr_crit, procedure category1 works

// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
********************************************************************************
*buyer spending concentration

// tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
// *positive, significant
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*positive, significant

// reg proa_ycsh singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
// reg proa_ycsh singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
// *singleb, benford, decision period works
********************************************************************************
*** final best regression and valid red flags

// logit singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// *30.18% explanatory power

// reg proa_ycsh singleb i.corr_ben2 i.corr_doc i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
*singleb, corr_ben, corr_decp works, 16.26% expl. power

********************************************************************************
*CRI generation

// sum singleb corr_proc corr_submp nocft corr_decp corr_crit corr_doc corr_ben2 taxhav2 proa_ycsh if filter_ok==1
// tab singleb, m
// tab corr_doc, m
// tab corr_proc, m //binarisation
// tab corr_submp, m
// tab corr_decp, m //binarisation
// tab corr_crit, m
// tab corr_ben2, m //binarisation
// tab nocft, m
// tab taxhav2, m

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
// tab corr_proc_bi corr_proc

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
// tab corr_decp_bi corr_decp

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh

do $utility_codes/cri.do singleb corr_proc_bi corr_submp nocft corr_decp_bi corr_ben_bi taxhav2 proa_ycsh4
rename cri cri_es

// sum cri_es if filter_ok==1
// hist cri_es if filter_ok==1, title("CRI ES, filter_ok")
// hist cri_es if filter_ok==1, by(tender_year, noiy title("CRI ES (by year), filter_ok")) 
********************************************************************************

save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END