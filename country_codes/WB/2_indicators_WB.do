local country "`0'"
********************************************************************************
/*This script runs the risk indicator models to identify risk thresholds.*/
********************************************************************************

*Data
use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
/*
*Controls only 
// logit singleb i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
****************************************************************************

*Submission period
// count if missing(subm_p)
destring subm_p, replace
destring corr_submp, replace
replace corr_submp=99 if missing(subm_p)
cap drop corr_submp subm_p

cap drop submp
gen submp = bid_deadline - cft_publ
label var submp "advertisement period"
replace submp=. if submp<=0
// sum submp
// hist submp
// hist submp if submp<20
// sum submp, det  
replace submp=. if submp>365 //cap ssubmission period to 1 year

// sum submp if filter_ok  //mean 34.3 days
xtile submp25=submp if filter_ok==1, nquantiles(25)
replace submp25=99 if submp==.
// tabstat submp, by(submp25) stat(min mean max)


// logit singleb ib2.submp25 i.ca_supply_type i.year i.market_id i.ca_contract_value10 if filter_ok, base

cap drop corr_submp
gen corr_submp=0
replace corr_submp=1 if submp<14  //used histogram drop threshold
replace corr_submp=99 if missing(submp)
// tab  corr_submp if filter_ok, missing

// logit singleb i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*+ve not significant
*Not valid
// count if filter_ok  & !missing(submp ) & !missing(singleb)
****************************************************************************
*Decision period

gen dec_p = sign_date - bid_deadline
lab var dec_p "Decision period"
// sum dec_p
replace dec_p=. if dec_p<0 //105 -ve values
replace dec_p=. if dec_p>365 //613 more than a year
// sum dec_p
// br tenderid ca_id lot_id cft_bid_deadline ca_signdate year dec_p if filter_ok & !missing(dec_p)

// hist dec_p
// hist dec_p, by(ca_procedure)
*consultancy proc seem to have a longer decision than other types
// sum dec_p if filter_ok & regex(ca_procedure,"^consultancy") //250 days
// sum dec_p if filter_ok & !regex(ca_procedure,"^consultancy") //140 days
// hist dec_p if filter_ok & regex(ca_procedure,"^consultancy")
*For consultancy types: drop in distr 100 and 300
// hist dec_p if filter_ok & !regex(ca_procedure,"^consultancy"), xlabel(10(10)400, alt)
*for the rest 20 and 250
gen corr_decp=0 if !missing(dec_p) & filter_ok
replace corr_decp=1 if (dec_p>=300 | dec_p<=100) & dec_p!=. & regex(ca_procedure,"^consultancy")
replace corr_decp=1 if (dec_p>=250 | dec_p<=20) & dec_p!=. & !regex(ca_procedure,"^consultancy")
replace corr_decp=99 if missing(dec_p)

// tab corr_decp if filter_ok, m
// tab corr_decp	
lab var corr_decp "Decision period - Cons (Less than 100 and more than 300) Non-cons (Less than 20 and more than 250)"

// logit singleb i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
// count if filter_ok  & !missing(dec_p) & !missing(singleb)
*+ve not significant 
********************************************************************************
*Procedure types 

// tab ca_procedure if filter_ok, m
encode ca_procedure, gen(proc_encoded)
// tab proc_encoded, m
label list proc_encoded

// logit singleb ib3.proc_encoded i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
		
gen corr_proc2=.
replace corr_proc2=0 if inlist(proc_encoded,3,6)
replace corr_proc2=1 if inlist(proc_encoded,1,2)
replace corr_proc2=2 if inlist(proc_encoded,5,7)
replace corr_proc2=99 if inlist(proc_encoded,4)

// logit singleb i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Works use corr_proc2
drop proc_encoded
********************************************************************************
*No cft

*Using missing submission period
gen yescft=1
replace yescft=0 if submp <=0 | submp==.
// tab yescft if filter_ok, m
// tab yescft, missing
gen nocft=(yescft-1)*-1
replace nocft=. if yescft==.
// tab nocft, missing

// logit singleb i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Works ++ decp now valid
********************************************************************************
*Tax haven

// tab iso, m
// tab w1_country if missing(iso), m
cap drop iso
gen iso = ""
do "${utility_codes}/country-to-iso.do" w1_country
replace iso = w1_country if missing(iso) & length(w1_country)==2
// tab w1_country if missing(iso)

cap drop _m
merge m:1 iso using "${utility_data}/FSI_wide_200812_fin.dta"
lab var iso "supplier country ISO"
drop if _merge==2
drop _merge
destring year, gen(year2)
cap drop sec_score
gen sec_score = sec_score2009 if year<=2009
replace sec_score = sec_score2011 if (year==2010 | year==2011) & sec_score==.
replace sec_score = sec_score2013 if (year==2012 | year==2013) & sec_score==.
replace sec_score = sec_score2015 if (year==2014 | year==2015) & sec_score==.
replace sec_score = sec_score2017 if (year==2016 | year==2017) & sec_score==.
replace sec_score = sec_score2019 if (year==2018 | year==2019 | year==2020) & sec_score==.
lab var sec_score "supplier country Secrecy Score (time varying)"
// sum sec_score
drop sec_score1998-sec_score2019

*Make sure the country variables are in the same form
rename iso iso_supplier
// br iso_supplier *country*
// count if missing(anb_country) & filter_ok
// count if missing(country_name) & filter_ok

*Use anb_country
gen iso_anb= anb_country
// br iso_anb iso_supplier if filter_ok

cap drop fsuppl*
cap drop taxhav*

gen fsuppl_x=1 
replace fsuppl_x=0 if ca_country== w1_country
replace fsuppl_x=. if missing(iso_anb) |  missing(iso_supplier)
// tab fsuppl_x, missing
// br fsuppl_x iso_anb iso_supplier if !missing(fsuppl_x)

gen taxhav_x =.
replace taxhav_x = 0 if sec_score<=59.5 & sec_score !=.
replace taxhav_x = 1 if sec_score>59.5 & sec_score!=.
replace taxhav_x = 9 if fsuppl_x==0
lab var taxhav_x "supplier is from tax haven (time varying)"
// tab taxhav_x if filter_ok, missing
// tab iso_supplier if taxhav_x==1 & fsuppl_x==1
replace taxhav_x = 0 if iso_supplier=="US" //removing the US
// br fsuppl_x iso_anb iso_supplier taxhav_x sec_score if taxhav_x==.

gen taxhav2_x = taxhav_x
replace taxhav2_x = 0 if taxhav_x==. 
lab var taxhav2_x "Tax haven supplier, missing = 0 (time varying)"
// tab taxhav2_x, missing

// logit singleb i.taxhav2_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*taxhav_x & taxhav2_x +ve but not significant

gen taxhav3_x= fsuppl_x
replace taxhav3_x = 2 if fsuppl_x==1 & taxhav_x==1
// tab taxhav3_x if filter_ok, m
// br fsuppl_x iso_anb iso_supplier  taxhav_x sec_score if taxhav3_x==. & filter_ok

// logit singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*Not significant not used
********************************************************************************
*Winning Supplier's contract share (by PE, by year)

// sum ca_lot_value_num if filter_ok==1

egen w_yam=sum(ca_lot_value) if filter_ok==1 & w_id!=. & year!=., by (w_id year) 
lab var w_yam "By Winner-year: Spending amount"

egen proa_w_yam=sum(ca_lot_value) if filter_ok==1 & anb_id!=. & w_id!=. & year!=., by(anb_id w_id year)
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

sort w_id year sign_date
egen filter_wy = tag(w_id year) if filter_ok==1 & w_id!=. & year!=.
lab var filter_wy "Marking Winner years"
// tab filter_wy

sort w_id
egen filter_w = tag(w_id) if filter_ok==1 & w_id!=.
lab var filter_w "Marking Winners"
// tab filter_w

sort w_id anb_id
egen filter_wproa = tag(w_id mca_buyerassignedid) if filter_ok==1 & w_id!=. & anb_id!=.
lab var filter_wproa "Marking Winner-buyer pairs"
// tab filter_wproa

sort year w_id anb_id
egen filter_wproay = tag(year w_id anb_id) if filter_ok==1 & w_id!=. & anb_id!=. & year!=.
lab var filter_wproay "Marking Winner-buyer pairs"
// tab filter_wproay

// reg w_ycsh singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base 
*proc and dec not valid
*nocft singleb sub insig
*taxhav valid
// reg w_ycsh singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>9 & w_ynrc!=., base 
*singleb taxhav valid
*nocft proc not valid
*dec insig sub omitted

gen w_ycsh4=w_ycsh if filter_ok==1 & w_ynrc>4 & w_ycsh!=.
// br w_ycsh4
********************************************************************************
*Buyer dependence on supplier

egen proa_yam=sum(ca_lot_value) if filter_ok==1 & anb_id!=. & year!=., by(anb_id year) 
lab var proa_yam "By PA-year: Spending amount"
*proa_w_yam already generated
*proa_ynrc already generated
gen proa_ycsh=proa_w_yam/proa_yam 
lab var proa_ycsh "By PA-year-supplier: share of supplier in total annual PA spend"
egen proa_mycsh=max(proa_ycsh), by(anb_id year)
lab var proa_mycsh "By PA-year: Max share spent on one supplier"

gsort anb_id +year +sign_date
egen filter_proay = tag(anb_id year) if filter_ok==1 & anb_id!=. & year!=.
lab var filter_proay "Marking PA years"
// tab filter_proay

sort anb_id
egen filter_proa = tag(anb_id) if filter_ok==1 & anb_id!=.
lab var filter_proa "Marking PAs"
// tab filter_proa

gen x=1
egen proa_nrc=total(x) if filter_ok==1 & anb_id!=., by(anb_id)
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
// reg proa_ycsh singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>2 & proa_ynrc!=., base 
// *good all valid (except submp) - best!
// reg proa_ycsh singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>4 & proa_ynrc!=., base 
// *componenets not significant
// reg proa_ycsh singleb i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>9 & proa_ynrc!=., base 
*even less significance

gen proa_ycsh4=proa_ycsh if filter_ok==1 & proa_ynrc>2 & proa_ycsh!=.
********************************************************************************
*New indicators market entry 

*Generate bidder market entry {product_code, year, supplier id, country local macro}
*Not valid for the WB data
*do "${utility_codes}/gen_bidder_market_entry.do" tender_cpvs tender_year bidder_masterid "`country'"
gen bidder_mkt_entry= .

*Generate market share {bid_price ppp version}
*Not valid for the WB data
*do "${utility_codes}/gen_bidder_market_share.do" bid_price_ppp 
gen bidder_mkt_share= .

*Generate is_capital region {`country', buyer_city , one or more nuts variables:buyer_nuts tender_addressofimplementation_n }
// tab anb_country if filter_ok & !missing(cft_fip_city)
// tab cft_fip_city if filter_ok & !missing(cft_fip_city) & missing(anb_country)
// br anb_country if filter_ok & !missing(cft_fip_city)
do "${utility_codes}/quick_location_cleaning.do" cft_fip_city "WB"
do "${utility_codes}/gen_is_capital.do" "`country'" cft_fip_city_clean 
cap drop cft_fip_city_clean

*Generate bidder is non local {`country', buyer_city bidder_city, buyer_nuts bidder_nuts}
*Not valid for the WB data
*do "${utility_codes}/gen_bidder_non_local.do" "`country'" buyer_city bidder_city buyer_nuts bidder_nuts
gen bidder_non_local=.
********************************************************************************
*Benford's Law 

// br anb_id  pr_borrower_name ca_lot_value_num if !missing(anb_id)
rename ca_contract_value ca_contract_value_ppp

********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*/

