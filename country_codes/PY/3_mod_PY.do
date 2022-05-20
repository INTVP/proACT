local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use "${country_folder}/`country'_wb_2011.dta", clear
********************************************************************************
*Calcluating indicators

// tab nocft , m
// tab singleb , m 
// tab corr_decp, m
// tab corr_submp , m
// tab corr_proc, m
// tab corr_ben, m

*For indicators with 1 category
foreach var of varlist nocft singleb {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_taxhav2_val=. 
// tab ind_nocft_val  nocft, m
// tab ind_singleb_val  singleb, m
************************************
*For indicators with more than 1 category

// tab corr_decp, m
// tab corr_proc, m
// tab corr_submp, m
// tab corr_ben, m
foreach var of varlist corr_proc corr_submp corr_decp corr_ben {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
// tab ind_corr_proc_val  corr_proc, m
// tab ind_corr_submp_val  corr_submp, m
// tab ind_corr_decp_val  corr_decp, m
// tab ind_corr_ben_val  corr_ben, m
************************************
*Contract Share

// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency

// count if missing(ca_lot_title) & filter_drop
// count if missing(ca_title) & filter_drop
// count if missing(ca_title) & !missing(ca_lot_title) & filter_drop
gen title = ca_title
replace title= ca_lot_title if missing(title)
// count if missing(title) & filter_drop

gen impl= ca_nuts
gen proc = tender_nationalproceduretype
gen aw_date2 = ca_date_first
replace ca_bids_new=. if year<2013
gen bids =ca_bids_new //we do not have a bids variables in PY -  this one is created from a count
gen tender_supplytype=""
foreach var of varlist anb_name title w_name tender_supplytype ca_contract_value impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids tender_supplytype

********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
use "${country_folder}/`country'_wb_2011.dta", clear

*Preparing variables for data export

gen tender_country="PY"
************************************
*No tender decision date

* aw_date is the contract signature date
gen ca_contractsignaturedate = aw_date
* ca_date_first is tender_publications_firstdcontra // use tender_publications_firstdcontra
* first_cft_pub is tender_publications_firstcallfor // use tender_publications_firstcallfor
*  bid_deadline is tender_biddeadline
gen tender_biddeadline = bid_deadline
************************************

// tab tender_proceduretype, m
************************************

gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(ca_url) | !missing(tender_publications_firstdcontra)
************************************

// tab source_website
************************************
*Fixing the date variables

// br ca_contractsignaturedate tender_biddeadline
foreach var of varlist ca_contractsignaturedate tender_biddeadline  {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = yearx + "-" + monthx + "-" + dayx
drop dayx monthx yearx
drop `var'
rename `var'_str `var'
}

foreach var of varlist ca_contractsignaturedate tender_biddeadline {
replace `var'="" if `var'==".-.-."
split(`var'),p("-")
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
************************************
*IDs

// count if missing(anb_masterid) & filter_drop 
// unique tender_id if missing(anb_masterid) & filter_drop 
// tab year if missing(anb_masterid) & filter_drop 
// count if missing(anb_id) & filter_drop
// count if missing(w_masterid) & filter_drop
// count if missing(w_id) & filter_drop
// *w_id_n w_country
************************************
*Location information

*Buyer Location
// br *anb*
// br anb_country_iso2 anb_city buyer_geocodes
rename buyer_geocodes buyer_geocodes_str
gen  buyer_geocodes = "["+ `"""' + buyer_geocodes_str + `"""' +"]" if !missing(buyer_geocodes_str)
// br anb_name if regex(anb_name,`"^""') //all good [ ] "
************************************
*Bidder Location

// tab w_nuts, m
// tab w_city, m
// br w_country iso
decode w_country, gen(w_country_str)
// tab w_city if filter_drop

*We don't report city not needed
replace w_city = subinstr(w_city,"-","",.) if regex(w_cit,"^-")
replace w_city = subinstr(w_city,"-","",.) if regex(w_cit,"-$")
// tab w_city if regex(w_city,"\?")
replace w_city ="CAACUPÃ" if w_city=="CAACUPÃ?"
replace w_city ="CONCEPCION" if w_city=="CONCEPCIÃ?N"
replace w_city ="ENCARNACION" if w_city=="ENCARANCIÃ?N"
replace w_city ="ITAPÚA" if w_city=="ITAPÃ?A"
replace w_city ="ÃEMBY" if w_city=="Ã?EMBY"
// tab anb_city, m

// replace bidder_city="Asunción" if regex(w_city_clean,"suncio")
// drop w_city_clean
gen bidder_geocodes="PYB" if !missing(w_city)
replace  bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]" if !missing(bidder_geocodes)
// br bidder_geocodes bidder_city w_city 
// count if missing(w_city) & filter_drop
// count if missing(bidder_city) & filter_drop
************************************

// br w_name if regex(w_name,`"^]"') //"
replace w_name = subinstr(w_name,`"""',"",.) if regex(w_name,`"^""')
************************************
*Tender CPVS

// br tender_unspsc_original tender_cpvs
split tender_unspsc_original,p(",")
drop tender_unspsc_original2-tender_unspsc_original372
rename tender_unspsc_original1 lot_localProductCode
gen lot_productCode = tender_cpvs
gen lot_localProductCode_type = "UNSPSC" if !missing(lot_localProductCode)
// br lot_productCode lot_localProductCode lot_localProductCode_type
************************************
*Title 

// br title 
************************************
*Bids

// br ca_bids_new
************************************
*Estimated price

// br ca_contract_value ca_tender_est_value_inlots ca_tender_est_value_inlots_ppp if !missing(ca_tender_est_value_inlots)
gen lot_est_pricecurrency=currency
************************************
*Bid price

// br ca_contract_value ca_contract_value_ppp currency curr_contract
gen curr_contract=currency if !missing(ca_contract_value)
************************************
*Generating indicator type variables

gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"

********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*Export for reverse flatten tool

use "${country_folder}/`country'_wb_2011.dta",clear

// count if missing(anb_masterid) & filter_drop
// count if missing(anb_name) & missing(anb_masterid) & filter_drop
replace filter_drop=0 if missing(anb_masterid)
// sort anb_masterid
// br anb_masterid anb_masterid_str anb_id anb_name if filter_drop
// count if missing(anb_id) & filter_drop
************************************
*Supplier id

// count if missing(w_masterid) & filter_drop
// count if missing(w_id)  & filter_drop
// count if missing(w_id_n) & filter_drop

foreach var of varlist w_masterid {
decode `var', gen(`var'_str)
replace `var'_str="" if `var'_str=="."
}
// br w_masterid w_masterid_str w_id w_id_n if  filter_drop  //w_id
************************************

drop if filter_drop==0
************************************

bys tender_id: gen x=_N
************************************
*Generating LOT NUMBER

*lot_row_nr was completely missing in file so it was dropped
// format  title ca_title ca_lot_title  w_name   %15s
// br x tender_id ca_lotscount  bid_iswinning title ca_title ca_lot_title  w_name ca_contract_value ca_url if x>1 & ca_lotscount>1

*Fixing bid_iswinning
*SUB-RULE #1 Switch bid is winning to "t" if it's missing and ca_lotscount==1
// tab ca_lotscount if bid_iswinning ==""
replace bid_iswinning="t" if bid_iswinning =="" & ca_lotscount==1
*For the rest give it "t" also id cotract value is not missing
replace bid_iswinning="t" if bid_iswinning =="" & ca_lotscount>1 & !missing(ca_contract_value)
*2 obs remain - drop
replace filter_drop=0 if missing(bid_iswinning)
drop x
drop if filter_drop==0
bys tender_id: gen x=_N
************************************
*RULE #2 - update on RULE #1

*It's only 1 lot 
gen  lot_number = 1

bys tender_id lot_number: gen bid_number=_n
************************************

// sort tender_id lot_number bid_number 
// unique tender_id lot_number bid_number 

foreach var of varlist bid_iswinning  {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************
*Export prevsanct and has sanct anyway

gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

sort tender_id lot_number bid_number bid_iswinning
************************************

gen tender_addressofimplementation_c =""
gen tender_addressofimplementation_n =""
foreach var of varlist w_id{
replace `var'="" if `var'=="null"
}
************************************

keep tender_id lot_number bid_number bid_iswinning tender_country ca_contractsignaturedate tender_biddeadline tender_proceduretype tender_publications_notice_type tender_publications_firstcallfor cft_url source_website tender_publications_award_type tender_publications_firstdcontra ca_url source_website anb_masterid_str anb_city anb_country_iso2 buyer_geocodes anb_name buyer_type tender_addressofimplementation_c tender_addressofimplementation_n w_masterid_str w_id w_country_str bidder_geocodes  w_name ca_contract_value_ppp ca_contract_value curr_contract bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title ca_bids_new ca_tender_est_value_inlots_ppp ca_tender_est_value_inlots lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_ca_contract_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************

order tender_id lot_number bid_number bid_iswinning tender_country ca_contractsignaturedate tender_biddeadline tender_proceduretype tender_publications_notice_type tender_publications_firstcallfor cft_url source_website tender_publications_award_type tender_publications_firstdcontra ca_url source_website anb_masterid_str anb_city anb_country_iso2 buyer_geocodes anb_name buyer_type tender_addressofimplementation_c tender_addressofimplementation_n w_masterid_str w_id w_country_str bidder_geocodes w_name ca_contract_value_ppp ca_contract_value curr_contract bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title ca_bids_new ca_tender_est_value_inlots_ppp ca_tender_est_value_inlots lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_ca_contract_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

// count if missing(anb_masterid)
// count if missing(w_masterid)
********************************************************************************
export delimited "${country_folder}/`country'_mod.csv", replace
********************************************************************************
*END