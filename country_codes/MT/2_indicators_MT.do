local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Single bidding

// sort tender_id lot_row_nr
// br source tender_id lot_row_nr tender_recordedbidscount lot_bidscount

gen singleb = 0
replace singleb=1 if lot_bidscount==1
replace singleb=. if missing(lot_bidscount)
// tab singleb, m

*Controls only
// logit singleb ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
//R2: 13.55% - 3,043 obs
********************************************************************************
*Procedure type

// br *proc*
// tab tender_proceduretype, m
// tab tender_proceduretype tender_indicator_integrity_proce , m

gen ca_procedure = tender_proceduretype
replace ca_procedure = "NA" if missing(ca_procedure)
encode ca_procedure, gen(ca_procedure2)
drop ca_procedure
rename ca_procedure2 ca_procedure
// tab ca_procedure, m
label list ca_procedure2

// logit singleb ib5.ca_procedure ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Based on regressions
*Level 1 risk - RESTRICTED , NEGOTIATED_WITH_PUBLICATION , NEGOTIATED_WITHOUT_PUBLICATION

// label list ca_procedure2
cap drop corr_proc
gen corr_proc=.
replace corr_proc=0 if inlist(ca_procedure,1,5)
replace corr_proc=1 if inlist(ca_procedure,3,4,6)
replace corr_proc=99 if missing(tender_proceduretype)

// logit singleb i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Much better
********************************************************************************
*Submission period

gen submp = bid_deadline - first_cft_pub
label var submp "advertisement period"
replace submp=. if submp<=0

// sum submp
// hist submp
// hist submp if submp<1000
// sum submp, det
replace submp=. if submp>365 //cap submission period to 1 year

*sum submp if filter_ok  //mean 92 days - used as benchmark submission period

xtile submp10=submp if filter_ok==1, nquantiles(10)
replace submp10=99 if submp==.
// tabstat submp, by(submp10) stat(min mean max)

// logit singleb ib8.submp10 ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
// *Compared to the mean , 1,3 and 10th are high risk
// logit singleb ib9.submp10 ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
// *1,3 and 10th are high risk

gen corr_submp=0
replace corr_submp=1 if inlist(submp10,1,3,10)
replace corr_submp=99 if submp10==99
// tab submp10 corr_submp if filter_ok, missing

// logit singleb i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Works
********************************************************************************
*Decision Period

gen decp=aw_date - bid_deadline

// sum decp
// hist decp
replace decp=0 if decp<0 & decp!=0
// count if decp==0 & filter_ok

// hist decp //mostly close to zero
*sum decp if decp>365
replace decp=. if decp>365 //cap at 1 year
lab var decp "decision period"
// hist decp if filter_ok
// hist decp if filter_ok, by(ca_procedure)

xtile decp20=decp if filter_ok==1, nquantiles(20)
replace decp20=99 if decp==.
// sum decp if filter_ok //mean: 145 days - used as benchmark decision period
// tabstat decp, by(decp20) stat(n min mean max)

// logit singleb ib12.decp20 i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
// *1,2,3  (2 not significant +ve)
// logit singleb ib13.decp20 i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
// *1,2,3 (1,2 not significant +ve)

gen corr_decp=0
replace corr_decp=1 if inlist(decp20,1,2,3)
replace corr_decp=99 if decp20==99
// tab decp20 corr_decp if filter_ok, missing
// tabstat decp, by(decp20) stat(min mean max)

// logit singleb i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Valid!
********************************************************************************
*No cft

*Method 1 is based on submision period
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft if filter_ok, m
// tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing

// logit singleb i.nocft i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*Works
********************************************************************************
*Tax haven

// tab bidder_country, m
gen iso = bidder_country
merge m:1 iso using "${utility_data}/FSI_wide_200812_fin.dta"
lab var iso "supplier country ISO"
drop if _merge==2  // dropping unmatched from the using data
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
replace fsuppl=0 if bidder_country=="`country'" | bidder_country==""
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

// logit singleb taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
// *taxhav +ve not significant
// *taxhav2 +ve not significant
// tab bidder_country if taxhav2==1

*Foreign supplier high risk
gen fsuppl2= fsuppl
replace fsuppl2 = 2 if fsuppl==1 & taxhav==1
// tab fsuppl2, m

// logit singleb i.fsuppl2 i.nocft i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*In this format: +ve not significant
*use taxhaven2
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

*observing counts of the organziaiton id variables
// unique buyer_masterid
// unique buyer_id
// unique buyer_name
// sort buyer_id
// format buyer_masterid buyer_id buyer_name %20s
// br buyer_masterid buyer_id buyer_name
*Use buyer_id and bidder_id

