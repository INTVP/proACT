local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*CRI components
*12 components - proc, decp, submp, nocft, singleb, taxhav, supplier share, benford, selection method, award criteria count, contract modification, published documents
************************************
*Procedure type
// tab tender_proceduretype, missing
// tab tender_nationalproceduretype, missing
************************************
*Submission period

*submission period = bid deadline -first or last call for tender

// sum bid_deadline first_cft_pub last_cft_pub

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
// sum submp
// hist submp
// hist submp, by(tender_proceduretype)
// sum submp, det  

// sum submp if submp<365 & filter_ok==1
// sum submp if submp<183 & filter_ok==1
// sum submp if submp>365
// sum submp if submp>183
// sum submp if submp>125
// sum submp if submp>100

replace submp=. if submp>183
************************************

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
******************************************
*singlebidding
// sum tender_recordedbidscount lot_bidscount if filter_ok==1
gen singleb=.
replace singleb=0 if lot_bidscount!=1 & lot_bidscount!=.
replace singleb=1 if lot_bidscount==1
// tab singleb
// tab singleb if filter_ok , missing 
******************************************

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
******************************************
*Tax haven
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
// tab bidder_country, missing

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="GR" | bidder_country==""
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
******************************************

*Winning Supplier's contract share (by PE, by year)

// sum ca_contract_value if filter_ok==1
rename bidder_name bidder_name_orig
gen bidder_name=lower(bidder_name_orig)

egen w_id_gen=group(bidder_name)
label var w_id_gen "generated company ID"
replace bidder_name=proper(bidder_name)

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

/*
tab w_ynrc if filter_wy==1
hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.
*/
******************************************

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

cap drop x
gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_id!=., by(buyer_id)
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
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year w_id_gen "`country'"

*Generate market share {bid_price ppp version}
do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
do "${utility_codes}/gen_is_capital.do" "`country'" buyer_city buyer_nuts  tender_addressofimplementation_n

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
********************************************************************************
*Benford's law export
rename buyer_id buyer_id_old
save "${country_folder}/`country'_wip.dta", replace

preserve
    rename buyer_masterid buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_id: gen count = _N
    keep if count >100
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
	export delimited  "${country_folder}/buyers_for_R.csv", replace
	! "${R_path_local}" "${utility_codes}/benford.R" "${country_folder}"
restore
************************************************
use $country_folder/buyers_benford, clear
rename buyer_id buyer_masterid
save $country_folder/buyers_benford.dta, replace
************************************************

use "${country_folder}/`country'_wip.dta", clear
rename buyer_id_old buyer_id

merge m:1 buyer_masterid using "$country_folder/buyers_benford.dta"
drop _m

// br buyer_id MAD MAD_conformitiy
// tab MAD_conformitiy, m
// tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — 0.003583 to 0.0058504
Acceptable conformity — 0.0061228 to 0.0116564
Marginally acceptable conformity — 0.0138452 to 0.0142697
Nonconformity — greater than 0.0151962
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
// tab corr_ben if filter_ok
********************************************************************************
*published documents

// tab tender_documents_count
*77.09% has 0 published documents
********************************************************************************
*CRI components validation

*controls only

// sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid
// sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid if filter_ok==1
*1,760,300
*all variables have missings, half of buyer type is missing 
replace anb_type=9 if anb_type==.
replace ca_type=99 if ca_type==.
replace anb_loc=99 if anb_loc==.
*too few, mostly empty

// tab anb_loc if filter_ok==1

// logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid, base
// logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*number of obs = 49,276, Pseudo R2 = 0.2368
********************************************************************************
*procedure types

// tab tender_proceduretype
// tab tender_proceduretype if filter_ok==1
encode tender_proceduretype,gen(ca_procedure)

// logit singleb i.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib6.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
 
gen corr_proc=.
replace corr_proc=0 if ca_procedure==1 | ca_procedure==6 | ca_procedure==7
replace corr_proc=1 if ca_procedure==3 | ca_procedure==5
replace corr_proc=2 if ca_procedure==4
replace corr_proc=2 if ca_procedure==. |  corr_proc==. 
// tab ca_procedure corr_proc, missing

// logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*nocft

// tab nocft if filter_ok==1
*80% of the contracts had no call for tenders
// tab ca_procedure nocft if filter_ok==1
// tab corr_proc nocft if filter_ok==1

// logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*counterint.

// logit singleb i.nocft##i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*works for corr_proc=2
// tab nocft corr_proc if filter_ok

gen corr_nocft=0
replace corr_nocft=1 if nocft==1 & corr_proc==2

// logit singleb i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*remains insignificant
********************************************************************************
*selection method

// tab tender_selectionmethod if filter_ok==1
// tab tender_selectionmethod ca_procedure if filter_ok==1, missing
encode tender_selectionmethod, gen(ten_select)
replace ten_select=99 if ten_select==.

// logit singleb i.ten_select i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_crit=.
replace corr_crit=0 if ten_select==1
replace corr_crit=1 if ten_select==2
replace corr_crit=99 if ten_select==99

// logit singleb i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*advertisement period
// sum submp
// tab submp
// hist submp
*peaks at around 10 and 35 days
// hist submp, by(ca_procedure)
*dps, outright award and inovation partnership has only 1-2 observations   

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==. | submp5==.
// xtile submp10=submp if filter_ok==1, nquantiles(10)
// replace submp10=99 if submp==.
// replace submp10=99 if submp10==.

// tab submp5
// tab submp10
// tab submp10 nocft
// sum submp if nocft==1
*no overlaps

// tabstat submp, by(submp10) stat(min max N)
// tabstat submp, by(submp5) stat(min max N)

// logit singleb submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp5 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp10 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib10.submp10 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp10#i.corr_proc i.corr_crit i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.submp5#i.corr_proc i.corr_crit i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base


