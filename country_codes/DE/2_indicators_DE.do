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
use $country_folder/DE_wip.dta, clear
********************************************************************************

*CRI components
*12 components - proc, decp, submp, nocft, singleb, taxhav, supplier share, benford, selection method, award criteria count, contract modification, published documents

******************************************
*Procedure type
tab tender_proceduretype, missing
tab tender_nationalproceduretype, missing

******************************************
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

replace submp=. if submp>183
************************************

*Decision period

*decision period = contract award or similar - deadline

sum aw_date ca_date bid_deadline

gen decp=aw_date - bid_deadline
sum decp
hist decp
count if decp==0 & filter_ok //14
replace decp=. if decp<=0 

hist decp //mostly close to zero
sum decp if decp>365
sum decp if decp>183
sum decp if decp>100
hist decp if decp<365
hist decp if decp<183
tab decp if decp>365 

replace decp=. if decp>365
lab var decp "decision period"
************************************

*singlebidding
sum tender_recordedbidscount lot_bidscount if filter_ok==1
gen singleb=.
replace singleb=0 if lot_bidscount!=1 & lot_bidscount!=.
replace singleb=1 if lot_bidscount==1
tab singleb
tab singleb if filter_ok , missing  //14.33% singlebidding
************************************

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
************************************
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
************************************

*Winning Supplier's contract share (by PE, by year)

egen x= nvals(bidder_id)
tab x
drop x
*30427

egen x= nvals(bidder_masterid)
tab x
drop x
*224813

egen x= nvals(bidder_name)
tab x
drop x
*140732

egen x= nvals(buyer_id)
tab x
drop x
*8032

egen x= nvals(buyer_masterid)
tab x
drop x
*71207

egen x= nvals(buyer_name)
tab x
drop x
*39883

sum ca_contract_value if filter_ok==1
rename bidder_name bidder_name_orig
gen bidder_name=lower(bidder_name_orig)

egen w_id_gen=group(bidder_name)
label var w_id_gen "generated company ID"

rename buyer_id buyer_id_orig
rename buyer_name buyer_name_orig
gen buyer_name=lower(buyer_name_orig)

egen buyer_id=group(buyer_name)
label var buyer_id "generated buyer ID"

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
************************************

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
************************************

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
/*Close conformity — 0.0046788 to 0.0056759
Acceptable conformity — 0.0063 to 0.0119974
Marginally acceptable conformity — 0.012052 to 0.0147474
Nonconformity — greater than 0.0150446
*/

cap drop corr_ben
gen corr_ben = .
replace corr_ben = 0 if inlist(MAD_conformitiy,"Acceptable conformity","Close conformity")
replace corr_ben = 1 if MAD_conformitiy=="Marginally acceptable conformity"
replace corr_ben = 2 if MAD_conformitiy=="Nonconformity"
replace corr_ben = 99 if missing(MAD_conformitiy)
************************************

*published documents
tab tender_documents_count
*67.5% has 0 published documents
************************************


********************************************************************************

*CRI components validation

*controls only

sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid
sum singleb anb_type anb_loc ca_contract_value10 tender_year ca_type marketid if filter_ok==1
*some missing in singleb
replace ca_type=99 if ca_type==.
replace anb_loc=999 if anb_loc==.

logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid, base
logit singleb i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*number of obs = 398,686, Pseudo R2 = 0.1316
********************************************************************************

*procedure types

tab tender_proceduretype if filter_ok==1
encode tender_proceduretype,gen(ca_procedure)
tab ca_procedure

logit singleb i.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib6.ca_procedure i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen corr_proc=.
replace corr_proc=0 if ca_procedure==1 | ca_procedure==3 | ca_procedure==6
replace corr_proc=1 if ca_procedure==8 | ca_procedure==5 | ca_procedure==2
replace corr_proc=2 if ca_procedure==7 | ca_procedure==4
replace corr_proc=99 if ca_procedure==. |  corr_proc==.
tab corr_proc

logit singleb i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*nocft

tab nocft if filter_ok==1
*39.46% of the contracts had no call for tenders
tab ca_procedure nocft if filter_ok==1
tab corr_proc nocft if filter_ok==1

