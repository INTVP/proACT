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
use $country_folder/dfid2_ug_cri_201116.dta, clear
********************************************************************************

*Fixing variables for reverse tool

gen tender_country = "UG"
******************************************

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_finalprice) | !missing(tender_publications_firstdcontra)

br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
******************************************

*rename buyer_NUTS3 buyer_geocodes
tab buyer_nuts
gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]"
replace buyer_geocodes="" if buyer_nuts==""

*if buyer nuts is missing it shoud be empty
*for bidder and impl also
*before that check nuts all nuts code and assigned city in a new sheet
******************************************

*Fixing IMPL nuts

gen tender_addressofimplementation_c = tender_addressofimplementation_n 

tab tender_addressofimplementation_n, m
tab tender_addressofimplementation_c, m
******************************************

*Fixing Bidder nuts
tab bidder_nuts, m

gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]"
replace bidder_geocodes="" if bidder_nuts==""

gen  buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
drop buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities
******************************************


rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
gen lot_est_pricecurrency = currency
******************************************


****check https://docs.google.com/spreadsheets/d/10hP2BFLi1-k7pjQU7vhF5SwYikrVpzxzs6y2sT4WP08/edit#gid=1804250147
**ask for the new updates from Aly (product harmonization)
rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
replace lot_localProductCode = substr(lot_localProductCode,1,8)
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)

br tender_title lot_title
gen title = lot_title
replace title = tender_title if missing(title)

sum tender_recordedbidscount lot_bidscount
gen bids_count = .
*replace bids_count = tender_recordedbidscount if missing(bids_count)
******************************************

*Exporting for the rev flatten tool

*Indicators
rename tender_indicator_integrity_proce c_INTEGRITY_PROCEDURE_TYPE
rename tender_indicator_integrity_adver  c_INTEGRITY_ADVERTISEMENT_PERIOD
rename tender_indicator_integrity_decis  c_INTEGRITY_DECISION_PERIOD
rename tender_indicator_integrity_call_  c_INTEGRITY_CALL_FOR_TENDER_PUB
rename tender_indicator_integrity_singl  c_INTEGRITY_SINGLE_BID
rename tender_indicator_integrity_ca_sh  c_INTERGIRTY_WINNER_SHARE

rename tender_indicator_transparency_ti c_TRANSPARENCY_TITLE_MISSING
rename tender_indicator_transparency_va c_TRANSPARENCY_VALUE_MISSING
rename v107 c_TRANSPARENCY_IMP_LOC_MISSING
rename tender_indicator_transparency_bu c_TRANSPARENCY_BUYER_NAME_MIS
rename v109 c_TRANSPARENCY_BIDDER_NAME_MIS
rename tender_indicator_transparency_pr c_TRANSPARENCY_PROC_METHOD_MIS
rename tender_indicator_transparency_aw c_TRANSPARENCY_AWARD_DATE_MIS


*rename buyer_district_api buyer_district
*rename buyer_city_api buyer_city
*rename buyer_county_api buyer_county
*rename buyer_NUTS3 buyer_nuts3

rename bid_price_ppp bid_price_netAmountUsd

reshape long c_ , i(tender_id proa_ycsh proa_ycsh4 taxhav2 ) j(indicator, string)

*rename c_ tender_indicator_value
*rename indicator tender_indicator_type
*br tender_indicator_type tender_indicator_value

*Fixing Transparency indicators first
replace tender_indicator_type="TRANSPARENCY_BUYER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BUYER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_BIDDER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BIDDER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_SUPPLY_TYPE_MISSING" if tender_indicator_type=="TRANSPARENCY_SUPPLY_TYPE_MIS"
replace tender_indicator_type="TRANSPARENCY_PROC_METHOD_MISSING" if tender_indicator_type=="TRANSPARENCY_PROC_METHOD_MIS"
replace tender_indicator_type="TRANSPARENCY_AWARD_DATE_MISSING" if tender_indicator_type=="TRANSPARENCY_AWARD_DATE_MIS"
******************************************

*Calculating  status


*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
 
*undefined if tax haven ==9 
gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
*gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
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


gen tender_indicator_status = "INSUFFICIENT DATA" if inlist(tender_indicator_value,99,999,.)
replace tender_indicator_status = "CALCULATED" if missing(tender_indicator_status)
replace tender_indicator_value=. if inlist(tender_indicator_value,99,999,.)


gen buyer_indicator_type = "INTEGRITY_BENFORD"
gen c_INTEGRITY_BENFORD=""
*rename corr_ben2 buyer_indicator_value
gen buyer_indicator_status = "INSUFFICIENT DATA" if inlist(c_INTEGRITY_BENFORD,99,.)
replace buyer_indicator_status = "CALCULATED" if missing(buyer_indicator_status)
replace buyer_indicator_value=. if inlist(buyer_indicator_value,99,999,.)
******************************************

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
******************************************

foreach var of varlist buyer_id bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
br  buyer_id bidder_id
 ******************************************

sort tender_id lot_row_nr

tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)
tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
******************************************