egen w_yam=sum(bid_price) if filter_ok==1 & bidder_id!="" & tender_year!=., by (bidder_id tender_year)
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(bid_price) if filter_ok==1 & buyer_id!="" & bidder_id!="" & tender_year!=., by(buyer_id bidder_id tender_year)
lab var proa_w_yam "By PA-year-supplier: Amount"

gen w_ycsh=proa_w_yam/w_yam
lab var w_ycsh "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen w_mycsh=max(w_ycsh), by(bidder_id tender_year)
lab var w_mycsh "By Win-year: Max share received from one buyer"

cap drop x
gen x=1
egen w_ynrc=total(x) if filter_ok==1 & bidder_id!="" & tender_year!=., by(bidder_id tender_year)
cap drop x
lab var w_ynrc "#Contracts by Win-year"

cap drop x
gen x=1
egen proa_ynrc=total(x) if filter_ok==1 & buyer_id!="" & tender_year!=., by(buyer_id tender_year)
drop x
lab var proa_ynrc "#Contracts by PA-year"

sort bidder_id tender_year aw_date
egen filter_wy = tag(bidder_id tender_year) if filter_ok==1 & bidder_id!="" & tender_year!=.
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort bidder_id
egen filter_w = tag(bidder_id) if filter_ok==1 & bidder_id!=""
lab var filter_w "Marking Winners"
// tab filter_w

sort bidder_id buyer_id
egen filter_wproa = tag(bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!=""
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort tender_year bidder_id buyer_id
egen filter_wproay = tag(tender_year bidder_id buyer_id) if filter_ok==1 & bidder_id!="" & buyer_id!="" & tender_year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay

*checking contract share
// reg w_ycsh singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>2 & w_ynrc!=., base
// *Very few nr of observations for validation
// *singleb, nocft (insign), subm
// reg w_ycsh singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>4 & w_ynrc!=., base
// *taxhav and proc works

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// sum w_ycsh4 w_ycsh
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
// tab filter_proay

sort buyer_id
egen filter_proa = tag(buyer_id) if filter_ok==1 & buyer_id!=""
lab var filter_proa "Marking PAs"
// tab filter_proa

cap drop x
gen x=1
egen proa_nrc=total(x) if filter_ok==1 & buyer_id!="", by(buyer_id)
drop x
lab var proa_nrc "#Contracts by PAs"

// sum proa_nrc
// hist proa_nrc

// sum proa_ynrc
// tab proa_ynrc
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>2 & proa_ynrc!=.
// sum proa_yam proa_w_yam proa_ycsh proa_mycsh proa_ynrc if proa_ynrc>9 & proa_ynrc!=.
// hist proa_ycsh if filter_proay==1 & proa_ynrc>2 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
// hist proa_ycsh if filter_proay==1 & proa_ynrc>9 & proa_ynrc!=., title("Buyer-level market shares of suppliers per year") freq
*validation

// reg proa_ycsh singleb  i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc lca_contract_value i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
*Positive directions mostly

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>4 & proa_ycsh!=.
// sum proa_ycsh4 proa_ycsh
********************************************************************************
*No Benford's, overrun and no delay
********************************************************************************
*Final best regressions

// logit singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok, base
*OK
// reg w_ycsh singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & w_ynrc>4 & w_ynrc!=., base
// reg proa_ycsh singleb i.taxhav2 i.nocft i.corr_decp i.corr_submp i.corr_proc ca_contract_value100 i.buyer_location i.anb_type i.ca_type i.tender_year i.market_id  if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base
*Works better: proa_ycsh
********************************************************************************

*CRI generation
// sum singleb corr_proc corr_submp corr_decp nocft taxhav2 nocft w_ycsh  if filter_ok==1
// tab singleb, m
// tab corr_proc, m
// tab corr_submp, m
// tab corr_decp, m
// tab nocft, m
// tab taxhav2, m
// tab w_ycsh, m

do "${utility_codes}/cri.do" singleb corr_proc corr_submp corr_decp nocft taxhav2 w_ycsh4
rename cri cri_mt

// sum cri_mt if filter_ok==1
// hist cri_mt if filter_ok==1, title("CRI `country', filter_ok")
// hist cri_mt if filter_ok==1, by(tender_year, noiy title("CRI `country' (by year), filter_ok"))
********************************************************************************

save "${country_folder}/`country'_wb_1020.dta", replace
********************************************************************************
*END