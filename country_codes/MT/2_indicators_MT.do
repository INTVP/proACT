
use "${country_folder}/MT_wip.dta", clear

********************************************************************************
*Single bidding

sort tender_id lot_row_nr

gen 	singleb = 0
replace singleb = 1 if lot_bidscount==1
replace singleb = . if missing(lot_bidscount)
tab 	singleb, m

********************************************************************************

*Procedure type

gen 	 ca_procedure = tender_proceduretype
replace  ca_procedure = "NA" if missing(ca_procedure)
encode 	 ca_procedure,  gen(ca_procedure2)
drop 	 ca_procedure 
rename 	 ca_procedure2 ca_procedure
lab list ca_procedure2

*Level 1 risk - RESTRICTED , NEGOTIATED_WITH_PUBLICATION , NEGOTIATED_WITHOUT_PUBLICATION 

cap drop corr_proc
gen 	 corr_proc = .
replace  corr_proc = inlist(ca_procedure, 3, 4, 6)
replace  corr_proc = 99 if ca_procedure == 2

********************************************************************************
*Submission period 

gen 	 submp = bid_deadline - first_cft_pub
lab var  submp  "advertisement period"
replace  submp = . if submp <= 0
replace  submp = . if submp >  365 //cap ssubmission period to 1 year

xtile   submp10 = submp if filter_ok == 1, nquantiles(10)
replace submp10 = 99    if submp 	 == .

gen 	corr_submp = 0
replace corr_submp = 1 	if inlist(submp10,1,3,10)
replace corr_submp = 99 if submp10 == 99

*Alternative submp - not part of the WB portals output
cap drop corr_submp2
gen 	 corr_submp2 = inlist(submp10, 1, 2, 3, 10)
replace  corr_submp2 = 99 if submp10 == 99

********************************************************************************
*Decision Period 

gen 	 decp = aw_date - bid_deadline
replace  decp = 0 	if decp < 0   & decp != 0
replace  decp =.  	if decp > 365 //cap at 1 year
lab var  decp "decision period"

xtile 	decp20 = decp 	if filter_ok == 1, nquantiles(20)
replace decp20 = 99 	if decp == .

gen 	corr_decp = 0
replace corr_decp = 1 	if inlist(decp20, 1, 2, 3)
replace corr_decp = 99 	if decp20 == 99

********************************************************************************

*No cft

gen 	yescft = 1
replace yescft = 0 if submp <= 0 | submp == .

gen 	nocft  = (yescft - 1) * -1
replace nocft  =. if yescft == .

********************************************************************************
*Tax haven

gen 	  iso = bidder_country
merge m:1 iso 	using "${utility_data}/FSI_wide_200812_fin.dta", keep(1 3) nogen
lab var   iso 	"supplier country ISO"

gen 	sec_score = sec_score2009 if  tender_year <= 2009
replace sec_score = sec_score2011 if (tender_year == 2010 | tender_year == 2011) & sec_score == .
replace sec_score = sec_score2013 if (tender_year == 2012 | tender_year == 2013) & sec_score == .
replace sec_score = sec_score2015 if (tender_year == 2014 | tender_year == 2015) & sec_score == .
replace sec_score = sec_score2017 if (tender_year == 2016 | tender_year == 2017) & sec_score == .
replace sec_score = sec_score2019 if (tender_year == 2018 | tender_year == 2019 | tender_year == 2020) & sec_score == .
lab var sec_score   "supplier country Secrecy Score (time varying)"

drop sec_score1998-sec_score2019

gen 	fsuppl = !(bidder_country == "MT" | bidder_country == "")

gen 	taxhav = sec_score > 59.5 	if sec_score != .
replace taxhav = 9 					if fsuppl==0
lab var taxhav  "supplier is from tax haven (time varying)"
replace taxhav = 0 					if bidder_country=="US" //removing the US because ....?

gen 	taxhav2 = taxhav
replace taxhav2 = 0 if taxhav == . 
lab var taxhav2 "Tax haven supplier, missing = 0 (time varying)"

