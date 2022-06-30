local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
-Add sanctions data
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************
*Data

use "${country_folder}/`country'_wb_2011.dta", clear
********************************************************************************
*Supply type

// br *ca_type*
cap drop ca_type_str
decode ca_type, gen(ca_type_str)
replace ca_type_str = "" if ca_type_str=="NA"
replace ca_type_str=upper(ca_type_str)
replace ca_type_str="SUPPLIES" if ca_type_str=="GOODS"
// tab ca_type_str, m
************************************
*Procedure type

// tab ca_procedure, m
cap drop ca_procedure_str
gen  ca_procedure_str=""
replace ca_procedure_str = "OPEN" if ca_procedure==3
replace ca_procedure_str = "OUTRIGHT_AWARD" if ca_procedure==1
replace ca_procedure_str = "APPROACHING_BIDDERS" if ca_procedure==2
replace ca_procedure_str = "OTHER" if ca_procedure==5
replace ca_procedure_str = "" if ca_procedure==4
replace ca_procedure_str = upper(ca_procedure_str)
// tab ca_procedure_str, m

decode ca_procedure_nat, gen(ca_procedure_nat_str)
// tab ca_procedure_nat_str , m
replace  ca_procedure_nat_str ="" if  ca_procedure_nat_str=="NA"
// br ca_procedure_nat 
// tab ca_procedure_nat_str, m
************************************
*Renaming/Fixing variables 

replace title = proper(title)
************************************
*Buyer type

// br *type*
decode anb_type, gen(anb_type_str)
replace anb_type_str = "" if anb_type_str=="NA"
replace anb_type_str= "Administración Pública Federal" if regex(anb_type_str,"^Administrac")
replace anb_type_str= "NATIONAL_AUTHORITY" if anb_type_str=="Administración Pública Federal"
replace anb_type_str= "REGIONAL_AUTHORITY" if anb_type_str=="Gobierno Estatal"
replace anb_type_str= "REGIONAL_AUTHORITY" if anb_type_str=="Gobierno Municipal"
tab anb_type_str, m
************************************
*Dates

// br ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline 
*fixed earlier
foreach var of varlist ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline  {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = yearx + "." + monthx + "." + dayx
drop dayx monthx yearx
drop `var'
rename `var'_str `var'
}
foreach var of varlist ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline  {
replace `var'="" if `var'=="....."
}
// br ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline

drop if inlist(ca_sign_date,"1906.4.21","2021.9.13","2023.6.25","2031.8.9","2047.5.3","2021.5.22","2021.8.3")

*Fixing dates from "1999.3.2" to 1999-03-02
foreach var of varlist ca_sign_date cft_date cft_deadline ca_start_date {
split(`var'),p(".")
gen len=length(`var'2)
replace `var'2="0"+`var'2 if len==1 & !missing(`var'2)
drop len
gen len=length(`var'3)
replace `var'3="0"+`var'3 if len==1 & !missing(`var'3)
drop len
gen `var'_v2=`var'1+"-"+`var'2+"-"+`var'3 if !missing(`var')
drop `var'
rename `var'_v2 `var'
drop `var'1 `var'2 `var'3
}
br ca_sign_date cft_date cft_deadline ca_start_date 
************************************
*Product codes

rename cpv lot_productCode
rename aw_item_class_id lot_localproductCode
gen lot_localproductCode_type = "CUCOP" if !missing(lot_localproductCode)
// br lot_productCode lot_localproductCode lot_localproductCode_type if !missing(lot_localproductCode)
************************************
*Cleaning names

gen len=length(anb_name)
// tab len if filter_ok,m
// br buyer_name if len<=3 & !missing(anb_name)
replace filter_ok=0 if anb_name=="-"
replace filter_ok=0 if anb_name=="."
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(anb_name,"x","xx","xxx")
replace anb_name=ustrupper(anb_name)
replace anb_name=subinstr(anb_name,"  "," ",.)
replace anb_name=ustrtrim(anb_name)
drop len

gen len=length(w_name)
// tab len if filter_ok,m
// br w_name len if len<=3 & !missing(w_name) 
replace filter_ok=0 if w_name=="-"
replace filter_ok=0 if w_name=="."
replace filter_ok=0 if w_name=="/,"
replace filter_ok=0 if w_name==".,"
*replace bidder_name=subinstr(bidder_name,","," ",.)
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(w_name,"x","xx","xxx","a","A","//","X","XX")
replace filter_ok=0 if inlist(w_name,"/.","-,","/",",","-","na")
replace filter_ok=0 if inlist(w_name,"","-,","/",",","-")
replace w_name=ustrupper(w_name)
replace w_name=subinstr(w_name,"  "," ",.)
replace w_name=ustrtrim(w_name)
drop len
************************************
*Contract notice and award variables

cap drop tender_publications_notice_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(w_name)
gen notice_url=""
gen ca_url="https://sites.google.com/site/cnetuc/contrataciones"
gen source="https://sites.google.com/site/cnetuc/descargas"
************************************

gen tender_country = "MX"
************************************

replace aw_curr="" if aw_curr=="NA"
replace aw_curr="MXN" if !missing(ca_contract_value_ppp)
************************************

// tab buyer_geocodes, m
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]" if !missing(buyer_geocodes)
************************************

