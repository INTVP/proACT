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
use $country_folder/RO_wip.dta, clear
********************************************************************************

*Single bidding
sort tender_id lot_row_nr
br source tender_id lot_row_nr tender_recordedbidscount lot_bidscount

gen singleb = 0
replace singleb=1 if lot_bidscount==1
replace singleb=. if missing(lot_bidscount)
tab singleb, m

*Controls only 
logit singleb i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok, base
//R2: 7.66% - 723,017 obs
********************************************************************************

*Procedure type
br *proc*
tab tender_proceduretype, m
tab tender_proceduretype tender_indicator_integrity_proce , m

gen ca_procedure=.
replace ca_procedure=1 if tender_procedure=="APPROACHING_BIDDERS"
replace ca_procedure=2 if tender_procedure=="COMPETITIVE_DIALOG"
replace ca_procedure=3 if tender_procedure=="NEGOTIATED"
replace ca_procedure=4 if tender_procedure=="NEGOTIATED_WITHOUT_PUBLICATION"
replace ca_procedure=5 if tender_procedure=="NEGOTIATED_WITH_PUBLICATION"
replace ca_procedure=6 if tender_procedure=="OPEN"
replace ca_procedure=7 if tender_procedure=="RESTRICTED"
replace ca_procedure=999 if missing(tender_procedure)
tab ca_procedure, m

label define ca_proc 1 "APPROACHING_BIDDERS" 2 "COMPETITIVE_DIALOG" 3"NEGOTIATED" 4"NEGOTIATED_WITHOUT_PUBLICATION" 5"NEGOTIATED_WITH_PUBLICATION" ///
6"OPEN" 7"RESTRICTED" 999 "MISSING" 
label var ca_procedure "type of procurement procedure followed"
label values ca_procedure ca_proc

tabstat singleb if filter_ok==1, by(tender_procedure) stat(mean n)

logit singleb ib6.ca_procedure  i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok, base
*restricted in this case has a sig lower coef..not using as a corr indicator
*going with negotiated and negotiated w/o publication level 2 
*approaching and neg w/ pub as level 1
gen corr_proc=.
replace corr_proc=0 if ca_procedure!=.
replace corr_proc=1 if inlist(ca_procedure,1,5)
replace corr_proc=2 if inlist(ca_procedure,3,4)
*replace corr_proc=99 if ca_procedure==999
tab ca_procedure corr_proc  if filter, m

logit singleb i.corr_proc  i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok, base
*good
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

sum submp if filter_ok  //mean 59 days
xtile submp25=submp if filter_ok==1, nquantiles(25)
replace submp25=99 if submp==.
tabstat submp if filter_ok, by(submp25) stat(min mean max)

logit singleb ib22.submp25 i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok & submp<=100, base
*1 to 5

gen corr_submp=0
replace corr_submp=1 if inlist(submp25,1,2,3,4,5)
replace corr_submp=99 if submp25==99
tab submp25 corr_submp if filter_ok, missing
tabstat submp if filter_ok, by(corr_submp) stat(min mean max)

logit singleb i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*works

sum submp
sum submp if filter_ok
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
replace decp=. if decp<0 //cap at 1 year
lab var decp "decision period"


xtile dec_p25=decp if filter_ok==1, nquantiles(25)
replace dec_p25=99 if dec_p25==. 
hist decp if filter_ok==1 
mean decp if filter_ok //71.1
tabstat decp if filter_ok, by(dec_p25) stat(n mean min max)
*cat 16/17 could be a good base
tabstat singleb, by(dec_p25) stat(n mean min max)


logit singleb ib16.dec_p25 i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*1-4
logit singleb ib17.dec_p25 i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*1-4

cap drop corr_decp
gen corr_decp=0
replace corr_decp=1 if inlist(dec_p25,3,4,99)
replace corr_decp=2 if inlist(dec_p25,1,2)
*replace corr_decp=99 if dec_p25==99
tab dec_p25 corr_decp if filter_ok, missing
tabstat decp if filter_ok, by(corr_decp) stat(min mean max)

logit singleb i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*works
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
*drop nocft yescft

*Method 2
gen nocft2=0
replace nocft2 = 1 if tender_publications_firstcallfor=="."
tab nocft2, missing


logit singleb i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*works 
*use nocft2
********************************************************************************

