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
use $country_folder/AT_wip.dta, clear
********************************************************************************

*Single bidding
sort tender_id lot_row_nr
br source tender_id lot_row_nr tender_recordedbidscount lot_bidscount

gen singleb = 0
replace singleb=1 if lot_bidscount==1
replace singleb=. if missing(lot_bidscount)
tab singleb, m

*Controls only 
logit singleb lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
//R2: 9% - 31k obs

logit singleb i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*drop cvalue10
*marginally improved R2, more observations - 102k

********************************************************************************
*Procedure type
br *proc*
tab tender_proceduretype, m
tab tender_proceduretype tender_indicator_integrity_proce , m
 
gen ca_procedure = tender_proceduretype
replace ca_procedure = "NA" if missing(ca_procedure)
encode ca_procedure, gen(ca_procedure2)
drop ca_procedure 
rename ca_procedure2 ca_procedure
tab ca_procedure, m
label list ca_procedure2
logit singleb ib7.ca_procedure lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
logit singleb ib7.ca_procedure i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Based on regressions 
*Level 1 risk - NEGOTIATED
*Level 2 risk - OUTRIGHT_AWARD
label list ca_procedure2
gen corr_proc=.
replace corr_proc=0 if inlist(ca_procedure,1,2,5,6,7,9) 
replace corr_proc=1 if inlist(ca_procedure,4)
replace corr_proc=2 if inlist(ca_procedure,8) 
replace corr_proc=99 if ca_procedure==3
logit singleb i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Much better 
********************************************************************************

*Submission period 
gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
sum submp
hist submp
hist submp if submp<1000
sum submp, det  
replace submp=. if submp>365 //cap ssubmission period to 1 year

sum submp if filter_ok  //mean 85 days
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
tabstat submp, by(submp10) stat(min mean max)

logit singleb ib8.submp10 i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
tabstat submp, by(submp5) stat(min mean max)

logit singleb ib4.submp5 i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Compared to the mean 1,2 and 3 are high risk

gen corr_submp=0
replace corr_submp=1 if submp5<=3
replace corr_submp=99 if submp5==99
tab submp5 corr_submp if filter_ok, missing

logit singleb i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Works

********************************************************************************

*Decision Period 
gen decp=aw_date - bid_deadline
sum decp
hist decp
replace decp=0 if decp<0 & decp!=0
count if decp==0 & filter_ok

hist decp //mostly close to zero
sum decp if decp>365
replace decp=. if decp>365 //cap at 1 year
lab var decp "decision period"

xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==.
sum decp if filter_ok //mean: 59 days
tabstat decp, by(decp10) stat(min mean max)

logit singleb ib7.decp10 i.corr_submp i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*<=7

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.
sum decp if filter_ok //mean: 59 days
tabstat decp, by(decp5) stat(min mean max)

logit singleb ib4.decp5 i.corr_submp i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base

gen corr_decp=0
replace corr_decp=1 if inlist(decp10,3,4,5)
replace corr_decp=2 if inlist(decp10,1,2)
replace corr_decp=99 if decp10==99
tab decp10 corr_decp if filter_ok, missing
*tabstat decp, by(decp5) stat(min mean max)

logit singleb i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Valid!

********************************************************************************

*No cft
*Method 1
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
tab yescft if filter_ok, m
tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
tab nocft, missing

logit singleb i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Not valid

drop nocft yescft

*Method 2
gen nocft=0
replace nocft = 1 if missing(tender_publications_firstcallfor)

logit singleb i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Valid
********************************************************************************

*Tax haven
tab bidder_country, m
gen iso = bidder_country
do $utility_codes/country-to-iso.do iso
merge m:1 iso using $utility_data/FSI_wide_200812_fin.dtalab var iso "supplier country ISO"
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
replace fsuppl=0 if bidder_country=="SE" | bidder_country==""
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

logit singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
logit singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Both are valid

tab bidder_country if taxhav==1

*Foreign supplier high risk
gen taxhav3= fsuppl
replace taxhav3 = 2 if fsuppl==1 & taxhav==1
tab taxhav3, m
logit singleb i.taxhav3 i.corr_decp i.corr_submp i.corr_proc lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*In this format taxhaven also works
********************************************************************************

*Winning Supplier's contract share (by PE, by year)
unique buyer_masterid
unique buyer_id
unique buyer_name
sort buyer_id
format buyer_masterid buyer_id buyer_name %20s
br buyer_masterid buyer_id buyer_name

