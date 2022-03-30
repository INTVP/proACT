*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/UY_wb_2011.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m 
tab nocft , m 
tab corr_decp, m
tab corr_submp , m
tab corr_proc, m

*For indicators with 1 category
foreach var of varlist singleb nocft  {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_taxhav2_val=.
gen ind_corr_ben_val=.

tab ind_singleb_val  singleb, m
tab ind_nocft_val  nocft, m
************************************

*For indicators with categories
tab corr_decp, m
tab corr_proc, m
foreach var of varlist corr_proc  corr_decp corr_submp  {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_decp_val  corr_decp, m
************************************

*Contract Share
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Transparency
decode ca_procedure_det, gen(proc)
replace proc="" if proc=="."
gen impl= ""
gen aw_date2 = aw_dec_date
gen bids =ca_nrbid
decode ten_descr, gen (title)
decode w_name, gen(bidder_name)
foreach var of varlist anb_name_str title bidder_name supply_type ca_contract_value impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids

cap drop ind_tr_title_val
gen ind_tr_title_val=0
replace ind_tr_title_val=100 if !missing(ten_title2)

********************************************************************************
save $country_folder/UY_wb_2011.dta, replace
********************************************************************************
*Prep for Reverse tool
use $country_folder/UY_wb_2011.dta, clear

*TITLE
replace title=ustrlower(title,"es")
replace title= subinstr(title,"©","",.)
replace title= subinstr(title,"ˇ","",.)
replace title= subinstr(title,"‰","",.)
charlist title
************************************

gen tender_country = "UY"
************************************

*Create notice type for tool
br year cft_date cft_deadline cft_deadline2 cft_open_date aw_dec_date *date* if filter_wb
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date) | !missing(cft_deadline) | !missing(cft_deadline2)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(aw_dec_date)
tab 
decode source, gen(source2)
drop source 
rename source2 source
replace source=upper(source)
************************************

*geocodes
gen  buyer_geocodes = ""
rename iso  bidder_geocodes
replace  bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]" if filter_wb& !missing(bidder_geocodes)
gen  impl_nuts = ""
************************************

*Enumeration buyer type
tab buyer_type if filter_wb, m //ok
************************************

*Enumeration supply type
tab supply_type if filter_wb, m //ok
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

*Renaming price variables
rename ca_contract_value_ppp bid_priceUsd
rename curr bid_pricecurrency
************************************

*Checking product codes
gen market_id_star=substr(tender_cpvs,1,2)
tab market_id_star if filter_wb, m //good
drop market_id_star
rename tender_cpvs lot_productCode
tostring aw_item_class_id, gen(lot_localProductCode)
replace lot_localProductCode="" if lot_localProductCode=="."
gen lot_localProductCode_type = "National System" if !missing(lot_localProductCode)
br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

rename ca_nrbid bids_count
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

************************************

*Checking ids & names to be used
count if missing(w_id_gen) & filter_wb //no missing
decode w_id2, gen(w_id2_2)
replace w_id2_2="" if w_id2_2=="."
decode w_addid, gen(w_addid_2)
replace w_addid_2="" if w_addid_2=="."
drop w_id2 w_addid
rename w_id2_2 w_id2
rename w_addid_2 w_addid
gen w_source_id = w_id2
replace w_source_id = w_addid if missing(w_source_id)
br w_id_gen w_source_id w_name
tostring w_id_gen, replace
replace w_id_gen="" if w_id_gen=="."
count if missing(w_source_id) & filter_wb //missing
replace bidder_name = ustrfix(bidder_name, "")
replace bidder_name=subinstr(bidder_name,"­","",.) 
replace bidder_name = ustrupper(bidder_name)

replace anb_name_str = ustrfix(anb_name_str, "")
replace anb_name_str=subinstr(anb_name_str,"­","",.) 
replace anb_name_str=subinstr(anb_name_str,"-","",.)  
replace anb_name_str = ustrupper(anb_name_str)
egen anb_id_gen = group(anb_name_str) if !missing(anb_name_str)
tostring anb_id_gen, replace
replace anb_id_gen="UY" + anb_id_gen if !missing(anb_id_gen)
replace anb_id_gen="" if anb_id_gen=="UY."
charlist anb_name_str
sort anb_id_gen
br anb_id_gen anb_id  anb_name_str
count if missing(anb_id_gen) & filter_wb //no missings
count if missing(anb_id) & filter_wb //missing
replace filter_wb=0 if missing(anb_id_gen)

replace filter_wb=0 if bidder_name=="-"
br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
************************************

tab tender_proceduretype, m
tab supply_type, m
************************************