*Tax haven
tab bidder_country, m

gen iso = bidder_country
do $utility_codes/country-to-iso.do iso
merge m:1 iso using $utility_data/FSI_wide_200812_fin.dta
lab var iso "supplier country ISO"
drop if _merge==2
drop _merge
tab tender_year if filter_ok
gen sec_score = sec_score2009 if tender_year<=2009
replace sec_score = sec_score2011 if (tender_year==2010 | tender_year==2011) & sec_score==.
replace sec_score = sec_score2013 if (tender_year==2012 | tender_year==2013) & sec_score==.
replace sec_score = sec_score2015 if (tender_year==2014 | tender_year==2015) & sec_score==.
replace sec_score = sec_score2017 if (tender_year==2016 | tender_year==2017) & sec_score==.
replace sec_score = sec_score2019 if (tender_year==2018 | tender_year==2019 | tender_year==2020) & sec_score==.
lab var sec_score "supplier country Secrecy Score (time varying)"
drop sec_score1998-sec_score2019
tab bidder_country, missing
br bidder_country iso sec_score if !missing(bidder_country) & bidder_country!="RO"

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="RO" | bidder_country=="."
tab fsuppl, missing

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
tab taxhav, missing
tab bidder_country if taxhav==1 & fsuppl==1
replace taxhav = 0 if inlist(bidder_country,"US") //removing the US

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"

gen taxhav3= fsuppl
replace taxhav3 = 2 if fsuppl==1 & taxhav==1
tab taxhav3 if filter_ok, m


tab taxhav if filter_ok, missing
tab taxhav2 if filter_ok, missing
tab taxhav3 if filter_ok, m

logit singleb i.taxhav i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*not working
logit singleb i.taxhav2 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*not working
logit singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*+ve but not significant
********************************************************************************

