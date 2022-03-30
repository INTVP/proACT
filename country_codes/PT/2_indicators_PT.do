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
use $country_folder/PT_wip.dta, clear
********************************************************************************

*CRI components
*12 components - proc, decp, submp, nocft, singleb, taxhav, supplier share, benford, selection method, award criteria count, contract modification, published documents

******************************************
*Procedure type
tab tender_proceduretype, missing
tab tender_nationalproceduretype, missing
********************************************************************************

*Submission period
*submission period = bid deadline -first or last call for tender

*tender_publications_firstcallfor tender_biddeadline

sum first_cft_pub last_cft_pub bid_deadline

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
sum submp
hist submp
hist submp, by(tender_proceduretype)
sum submp, det  

sum submp if submp>365
sum submp if submp>183
sum submp if submp>125
sum submp if submp>100

replace submp=. if submp>183

********************************************************************************
*decision period = contract award or similar - deadline

sum aw_date ca_date bid_deadline

gen decp=aw_date - bid_deadline
replace decp=. if decp<=0
sum decp
hist decp

gen decp2=ca_date - bid_deadline
replace decp2=. if decp2<=0
sum decp2
sum decp2 if decp==.
*barely any difference
hist decp2

replace decp2=. if decp2>365

hist decp //mostly close to zero
sum decp if decp>365
sum decp if decp>183
sum decp if decp>100
hist decp if decp<365
hist decp if decp<183
tab decp if decp>365 //take one year as an upper bound

replace decp=. if decp>365
lab var decp "decision period"

********************************************************************************
*singlebidding
sum tender_recordedbidscount lot_bidscount if filter_ok==1
gen singleb=.
replace singleb=0 if tender_recordedbidscount!=1 & tender_recordedbidscount!=.
replace singleb=1 if tender_recordedbidscount==1
tab singleb
tab singleb if filter_ok , missing  //77.19% singlebidding

********************************************************************************
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
********************************************************************************
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
*basically missing for 98% of the sample, so all national records


gen fsuppl=1 
replace fsuppl=0 if bidder_country=="PT" | bidder_country==""
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
********************************************************************************

*Winning Supplier's contract share (by PE, by year)

sum ca_contract_value if filter_ok==1
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
tab filter_wy

sort w_id_gen
egen filter_w = tag(w_id_gen) if filter_ok==1 & w_id_gen!=.
lab var filter_w "Marking Winners"
tab filter_w

sort w_id_gen buyer_id
egen filter_wproa = tag(w_id_gen buyer_id) if filter_ok==1 & w_id_gen!=. & buyer_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
tab filter_wproa

sort tender_year w_id_gen buyer_id
egen filter_wproay = tag(tender_year w_id_gen buyer_id) if filter_ok==1 & w_id_gen!=. & buyer_id!=. & tender_year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
tab filter_wproay

