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
use $country_folder/MX_wip.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************

*(Re)Checking indicators
*Used same calculated variables from older script
desc *corr* singleb nocft *tax* *csh* *cri*
********************************************************************************

*Single bidding

*From older code - do not run this section
/*
gen ca_nrbid_trim=ca_nrbid
replace ca_nrbid_trim=50 if ca_nrbid>=50 & ca_nrbid!=.
hist ca_nrbid_trim
lab var ca_nrbid_trim "number of bids trimmed to 50"

gen singleb=.
replace singleb=1 if ca_nrbid==1
replace singleb=0 if ca_nrbid>1 & ca_nrbid!=.
tab singleb
lab var singleb "single-bid red flag"
*/
tab singleb, m
********************************************************************************
*Procedure type

*From older code - do not run this section
/*
rename ca_procedure ca_procedure_form
rename ca_procedure2 ca_procedure_int
rename ca_procedure_broad ca_procedure_ocds
lab var ca_procedure_ocds "simple, OCDS-compliant procedure type"
lab var ca_procedure_nat "national, detailed procedure type"

gen ca_procedure=.
label list ca_procedure_broad_n
label define ca_procedure 1"direct contracting" 2"invitation (3 entities)" 3"open auction" 4"missing" 5"other", replace
lab values ca_procedure ca_procedure
replace ca_procedure=1 if ca_procedure_nat==1
replace ca_procedure=1 if ca_procedure_nat==2
replace ca_procedure=2 if ca_procedure_nat==3
replace ca_procedure=2 if ca_procedure_nat==4
replace ca_procedure=3 if ca_procedure_nat==5
replace ca_procedure=3 if ca_procedure_nat==6
replace ca_procedure=3 if ca_procedure_nat==7
replace ca_procedure=4 if ca_procedure_nat==8
replace ca_procedure=5 if ca_procedure_nat==9
replace ca_procedure=5 if ca_procedure_nat==10
tab ca_procedure_nat ca_procedure
tab ca_procedure
tab ca_procedure ca_procedure_ocds
lab var ca_procedure "composed procedure type"


tab ca_procedure_int ca_procedure
*interesting combinations, create new international/national var
tab ca_procedure ca_procedure_form
*interesting variation

label list ca_procedure2_n
label define ca_procedure_int_bi 1"international" 2"national" 3"missing" 4"other", replace
gen ca_procedure_int_bi=.
replace ca_procedure_int_bi=1 if ca_procedure_int==1
replace ca_procedure_int_bi=1 if ca_procedure_int==2
replace ca_procedure_int_bi=1 if ca_procedure_int==3
replace ca_procedure_int_bi=1 if ca_procedure_int==4
replace ca_procedure_int_bi=2 if ca_procedure_int==6
replace ca_procedure_int_bi=3 if ca_procedure_int==5
replace ca_procedure_int_bi=4 if ca_procedure_int==7
label values ca_procedure_int_bi ca_procedure_int_bi
lab var ca_procedure_int_bi "inter/national procedure"
tab ca_procedure_int_bi
tab ca_procedure_int_bi ca_procedure


gen corr_proc=.
replace corr_proc=0 if ca_procedure==3
replace corr_proc=1 if ca_procedure==2
replace corr_proc=2 if ca_procedure==1
replace corr_proc=0 if ca_procedure==4

tab ca_procedure ca_procedure_int_bi
replace corr_proc=0 if ca_procedure_int_bi==1

tab corr_proc ca_procedure_form
replace corr_proc=2 if ca_procedure_form==4
replace corr_proc=1 if ca_procedure_form==2

tab corr_proc, missing
tab corr_proc if filter_ok==1, missing

tab corr_proc ca_procedure if filter_ok==1
tab ca_procedure_nat corr_proc if filter_ok==1
tab corr_proc ca_procedure_form if filter_ok==1
*/

tab corr_proc, m
tab corr_proc_bi, m

logit singleb  i.corr_proc  ca_contract_value100 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base  
********************************************************************************
*Adv/Submission period