*Use buyer_id and bidder_id
egen w_yam=sum(bid_price) if filter_ok==1 & bidder_id!="" & tender_year!=., by (bidder_id tender_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(bid_price) if filter_ok==1 & buyer_id!="" & bidder_id!="" & tender_year!=., by(buyer_id bidder_id tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(bidder_id tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

drop x
gen x=1
egen w_ynrc=total(x) if filter_ok==1 & bidder_id!="" & tender_year!=., by(bidder_id tender_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & buyer_id!="" & tender_year!=., by(buyer_id tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort bidder_id tender_year aw_date
egen filter_wy = tag(bidder_id tender_year) if filter_ok==1 & bidder_id!="" & tender_year!=.
lab var filter_wy "Marking Winner years"
tab filter_wy

sort bidder_id
egen filter_w = tag(bidder_id) if filter_ok==1 & bidder_id!=""
lab var filter_w "Marking Winners"
tab filter_w

sort bidder_id buyer_id
egen filter_wproa = tag(bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!=""
lab var filter_wproa "Marking Winner-buyer pairs"
tab filter_wproa

sort tender_year bidder_id buyer_id
egen filter_wproay = tag(tender_year bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!="" & tender_year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
tab filter_wproay

*checking contract share
reg w_ycsh singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>2 & w_ynrc!=., base
reg w_ycsh singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>4 & w_ynrc!=., base
reg w_ycsh singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>9 & w_ynrc!=., base
*singleb works

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
sum w_ycsh4 w_ycsh
********************************************************************************

*Buyer dependence on supplier
egen proa_yam=sum(bid_price) if filter_ok==1 & buyer_id!="" & tender_year!=., by(buyer_id tender_year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(buyer_id tender_year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort buyer_id +tender_year +aw_date
egen filter_proay = tag(buyer_id tender_year) if filter_ok==1 & buyer_id!="" & tender_year!=.
lab var filter_proay "Marking PA years"
tab filter_proay

sort buyer_id
egen filter_proa = tag(buyer_id) if filter_ok==1 & buyer_id!=""
lab var filter_proa "Marking PAs"
tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_id!="", by(buyer_id)
drop x
lab var proa_nrc "#Contracts by PAs"
sum proa_nrc
hist proa_nrc

sum proa_ynrc
tab proa_ynrc
sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*validation below
********************************************************************************

*Benford's
*Benford's law export
br buyer_name  buyer_id
gen buyer_id_temp = "f" + buyer_id
rename buyer_id buyer_id_old
br buyer_name buyer_id_temp buyer_id_old
save $country_folder/SE_wip.dta, replace

preserve
    rename buyer_id_temp buyer_id //buyer id variable
    rename bid_price ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
	keep if !missing(buyer_id_old)
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
************************************************

use $country_folder/buyers_benford
decode buyer_id, gen (buyer_id2)
drop buyer_id
rename buyer_id2 buyer_id
save $country_folder/buyers_benford.dta, replace
************************************************

use $country_folder/SE_wip.dta, clear
rename buyer_id_temp buyer_id
merge m:1 buyer_id using $country_folder/buyers_benford.dta
drop if _m==2
drop _m
drop buyer_id
rename buyer_id_old buyer_id

br buyer_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
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

logit singleb i.corr_ben i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Doesn't work 

xtile ben=MAD if filter_ok==1, nquantiles(10)
replace ben=99 if MAD==. 
mean MAD if filter_ok //.021556 mean
tabstat MAD, by(ben) stat(min max)
logit singleb ib6.ben i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.cvalue10  if filter_ok , base
logit singleb ib1.ben i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.anb_type i.ca_type i.tender_year i.market_id  i.cvalue10  if filter_ok , base
*Does not work
********************************************************************************
*No overrun, delay, or sanctions
********************************************************************************

*Final best regressions
logit singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
outreg2 using se_valid1.doc
*OK

reg w_ycsh singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>4 & w_ynrc!=., base
reg proa_ycsh singleb i.taxhav i.nocft i.corr_decp i.corr_submp i.corr_proc i.cvalue10 i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
outreg2 using se_valid2.doc

*Calc from buyer side more valid than calc from winner side. 
********************************************************************************
save $country_folder/SE_wb_1020.dta, replace

********************************************************************************
*CRI calculation

sum singleb corr_proc corr_submp corr_decp nocft taxhav3 proa_ycsh corr_ben if filter_ok==1
tab singleb, m
tab corr_proc, m //rescale
tab corr_submp, m 
tab corr_decp, m //rescale
tab nocft, m
tab taxhav, m 
*tab corr_ben, m  
*tab proa_ycsh, m

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
tab corr_decp_bi corr_decp

*gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
sum w_ycsh4 w_ycsh

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
sum proa_ycsh4 proa_ycsh


do $utility_codes/cri.do singleb corr_proc_bi corr_submp corr_decp_bi nocft taxhav proa_ycsh4
rename cri cri_se

sum cri_se if filter_ok==1
hist cri_se if filter_ok==1, title("CRI SE, filter_ok")
hist cri_se if filter_ok==1, by(tender_year, noiy title("CRI SE (by year), filter_ok")) 
********************************************************************************

save $country_folder/SE_wb_1020.dta, replace
********************************************************************************
*END