preserve
    rename anb_id buyer_id //buyer id variable
    rename ca_lot_value ca_contract_value //bid price variable
    keep if filter_ok==1 
    keep if !missing(ca_contract_value)
    bys buyer_id: gen count = _N
    keep if count >100
    keep buyer_id ca_contract_value
	order buyer_id ca_contract_value
	export delimited  "${country_folder}/buyers_for_R.csv", replace
	! "${R_path_local}" "${utility_codes}/benford.R" "${country_folder}"
restore

use "${country_folder}/`country'_wip.dta", clear
gen buyer_id=anb_id
merge m:1 buyer_id using "${country_folder}/buyers_benford.dta"
drop if _m==2
// br buyer_id pr_borrower_name MAD_conformitiy MAD _merge if _m==3
drop _m buyer_id

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

// logit singleb i.corr_ben i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*2nd category works not the 1st
replace corr_ben=0 if corr_ben==1

// logit singleb i.corr_ben i.taxhav3_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
********************************************************************************

*Final Best Regressions

// logit singleb i.corr_ben i.taxhav2_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok, base
*nocft became  insignificant
*taxhav2_x, submp +ve insignificant 
*Singlebidding data is historic
*Although tax haven, cft, and subm are not valid, I will include in cri

// reg w_ycsh singleb  i.corr_ben i.taxhav2_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & w_ynrc>4 & w_ynrc!=., base