*From older code - do not run this section
/*
gen submp =cft_deadline-cft_date
tab submp 
label var submp "advertisement period"
replace submp=. if submp<0

xtile submp25=submp if filter_ok==1, nquantiles(25)
replace submp25=99 if submp==.
replace submp25=99 if nocft==1


gen corr_submp=.
replace corr_submp=0 if submp25>=19 & submp25!=.
replace corr_submp=1 if submp25>=7 & submp25<=18 & submp25!=.
replace corr_submp=2 if submp25<=5 & submp25!=.
replace corr_submp=99 if submp25==99
tab submp25 corr_submp, missing
tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

*/
tab corr_submp, m


logit singleb i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base
********************************************************************************

*No cft

*From older code - do not run this section
/*
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
tab yescft, missing

gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
tab nocft, missing
*/

tab nocft, m
logit singleb  i.nocft i.corr_proc  ca_contract_value100 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base
********************************************************************************

*Decision period

*From older code - do not run this section
/*
gen decp=ca_start_date - cft_deadline
sum decp
replace decp=0 if decp<0 & decp!=0

xtile decp25=decp if filter_ok==1, nquantiles(25)
replace decp25=99 if decp==.


gen corr_decp=.
replace corr_decp=0 if decp25>=16 & decp25!=.
replace corr_decp=2 if decp25==1 & decp25!=.
replace corr_decp=1 if decp25>=6 & decp25<=15 & decp25!=.
replace corr_decp=99 if decp==.
tab decp25 corr_decp, missing
*/

tab corr_decp, m
tab corr_decp_bi, m
logit singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base 
********************************************************************************

*Contract Share

*From older code - do not run this section
/*
egen w_yam=sum(ca_contract_value) if filter_ok==1 & w_id2!=. & year!=., by (w_id2 year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_contract_value) if filter_ok==1 & anb_id_detail!=. & w_id2!=. & year!=., by(anb_id_detail w_id2 year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam 
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(w_id2 year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

gen x=1
egen w_ynrc=total(x) if filter_ok==1 & w_id2!=. & year!=., by(w_id2 year)
drop x
lab var w_ynrc "#Contracts by Win-year"

gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & anb_id_detail!=. & year!=., by(anb_id_detail year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort w_id2 year ca_sign
egen filter_wy = tag(w_id2 year) if filter_ok==1 & w_id2!=. & year!=.
lab var filter_wy "Marking Winner years"
tab filter_wy

sort w_id2
egen filter_w = tag(w_id2) if filter_ok==1 & w_id2!=.
lab var filter_w "Marking Winners"
tab filter_w

tab w_ynrc if filter_wy==1
hist w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
hist w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=., title("Highest share of amounts received from same buyer by Winner") subtitle("Number of Winner-years: `n'") freq
sum w_ycsh if filter_wy==1 & w_ynrc>2 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>4 & proa_ynrc!=.
sum w_mycsh if filter_wy==1 & w_ynrc>9 & proa_ynrc!=.
*spectacularly high values, huge concentration, probably represents the great concentration of buying power, few large ministries and a large supplier pool
*/

br w_ycsh w_mycsh proa_ycsh proa_mycsh  w_ycsh

reg w_ycsh i.singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
*singleb, nocft, corr_proc work
reg w_ycsh i.singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*nocft and corr_proc work
*Using contract share from supplier side
gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
*use : w_ycsh4
********************************************************************************

*Trying the buyer side calc

*From older code - do not run this section
/*
egen proa_yam=sum(ca_contract_value) if filter_ok==1 & anb_id_detail!=. & year!=., by(anb_id_detail year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_id_detail year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_id_detail +year +ca_start_date
egen filter_proay = tag(anb_id_detail year) if filter_ok==1 & anb_id_detail!=. & year!=.
lab var filter_proay "Marking PA years"
tab filter_proay

sort anb_id_detail
egen filter_proa = tag(anb_id_detail) if filter_ok==1 & anb_id_detail!=.
lab var filter_proa "Marking PAs"
tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & anb_id_detail!=., by(anb_id_detail)
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

gen proa_ycsh9=proa_ycsh if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=.
sum proa_ycsh9 proa_ycsh
*/

br w_ycsh w_mycsh proa_ycsh proa_mycsh  w_ycsh
reg proa_ycsh i.singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & proa_ynrc>2 & proa_ynrc!=., base
*nocft, corr_proc work
reg proa_ycsh i.singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
*nocft and corr_proc work
gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.

********************************************************************************

*Tax haven
desc *tax*

