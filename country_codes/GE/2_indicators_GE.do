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
use $country_folder/GE_wip.dta, clear
********************************************************************************

*Procedure type
tab tender_proceduretype, missing
tab tender_nationalproceduretype, missing
gen ca_procedure2=.
replace ca_procedure2 = 1 if regex(tender_nationalproceduretype,"NAT")
replace ca_procedure2 = 2 if regex(tender_nationalproceduretype,"DAP")
replace ca_procedure2 = 3 if regex(tender_nationalproceduretype,"SPA")
replace ca_procedure2 = 4 if regex(tender_nationalproceduretype,"MEP")
replace ca_procedure2 = 5 if regex(tender_nationalproceduretype,"DEP")
replace ca_procedure2 = 6 if regex(tender_nationalproceduretype,"GEO")
tab tender_national if filter, m
tab ca_procedure2 if filter, m
rename ca_procedure2 ca_procedure
tab ca_procedure if filter, m

gen corr_proc=.
replace corr_proc=0 if inlist(ca_procedure,1,2,4,5)
replace corr_proc=1 if ca_procedure==3  
replace corr_proc=2 if ca_procedure==6
replace corr_proc=99 if ca_procedure==.

tab corr_proc, missing
tab corr_proc ca_procedure if filter_ok==1, missing
********************************************************************************

*Submission period
*submission period = bid deadline -first or last call for tender

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0
sum submp
hist submp
hist submp, by(tender_nationalproceduretype )
sum submp, det  //largest 105 days ok

xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.

gen corr_submp=0
replace corr_submp=1 if (submp10==5 | submp10==6 | submp10==7)
replace corr_submp=2 if (submp10<=2)
replace corr_submp=99 if submp10==99
tab submp10 corr_submp, missing

tab corr_submp if filter_ok, m
tabstat submp, by(submp10) stat(min max)
********************************************************************************

*decision period = contract award or similar - deadline

gen decp=aw_date - bid_deadline
sum decp
hist decp
replace decp=0 if decp<0 & decp!=0
count if decp==0 & filter_ok

hist decp //mostly close to zero
sum decp if decp>365
sum decp if decp>183
sum decp if decp>100
hist decp if decp<365
hist decp if decp<183
tab decp if decp>183 //take half year as an upper bound

replace decp=. if decp>183
lab var decp "decision period"

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.


gen corr_decp=.
replace corr_decp=0 if decp5>=3 & decp5!=99
replace corr_decp=1 if (decp5<=2 | decp5==5) & decp5!=99
replace corr_decp=99 if decp==.
tab decp5 corr_decp, missing

tab corr_decp if filter_ok, m
tabstat decp, by(decp5) stat(min max)
********************************************************************************

*singlebidding
gen singleb=.
replace singleb=0 if filter_ok==1
replace singleb=1 if tender_recordedbidscount==1 & filter_ok==1
replace singleb=99 if missing(singleb)

tab singleb if filter_ok , missing  //51% singlebidding
mean singleb if filter_ok //0.51
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

gen fsuppl=1 
replace fsuppl=0 if bidder_country=="GE" | bidder_country==""
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

egen w_yam=sum(ca_contract_value) if filter_ok==1 & bidder_id!="" & tender_year!=., by (bidder_id tender_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & buyer_id!=. & bidder_id!="" & tender_year!=., by(buyer_id bidder_id tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(bidder_id tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

gen x=1
egen w_ynrc=total(x) if filter_ok==1 & bidder_id!="" & tender_year!=., by(bidder_id tender_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & buyer_id!=. & tender_year!=., by(buyer_id tender_year)
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
egen filter_wproa = tag(bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
tab filter_wproa

sort tender_year bidder_id buyer_id
egen filter_wproay = tag(tender_year bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!=. & tender_year!=.
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

merge m:1 buyer_id using $country_folder/buyers_benford.dta
drop _m

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

logit singleb i.corr_ben i.corr_proc i.corr_submp i.corr_decp i.nocft i.taxhav2 lca_contract_value i.anb_type i.tender_year i.marketid if filter_ok, base
*looks great

/*
hist MAD
gen corr_ben_bi = .
replace corr_ben_bi = 0 if MAD<0.02
replace corr_ben_bi = 0 if MAD>=0.02
replace corr_ben_bi = 99 if missing(MAD)

logit singleb i.corr_ben_bi i.corr_proc i.corr_submp i.corr_decp i.nocft i.taxhav2 lca_contract_value i.anb_type i.tender_year i.marketid if filter_ok, base
*looks great
*/
********************************************************************************

*CRI components validation
*controls only
sum singleb buyer_buyertype lca_contract_value tender_year tender_supplytype
sum singleb buyer_buyertype lca_contract_value tender_year tender_supplytype if filter_ok==1
logit singleb lca_contract_value i.anb_type  i.tender_year , base
logit singleb lca_contract_value i.anb_type  i.tender_year  if filter_ok, base
*Full
logit singleb i.corr_proc i.corr_submp i.corr_decp i.nocft lca_contract_value i.anb_type  i.tender_year  if filter_ok, base
*low R2 - positive coeffcients 

*checking contract share
reg w_ycsh singleb i.corr_proc i.corr_submp i.corr_decp i.nocft lca_contract_value i.anb_type  i.tender_year if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
reg w_ycsh singleb i.corr_proc i.corr_submp i.corr_decp i.nocft lca_contract_value i.anb_type  i.tender_year if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
reg w_ycsh singleb i.corr_proc i.corr_submp i.corr_decp i.nocft lca_contract_value i.anb_type  i.tender_year if filter_ok==1 & w_ynrc>9 & w_ynrc!=., base
*subm is negative

*** final best regression and valid red flags

logit singleb i.corr_ben i.corr_proc i.corr_submp i.corr_decp i.nocft i.taxhav2 lca_contract_value i.anb_type i.tender_year i.marketid if filter_ok, base
*looks good
*outreg2 using ge_cri_valid1.doc
tabstat submp if e(sample), stat(mean min max) by(corr_submp)
tabstat decp if e(sample), stat(mean min max) by(corr_decp)
tabstat decp if e(sample), stat(mean min max) by(decp5)

reg w_ycsh singleb i.corr_proc i.corr_submp i.corr_decp i.nocft i.taxhav2  lca_contract_value i.anb_type i.tender_year  i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*great works for most predictors, R2=23.17%
********************************************************************************

*CRI generation
sum singleb corr_proc corr_submp corr_decp nocft taxhav2 nocft w_ycsh corr_ben if filter_ok==1
tab singleb, m
tab corr_proc, m  //turn into binary
tab corr_submp, m //turn into binary
tab corr_decp, m
tab nocft, m
tab taxhav2, m
tab corr_ben, m  //turn into binary
tab w_ycsh, m

gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
tab corr_submp_bi corr_submp

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
sum w_ycsh4 w_ycsh


do $utility_codes/cri.do singleb corr_proc_bi corr_submp_bi corr_decp nocft taxhav2 w_ycsh4 corr_ben_bi
rename cri cri_ge

sum cri_ge if filter_ok==1
hist cri_ge if filter_ok==1, title("CRI GE, filter_ok")
hist cri_ge if filter_ok==1, by(tender_year, noiy title("CRI GE (by year), filter_ok")) 
********************************************************************************

save $country_folder/GE_wb_0920.dta, replace
********************************************************************************
*END