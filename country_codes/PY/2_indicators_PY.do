local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data
use "${country_folder}//`country'_wip.dta", clear
********************************************************************************
*Winner dependence on buyer

// sum ca_contract_value

egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_masterid!=. & year!=., by (w_masterid year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & anb_masterid!=. & w_masterid!=. & year!=., by(anb_masterid w_masterid year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(w_masterid year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

cap drop x	
gen x=1
egen w_ynrc=total(x) if filter_ok==1 & w_masterid!=. & year!=., by(w_masterid year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & anb_masterid!=. & year!=., by(anb_masterid year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort w_masterid year ca_date_first
egen filter_wy = tag(w_masterid year) if filter_ok==1 & w_masterid!=. & year!=.
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort w_masterid
egen filter_w = tag(w_masterid) if filter_ok==1 & w_masterid!=.
lab var filter_w "Marking Winners"
// tab filter_w

sort w_masterid anb_masterid
egen filter_wproa = tag(w_masterid anb_masterid) if filter_ok==1 & w_masterid!=. & anb_masterid!=.
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort year w_masterid anb_masterid
egen filter_wproay = tag(year w_masterid anb_masterid) if filter_ok==1 & w_masterid!=. & anb_masterid!=. & year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay

// tab w_ynrc if filter_wy==1
// hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
// sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
// sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.
*spectacularly high values, huge concentration, probably represents the great concentration of buying power, few large ministries and a large supplier pool
********************************************************************************
* Buyer spending concentration

egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_masterid!=. & year!=., by(anb_masterid year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_masterid year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_masterid +year +ca_date_first
egen filter_proay = tag(anb_masterid year) if filter_ok==1 & anb_masterid!=. & year!=.
lab var filter_proay "Marking PA years"
// tab filter_proay

sort anb_masterid
egen filter_proa = tag(anb_masterid) if filter_ok==1 & anb_masterid!=.
lab var filter_proa "Marking PAs"
// tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & anb_masterid!=., by(anb_masterid)
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
*very small concentrations from the buyer's perspective
********************************************************************************
*Tax haven

decode w_country, gen(iso)
do "${utility_codes}/country-to-iso.do" iso
merge m:1 iso using "${utility_data}/FSI_wide_200812_fin.dta"
lab var iso "supplier country ISO"
drop if _merge==2
drop _merge
gen sec_score = sec_score2009 if year<=2009
replace sec_score = sec_score2011 if (year==2010 | year==2011) & sec_score==.
replace sec_score = sec_score2013 if (year==2012 | year==2013) & sec_score==.
replace sec_score = sec_score2015 if (year==2014 | year==2015) & sec_score==.
replace sec_score = sec_score2017 if (year==2016 | year==2017) & sec_score==.
replace sec_score = sec_score2019 if (year==2018 | year==2019 | year==2020) & sec_score==.
lab var sec_score "supplier country Secrecy Score (time varying)"
// sum sec_score
drop sec_score1998-sec_score2019
// tab w_country, missing
decode w_country, gen(w_country_str)
gen fsuppl=1 
replace fsuppl=0 if w_country_str=="PY" | w_country==.
// tab fsuppl, missing
drop w_country_str
*very few foreign companies

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
// tab taxhav, missing
// tab w_country if taxhav==1 & fsuppl==1
*there are no cases, sec_score is missing for relevant countries

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"
// tab taxhav2, missing
********************************************************************************
*Submission period 

cap drop submp
gen submp =bid_deadline-first_cft_pub
replace submp=. if submp<=0
replace submp=. if submp>365 //cap submission period to 1 year
label var submp "advertisement period"
// hist submp
********************************************************************************
*No cft

*Method 1 
cap drop yescft nocft
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft if filter_ok, m
// tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing
*drop nocft yescft
********************************************************************************
*Decision Period 

cap drop decp
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
********************************************************************************
*Procedure type 

// tab tender_proceduretype, m //missing
// tab tender_nationalproceduretype, m
*tender_proceduretype missing, used nationalproceduretype
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "ó", "o", .) 
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "ú", "u", .) 
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ó", "o", .) 

gen ca_procedure=.
replace ca_procedure=2 if tender_nationalproceduretype=="Acuerdo Internacional"
replace ca_procedure=2 if tender_nationalproceduretype=="Acuerdo Nacional"
replace ca_procedure=4 if tender_nationalproceduretype=="BID - Concurso de Ofertas (CO/CP)"
replace ca_procedure=1 if tender_nationalproceduretype=="BID - Contratacion Directa (CD/SD)"
replace ca_procedure=1 if tender_nationalproceduretype=="BID - Contratacion por Excepcion"
replace ca_procedure=2 if tender_nationalproceduretype=="BID - Licitacion Internacional"
replace ca_procedure=3 if tender_nationalproceduretype=="BID - Licitacion Publica Nacional"
replace ca_procedure=5 if tender_nationalproceduretype=="BID - Locacion de Inmuebles"
replace ca_procedure=4 if tender_nationalproceduretype=="BM - Concurso de Ofertas - CO"
replace ca_procedure=1 if tender_nationalproceduretype=="BM - Contratacion Directa - CD"
replace ca_procedure=1 if tender_nationalproceduretype=="BM - Contratacion por Excepcion - CE"
replace ca_procedure=3 if tender_nationalproceduretype=="BM - Licitacion Publica Internacional - LPI"
replace ca_procedure=3 if tender_nationalproceduretype=="BM - Licitacion Publica Nacional - LPN"
replace ca_procedure=1 if tender_nationalproceduretype=="CD_SBE_DNCP_BID - CONTRATACIoN DIRECTA POR SBE SISTEMA NACIONAL BID PARA BIENES COMUNES"
replace ca_procedure=4 if tender_nationalproceduretype=="Concurso de Ofertas"
replace ca_procedure=1 if tender_nationalproceduretype=="Contratacion Directa"
replace ca_procedure=1 if tender_nationalproceduretype=="Contratacion por Excepcion"
replace ca_procedure=4 if tender_nationalproceduretype=="LCO_DNCP_BID_OBRAS - LICITACIoN POR CONCURSO DE OFERTA SISTEMA NACIONAL BID OBRAS SIMPLES"
replace ca_procedure=4 if tender_nationalproceduretype=="LCO_SBE_DNCP_BID - LICITACIoN POR CONCURSO DE OFERTA POR SBE SISTEMA NACIONAL BID BIENES COMUNES"
replace ca_procedure=3 if tender_nationalproceduretype=="LPN_SBE_DNCP_BID - LICITACIoN PUBLICA NACIONAL POR SBE SISTEMA NACIONAL BID BIENES COMUNES"
replace ca_procedure=3 if tender_nationalproceduretype=="Licitacion Publica Internacional"
replace ca_procedure=3 if tender_nationalproceduretype=="Licitacion Publica Nacional"
replace ca_procedure=5 if tender_nationalproceduretype=="Locacion de Inmuebles"

label define ca_procedure 1"direct contracting" 2"limited" 3"open auction" 4"open within threshold" 5"other" 99"missing", replace
lab values ca_procedure ca_procedure
label var ca_procedure "type of procurement procedure followed"
label values ca_procedure ca_procedure

// tab ca_procedure, missing
********************************************************************************
*Checking Validity & Generating corruption risk indicators
********************************************************************************
*Single bidding 

bysort tender_id w_masterid: gen unique_company_per_tender=_n==1
replace unique_company_per_tender=. if w_masterid==.

bysort tender_id: egen ca_bids_new=total(unique_company_per_tender)
bysort tender_id: egen awarded_companies_per_tender=total(iswinningbid)

gen competitionlevel=ca_bids_new/awarded_companies_per_tender
replace competitionlevel=. if iswinningbid==.

gen singleb=1 if competitionlevel==1
replace singleb=0 if competitionlevel>1 & competitionlevel!=.

// tab singleb, missing
*14.05% single bidding, 21.6% missing
// tab singleb if iswinningbid==1, missing

lab var singleb "single-bid red flag"
// tab singleb, m

// tab singleb, missing
replace singleb=. if year<2013  //data glitch with singleb before 2013
*4.88% single bidding, 30.35% missing

lab var singleb "single-bid red flag"
// tab year singleb , m
*Controls only
// sum singleb anb_type  year market_id ca_contract_value10 anb_location if filter_ok
// logit singleb  i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
//R2: 10.14% - 86,916 obs

*******************************************************************************

*Use cpv_div instead of market
encode cpv_div, gen(cpv_div_num)

// sum singleb anb_type lca_contract_value year cpv_div_num
// sum singleb anb_type lca_contract_value year cpv_div_num if filter_ok==1
//
// logit singleb lca_contract_value i.anb_type i.year i.cpv_div_num, base
// logit singleb lca_contract_value i.anb_type i.year i.cpv_div_num if filter_ok==1, base
*******************************************************************************
*Procedure Types

// br *proc*
// br tender_nationalproceduretype, ca_procedure
// tab ca_procedure if filter_ok==1, m
label list ca_procedure

*from dfif_py_cri_191119.do
cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if ca_procedure==3 | ca_procedure==2
replace corr_proc=1 if ca_procedure==4 
replace corr_proc=2 if ca_procedure==1 | ca_procedure==5
replace corr_proc=99 if ca_procedure==.
// tab corr_proc if filter_ok, m

// logit singleb i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Valid
*******************************************************************************
*A second version for corr_proc without open within treshold as a risky category

// count if missing(tender_proceduretype) // all missing - drop
drop tender_proceduretype

label list ca_procedure
gen tender_proceduretype = ""
replace tender_proceduretype = "OUTRIGHT_AWARD" if inlist(ca_procedure,1)
replace tender_proceduretype = "OPEN" if inlist(ca_procedure,3,4)
replace tender_proceduretype = "OTHER" if inlist(ca_procedure,5)
replace tender_proceduretype = "RESTRICTED" if inlist(ca_procedure,2)
replace tender_proceduretype = "" if inlist(ca_procedure,99) | missing(ca_procedure) | ca_procedure==.
// tab tender_proceduretype ca_procedure, m

*Old code (Excluding the open wthin threshold)
label list ca_procedure

// logit singleb ib3.ca_procedure i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Based on regressions 
*Level 1 risk - OUTRIGHT_AWARD
*Level 2 risk - OTHER, NA  

label list ca_procedure
cap drop corr_proc2
gen corr_proc2=.
replace corr_proc2=0 if inlist(ca_procedure,3,4,2) 
replace corr_proc2=1 if inlist(ca_procedure,1) 
replace corr_proc2=2 if inlist(ca_procedure,5)
replace corr_proc2=99 if ca_procedure==.
// tab ca_procedure corr_proc2, m
// tab corr_proc2, m
	
// logit singleb i.corr_proc2 i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*valid R2 12.29% , 86,916 obs
*******************************************************************************
*Submission Period

// tabstat submp if filter_ok, stat(mean media) //mean 51.57 days , med 31
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
// tabstat submp, by(submp10) stat(min mean max)

*Thresholds from dfif_py_cri_191119.do (older code)
gen corr_submp=0
replace corr_submp=1 if (submp10>=2 & submp10<=5 & submp10!=3) & corr_proc==0
replace corr_submp=2 if (submp10==1 | submp10==6 | submp10==7) & corr_proc==0
replace corr_submp=99 if submp10==99
// tab submp10 corr_submp, missing
// tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

// logit singleb i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Works!
*******************************************************************************
*no cft

// logit singleb i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*OK
*******************************************************************************
*Decision Period

// sum decp
// hist decp

xtile decp25=decp if filter_ok==1, nquantiles(25)
replace decp25=99 if decp==.
// tabstat decp if filter_ok, stat(mean media) //mean 74.1 days , med 35
// tabstat decp, by(decp25) stat(n min mean max)

*Thresholds from dfif_py_cri_191119.do (older code)
gen corr_decp=.
replace corr_decp=0 if decp25>=20 & decp25!=.
replace corr_decp=1 if decp25>=8 & decp25<=19 & decp25!=.
replace corr_decp=2 if decp25>=1 & decp25<=7 & decp25!=.
replace corr_decp=99 if decp==.
// tab decp25 corr_decp if filter_ok, missing

// logit singleb i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Works
*******************************************************************************
*Winning Supplier's contract share (by PE, by year)  

// checking contract share
// reg w_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & w_ynrc>2 & w_ynrc!=., base
// //+*singleb,proc,decp,subp  (omitted)corr_nocft  -  nocft remains but is not significant
// reg w_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & w_ynrc>4 & w_ynrc!=., base
// //+*singleb,proc,decp,subp  (omitted)corr_nocft  -  nocft remains but is -ve significant
// reg w_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & w_ynrc>9 & w_ynrc!=., base
// +*singleb,,decp,subp  (omitted)corr_nocft (not sign) proc -  nocft remains but is not significant

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// sum w_ycsh4 w_ycsh
*******************************************************************************
*Buyer dependence on supplier 

*validation 
// reg proa_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & proa_ynrc>2 & proa_ynrc!=., base
// //+*singleb,proc,decp  (omitted)corr_nocft (not sig)subp,nocft  -  nocft remains but is not significant
// reg proa_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & proa_ynrc>4 & proa_ynrc!=., base
// //+*singleb,proc,decp  (omitted)corr_nocft (not sig)subp,nocft  -  nocft remains but is not significant
// reg proa_ycsh singleb i.taxhav3 i.corr_decp i.corr_submp i.nocft i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & proa_ynrc>9 & proa_ynrc!=., base
// //+*singleb,proc,decp  (omitted)corr_nocft (not sig)subp,nocft  -  nocft remains but is not significant

*Significance dec for proc, and decp as proa_ynrc increases

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh
*******************************************************************************
*Benford's

*anb_masterid  if the main id
// br *anb_name anb_id anb_masterid
decode anb_masterid, gen(anb_masterid_str)
// sort anb_masterid_str 
// format anb_masterid_str anb_name %12s
// br anb_masterid_str anb_name
*******************************************************************************
save "${country_folder}/`country'_wip.dta", replace
*******************************************************************************
preserve
    rename anb_masterid_str buyer_id //buyer id variable
    *rename bid_price ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
	keep if !missing(buyer_id)
    bys buyer_id: gen count = _N
    keep if count >100
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
    export delimited  "${country_folder}/buyers_for_R.csv", replace
    ! "$R_path_local" "${utility_codes}/benford.R" "${country_folder}" 
restore

************************************************
use "${country_folder}/buyers_benford.dta"
// decode buyer_id, gen (buyer_id2)
// drop buyer_id
rename buyer_id anb_masterid_str
save "${country_folder}/buyers_benford.dta", replace
************************************************
use "${country_folder}/`country'_wip.dta", clear
merge m:1 anb_masterid_str using "${country_folder}/buyers_benford.dta"
drop if _m==2
drop _m

// br anb_masterid_str MAD MAD_conformitiy if !missing(MAD)
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

// logit singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Doesn't work

// tabstat MAD, by(MAD_conformitiy) stat(min mean max)

xtile ben=MAD if filter_ok==1, nquantiles(10)
replace ben=99 if MAD==. 
// tabstat MAD if filter_ok, stat(mean median) //mean 0.0142047 median .0107676
// tabstat MAD, by(ben) stat(min max)

*compared to median 5
// logit singleb ib5.ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*doesn't work
*compared to mean 7
// logit singleb ib7.ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*8-10 - same level
// bys ben: tab MAD_conformitiy if filter_ok 
*OK - use 10 
*We only use what conforms with MAD_conformitiy 

cap drop corr_ben
gen corr_ben=0
replace corr_ben=2 if inlist(ben,10)
replace corr_ben=99 if ben==99
// tab ben corr_ben if filter_ok, missing
// tabstat MAD if filter_ok, by(ben) stat(min mean max)

// logit singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Valid
*******************************************************************************
*No overrun, delay, or sanctions

*******************************************************************************

*Final best regressions
*excluded: i.taxhav3 only 1 case
// logit singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
// *R2 13.26%, 86,196 obs
//
// reg w_ycsh singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & w_ynrc>4 & w_ynrc!=., base
// //+*singleb,decp,ben | submp | nocft, proc  is -ve significant
//
// *Excluded: taxhav3
// reg proa_ycsh singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_proc i.anb_type year i.market_id i.ca_contract_value10 i.anb_location if filter_ok & proa_ynrc>4 & proa_ynrc!=., base
//+*singleb,decp,ben,proc,submp | nocft is not significant
*******************************************************************************

*CRI calculation

// sum singleb corr_proc nocft corr_submp corr_decp  proa_ycsh corr_ben if filter_ok==1
// tab singleb, m
// tab nocft, m
// tab corr_proc, m  //rescale
// tab corr_submp, m //rescale
// tab corr_decp, m //rescale
// tab corr_ben, m  //rescale

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
// tab corr_decp_bi corr_decp

gen corr_subm_bi=99
replace corr_subm_bi=corr_submp/2 if corr_submp!=99
// tab corr_subm_bi corr_submp


gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
// tab corr_proc_bi corr_proc

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

do $utility_codes/cri.do singleb nocft corr_proc_bi corr_subm_bi corr_decp_bi proa_ycsh4 corr_ben_bi
rename cri cri_py

// sum cri_py if filter_ok==1
// hist cri_py if filter_ok==1, title("CRI PY, filter_ok")
// hist cri_py if filter_ok==1, by(year, noiy title("CRI PY (by year), filter_ok")) 

********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*END