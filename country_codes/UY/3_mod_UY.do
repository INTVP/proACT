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
*Generate tender_country
gen tender_country = "UY"

************************************
*Create notice type for tool

// br year cft_date cft_deadline cft_deadline2 cft_open_date aw_dec_date *date* if filter_wb
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date) | !missing(cft_deadline) | !missing(cft_deadline2)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(aw_dec_date)

decode source, gen(source2)
drop source 
rename source2 source
replace source=upper(source)

*Fixing source
gen source2 = "https://www.gub.uy/agencia-reguladora-compras-estatales/" if source=="ACCE"
replace source2 = "https://www.comprasestatales.gub.uy/rupe/clientes/publicos/LoginCliente.jsf?faces-redirect=true" if source=="RUPE"
rename source source_abr
rename source2 source
************************************
*TITLE

decode ten_descr, gen(title)
replace title = ""  if title == "."
replace title=ustrlower(title,"es")
replace title= subinstr(title,"©","",.)
replace title= subinstr(title,"ˇ","",.)
replace title= subinstr(title,"‰","",.)
replace title= ustrtitle(title,"es")

// charlist title
************************************
*Enumeration buyer type
// tab buyer_type if filter_wb, m //ok
// gen buyer_buyertype = buyer_type
// cap drop buyer_buyertype
rename buyer_type buyer_buyertype
************************************
*Enumeration supply type

// tab supply_type if filter_wb, m //ok
// gen tender_supplytype = supply_type
cap drop tender_supplytype
rename supply_type tender_supplytype
************************************
*Renaming price variables
rename ca_contract_value bid_price
rename ca_contract_value_ppp bid_priceUsd
rename curr bid_pricecurrency
************************************
*Checking product codes

gen market_id_star=substr(tender_cpvs,1,2)
// tab market_id_star if filter_wb, m //good
drop market_id_star
rename tender_cpvs lot_productCode
tostring aw_item_class_id, gen(lot_localProductCode)
replace lot_localProductCode="" if lot_localProductCode=="."
gen lot_localProductCode_type = "National System" if !missing(lot_localProductCode)
// br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

rename ca_nrbid bids_count
************************************

decode ca_procedure_det, gen(tender_nationalproceduretype)
replace tender_nationalproceduretype = "" if tender_nationalproceduretype=="."
replace tender_nationalproceduretype = ustrtitle(tender_nationalproceduretype)
do "${utility_codes}/fix_bad_national_proc_type.do"
************************************

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

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"
************************************
*Checking ids & names to be used


*Bidder id
// count if missing(w_id_gen) & filter_wb //no missing
decode w_id2, gen(w_id2_2)
replace w_id2_2="" if w_id2_2=="."
decode w_addid, gen(w_addid_2)
replace w_addid_2="" if w_addid_2=="."
drop w_id2 w_addid
rename w_id2_2 w_id2
rename w_addid_2 w_addid
gen w_source_id = w_id2
replace w_source_id = w_addid if missing(w_source_id)
// br w_id_gen w_source_id w_name

// rename w_id_gen bidder_masterid
tostring bidder_masterid, replace
replace bidder_masterid="" if bidder_masterid=="."
// count if missing(w_source_id) & filter_wb //missing
rename w_source_id bidder_id

*Bidder name
decode w_name, gen(bidder_name) 
replace bidder_name = ustrfix(bidder_name, "")
replace bidder_name=subinstr(bidder_name,"­","",.) 
replace bidder_name = ustrupper(bidder_name)

*Buyer name
rename anb_name_str buyer_name
replace buyer_name = ustrfix(buyer_name, "")
replace buyer_name=subinstr(buyer_name,"­","",.) 
replace buyer_name=subinstr(buyer_name,"-","",.)  
replace buyer_name = ustrupper(buyer_name)

*Buyer id
egen anb_id_gen = group(buyer_name) if !missing(buyer_name)
tostring anb_id_gen, replace
replace anb_id_gen="UY" + anb_id_gen if !missing(anb_id_gen)
replace anb_id_gen="" if anb_id_gen=="UY."
// charlist anb_name_str
sort anb_id_gen
rename anb_id_gen buyer_masterid
// br anb_id_gen anb_id  anb_name_str
// count if missing(anb_id_gen) & filter_wb //no missings
// count if missing(anb_id) & filter_wb //missing

decode anb_id, gen(anb_id2)
replace anb_id2 = "" if anb_id2 == "."
drop anb_id
ren anb_id2 anb_id
replace anb_id="UY" + anb_id if !missing(anb_id)
ren anb_id buyer_id
replace buyer_id=subinstr(buyer_id,"-","/",.)