*Foreign supplier high risk
gen 	fsuppl2 = fsuppl
replace fsuppl2 = 2 		if fsuppl == 1 & taxhav == 1

********************************************************************************
*Winning Supplier's contract share (by PE, by year)

sort 	buyer_id
format 	buyer_masterid buyer_id buyer_name %20s

*Use buyer_id and bidder_id
egen 	w_yam = sum(bid_price) if filter_ok == 1 & bidder_id != "" & tender_year != ., by (bidder_id tender_year) 
lab var w_yam   "By Winner-year: Spending amount"

egen 	proa_w_yam = sum(bid_price) if filter_ok == 1 & buyer_id != "" & bidder_id !="" & tender_year != ., by(buyer_id bidder_id tender_year)
lab var proa_w_yam   "By PA-year-supplier: Amount"

gen 	w_ycsh = proa_w_yam/w_yam 
lab var w_ycsh   "By Winner-year-buyer: share of buyer in total annual winner contract value"

egen 	w_mycsh = max(w_ycsh), by(bidder_id tender_year)
lab var w_mycsh   "By Win-year: Max share received from one buyer"

gen 	x = 1
egen 	w_ynrc = total(x) if filter_ok == 1 & bidder_id != "" & tender_year != ., by(bidder_id tender_year)
drop 	x
lab var w_ynrc "#Contracts by Win-year"

gen 	x = 1
egen 	proa_ynrc=total(x) if filter_ok == 1 & buyer_id != "" & tender_year != ., by(buyer_id tender_year)
drop 	x
lab var proa_ynrc "#Contracts by PA-year"

sort 	bidder_id tender_year aw_date
egen 	filter_wy = tag(bidder_id tender_year) if filter_ok == 1 & bidder_id != "" & tender_year != .
lab var filter_wy "Marking Winner years"

sort 	bidder_id
egen 	filter_w = tag(bidder_id) if filter_ok == 1 & bidder_id != ""
lab var filter_w "Marking Winners"

sort 	bidder_id buyer_id
egen 	filter_wproa = tag(bidder_id buyer_id) if filter_ok == 1 & bidder_id != "" & buyer_id != ""
lab var filter_wproa "Marking Winner-buyer pairs"

sort 	tender_year bidder_id buyer_id
egen 	filter_wproay = tag(tender_year bidder_id buyer_id) if filter_ok == 1 & bidder_id != "" & buyer_id != "" & tender_year != .
lab var filter_wproay "Marking Winner-buyer pairs"

********************************************************************************
*Buyer dependence on supplier

egen 	proa_yam = sum(bid_price) if filter_ok == 1 & buyer_id != "" & tender_year != ., by(buyer_id tender_year) 
lab var proa_yam   "By PA-year: Spending amount"

gen 	proa_ycsh = proa_w_yam/proa_yam 
lab var proa_ycsh   "By PA-year-supplier: share of supplier in total annual PA spend"

egen 	proa_mycsh = max(proa_ycsh), by(buyer_id tender_year)
lab var proa_mycsh 	 "By PA-year: Max share spent on one supplier"

gsort 	buyer_id +tender_year +aw_date
egen 	filter_proay = tag(buyer_id tender_year) if filter_ok == 1 & buyer_id != "" & tender_year != .
lab var filter_proay "Marking PA years"

sort 	buyer_id
egen 	filter_proa = tag(buyer_id) if filter_ok==1 & buyer_id!=""
lab var filter_proa "Marking PAs"

gen 	x = 1
egen 	proa_nrc=total(x) if filter_ok == 1 & buyer_id != "", by(buyer_id)
drop 	x

********************************************************************************
*No Benford's, overrun and no delay
********************************************************************************

save "${country_folder}/MT_wb_1020.dta", replace

********************************************************************************

do "${utility_codes}/cri.do" singleb corr_proc corr_submp corr_decp nocft taxhav2 w_ycsh4
rename cri cri_mt

********************************************************************************

save "${country_folder}/MT_wb_1020.dta", replace

********************************************************************************
*END