*Winning Supplier's contract share (by PE, by year)
unique buyer_masterid
unique buyer_id
unique buyer_name
unique bidder_masterid
unique bidder_id
unique bidder_name
sort buyer_id
format buyer_masterid  buyer_id buyer_name bidder_masterid bidder_id bidder_nam %20s
br buyer_masterid  buyer_id buyer_name bidder_masterid bidder_id bidder_name 
foreach var of varlist buyer_masterid  buyer_id buyer_name bidder_masterid bidder_id bidder_name {
replace `var' = "" if `var'=="."
}
*using buyer_masterid & bidder_masterid
*Use buyer_id and bidder_id
egen w_yam=sum(bid_price) if filter_ok==1 & bidder_masterid!="" & tender_year!=., by (bidder_masterid tender_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(bid_price) if filter_ok==1 & buyer_masterid!="" & bidder_masterid!="" & tender_year!=., by(buyer_masterid bidder_masterid tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(bidder_masterid tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

gen x=1
egen w_ynrc=total(x) if filter_ok==1 & bidder_masterid!="" & tender_year!=., by(bidder_masterid tender_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & buyer_masterid!="" & tender_year!=., by(buyer_masterid tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort bidder_masterid tender_year aw_date
egen filter_wy = tag(bidder_masterid tender_year) if filter_ok==1 & bidder_masterid!="" & tender_year!=.
lab var filter_wy "Marking Winner years"
tab filter_wy

sort bidder_masterid
egen filter_w = tag(bidder_masterid) if filter_ok==1 & bidder_masterid!=""
lab var filter_w "Marking Winners"
tab filter_w

sort bidder_masterid buyer_masterid
egen filter_wproa = tag(bidder_masterid buyer_masterid) if filter_ok==1 & bidder_masterid!="" & buyer_masterid!=""
lab var filter_wproa "Marking Winner-buyer pairs"
tab filter_wproa

sort tender_year bidder_masterid buyer_masterid
egen filter_wproay = tag(tender_year bidder_masterid buyer_masterid) if filter_ok==1 & bidder_masterid!="" & buyer_masterid!="" & tender_year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
tab filter_wproay

*checking contract share
reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok  & w_ynrc>2 & w_ynrc!=., base
*singleb, taxhav, nocft
reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok  & w_ynrc>4 & w_ynrc!=., base
*singleb, taxhav, nocft
reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok  & w_ynrc>9 & w_ynrc!=., base
*singleb, taxhav, nocft

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
sum w_ycsh4 w_ycsh
********************************************************************************

*Buyer dependence on supplier
egen proa_yam=sum(bid_price) if filter_ok==1 & buyer_masterid!="" & tender_year!=., by(buyer_masterid tender_year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(buyer_masterid tender_year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort buyer_masterid +tender_year +aw_date
egen filter_proay = tag(buyer_masterid tender_year) if filter_ok==1 & buyer_masterid!="" & tender_year!=.
lab var filter_proay "Marking PA years"
tab filter_proay

sort buyer_masterid
egen filter_proa = tag(buyer_masterid) if filter_ok==1 & buyer_masterid!=""
lab var filter_proa "Marking PAs"
tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_masterid!="", by(buyer_masterid)
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

reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok & proa_ynrc>2 & proa_ynrc!=., base
*singleb, nocft, decp, proc, taxhav(cat.2)
reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok & proa_ynrc>4 & proa_ynrc!=., base
*singleb, nocft, decp, proc, taxhav(cat.2)
reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok & proa_ynrc>4 & proa_ynrc!=., base
*singleb, nocft, decp, proc, taxhav(cat.2)

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
sum proa_ycsh4 proa_ycsh
********************************************************************************

*Benford's
*Benford's law export
br buyer_name  buyer_masterid
rename buyer_id buyer_id_old
save $country_folder/RO_wip.dta, replace

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
rename buyer_id2 buyer_masterid
save $country_folder/buyers_benford.dta, replace
************************************************
use $country_folder/RO_wip.dta, clear
rename buyer_id_old buyer_id
merge m:1 buyer_masterid using $country_folder/buyers_benford.dta
drop if _m==2
drop _m

br buyer_masterid MAD MAD_conformitiy
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


logit singleb i.corr_ben i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*Not working 

*Trying the cont format
logit singleb MAD i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*Not working 

xtile ben=MAD if filter_ok==1, nquantiles(10)
replace ben=99 if MAD==. 
mean MAD if filter_ok //0.0128
tabstat MAD, by(ben) stat(min max)

logit singleb ib7.ben i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base
*1,2,3 and 10
*defn: cat  from .0030048  - .0076916
*defn: cat 2 from .0232112  - .122721
*We only use what conforms with MAD_conformitiy 

cap drop corr_ben
gen corr_ben=0
replace corr_ben=2 if inlist(ben,10)
*replace corr_ben2=2 if inlist(ben,1,2,3)
replace corr_ben=99 if ben==99
tab ben corr_ben if filter_ok, missing
tabstat MAD if filter_ok, by(ben) stat(min mean max)


logit singleb i.corr_ben i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base

*If we want to go safe we should only chose ben==10 as the risk because it aligns with non-conformity
********************************************************************************

*Final best regressions
logit singleb i.corr_ben i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok , base

*R2: 30.56, 306kobs
*OK

reg w_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok  & w_ynrc>4 & w_ynrc!=., base

reg proa_ycsh singleb i.taxhav3 i.nocft2 i.corr_decp i.corr_submp i.corr_proc i.anb_location  i.anb_type i.ca_type i.tender_year i.market_id  i.ca_contract_value10  if filter_ok & proa_ynrc>4 & proa_ynrc!=., base

*export delimited RO_wip.csv, replace
save $country_folder/RO_wip.dta, replace
********************************************************************************
*CRI generation
sum singleb corr_proc corr_submp corr_decp nocft2  proa_ycsh corr_ben if filter_ok==1
tab singleb, m
tab nocft2, m
tab corr_proc, m  //rescale
tab corr_submp, m 
tab corr_decp, m //rescale
tab corr_ben, m  //rescale

gen corr_decp_bi=99
replace corr_decp_bi=corr_decp/2 if corr_decp!=99
tab corr_decp_bi corr_decp

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben

do $utility_codes/cri.do singleb nocft2 corr_proc_bi corr_subm corr_decp_bi proa_ycsh4 corr_ben_bi
rename cri cri_ro

sum cri_ro if filter_ok==1
hist cri_ro if filter_ok==1, title("CRI RO, filter_ok")
hist cri_ro if filter_ok==1, by(tender_year, noiy title("CRI RO (by year), filter_ok")) 
********************************************************************************

save $country_folder/RO_wb_2011.dta, replace
********************************************************************************
*END