// br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
replace `var' = "" if `var'=="-"

}

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}

replace filter_wb=0 if missing(buyer_masterid)
replace filter_wb=0 if bidder_name=="-"

// br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
*Check if titles/names start with "" or []
foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

// tab tender_proceduretype, m
// tab tender_supplytype, m
************************************
*Dates

gen deadline_temp=cft_deadline
replace deadline_temp=cft_deadline2 if missing(deadline_temp)
format deadline_temp %d
// br year cft_date deadline_temp cft_deadline cft_deadline2 cft_open_date aw_dec_date *date* if filter_wb
foreach var of varlist cft_date deadline_temp cft_open_date aw_dec_date {
cap drop day
gen day=day(`var')
tostring day, replace
replace day="" if day=="."
cap drop month
gen month=month(`var')
tostring month, replace
replace month="" if month=="."
cap drop year2
gen year2=year(`var')
tostring year2, replace
replace year2="" if year2=="."
gen len=length(day)
replace day="0"+day if len==1 & !missing(day)
drop len
gen len=length(month)
replace month="0"+month if len==1 & !missing(month)
drop len
gen `var'2 = year2+"-"+month+"-"+day if !missing(year2)
drop year2 month day
drop `var'
rename `var'2 `var'
cap drop day 
cap drop month 
cap drop year2 
}
************************************
*Countries
gen bidder_country = iso
// gen bidder_country=substr(bidder_geocodes,3,5) if filter_wb
// replace bidder_country=subinstr(bidder_country,`""]"',"",.) if filter_wb
*No buyer country or implementation info
************************************
*Calcluating indicators

*For indicators with 1 category
foreach var of varlist singleb nocft  {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_taxhav_val=.
gen ind_corr_ben_val=.

*For indicators with categories
foreach var of varlist corr_proc corr_decp corr_submp  {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
************************************
*Contract Share

// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency

gen proc = tender_nationalproceduretype
gen impl= ""
gen aw_date2 = aw_dec_date
gen bids =bids_count
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids
********************************************************************************
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
*Export for Reverse tool

************************************
drop if filter_wb==0
drop if missing(bidder_name) | bidder_name=="N/A"
duplicates drop 
************************************
// br *id*

foreach var of varlist uniqueid ca_id  aw_id aw_id2 ocid ten_id tenawid {
decode `var', gen(`var'_2)
replace `var'_2="" if `var'_2=="." 
drop `var'
rename `var'_2 `var' 
}
// br uniqueid ca_id aw_id aw_id2 ocid ten_id tenawid  ten_id_bcu
sort uniqueid
************************************

duplicates drop ca_id aw_id, force
bys ca_id aw_id: gen x=_N
sort ca_id aw_id
drop x
// format title  bidder_name anb_name_str   %15s
// br x uniqueid ca_id aw_id title anb_name_str bidder_name ca_contract_value bid_priceUsd * if x>1

// unique ca_id aw_id
// unique uniqueid 
************************************
*Generating BID NUMBER 
bys ca_id: gen lot_number=_n 
bys ca_id lot_number: gen bid_number=_n
sort ca_id lot_number bid_number 
// unique ca_id lot_number bid_number 
************************************
replace bid_pricecurrency="" if  missing(bid_priceUsd) | missing(ca_contract_value) 
************************************
rename ca_id tender_id
rename aw_dec_date tender_awarddecisiondate
rename deadline_temp tender_biddeadline
rename cft_date tender_publications_firstcallfor

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type buyer_masterid buyer_id  buyer_name buyer_buyertype bidder_masterid bidder_id bidder_country bidder_name bid_price bid_priceUsd bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_taxhav_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_corr_proc_val ind_corr_proc_type decp ind_corr_decp_val ind_corr_decp_type submp ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type buyer_masterid buyer_id  buyer_name buyer_buyertype bidder_masterid bidder_id bidder_country bidder_name bid_price bid_priceUsd bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_taxhav_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_corr_proc_val ind_corr_proc_type decp ind_corr_decp_val ind_corr_decp_type submp ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************
export excel using "${utility_data}/country/`country'/`country'_mod.xlsx", firstrow(var) replace
// import excel using "${utility_data}/country/`country'/`country'_mod.xlsx", firstr clear
// save "${utility_data}/country/`country'/`country'_mod.dta", replace
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
*Implementing some fixes

// destring bid_priceUsd, replace force
// destring bid_price, replace force
********************************************************************************
*END