logit singleb i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*as expected
********************************************************************************

*selection method

tab tender_selectionmethod if filter_ok==1
tab tender_selectionmethod ca_procedure if filter_ok==1, missing
encode tender_selectionmethod,gen(ten_select)

logit singleb i.ten_select i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************

gen corr_crit=.
replace corr_crit=0 if ten_select==2
replace corr_crit=1 if ten_select==1
replace corr_crit=99 if ten_select==.

logit singleb i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*advertisement period
sum submp
tab submp
hist submp if filter_ok==1
hist submp if filter_ok==1 & submp<80
hist submp if filter_ok==1 & submp<60
hist submp, by(ca_procedure)
*similar patterns for each category, 93% <=30 days

xtile submp5=submp if filter_ok==1, nquantiles(5)
replace submp5=99 if submp5==.
xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp10==.

tab submp5
tab submp10
tab submp10 nocft
sum submp if nocft==1
*no overlaps

tabstat submp, by(submp10) stat(min max N)
tabstat submp, by(submp5) stat(min max N)

logit singleb submp i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib5.submp5 i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib9.submp10 i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base

gen submp10simp=submp10
replace submp10simp=9 if submp10==8
replace submp10simp=9 if submp10==10
tab submp10simp submp10

logit singleb ib9.submp10simp i.corr_crit i.nocft i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base


logit singleb i.submp10#i.corr_proc i.corr_crit i.nocft ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.submp5#i.corr_proc i.corr_crit i.nocft ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*shorter submission periods increase risk of single bidding, but insign

gen corr_submp=.
replace corr_submp=0 if submp10simp==9
replace corr_submp=1 if submp10>=4 & submp10<=7 & submp10!=99 
replace corr_submp=2 if submp10>=1 & submp10<=3 & submp10!=99 
replace corr_submp=99 if submp10==99 | submp10==.
tab submp10 corr_submp, missing
tabstat submp if filter_ok==1, by(corr_submp) stat(min mean max N)

logit singleb i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*decision making period

sum decp
hist decp

xtile decp5=decp if filter_ok==1, nquantiles(5)
replace decp5=99 if decp5==.
xtile decp10=decp if filter_ok==1, nquantiles(10)
replace decp10=99 if decp10==.
tab decp5, m 
tab decp10, m 
tabstat decp, by(decp10) stat(min max mean N)

logit singleb decp i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.decp5 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.decp10 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib10.decp10 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib5.decp10 i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*this works

gen corr_decp=.
replace corr_decp=0 if decp210>=6 & decp210!=99
replace corr_decp=1 if decp210>=3 & decp210<=5 & decp210!=99
replace corr_decp=2 if decp210<=2 & decp210!=99
replace corr_decp=99 if decp210==99 | corr_decp==.
tab decp210 corr_decp, m

logit singleb i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok
********************************************************************************

*award criteria count
tab tender_awardcriteria_count
*15,91% 0, 58.42% 1 criteria

xtile ten_awcrit5=tender_awardcriteria_count if filter_ok==1, nquantiles(5)
replace ten_awcrit5=99 if tender_awardcriteria_count==.

gen ten_awcrit3=1 if tender_awardcriteria_count<=1 & filter_ok==1
replace ten_awcrit3=2 if tender_awardcriteria_count>=2 & tender_awardcriteria_count<=5 & filter_ok==1
replace ten_awcrit3=3 if tender_awardcriteria_count>=6 & tender_awardcriteria_count!=99 & filter_ok==1
replace ten_awcrit3=99 if tender_awardcriteria_count==.

logit singleb tender_awardcriteria_count i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.ten_awcrit5 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.ten_awcrit3 i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*little variance, more specifications decrease the risk of single bidding 
********************************************************************************

*contract modification
tab tender_corrections_count if filter_ok==1
*no variance, 94.72% of tenders have no modification
********************************************************************************

*published documents
tab tender_documents_count if filter_ok==1
*99% of tenders have 0 or 1 document published

xtile ten_doc5=tender_documents_count if filter_ok==1, nquantiles(5)
replace ten_doc5=99 if tender_documents_count==.