*From older code - do not run this section
/*
gen fsuppl=1 
replace fsuppl=0 if w_country_str=="MX" | w_country==.
tab fsuppl, missing
drop w_country_str

gen taxhav =.
replace taxhav = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav = 1 if sec_score>59.5 & sec_score!=.
*replace taxhav = 9 if fsuppl==0
lab var taxhav "supplier is from tax haven (time varying)"
tab taxhav, missing
tab w_country if taxhav==1 & fsuppl==1

gen taxhav2 = taxhav
replace taxhav2 = 0 if taxhav==. 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"
tab taxhav2, missing
*/

tab taxhav, m
tab taxhav2, m  //use this

gen fsuppl2= fsuppl
replace fsuppl2 = 2 if fsuppl==1 & taxhav==1
tab fsuppl2 if filter_ok==1, m
bys fsuppl2: tab singleb, m
br ca_nrbid if fsuppl2==1 //no singleb information for suppliers in tax haven 

logit singleb i.fsuppl2 i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base  
* Tax haven can't be validated so it won't be included in cri

********************************************************************************

*Cost Overrun

*From older code - do not run this section
/*
gen overrun=ci_value - ca_contract_value 
sum overrun
hist overrun
lab var overrun "cost overrun"

gen roverrun=(ci_value - ca_contract_value )/ca_contract_value
sum overrun roverrun
hist roverrun
*/

desc *overrun*
hist  overrun
br overrun roverrun if !missing(overrun)
hist roverrun if !missing(roverrun)

********************************************************************************

*Benford's
count if missing(anb_id)
count if missing(anb_id2)
unique anb_id
unique anb_id2
br anb_id anb_id2
sort anb_id2
br anb_id2 anb_name  //use anb_id2
sum ca_contract_value
save $country_folder/MX_wip.dta, replace

*********************************
preserve
    rename anb_id2 buyer_id //buyer id variable
    *rename xxxx ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_id: gen count = _N
    keep if count >100
	drop count
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
    export delimited  $country_folder/buyers_for_R.csv, replace
    * set directory 
    ! cd $country_folder
	//Make sure to change path to the local path of Rscript.exe
    ! "C:/Program Files/R/R-3.6.0/bin/x64/Rscript.exe" $utility_codes/benford.R
restore
*********************************

gen buyer_id = anb_id2
merge m:1 buyer_id using $country_folder/buyers_benford.dta
drop _m buyer_id
br anb_id2 MAD MAD_conformitiy

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)

logit singleb i.corr_ben i.corr_decp i.corr_submp  i.nocft i.corr_proc i.taxhav2 i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base  //corr_ben is valid
********************************************************************************

*Final best regressions

logit singleb i.corr_ben i.corr_decp i.corr_submp  i.nocft i.corr_proc i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1, base  

reg w_ycsh i.singleb i.corr_ben i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base


reg proa_ycsh i.singleb i.corr_ben i.corr_decp i.corr_submp  i.nocft i.corr_proc  i.ca_contract_value10 anb_location i.anb_type i.year i.ca_type i.w_sector if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base

********************************************************************************
save $country_folder/MX_wip.dta, replace
********************************************************************************
use $country_folder/MX_wip.dta, clear

*Calculate CRI
drop cri*
*CRI generation
sum singleb corr_proc corr_submp corr_decp  nocft corr_ben w_ycsh  if filter_ok==1
tab singleb, m
tab corr_proc, m  //turn into binary
tab corr_submp, m //turn into binary
tab corr_decp, m //turn into binary
tab nocft, m
tab taxhav2, m  //out of cri
tab corr_ben, m //turn into binary
tab w_ycsh, m

*gen corr_submp_bi=99
*replace corr_submp_bi=corr_submp/2 if corr_submp!=99
tab corr_submp_bi corr_submp

*gen corr_proc_bi=99
*replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc, m

tab corr_decp_bi corr_decp, m

tab  corr_ben, m
gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
tab corr_ben_bi corr_ben, m

*gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
sum w_ycsh4 w_ycsh

do $utility_codes/cri.do  singleb corr_proc_bi corr_submp_bi corr_decp_bi corr_ben_bi nocft  proa_ycsh4
rename cri cri_mx


sum cri_mx if filter_ok==1
hist cri_mx if filter_ok==1
********************************************************************************

save $country_folder/MX_171020.dta , replace
********************************************************************************
*END