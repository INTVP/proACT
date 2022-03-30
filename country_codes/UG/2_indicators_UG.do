*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data 
use $country_folder/UG_wip.dta, clear
********************************************************************************


*CRI components
*12 components - proc, decp, submp, nocft, singleb, taxhav, supplier share, benford, selection method, award criteria count, contract modification, published documents

************************************

*Procedure type
*31.05% missing
tab tender_nationalproceduretype, missing
encode tender_proceduretype, gen(ca_procedure)

************************************

*Submission period
*submission period = bid deadline -first or last call for tender

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
sum submp
hist submp
hist submp, by(tender_proceduretype)
sum submp, det  

sum submp if submp>365
sum submp if submp>250
sum submp if submp>183
sum submp if submp>125
sum submp if submp>100

replace submp=. if submp>365
************************************

*No cft

*no/yes cft
*gen yescft=(!missing(notice_url))
*tab yescft if filter_ok, m
*Don't use the notice url but sub period to determine if a cft was published
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
tab yescft if filter_ok, m

tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
tab nocft, missing

******************************************

*Decision period

*decision period = contract award or similar - deadline
gen aw_date = date(tender_publications_firstdcontra, "YMD")
gen ca_date = date(tender_awarddecisiondate, "YMD")
format aw_date ca_date first_cft_pub %d
label var aw_date "award date - from publication first contract date"
label var ca_date "award decision date"

sum aw_date ca_date bid_deadline

gen decp=ca_date - bid_deadline
sum decp
hist decp
count if decp==0 & filter_ok //6,976
replace decp=. if decp<=0 
*8,824

hist decp //mostly close to zero
sum decp if decp>365
sum decp if decp>183
sum decp if decp>100
hist decp if decp<365
hist decp if decp<183
tab decp if decp>365 

replace decp=. if decp>183
lab var decp "decision period"
******************************************

* supplier dependence on a buyer (including filter_ok throughout which also removes cancelled tenders)

*winner dependence on buyer
gen year=tender_year
encode buyer_masterid, gen(anb_id)
sum ca_contract_value

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

sort w_id year ca_date
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
******************************************

* buyer spending concentration

egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_id!=. & year!=., by(anb_id year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_id year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_id +year +ca_date
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
*very small concentrations from the buyer's perspective
******************************************

*Tax haven
gen iso = bidder_country
merge m:1 iso using $utility_data/FSI_wide_200812_fin.dta
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
sum sec_score
drop sec_score1998-sec_score2019
tab bidder_country, missing

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="DE" | bidder_country==""
tab fsuppl, missing

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
tab taxhav, missing
tab bidder_country if taxhav==1 & fsuppl==1
replace taxhav = 0 if bidder_country=="US" //removing the US

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"
tab taxhav2, missing

******************************************

save $country_folder/dfid2_ug_cri_201102.dta, replace
******************************************

*Benford's law export

preserve
    *rename xxxx buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys anb_id: gen count = _N
    keep if count >100
    keep anb_id ca_contract_value
	order anb_id ca_contract_value
    export delimited  $country_folder/buyers_for_R.csv, replace
    * set directory 
    ! cd $country_folder
	//Makse sure to change path to the local path of Rscript.exe
    ! "C:/Program Files/R/R-3.6.0/bin/x64/Rscript.exe" $utility_codes/benford.R
restore

rename anb_id anb_id_orig
decode anb_id_orig, gen(anb_id)
merge m:1 anb_id using $country_folder/buyers_benford.dta
drop _m

br buyer_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — 0.0048826 to 0.0048826
Acceptable conformity — 0.0105459 to 0.0105459
Marginally acceptable conformity — 0.0147056 to 0.0147056
Nonconformity — greater than 0.0152009
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
******************************************

*Cost overrun

sum lot_estimatedprice ca_contract_value 

gen overrun=ca_contract_value - lot_estimatedprice 
sum overrun
hist overrun
lab var overrun "cost overrun"

gen roverrun=(ca_contract_value - lot_estimatedprice)/lot_estimatedprice
sum overrun roverrun
hist roverrun

******************************************

* Single bidding

bysort tender_id w_id lot_estimatedprice: gen unique_company_per_tender=_n==1
replace unique_company_per_tender=. if w_id==.

bysort tender_id : egen ca_bids_new=total(unique_company_per_tender)

gen singleb=1 if ca_bids_new==1
replace singleb=0 if ca_bids_new>1 & ca_bids_new!=.
replace singleb=0 if bidder_name==""
replace singleb=. if tender_finalprice==.

tab singleb, missing
*38.4% single bidding

lab var singleb "single-bid red flag"
tab singleb
******************************************

*CRI components validation


*year, contract value, market, filter_ok: created already
*** red flag validation: singleb regressions ***


*controls only

sum singleb ca_contract_value10 anb_type year anb_loc marketid
sum singleb ca_contract_value10 anb_type year anb_loc marketid if filter_ok==1
*missing in year

logit singleb i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid, base
logit singleb i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*Number of obs = 44,516, Pseudo R2 =  0.264
*little difference between the 2 samples
******************************************

*procedure type

tab ca_procedure,m
tab ca_procedure if filter_ok==1, m
tab ca_procedure year if filter_ok==1
tabstat singleb if filter_ok==1, by(ca_procedure) stat(mean N)

logit singleb ib5.ca_procedure i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*selective contracting has highest risk, although it has only few cases; limited insign.
*counterint. direct contracting (73%) has the lowest risk

gen corr_proc=.
replace corr_proc=0 if ca_procedure==1 | ca_procedure==3 | ca_procedure==5
replace corr_proc=1 if ca_procedure==6 
replace corr_proc=99 if corr_proc==.

tab corr_proc, missing
tab corr_proc ca_procedure if filter_ok==1, missing

logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
******************************************

*nocft

logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*ok

logit singleb i.nocft##ib5.ca_procedure i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*no improvement in procedure type
******************************************

*advertisement period

sum submp if filter_ok==1
hist submp if filter_ok==1
*drop around 50 days
hist submp if filter_ok==1 & submp<50
hist submp if filter_ok==1, by(ca_procedure)
hist submp if filter_ok==1 & submp<75, by(ca_procedure)
*different cut-point for direct procedure types, drop around 50 for others
hist submp, by(year)

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
tab submp5
tab submp10
tab submp10 nocft
sum submp if nocft==1
*no overlap

tabstat submp if filter_ok==1, by(submp5) stat(min max mean N)
tabstat submp if filter_ok==1, by(submp10) stat(min max mean N)

logit singleb submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
logit singleb ib5.submp5 i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
logit singleb ib10.submp10 i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*very short and medium length have the highest risk  

logit singleb ib5.submp5##i.corr_proc i.nocft i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*doesn't work
logit singleb ib5.submp5##i.corr_proc i.nocft i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & corr_proc!=0, base
*similar pattern as without interaction
tab submp5 corr_proc if filter_ok==1
tab submp5 corr_proc if filter_ok==1, column nofreq
*different distributions by procedure type

tabstat submp if filter_ok==1 & corr_proc==0, by(submp5) stat(min max mean N)
tabstat submp if filter_ok==1 & corr_proc!=0, by(submp5) stat(min max mean N)

hist submp if filter_ok==1 & submp<185, by(corr_proc)
*no clear spike for category 0 and 2

gen corr_submp=0
replace corr_submp=1 if (submp10>=5 & submp10<=8)
replace corr_submp=2 if (submp10<=4)
replace corr_submp=99 if submp10==99
tab submp10 corr_submp, missing

logit singleb i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*ok


tab corr_submp
tab ca_procedure
logit singleb i.nocft i.corr_submp##ib5.ca_procedure i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
margins , at(corr_submp=(0 1 2) ca_procedure=(1 3 5 6)) noestimcheck
marginsplot, x(ca_procedure)
marginsplot, x(corr_submp)
*still open one of the worse procedure tpyes
******************************************

*decision making period
sum decp
hist decp

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.
tab decp5
tabstat decp, by(decp5) stat(min max mean N)

logit singleb decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*as expected

logit singleb i.decp5 i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*short decision period has highest risk of singleb, medium is insignificant

gen corr_decp=.
replace corr_decp=0 if decp5>=4 & decp5!=99
replace corr_decp=1 if (decp5<=3) & decp5!=99
replace corr_decp=99 if decp==.
tab decp5 corr_decp, missing
tab corr_decp year if filter_ok==1

logit singleb i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*ok
******************************************

*cost overrun

sum roverrun if filter_ok
sum roverrun if filter_ok==1 & roverrun<0
sum roverrun if filter_ok==1 & roverrun<=0
sum roverrun if filter_ok==1 & roverrun>0
*spending mostly below contract value
sum roverrun if roverrun>0
hist roverrun if roverrun<=0
hist roverrun if roverrun<=1
*spike at 0


gen roverrun2=0 if roverrun!=.
replace roverrun2=1 if roverrun>0 & roverrun !=.
replace roverrun2=99 if roverrun==.
tab roverrun2 if filter_ok==1

xtile roverrun215=roverrun if filter_ok==1 & roverrun>0, nquantiles(5)
gen roverrun6=roverrun2
replace roverrun6=roverrun215 if roverrun2==1
replace roverrun6=99 if roverrun ==.
tab roverrun2 roverrun6 if filter_ok, missing
tabstat roverrun if filter_ok, by(roverrun6) stat(min mean p50 max sd N)


logit singleb roverrun i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
logit singleb c.roverrun##roverrun2 i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
logit singleb i.roverrun2 i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*higher overrun increase single bidding, counterintuitive
logit singleb i.roverrun6 i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*similar result

tabstat roverrun if filter_ok==1, by(roverrun6) stat(min max mean N)
hist roverrun if filter_ok==1, by(year)

gen roverrun_alt=roverrun
sum roverrun_alt if filter_ok==1
sum roverrun_alt if filter_ok==1 & roverrun_alt <10
sum roverrun_alt if filter_ok==1 & roverrun_alt <3
*only a handful of cases at such extremes

replace roverrun_alt=. if roverrun_alt>3
hist roverrun_alt if filter_ok, percent
hist roverrun_alt if filter_ok & roverrun_alt<-0.2, percent
*strangely many -1s, probably data error

sum roverrun_alt if filter_ok==1 & roverrun_alt >=-1
sum roverrun_alt if filter_ok==1 & roverrun_alt >=-0.8

replace roverrun_alt=. if roverrun_alt<=-0.8

logit singleb roverrun_alt i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*still no improvement


gen roverrun_bi=.
replace roverrun_bi=0 if roverrun<=0 & roverrun !=.
replace roverrun_bi=1 if roverrun>0 & roverrun !=.
replace roverrun_bi=99 if roverrun ==.
tab roverrun_bi if filter_ok==1,m

logit singleb i.roverrun_bi i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
logit singleb i.roverrun_bi i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*strange still positive
******************************************

*benford's law

tab corr_ben if filter_ok==1
*strange distribution, mainly noncoform...

logit singleb i.corr_ben i. roverrun_bi i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*not working

xtile ben=MAD if filter_ok==1, nquantiles(10)
replace ben=99 if MAD==. 
tabstat MAD if filter_ok, stat(mean median) //mean 0.0142047 median .0107676
tabstat MAD if filter_ok, by(ben) stat(min max N)
tab ben corr_ben if filter_ok,m

xtile ben5=MAD if filter_ok==1, nquantiles(5)
replace ben5=99 if MAD==. 
tabstat MAD if filter_ok, stat(mean median) //mean 0.033203 median .0285786
tabstat MAD if filter_ok, by(ben) stat(min max N)
tab ben5 corr_ben if filter_ok,m

logit singleb ib3.ben5 i. roverrun_bi i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*makes no sense
******************************************

*supplier dependence on buyer

tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
*negative sign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
*negative insign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
*pos. INsign.

reg w_ycsh singleb i. roverrun_bi i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
reg w_ycsh singleb i. roverrun_bi i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*works for singleb, nocft

hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
*not too strong spike at the top
******************************************

*buyer spending concentration

tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
*negative, significant
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*negative, significant

reg proa_ycsh singleb i. roverrun_bi i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
reg proa_ycsh singleb i. roverrun_bi i.corr_decp i.corr_submp i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*works for nocft
******************************************

*** final best regression and valid red flags

logit singleb i. roverrun_bi i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
*38.18% explanatory power
reg proa_ycsh singleb i. roverrun_bi i.corr_decp i.nocft i.corr_submp i.corr_proc i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*works for decp, submp category 1, nocft, R2=11.61%
******************************************

*** CRI generation ***


sum singleb roverrun_bi corr_decp corr_submp nocft corr_proc proa_ycsh if filter_ok==1
*some missing for proa_ycsh

tab singleb if filter_ok==1
tab roverrun_bi if filter_ok==1
tab corr_decp if filter_ok==1
tab corr_submp if filter_ok==1
*needs binarisation
tab nocft if filter_ok==1
tab corr_proc if filter_ok==1

gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
tab corr_submp_bi corr_submp

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
sum proa_ycsh4 proa_ycsh

do $utility_codes/cri.do singleb corr_decp corr_submp_bi nocft corr_proc roverrun_bi proa_ycsh4 
rename cri cri_ug

sum cri_ug if filter_ok==1
hist cri_ug if filter_ok==1
hist cri_ug if filter_ok==1, by(year)

******************************************
save $country_folder/dfid2_ug_cri_201116.dta, replace
******************************************

*relative price

gen relprice=ca_contract_value/lot_estimatedprice
hist relprice if filter_ok==1

reg relprice cri_ug i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1, base
reg relprice cri_ug i.ca_contract_value10 i.anb_type i.year i.anb_loc i.marketid if filter_ok==1 & relprice<=1, base
*first is neg, insignificant, second is positive significant
******************************************