foreach var of varlist anb_id2  w_id2 w_id  {
tostring `var', replace
replace `var' = "" if `var'=="."
}
decode anb_id_detail, gen(anb_id_detail_str)
replace anb_id_detail_str = "" if anb_id_detail_str=="."
drop anb_id_detail
rename anb_id_detail_str anb_id_detail
// br anb_id2 anb_id_detail  w_id2 w_id
************************************

decode w_country, gen(w_country_str)
drop w_country
rename w_country_str w_country
// tab w_country
replace w_country = "UK" if w_country == "GB"

// tab buyer_country
replace buyer_country="MX" if  buyer_country=="Mexico"
************************************

gen bids_count = ca_nrbid
************************************

gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_roverrun2_type = "INTEGRITY_COST_OVERRUN"

gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"

************************************

local temp ""<Fa>" "<E1>""
local temp2 ""ú" "á""
local n_temp : word count `temp'
foreach var of varlist title anb_name w_name {
replace `var'=subinstr(`var',"_","",.) if regex(`var',"^_")
forval s=1/`n_temp'{
 replace `var' =subinstr(`var',"`: word `s' of `temp''","`: word `s' of `temp2''",.) 
}
replace `var' = ustrupper(`var')
}

************************************
*Calcluating indicators

foreach var of varlist nocft singleb taxhav2 {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = . if  `var'==9  //tax haven undefined
}
replace ind_taxhav2_val = .   if  taxhav2==1 //tax haven undefined

*For indicators with categories
foreach var of varlist corr_proc corr_submp corr_decp corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

*Contract Share
// sum w_ycsh4
gen ind_csh_val = w_ycsh4*100
replace ind_csh_val = 100-ind_csh_val

*Overrun
gen ind_overrun_val = roverrun*100
************************************
gen impl= buyer_geocodes
gen proc = ca_procedure_nat_str
gen aw_date2 = ca_start_date
gen bids =bids_count
gen buyer_name =anb_name
gen bidder_name =w_name
gen tender_supplytype =ca_type_str
gen bid_price =ca_contract_value

foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids buyer_name bidder_name tender_supplytype bid_price
************************************
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = bids_count

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*Main filter
replace filter_ok=0 if inlist(w_name,"na","0","","no mipyme")
************************************

*Dealing with duplicates
duplicates tag tender_id ca_id, gen(d)
bys  tender_id ca_id: gen x=_n
replace filter_ok=0 if d>0 & x >1
drop d x 

// unique tender_id if filter_ok
// unique tender_id ca_id if filter_ok

bys tender_id filter_ok: gen x=_N if filter_ok==1
sort tender_id ca_id
// br tender_id ca_id anb_name w_name ca_contract_value x if x>1 & filter_ok==1
// br tender_id ca_id anb_name w_name ca_contract_value x if missing(ca_id) & filter_ok
************************************
*Creating lot_number & bid_number

bys tender_id filter_ok: gen lot_number=_n if filter_ok
*contracts treated as lots
bys tender_id ca_id filter_ok: gen bid_number=_n  if filter_ok

sort tender_id ca_id
// br tender_id ca_id lot_number bid_number if filter_ok

drop if filter_ok==0
************************************

foreach var of varlist title w_name anb_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

sort  tender_id lot_number bid_number
rename ca_procedure_str tender_proceduretype
renam ca_procedure_nat_str tender_nationalproceduretype
rename ca_type_str tender_supplytype
rename ca_start_date tender_publications_firstdcontra
rename anb_id2 buyer_masterid
rename anb_id_detail buyer_id
rename anb_type_str buyer_buyertype
rename w_id2 bidder_masterid
rename w_id bidder_id
rename aw_curr bid_pricecurrency

keep tender_id lot_number bid_number tender_country ca_sign_date cft_deadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type cft_date notice_url  source tender_publications_award_type tender_publications_firstdcontra ca_url buyer_masterid buyer_id buyer_city_api buyer_country_api buyer_geocodes anb_name buyer_buyertype bidder_masterid bidder_id w_country w_name ca_contract_value_ppp ca_contract_value bid_pricecurrency lot_productCode lot_localproductCode_type lot_localproductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_overrun_val ind_roverrun2_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

order tender_id lot_number bid_number tender_country ca_sign_date cft_deadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type cft_date notice_url  source tender_publications_award_type tender_publications_firstdcontra ca_url buyer_masterid buyer_id buyer_city_api buyer_country_api buyer_geocodes anb_name buyer_buyertype bidder_masterid bidder_id w_country w_name ca_contract_value_ppp ca_contract_value bid_pricecurrency lot_productCode lot_localproductCode_type lot_localproductCode title ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_overrun_val ind_roverrun2_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************
forval x=1/2{
if (`x'==1) {
local start_c = 1
local end_c = round(_N/2) //612966
}
if (`x'==2) {
local start_c = round(_N/2) + 1
local end_c = _N 
}

export excel if _n>=`start_c' & _n<=`end_c' using "${utility_data}/country/`country'/`country'_mod`x'.xlsx", firstrow(var) replace
}

// export excel using "${utility_data}/country/`country'/`country'_mod.xlsx", firstrow(var) replace
// export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace
********************************************************************************
*Clean up
copy "${country_folder}/`country'_wb_2011.dta" "${utility_data}/country/`country'/`country'_wb_2011.dta", replace
local files : dir  "${country_folder}" files "*.dta"
foreach file in `files' {
cap erase "${country_folder}/`file'"
}
cap erase "${country_folder}/buyers_for_R.csv"
********************************************************************************
*END