logit singleb tender_documents_count i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb i.ten_doc5 i.corr_decp i.corr_submp i.nocft i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
logit singleb ib4.ten_doc5 i.corr_decp i.corr_submp i.nocft i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*doesn't work
********************************************************************************

*benford's law
logit singleb i.corr_ben i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*ok, cat1 positive, but insign.

gen corr_ben_bi=corr_ben
replace corr_ben_bi=1 if corr_ben==2
replace corr_ben_bi=99 if corr_ben==99

logit singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
********************************************************************************

*tax haven

tab taxhav if filter_ok==1
tab taxhav2 if filter_ok==1
tab taxhav2 if filter_ok==1 & fsuppl==1

ttest singleb if filter_ok==1 & fsuppl==1, by(taxhav2)
*neg, significant

ttest corr_proc if filter_ok==1 & fsuppl==1, by(taxhav2)
*neg, significant

ttest nocft if filter_ok==1 & fsuppl==1, by(taxhav2)
*neg, significant

ttest w_mycsh if filter_ok==1 & fsuppl==1 & filter_wy==1 & w_ynrc>2 & w_ynrc!=., by(taxhav2)
*pos, sign, small sample

*supplier dependence on buyer
tabstat w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb) stat(mean sd N)
ttest w_ycsh if filter_wproay==1 & w_ynrc>2 & w_ynrc!=., by(singleb)
*positive sign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>4 & w_ynrc!=., by(singleb)
*positive sign.
ttest w_ycsh if filter_wproay==1 & w_ynrc>9 & w_ynrc!=., by(singleb)
*positive sign.

reg w_ycsh singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>2 & w_ynrc!=., base
reg w_ycsh singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & w_ynrc>4 & w_ynrc!=., base
*only corr_crit works

hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>2 & w_ynrc!=., freq
hist w_ycsh if filter_ok==1 & filter_wproay==1 & w_ynrc>4 & w_ynrc!=., freq
********************************************************************************

*buyer spending concentration
tabstat proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb) stat(mean sd N)
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>2 & proa_ynrc!=., by(singleb)
*negative, significant
ttest proa_ycsh if filter_wproay==1 & proa_ynrc>9 & proa_ynrc!=., by(singleb)
*negative, significant

reg proa_ycsh singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>4 & proa_ynrc!=., base
reg proa_ycsh singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*singleb, benford, decision period works
********************************************************************************

*** final best regression and valid red flags
logit singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1, base
*19.38% explanatory power

reg proa_ycsh singleb i.corr_ben_bi i.corr_decp i.nocft i.corr_submp i.corr_crit i.corr_proc i.ca_contract_value10 i.anb_type i.anb_loc i.tender_year i.ca_type i.marketid if filter_ok==1 & proa_ynrc>9 & proa_ynrc!=., base
*R2=25.09%
********************************************************************************

*CRI generation
sum singleb corr_proc corr_submp corr_decp nocft corr_crit taxhav2 proa_ycsh corr_ben_bi if filter_ok==1
tab singleb, m
tab corr_proc, m //binarisation
tab corr_submp, m //binarisation
tab corr_decp, m
tab corr_crit, m
tab corr_ben_bi, m
tab taxhav2, m
tab nocft, m

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc/2 if corr_proc!=99
tab corr_proc_bi corr_proc, missing

gen corr_submp_bi=99
replace corr_submp_bi=corr_submp/2 if corr_submp!=99
tab corr_submp_bi corr_submp, missing

gen proa_ycsh9=proa_ycsh if filter_ok==1 & proa_ynrc>9 & proa_ycsh!=.
sum proa_ycsh9 proa_ycsh


do $utility_codes/cri.do singleb corr_proc_bi corr_submp_bi corr_decp corr_crit nocft taxhav2 proa_ycsh9 corr_ben_bi
rename cri cri_de

sum cri_de if filter_ok==1
hist cri_de if filter_ok==1, title("CRI DE, filter_ok")
hist cri_de if filter_ok==1, by(tender_year, noiy title("CRI DE (by year), filter_ok")) 
********************************************************************************

save $country_folder/wb_de_cri201005c.dta, replace
********************************************************************************
*END