gen corr_submp=.
replace corr_submp=0 if submp5>=4 & submp5!=99 
replace corr_submp=1 if submp5<=3 & submp5!=99 
replace corr_submp=99 if submp5==99 | submp5==.
// tab submp5 corr_submp, missing
// tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

// logit singleb i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*decision making period

// sum decp
// hist decp

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.
// xtile decp10=decp if filter_ok==1, nquantiles(10)
// replace decp10=99 if decp==. | decp10==.
// tab decp5
// tab decp10
// tabstat decp, by(decp10) stat(min max mean N)
// tabstat decp, by(decp5) stat(min max mean N)

// logit singleb decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.decp5 i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.decp10 i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib5.decp10 i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb ib4.decp5 i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_decp=.
replace corr_decp=0 if decp5>=3 & decp5!=99
replace corr_decp=1 if decp5==2 & decp5!=99
replace corr_decp=2 if decp5==1 & decp5!=99
replace corr_decp=99 if decp==. | corr_decp==.
// tab decp5 corr_decp if filter_ok

logit singleb i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*award criteria count
// tab tender_awardcriteria_count
*8.74% 0, 80.36% 1

xtile ten_awcrit5=tender_awardcriteria_count if filter_ok==1, nquantiles(5)
replace ten_awcrit5=99 if tender_awardcriteria_count==.

gen ten_awcrit3=0 if filter_ok==1 & tender_awardcriteria_count==0
replace ten_awcrit3=1 if filter_ok==1 & tender_awardcriteria_count==1  
replace ten_awcrit3=2 if filter_ok==1 & tender_awardcriteria_count>1  
replace ten_awcrit3=99 if filter_ok==1 & tender_awardcriteria_count==.  
// tab ten_awcrit3

// logit singleb tender_awardcriteria_count i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.ten_awcrit5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.corr_nocft i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// logit singleb i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.corr_nocft i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*more specificatons increase singlebidding risk
********************************************************************************
*contract modification
// tab tender_corrections_count if filter_ok==1
*little variance, 96.49% of tenders have no modification
********************************************************************************
*published documents
// tab tender_documents_count if filter_ok==1
*84.66% has 0 published documents

gen ten_doc2=0 if tender_documents_count==0
replace ten_doc2=1 if tender_documents_count>0
replace ten_doc2=99 if tender_documents_count==.

// logit singleb i.ten_doc2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*more docs increase singleb
********************************************************************************
*benford's law
// tab corr_ben
// logit singleb i.corr_ben i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocfti.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_ben2=corr_ben
replace corr_ben2=1 if corr_ben==2
replace corr_ben2=99 if corr_ben==. | corr_ben==99

cap drop corr_ben
rename corr_ben2 corr_ben
// logit singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*tax haven

// tab taxhav if filter_ok==1
// tab taxhav2 if filter_ok==1
// tab taxhav2 if filter_ok==1 & fsuppl==1

// ttest singleb if filter_ok==1 & fsuppl==1, by(taxhav2)
*positive, insign

// ttest corr_proc if filter_ok==1 & fsuppl==1, by(taxhav2)
*positive, insign

// ttest w_mycsh if filter_ok==1 & fsuppl==1 & filter_wy==1 & w_ynrc>2 & w_ynrc!=., by(taxhav2)
*empty

*supplier dependence on buyer
// tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
// ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
// *negative sign.
// ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
// *negative sign.

// reg w_ycsh singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
// reg w_ycsh singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
// *singleb, corr_ben, submp works, others parially work

// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
// hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
*******************************************************************************
*buyer spending concentration
// tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
// *positive, significant
// ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*positive, significant

// reg proa_ycsh singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
// reg proa_ycsh singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
// *singleb, benford, decision, submission period works

// gen corr_proc_bi=corr_proc
// replace corr_proc_bi=1 if corr_proc==2

cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if ca_procedure==1 | ca_procedure==6 | ca_procedure==7
replace corr_proc=1 if ca_procedure==3 | ca_procedure==5
replace corr_proc=1 if ca_procedure==4
replace corr_proc=1 if ca_procedure==. |  corr_proc==. 
********************************************************************************
*** final best regression and valid red flags
// logit singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc_bi i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
// *26.59% explanatory power
//
// reg proa_ycsh singleb i.corr_ben2 i.ten_awcrit3 i.corr_decp i.corr_submp i.corr_crit i.corr_nocft i.corr_proc_bi i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
// *singleb, benford, criteria, decision, submission period works, 35.99%
********************************************************************************
*CRI calculation

// sum singleb corr_proc_bi nocft corr_submp corr_decp corr_crit ten_awcrit3 corr_ben2 proa_ycsh if filter_ok==1

// tab singleb, m
// tab ten_awcrit3, m //binarisation
// tab corr_proc_bi, m
// tab corr_submp, m
// tab corr_decp, m //binarisation
// tab corr_crit, m
// tab corr_ben, m

// gen corr_awcrit=99
// replace corr_awcrit=ten_awcrit3/2 if ten_awcrit3!=99
// tab corr_awcrit ten_awcrit3

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
tab corr_decp_bi corr_decp

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh

do $utility_codes/cri.do singleb corr_nocft corr_proc corr_submp corr_decp_bi corr_ben_bi proa_ycsh4 
rename cri cri_gr

// sum cri_gr if filter_ok==1
// hist cri_gr if filter_ok==1, title("CRI GR, filter_ok")
// hist cri_gr if filter_ok==1, by(tender_year, noiy title("CRI GR (by year), filter_ok")) 
********************************************************************************

save "${country_folder}/`country'__wb_2011.dta", replace
********************************************************************************
*END