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
use $country_folder/CO_wip.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************

* Winner dependence

sum ca_contract_value if filter_ok==1

egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_id!=. & ca_year!=., by (w_id ca_year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & anb_id!=. & w_id!=. & ca_year!=., by(anb_id w_id ca_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(w_id ca_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"


gen x=1
egen w_ynrc=total(x) if filter_ok==1 & w_id!=. & ca_year!=., by(w_id ca_year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & anb_id!=. & ca_year!=., by(anb_id ca_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

bysort source: sum ca_sign_date
sum ca_start_date if ca_sign_date==.
*best guess at contract award date is contract signature date but with 23% missing 

sort w_id ca_year ca_sign_date
egen filter_wy = tag(w_id ca_year) if filter_ok==1 & w_id!=. & ca_year!=.
lab var filter_wy "Marking Winner years"
tab filter_wy

sort w_id
egen filter_w = tag(w_id) if filter_ok==1 & w_id!=.
lab var filter_w "Marking Winners"
tab filter_w

tab w_ynrc if filter_wy==1
hist w_ycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
********************************************************************************

* Buyer dependence

egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_id!=. & ca_year!=., by(anb_id ca_year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_id ca_year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_id +ca_year +ca_sign_date
egen filter_proay = tag(anb_id ca_year) if filter_ok==1 & anb_id!=. & ca_year!=.
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
hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
********************************************************************************

*company tax haven registration
/*

decode w_country_iso, gen(iso)
do $utility_codes/country-to-iso.do iso
merge m:1 iso using $utility_data/FSI_wide_200812_fin.dta
lab var iso "supplier country ISO"
drop if _merge==2
drop _merge
	 
	drop sec_score
	gen sec_score = SS2009 if ca_year<=2009
	replace sec_score = SS2011 if ca_year==2010 | ca_year==2011
	replace sec_score = SS2013 if ca_year==2012 | ca_year==2013
	replace sec_score = SS2015 if ca_year==2014 | ca_year==2015
	replace sec_score = SS2011 if ca_year<=2009 & sec_score==.
	replace sec_score = SS2013 if ca_year<=2009 & sec_score==.
	replace sec_score = SS2015 if ca_year<=2009 & sec_score==.
	replace sec_score = SS2013 if (ca_year==2011 | ca_year==2010) & sec_score==.
	replace sec_score = SS2015 if (ca_year==2012 | ca_year==2013) & sec_score==.
	lab var sec_score "supplier country Secrecy Score (time varying)"
	sum sec_score

drop rank2009- SS2009

tab w_country, missing
label list w_country

decode w_country_iso, gen(w_country_str)
gen fsuppl=1 
replace fsuppl=0 if w_country_str=="CO" | w_country==.
tab fsuppl, missing
drop w_country_str

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
tab taxhav, missing
tab w_country if taxhav==1 & fsuppl==1
*barely any foreign firm and even fewer tax havens

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"
tab taxhav2, missing
*/
********************************************************************************

*sameloc
*w_loc, anb_loc -- generate w_county, anb_county
*supplier location (county-based): sameloc

/*
gen sameloc_county=.
replace sameloc_county=1 if anb_county==w_county & anb_county!=. & w_county!=.
replace sameloc_county=0 if anb_county!=w_county & anb_county!=. & w_county!=.
replace sameloc_county=9 if sameloc_county==.
tab sameloc_county if filter_ok==1
*/
********************************************************************************

* Submission period
***cft_deadline - limited, only in Secop II Procesos

/*
gen submp =cft_deadline-cft_date
tab submp 
replace submp=. if submp<=0
replace submp=. if submp>183
label var submp "advertisement period"
hist submp if filter_ok==1
sum submp 
sum submp if filter_ok==1
*/
********************************************************************************

* Decision period *
*using contract start date instead of contract award decision or contract award publication date

/*
*cft_deadline, aw_date
sum aw_date cft_deadline
gen decp=aw_date - cft_deadline
sum decp
replace decp=. if decp<=0 | decp >183
sum decp if filter_ok==1
*/
********************************************************************************

* Nocft
/*
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
tab yescft, missing

gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
*/
tab nocft, missing
********************************************************************************

* Signature period
*aw_date, ca_sign_date
/*
gen signp = ca_sign_date - aw_date
*/
********************************************************************************

* Delay (days & relative)
*ci_modif(=1 if any modification)
*ca_ext_days, ca_ext_month, ca_end_date, ci_end_date
/*
rename delay delay_bi
sum delay_bi if filter_ok==1
tab delay_bi if filter_ok==1

rename ca_t_days delay
sum delay
sum delay if filter_ok==1
sum delay if delay<0
sum delay if delay>365
*10K negative, 97K zero values 
*in most cases where delay is <=0, ca_duration is not available

gen rdelay = (ca_duration+delay) / ca_duration
sum rdelay if filter_ok==1
sum rdelay if delay<0
sum rdelay if filter_ok==1 & rdelay>2
sum rdelay if filter_ok==1 & rdelay>3
sum rdelay if filter_ok==1 & rdelay>4
*few exorbitantly high values, outliers or data errors
replace rdelay=. if rdelay>3

hist rdelay


gen ca_duration_alt=ca_end_date-ca_start_date
sum ca_duration_alt
replace ca_duration_alt=. if ca_duration_alt<0
*1200

gen rdelay2 = (ca_duration_alt+delay) / ca_duration_alt
sum rdelay2 if filter_ok==1
sum rdelay2 if delay<0
sum rdelay2 if filter_ok==1 & rdelay2>2
sum rdelay2 if filter_ok==1 & rdelay2>3
sum rdelay2 if filter_ok==1 & rdelay2>4
*/
********************************************************************************
*cancel, ci_modif(=1 if any modification)
*ca_status, is_awarded, ten_status
tab ci_modif if filter_ok==1
replace ci_modif=9 if ci_modif==.
tab ci_modif if filter_ok==1
****60k modified contract
********************************************************************************

* Overrun (absolute and relative)
*ci_modif(=1 if any modification)
*ca_contract_value, paid_value -- this refers to the amount already paid, but those tenders have pending values as well, there sum should be considered for this indicator
/*
gen ci_value= paid_value + pending_pvalue
sum ca_contract_value ci_value

gen overrun=ci_value - ca_contract_value 
sum overrun if filter_ok==1
hist overrun if filter_ok==1
lab var overrun "cost overrun"

gen roverrun=ci_value /ca_contract_value
sum overrun roverrun if filter_ok==1
lab var roverrun "relative cost overrun"
sum roverrun if filter_ok==1 & roverrun<1
sum roverrun if filter_ok==1 & roverrun<0.9
sum roverrun if filter_ok==1 & roverrun<0.5
sum roverrun if filter_ok==1 & roverrun<0.2
replace roverrun=. if roverrun<0.2
sum roverrun if filter_ok==1 & roverrun==1
*mostly on target
sum roverrun if filter_ok==1 & roverrun>1
sum roverrun if filter_ok==1 & roverrun>2
sum roverrun if filter_ok==1 & roverrun>3
replace roverrun=. if roverrun>3
*/

sum roverrun if filter_ok==1
hist roverrun if filter_ok==1
********************************************************************************

* Validity regressions 



*** controls only

tab year if filter_ok==1, missing

sum proa_ycsh ca_contract_value ca_contract_value5 year ca_type marketid anb_type anb_county source if filter_ok==1

reg proa_ycsh i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county if filter_ok==1, base
reg w_ycsh i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county if filter_ok==1, base

*** controls + red flags


sum proa_ycsh ca_procedure submp decp nocft roverrun rdelay ci_advance rpendingval ci_modif if filter_ok==1
sum ca_contract_value

********************************************************************************
*ca_procedure

* procedure type

reg proa_ycsh i.ca_procedure i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh ib4.ca_procedure i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
/*

label list ca_procedure
gen corr_proc=.
replace corr_proc=2 if ca_procedure==2 | ca_procedure==3
replace corr_proc=1 if ca_procedure==1 | ca_procedure==7
replace corr_proc=0 if ca_procedure==4 | ca_procedure==5
replace corr_proc=99 if corr_proc==.
tab corr_proc
*/

reg proa_ycsh i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
********************************************************************************

*nocft
reg proa_ycsh i.nocft i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
*as expected
********************************************************************************

*tax haven

tab taxhav if filter_ok==1
tab taxhav2 if filter_ok==1
tab taxhav2 if filter_ok==1 & fsuppl==1
tab taxhav2 fsuppl
replace taxhav2=9 if fsuppl==0
tab taxhav2 if filter_ok==1
*very few, 573 cases

ttest proa_mycsh if filter_ok==1 & fsuppl==1 & filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., by(taxhav2)
*no observation, but keep as rare red flag because literature is unequivocal
ttest proa_ycsh if filter_ok==1 & fsuppl==1 & proa_nrc>=5, by(taxhav2)
*small sample, negative, insignificant
********************************************************************************


*sameloc_county
tab sameloc_county if filter_ok==1
tab sameloc_county source if filter_ok==1
*missing for secop2
reg proa_ycsh i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
*ok
********************************************************************************

*submp
/*
xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp==.
tab submp5 if filter_ok==1

xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
tab submp10 if filter_ok==1

xtile submp25=submp if filter_ok==1, nquantiles(25)
replace submp25=99 if submp==.
tab submp25 if filter_ok==1
*/

gen submp3=.
replace submp3=1 if submp<6 & submp!=.
replace submp3=2 if submp>=6 & submp<10 & submp!=.
replace submp3=3 if submp>=10 & submp!=.
replace submp3=99 if submp==.


*only secop2
reg proa_ycsh i.nocft i.submp3 i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh i.nocft i.submp3#corr_proc i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh i.nocft ib5.submp5 i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh i.nocft ib5.submp5 i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1 & corr_proc==0, base
reg proa_ycsh i.nocft i.submp5#corr_proc i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh i.nocft ib5.submp10 i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh i.nocft ib13.submp25 i.sameloc_county i.direct_noreason i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
*counterint., longer submission period has higher risk
********************************************************************************

*decp - decision making period
sum decp
hist decp
/*

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp==.
xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp==.
*/
tab decp5
tab decp10
tabstat decp, by(decp10) stat(min max mean N)

reg proa_ycsh decp i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh ib2.decp5 i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
reg proa_ycsh ib5.decp10 i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1, base
*counterint., longer decision period has higher risk
********************************************************************************

*Benford's law export
decode anb_id, gen(anb_ids)
replace anb_ids="" if anb_ids=="."
preserve
    rename anb_ids buyer_id //buyer id variable
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
********************************************************************************
save $country_folder/CO_wip.dta, replace
********************************************************************************
use $utility_codes/benford.R, clear
rename buyer_id anb_ids 
save $utility_codes/benford.R, repalce
********************************************************************************

use $country_folder/CO_wip.dta, replace
merge m:1 anb_ids using $country_folder/buyers_benford.dta
drop _m
drop anb_ids

br anb_id MAD MAD_conformitiy
tab MAD_conformitiy, m
tabstat MAD, by(MAD_conformitiy) stat(min mean max)
*Theoretical mad values and conformity
/*Close conformity — 0.0044941 to 0.005985
Acceptable conformity — 0.0064871 to 0.0119673
Marginally acceptable conformity — 0.0120304 to 0.0149709
Nonconformity — greater than 0.0150217
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)

reg proa_ycsh i.corr_ben i.corr_rdelay2 i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.ca_year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1 & proa_nrc>=5, base
*sameloc changes direction
********************************************************************************

*final best regression
reg proa_ycsh i.corr_ben i.corr_rdelay2 i.sameloc_county i.nocft i.corr_proc i.ca_contract_value10 i.ca_year i.ca_type i.marketid i.anb_type i.anb_county i.source if filter_ok==1 & proa_nrc>=5, base
********************************************************************************

* Single bidding

/*
sum ca_nrbid
gen singleb=1 if ca_nrbid==1
replace singleb=0 if ca_nrbid>1 
replace singleb=99 if ca_nrbid==.
tab singleb 
*/
********************************************************************************
* CRI calculations

*best risk indicators based on single bidder regressions
sum proa_ycsh corr_ben corr_rdelay2 sameloc_county nocft taxhav2 corr_proc if filter_ok==1 & proa_nrc>=5, base


tab corr_ben if filter_ok==1 //needs binarisation
tab sameloc_county if filter_ok==1
tab nocft if filter_ok==1
tab corr_proc //needs binarisation
tab corr_rdelay2 if filter_ok==1 //needs binarisation

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc

/*
gen corr_rdelay2_bi=99
replace corr_rdelay2_bi=corr_rdelay2/2 if corr_rdelay2!=9
tab corr_rdelay2_bi corr_rdelay2
*/

/*
gen proa_ycsh5=proa_ycsh if filter_ok==1 & proa_ynrc>5 & proa_ynrc!=.
sum proa_ycsh5 proa_ycsh
*/

cap drop cri_col
do $utility_codes/cri.do  proa_ycsh5 nocft corr_proc_bi corr_ben_bi taxhav2 sameloc_county corr_rdelay2_bi singleb
rename cri cri_col


sum cri_col if filter_ok==1
hist cri_col if filter_ok==1
hist cri_col if filter_ok==1 & & cri_col>0.66, freq
hist cri_col if filter_ok==1, by(ca_year)
********************************************************************************

save $country_folder/wb_col_cri201126.dta, replace
********************************************************************************
*END