bys tender_id: gen x=_N
format tender_title  bidder_name %15s
br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
count if missing(tender_lotscount)
*if tender_isframework=="t" & missing(lot_row_nr)
gen lot_number = 1 
*replace lot_number = lot_row_nr if tender_isframework=="t" & !missing(lot_row_nr)
bys tender_id bidder_name: gen lot_number=_n 
count if missing(lot_number)

sort tender_id lot_number
br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
******************************************

*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n
br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK
******************************************


*Sanctions

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
/*

recast str818 bidder_name, force
merge m:1 bidder_name using $utility_data/country/UG/UG_sanctions.dta
drop bidder_name 
drop if _m==2
drop _m
format w_name %15s
br w_name n_row1-sanct_country4 if !missing(n_row1)
drop n_row*
*Manage dates
format sanct_startDate1 sanct_startDate2 sanct_startDate3 %d


forval x =1/2 {
gen sanct_startDate`x'_f = date(sanct_startdate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_enddate`x',"YMD")
}
format sanct_startDate* sanct_endDate* %d
br  ca_date sanct_startDate* sanct_endDate* if !missing(sanct_startDate1_f)

gen bidder_hasSanction="false"
replace bidder_hasSanction="true" if !missing(sanct_startDate1_f)
gen bidder_previousSanction="false"
replace bidder_previousSanction="true" if ca_date>=sanct_endDate1_f & !missing(sanct_endDate1_f)
replace bidder_previousSanction="" if missing(ca_date)
*Dates we only keep the latest start and end date
gen sanct_startdate = ""
replace sanct_startdate = sanct_startdate1 if !missing(sanct_startdate1)
replace sanct_startdate = sanct_startdate2 if !missing(sanct_startdate2)
*replace sanct_startdate = sanct_startDate3 if !missing(sanct_startDate3)
*replace sanct_startdate = sanct_startDate4 if !missing(sanct_startDate4)
*format sanct_startdate %d
*br sanct_startdate sanct_startDate* if !missing(sanct_startDate3)
gen sanct_enddate = ""
replace sanct_enddate = sanct_enddate1 if !missing(sanct_enddate1)
replace sanct_enddate = sanct_enddate2 if !missing(sanct_enddate2)
*replace sanct_enddate = sanct_endDate3 if !missing(sanct_endDate3)
*replace sanct_enddate = sanct_endDate4 if !missing(sanct_endDate4)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate3)

rename sanct_startdate sanct_startdate_d
gen sanct_startdate=sanct_startDate1
replace sanct_startdate=sanct_startDate2 if missing(sanct_startdate)
*replace sanct_startdate=sanct_startDate3 if missing(sanct_startdate)

*Sanctioning Authority name
br sanct_name1 sanct_name2 if !missing(sanct_startdate)
gen sanct_name = sanct_name1 if !missing(sanct_name1)
replace sanct_name= sanct_name + " & " + sanct_name2 if !missing(sanct_name2)
*replace sanct_name= sanct_name + " & " + sanct_name3 if !missing(sanct_name3)
*replace sanct_name= sanct_name + " & " + sanct_name4 if !missing(sanct_name4)
*Sanctioned corruption indicator
tab bidder_hasSanction, m
tab bidder_previousSanction, m
br aw_dec_date bidder_hasSanction bidder_previousSanction  sanct_startdate sanct_enddate sanct_name if !missing(sanct_startdate)
*/
******************************************
   

gen c_TRANSPARENCY_SUPPLY_TYPE_MIS=0
gen c_TRANSPARENCY_BID_NR_MISSING=0

gen ind_nocft_val=c_INTEGRITY_CALL_FOR_TENDER_PUB
gen ind_singleb_val=c_INTEGRITY_SINGLE_BID
gen ind_corr_decp_val=c_INTEGRITY_DECISION_PERIOD
gen ind_corr_proc_val=c_INTEGRITY_PROCEDURE_TYPE
gen ind_corr_submp_val=c_INTEGRITY_ADVERTISEMENT_PERIOD
gen ind_csh_val=c_INTERGIRTY_WINNER_SHARE
gen ind_corr_ben2_val=c_INTEGRITY_BENFORD

gen ind_tr_buyer_name_val=c_TRANSPARENCY_BUYER_NAME_MIS
gen ind_tr_tender_title_val=c_TRANSPARENCY_TITLE_MISSING
gen ind_tr_bidder_name_val=c_TRANSPARENCY_BIDDER_NAME_MIS
gen ind_tr_tender_supplytype_val=c_TRANSPARENCY_SUPPLY_TYPE_MIS
gen ind_tr_bid_price_val=c_TRANSPARENCY_VALUE_MISSING
gen ind_tr_impl_val=c_TRANSPARENCY_IMP_LOC_MISSING
gen ind_tr_proc_val=c_TRANSPARENCY_PROC_METHOD_MIS
gen ind_tr_bids_val=c_TRANSPARENCY_BID_NR_MISSING
gen ind_tr_aw_date2_val=c_TRANSPARENCY_AWARD_DATE_MIS
******************************************

save $country_folder/dfid2_ug_cri_201116.dta, replace

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben2_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben2_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

export delimited using $country_folder/UG_mod.csv, replace
********************************************************************************
*END