*Dates
gen deadline_temp=cft_deadline
replace deadline_temp=cft_deadline2 if missing(deadline_temp)
format deadline_temp %d
br year cft_date deadline_temp cft_deadline cft_deadline2 cft_open_date aw_dec_date *date* if filter_wb
foreach var of varlist cft_date deadline_temp cft_open_date aw_dec_date {
gen day=day(`var')
tostring day, replace
replace day="" if day=="."
gen month=month(`var')
tostring month, replace
replace month="" if month=="."
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
}
************************************

*Countries
gen bidder_country=substr(bidder_geocodes,3,5) if filter_wb
replace bidder_country=subinstr(bidder_country,`""]"',"",.) if filter_wb
*No buyer country or implementation info

********************************************************************************
save $country_folder/UY_wb_2011.dta, replace
********************************************************************************
*Export for Reverse tool
use  $country_folder/UY_wb_2011.dta, clear

************************************
drop if filter_wb==0
duplicates drop 
************************************
br *id*

foreach var of varlist uniqueid ca_id  aw_id aw_id2 ocid ten_id tenawid {
decode `var', gen(`var'_2)
replace `var'_2="" if `var'_2=="." 
drop `var'
rename `var'_2 `var' 
}
br uniqueid ca_id aw_id aw_id2 ocid ten_id tenawid  ten_id_bcu
sort uniqueid
************************************

duplicates drop ca_id aw_id, force
drop x
bys ca_id aw_id: gen x=_N
sort ca_id aw_id
format title  bidder_name anb_name_str   %15s
br x uniqueid ca_id aw_id title anb_name_str bidder_name ca_contract_value bid_priceUsd * if x>1

unique ca_id aw_id
unique uniqueid 

************************************
*Generating BID NUMBER 
bys ca_id: gen lot_number=_n 
bys ca_id lot_number: gen bid_number=_n
sort ca_id lot_number bid_number 
unique ca_id lot_number bid_number 
************************************

replace bid_pricecurrency="" if  missing(bid_priceUsd) | missing(ca_contract_value) 
************************************

decode ten_title, gen(ten_title2)
replace ten_title2="" if ten_title2=="."
replace ten_title2 = ustrfix(ten_title2, "")
replace ten_title2 = ustrupper(ten_title2)
replace ten_title2 = stritrim(ten_title2)	
replace ten_title2 = strrtrim(ten_title2)	
replace ten_title2 = strltrim(ten_title2)	
replace ten_title2 = strtrim(ten_title2)
************************************

*Fixing source
gen source2 = "https://www.gub.uy/agencia-reguladora-compras-estatales/" if source=="ACCE"
replace source2 = "https://www.comprasestatales.gub.uy/rupe/clientes/publicos/LoginCliente.jsf?faces-redirect=true" if source=="RUPE"
************************************

*Check if titles/names start with "" or []
foreach var of varlist title anb_name_str bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

replace anb_id=subinstr(anb_id,"-","/",.)
replace anb_id="UY" + anb_id if !missing(anb_id)
************************************

keep ca_id lot_number bid_number  tender_country aw_dec_date deadline_temp tender_proceduretype supply_type tender_publications_notice_type cft_date source2 tender_publications_award_type anb_id_gen anb_id  anb_name_str  buyer_type w_id_gen w_source_id bidder_country bidder_geocodes bidder_name bid_priceUsd ca_contract_value bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode ten_title2 bids_count ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_taxhav2_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_corr_proc_val ind_corr_proc_type ind_corr_decp_val ind_corr_decp_type ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_anb_name_str_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_supply_type_val ind_tr_tender_supplytype_type ind_tr_ca_contract_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type
************************************

order  ca_id lot_number bid_number  tender_country aw_dec_date deadline_temp tender_proceduretype supply_type tender_publications_notice_type cft_date source2 tender_publications_award_type anb_id_gen anb_id  anb_name_str  buyer_type w_id_gen w_source_id bidder_country bidder_geocodes bidder_name bid_priceUsd ca_contract_value bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode ten_title2 bids_count ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_taxhav2_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_corr_proc_val ind_corr_proc_type ind_corr_decp_val ind_corr_decp_type ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_anb_name_str_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_supply_type_val ind_tr_tender_supplytype_type ind_tr_ca_contract_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type

count if missing(ca_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(anb_id_gen)
count if missing(w_id_gen)
count if missing(lot_productCode)
********************************************************************************

*Implementing some fixes

drop if missing(bidder_name) | bidder_name=="N/A"

replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype)

destring bid_priceUsd, replace force
destring ca_contract_value, replace force
********************************************************************************

export delimited $country_folder/UY_mod.csv, replace
********************************************************************************
*END