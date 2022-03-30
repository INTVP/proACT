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
use $country_folder/wb_jm_cri201114.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. 
********************************************************************************

*Fixing variables for reverse tool

gen tender_country = "JM"
************************************

br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD"
**all are completed contracts

br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************

*buyer nuts
tab buyer_nuts, m
gen  buyer_geocodes = buyer_nuts
************************************

*Bidder nuts
tab bidder_nuts, m
gen  bidder_geocodes = bidder_nuts
************************************

*gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
*no obs
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
gen lot_est_pricecurrency = currency
************************************

rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

br tender_title lot_title
gen title = tender_title
************************************

br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
************************************

*Exporting for the rev flatten tool\

*Indicators
rename tender_indicator_integrity_proce c_INTEGRITY_PROCEDURE_TYPE
rename tender_indicator_integrity_adver  c_INTEGRITY_ADVERTISEMENT_PERIOD
rename tender_indicator_integrity_decis  c_INTEGRITY_DECISION_PERIOD
rename tender_indicator_integrity_call_  c_INTEGRITY_CALL_FOR_TENDER_PUB
rename tender_indicator_integrity_singl  c_INTEGRITY_SINGLE_BID
rename proa_ycsh  c_INTERGIRTY_WINNER_SHARE
************************************

rename title_missing c_TRANSPARENCY_TITLE_MISSING
rename value_missing c_TRANSPARENCY_VALUE_MISSING
rename imp_loc_missing c_TRANSPARENCY_IMP_LOC_MISSING
rename bid_nr_missing c_TRANSPARENCY_BID_NR_MISSING
rename buyer_name_missing c_TRANSPARENCY_BUYER_NAME_MIS
rename bidder_name_missing c_TRANSPARENCY_BIDDER_NAME_MIS
rename ca_type_missing c_TRANSPARENCY_SUPPLY_TYPE_MIS
rename proc_method_missing c_TRANSPARENCY_PROC_METHOD_MIS
rename award_date_missing c_TRANSPARENCY_AWARD_DATE_MIS
************************************

rename bid_price_ppp bid_price_netAmountUsd
************************************

reshape long c_ , i(tender_id proa_ycsh proa_ycsh9 taxhav2 ) j(indicator, string)
************************************

*Fixing Transparency indicators first
gen tender_indicator_type=""
replace tender_indicator_type="TRANSPARENCY_BUYER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BUYER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_BIDDER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BIDDER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_SUPPLY_TYPE_MISSING" if tender_indicator_type=="TRANSPARENCY_SUPPLY_TYPE_MIS"
replace tender_indicator_type="TRANSPARENCY_PROC_METHOD_MISSING" if tender_indicator_type=="TRANSPARENCY_PROC_METHOD_MIS"
replace tender_indicator_type="TRANSPARENCY_AWARD_DATE_MISSING" if tender_indicator_type=="TRANSPARENCY_AWARD_DATE_MIS"
************************************

*Calculating  status


*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
 
*undefined if tax haven ==9 
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


gen tender_indicator_status = "INSUFFICIENT DATA" if inlist(tender_indicator_value,99,999,.)
replace tender_indicator_status = "CALCULATED" if missing(tender_indicator_status)
replace tender_indicator_value=. if inlist(tender_indicator_value,99,999,.)
************************************

gen corr_ben_bi=.
gen buyer_indicator_type = "INTEGRITY_BENFORD"
rename corr_ben_bi buyer_indicator_value
gen buyer_indicator_status = "INSUFFICIENT DATA" if inlist(buyer_indicator_value,99,.)
replace buyer_indicator_status = "CALCULATED" if missing(buyer_indicator_status)
replace buyer_indicator_value=. if inlist(buyer_indicator_value,99,999,.)
************************************

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
br  buyer_id bidder_id

********************************************************************************
save $country_folder/wb_jm_cri201114.dta, replace
********************************************************************************

********************************************************************************
*Fixing variables for the rev flatten tool\

sort tender_id lot_row_nr

tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)
tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
************************************

*tender_id is unique

gen lot_number=1
bys tender_id lot_number: gen bid_number=_n
************************************

gen ind_nocft_val=c_INTEGRITY_CALL_FOR_TENDER_PUB
gen ind_singleb_val=c_INTEGRITY_SINGLE_BID
gen ind_corr_decp_val=c_INTEGRITY_DECISION_PERIOD
gen ind_corr_proc_val=c_INTEGRITY_PROCEDURE_TYPE
gen ind_corr_submp_val=c_INTEGRITY_ADVERTISEMENT_PERIOD
gen ind_csh_val=c_INTERGIRTY_WINNER_SHARE

gen ind_tr_buyer_name_val=c_TRANSPARENCY_BUYER_NAME_MIS
gen ind_tr_tender_title_val=c_TRANSPARENCY_TITLE_MISSING
gen ind_tr_bidder_name_val=c_TRANSPARENCY_BIDDER_NAME_MIS
gen ind_tr_tender_supplytype_val=c_TRANSPARENCY_SUPPLY_TYPE_MIS
gen ind_tr_bid_price_val=c_TRANSPARENCY_VALUE_MISSING
gen ind_tr_impl_val=c_TRANSPARENCY_IMP_LOC_MISSING
gen ind_tr_proc_val=c_TRANSPARENCY_PROC_METHOD_MIS
gen ind_tr_bids_val=c_TRANSPARENCY_BID_NR_MISSING
gen ind_tr_aw_date2_val=c_TRANSPARENCY_AWARD_DATE_MIS
************************************

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

*Implementing some fixes

cap gen buyer_country = "JM"

foreach var in buyer_geocodes buyer_mainactivities tender_addressofimplementation_n bidder_geocodes{
replace  `var' = "["+ `"""' + `var' + `"""' +"]" if !missing(`var')
}
********************************************************************************

export delimited $country_folder/JM_mod.csv, replace
********************************************************************************
*END