// reg proa_ycsh singleb  i.corr_ben i.taxhav2_x i.nocft i.corr_proc2 i.corr_decp i.corr_submp i.ca_supply_type i.year i.market_id i.ca_contract_value10 i.anb_location if filter_ok  & proa_ynrc>2 & proa_ynrc!=., base 
*submp -ve insignificant
********************************************************************************
*CRI calculation

// sum singleb corr_proc2 corr_submp corr_decp nocft taxhav2_x  proa_ycsh corr_ben if filter_ok==1
// tab singleb, m
// tab corr_proc2, m  //rescale
// tab corr_submp, m 
// tab corr_decp, m 
// tab nocft, m
// tab taxhav2_x, m 
// tab corr_ben, m  //rescale 
// sum proa_ycsh

gen corr_proc_bi=99
replace corr_proc_bi=corr_proc2/2 if corr_proc2!=99
// tab corr_proc_bi corr_proc2

gen corr_ben_bi=99
replace corr_ben_bi=corr_ben/2 if corr_ben!=99
// tab corr_ben_bi corr_ben

do "${utility_codes}/cri.do" singleb corr_proc_bi corr_submp corr_decp nocft taxhav2_x proa_ycsh4 corr_ben_bi
rename cri cri_wb

// sum cri_wb if filter_ok==1
// hist cri_wb if filter_ok==1, title("CRI WB, filter_ok")
// hist cri_wb if filter_ok==1, by(year, noiy title("CRI WB (by year), filter_ok")) 
********************************************************************************

save "${country_folder}/`country'_wb_0920.dta", replace
********************************************************************************
*END