/*
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
tab filter_proay

sort buyer_id
egen filter_proa = tag(buyer_id) if filter_ok==1 & buyer_id!=.
lab var filter_proa "Marking PAs"
tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_id!=., by(buyer_id)
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

save $country_folder/PT_wip.dta, replace
********************************************************************************
*Benford's law export

preserve
    *rename xxxx buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
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

use $country_folder/PT_wip.dta, replace
merge m:1 buyer_id using $country_folder/buyers_benford.dta
drop _m

br buyer_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
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
tab tender_documents_count
*98.32% has 0 published documents
********************************************************************************

*CRI components validation

*controls only

sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid
sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid if filter_ok==1
*1,161,033
*large missing in buyer type, buyer location and some in supply type

logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid, base
logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*number of obs = 1,160,827, Pseudo R2 = 0.5748
********************************************************************************

*procedure types

tab tender_proceduretype
tab tender_proceduretype if filter_ok==1
encode tender_proceduretype,gen(ca_procedure)
tab ca_procedure if filter_ok==1
replace ca_procedure=99 if tender_proceduretype==""

logit singleb i.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib9.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_proc=.
replace corr_proc=0 if ca_procedure==9 | ca_procedure==11
replace corr_proc=1 if ca_procedure==6 | ca_procedure==7 | ca_procedure==8 | ca_procedure==10
replace corr_proc=99 if ca_procedure==. |  corr_proc==.
tab ca_procedure corr_proc, missing

logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************
*nocft

tab nocft if filter_ok==1
*national data does not include bid deadline info, 72% direct contract
tab ca_procedure nocft if filter_ok==1, row
tab corr_proc nocft if filter_ok==1

logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*negative, most tenders don't have call for tender

logit singleb i.nocft##i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*not really meaningful

gen nocft2=nocft
replace nocft2=99 if corr_proc==1 | corr_proc==99
tab nocft2 nocft

logit singleb i.nocft2 i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*still not better
********************************************************************************

tab source
*http://www.base.gov.pt

gen source_bi=1
replace source_bi=0 if source=="http://www.base.gov.pt"
tab source_bi if filter_ok==1, m
tab source_bi nocft if filter_ok==1, m

logit singleb i.nocft##i.source_bi i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*no improvement

gen nocft_source=nocft
replace nocft_source=99 if source_bi==0
tab nocft_source if filter_ok==1, m

logit singleb i.nocft_source i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************

*selection method

tab tender_selectionmethod if filter_ok==1
tab tender_selectionmethod ca_procedure if filter_ok==1, missing
encode tender_selectionmethod,gen(ten_select)
replace ten_select=99 if ten_select==.

logit singleb i.ten_select i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************

gen corr_crit=.
replace corr_crit=0 if ten_select==2
replace corr_crit=1 if ten_select==1
replace corr_crit=99 if ten_select==99

logit singleb i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*advertisement period
sum submp
tab submp
hist submp
*mostly between 25-47 days, available only for ted data
hist submp, by(ca_procedure)
*outright award and inovation partnership has only 1-3 observations   

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
replace submp10=99 if submp10==.

tab submp5
tab submp10
tab submp10 nocft
sum submp if nocft==1
*no overlaps

tabstat submp, by(submp10) stat(min max N)
tabstat submp, by(submp5) stat(min max N)

logit singleb submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.submp5 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.submp10 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib8.submp10 i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*as expected
logit singleb i.submp10#i.corr_proc i.corr_crit ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.submp5#i.corr_proc i.corr_crit ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_submp=.
replace corr_submp=0 if submp10>=6 & submp10!=99 
replace corr_submp=1 if submp10>=4 & submp10<=5 & submp10!=99 
replace corr_submp=2 if submp10<=3 & submp10!=99 
replace corr_submp=99 if submp10==99 | submp10==.
tab submp10 corr_submp, missing
tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

logit singleb i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*decision making period

sum decp
*few observation, 29K, only ted data
hist decp

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp5==.
xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp10==.
tab decp5
tab decp10
tabstat decp, by(decp10) stat(min max mean N)
tabstat decp, by(decp5) stat(min max mean N)

xtile decp25=decp2 if filter_ok==1, nquantiles(5)
replace decp25=99 if decp25==.
xtile decp210=decp2 if filter_ok==1, nquantiles(10)
replace decp210=99 if decp210==.
tab decp25
tab decp210
tabstat decp2, by(decp210) stat(min max mean N)
tabstat decp2, by(decp25) stat(min max mean N)

logit singleb decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.decp5 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.decp10 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib6.decp10 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib2.decp5 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*counterint., shortest seems to be non-risky; 90% of category1 is between 30-78 days

logit singleb i.decp25 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.decp210 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib4.decp210 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib2.decp25 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_decp=.
replace corr_decp=0 if decp210>=6 & decp210!=99
replace corr_decp=1 if decp210>=3 & decp210<=5 & decp210!=99
replace corr_decp=2 if decp210<=2 & decp210!=99
replace corr_decp=99 if decp210==99 | corr_decp==.
tab decp210 corr_decp, m

logit singleb i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*award criteria count
tab tender_awardcriteria_count
*96.65% 0

*contract modification
tab tender_corrections_count if filter_ok==1
*no variance, 99.34% of tenders have no modification
********************************************************************************


*benford's law
logit singleb i.corr_ben i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*neg., significant
logit singleb ib2.corr_ben i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_ben_bi=corr_ben
replace corr_ben_bi=0 if corr_ben==1
replace corr_ben_bi=1 if corr_ben==2
replace corr_ben_bi=99 if corr_ben==. | corr_ben==99
tab corr_ben_bi if filter_ok==1, m

logit singleb i.corr_ben_bi i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*still not ok


xtile ben5=MAD if filter_ok==1, nquantiles(5)
replace ben5=99 if ben5==.
xtile ben10=MAD if filter_ok==1, nquantiles(10)
replace ben10=99 if ben10==.
tab ben5
tab ben10
tabstat MAD, by(ben10) stat(min max mean N)
tabstat MAD, by(ben5) stat(min max mean N)

logit singleb i.ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.ben10 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_ben5=ben5
replace corr_ben5=0 if ben5<=4
replace corr_ben5=1 if ben5==5
replace corr_ben5=99 if ben5==99
tab corr_ben5 if filter_ok==1, m

logit singleb i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

sum ca_contract_value lot_estimatedprice 
*13K lot_estimatedprice
********************************************************************************

*Overrun

gen overrun=payments_sum-ca_contract_value 
sum overrun
hist overrun
lab var overrun "cost overrun"

gen roverrun=(payments_sum-ca_contract_value)/ca_contract_value
sum overrun roverrun
hist roverrun
hist roverrun if roverrun <1

gen roverrun2=0 if roverrun!=.
replace roverrun2=1 if roverrun>0 & roverrun !=.
replace roverrun2=99 if roverrun==.
tab roverrun2
*only 332K obs

logit singleb roverrun i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*higher overrun lower single bidding, as expected
********************************************************************************

*delay (days & relative)

sum lot_updatedcompletiondate lot_updateddurationdays tender_estimateddurationindays if filter_ok==1
*obs only for tender_estimateddurationindays, contract dates are not available
*not computable

********************************************************************************

*tax haven

tab taxhav if filter_ok==1
tab taxhav2 if filter_ok==1
tab taxhav2 if filter_ok==1 & fsuppl==1

ttest singleb if filter_ok==1 & fsuppl==1, by(taxhav)
ttest singleb if filter_ok==1 & fsuppl==1, by(taxhav2)
*negative, insign

ttest corr_proc if filter_ok==1 & fsuppl==1, by(taxhav)
ttest corr_proc if filter_ok==1 & fsuppl==1, by(taxhav2)
*negative, sign

ttest w_mycsh if filter_ok==1 & fsuppl==1 & filter_wy==1 & w_ynrc>2 & w_ynrc!=., by(taxhav2)
*no such case

*supplier dependence on buyer
tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
*negative sign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
*negative sign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
*negative sign.

reg w_ycsh singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
reg w_ycsh singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*most predictors work, except corr_decp cat2

hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
********************************************************************************

*buyer spending concentration
tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
*positive, significant
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*positive, significant

reg proa_ycsh singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
reg proa_ycsh singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*decision perid works

*** final best regression and valid red flags
logit singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*17.76% explanatory power

reg proa_ycsh singleb i.roverrun2 i.corr_ben5 i.corr_decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*singleb, submp works, 16.83%

********************************************************************************

*CRI generation
sum singleb corr_proc corr_submp corr_decp corr_crit w_ycsh corr_ben5 roverrun2 if filter_ok==1
tab singleb, m
tab corr_proc, m
tab corr_submp, m //binarisation
tab corr_decp, m //binarisation
tab corr_crit, m
tab corr_ben5, m 
tab roverrun2, m

gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
tab corr_submp_bi corr_submp

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
tab corr_decp_bi corr_decp

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
sum proa_ycsh4 proa_ycsh


do $utility_codes/cri.do singleb corr_proc corr_submp_bi corr_decp_bi corr_crit proa_ycsh4 corr_ben5 roverrun2
rename cri cri_pt

sum cri_pt if filter_ok==1
hist cri_pt if filter_ok==1, title("CRI PT, filter_ok")
hist cri_pt if filter_ok==1, by(tender_year, noiy title("CRI PT (by year), filter_ok")) 
********************************************************************************

save $country_folder/wb_pt_cri201117.dta, replace
********************************************************************************
*END

save "C:\Users\Shaibani\Desktop\RN\200611\RN\CRI\PT\wb_pt_cri201104.dta", replace
