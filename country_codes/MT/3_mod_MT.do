*Data
use "${country_folder}/MT_wb_1020.dta", clear

********************************************************************************
*For indicators with 1 category

foreach var of varlist nocft singleb taxhav2 corr_submp corr_decp corr_proc {
	gen 	ind_`var'_val = 0 
	replace ind_`var'_val = 0 	if `var'==1
	replace ind_`var'_val = 100 if `var'==0
	replace ind_`var'_val =	. 	if missing(`var') | `var'==99
	replace ind_`var'_val = .  	if `var'==9  //tax haven undefined
}

gen ind_corr_ben_val = . 

************************************
*Contract Share

sum w_ycsh4

gen 	ind_csh_val = w_ycsh4*100
replace ind_csh_val = 100-ind_csh_val

************************************
*Transparency

gen 	title = lot_title
replace title = tender_title if missing(title)

gen impl 	 = tender_addressofimplementation_n
gen proc 	 = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids 	 = lot_bidscount

foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
	gen 	ind_tr_`var'_val = 0
	replace ind_tr_`var'_val = 100 if !missing(`var') 
}

cap drop  impl proc aw_date2 title bids

********************************************************************************

save "${country_folder}/MT_wb_1020.dta", replace

********************************************************************************
*Exporting for the rev flatten tool

use "${country_folder}/MT_wb_1020.dta", clear

drop if missing(tender_publications_lastcontract)
drop if filter_ok==0

bys 	tender_id: gen x=_N
format 	tender_title bidder_name lot_title  tender_publications_lastcontract  %15s

************************************
*RULE: use tender_lotscount, if tender_lotscount==1 then lot_number is 1 for all obs with the same tender_id; if tender_lotscount>1 then we count rows as seperate lots

bys 	tender_id: gen lot_number = _n 	if tender_lotscount > 1
replace 			   lot_number = 1 	if missing(lot_number) & tender_lotscount == 1

************************************
*Bid number: Rule;

bys tender_id lot_number: gen bid_number=_n

************************************

gen tender_country = "MT"

************************************
*Create notice type for tool

cap drop tender_publications_notice_type tender_publications_award_type
gen 	 tender_publications_notice_type = "CONTRACT_NOTICE" 	if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen 	 tender_publications_award_type  = "CONTRACT_AWARD" 	if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)

************************************
*rename buyer_NUTS3 buyer_geocodes

gen  	buyer_geocodes = buyer_nuts
replace buyer_geocodes = "MT000" 	if buyer_nuts=="MT"
replace buyer_geocodes = "MT000" 	if buyer_nuts=="MT0"
replace buyer_geocodes = "MT000" 	if buyer_nuts=="MT00"
replace buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]"

************************************

gen  	buyer_mainactivities2 = "["+ `"""' + buyer_mainactivities + `"""' +"]"
drop 	buyer_mainactivities
rename buyer_mainactivities2 buyer_mainactivities

************************************
*fixing nuts

gen 	impl_nuts = tender_addressofimplementation_n
replace impl_nuts = "" 		if impl_nuts == "00"
replace impl_nuts = "GR000" if impl_nuts == "GR"
replace impl_nuts = "IT000" if impl_nuts == "IT"
replace impl_nuts = "MT000" if impl_nuts == "MT"
replace impl_nuts = "MT000" if impl_nuts == "MT0"
replace impl_nuts = "MT000" if impl_nuts == "MT00"
replace impl_nuts = "TR000" if impl_nuts == "TR"

gen 	tender_addressofimplementation_c = substr(impl_nuts,1,2) 
gen 	tender_addressofimplementation2  = "["+ `"""' + impl_nuts + `"""' +"]"
drop	tender_addressofimplementation_n
rename 	tender_addressofimplementation2  tender_addressofimplementation_n


gen bidder_nuts_len = length(bidder_nuts)
gen bidder_geocodes =  bidder_nuts

*Fix Greece 
replace bidder_geocodes = subinstr(bidder_geocodes,"GR","EL",.)
replace bidder_geocodes = bidder_geocodes + "000" 	if bidder_nuts_len==2
replace bidder_geocodes = bidder_geocodes + "00" 	if bidder_nuts_len==3
replace bidder_geocodes = bidder_geocodes + "0" 	if bidder_nuts_len==4
replace bidder_geocodes = bidder_nuts + "0" 		if bidder_nuts_len==4
replace bidder_geocodes = "EL300" 					if bidder_nuts_len==3
replace bidder_geocodes = bidder_nuts + "000" 		if bidder_nuts_len==2
replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"

************************************
*Export prevsanct and has sanct anyway

gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""

************************************

rename  bid_price_ppp 				bid_priceUsd
rename  tender_finalprice_ppp 		tender_finalpriceUsd
rename  lot_estimatedprice_ppp  		lot_estimatedpriceUsd
rename  tender_estimatedprice_ppp 	tender_estimatedpriceUsd

gen	 	bid_pricecurrency  = currency
gen 	ten_est_pricecurrency = currency

************************************

rename 	tender_cpvs 			lot_productCode
gen 	lot_localProductCode =  lot_productCode
gen 	lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)

************************************

gen 	title = lot_title
replace title = tender_title if missing(title)

************************************

gen 	bids_count = lot_bidscount
replace bids_count = tender_recordedbidscount if missing(bids_count)

************************************

gen ind_nocft_type 					= "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type 				= "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type 				= "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type 				= "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type 			= "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type 				= "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type 				= "INTEGRITY_BENFORD"
gen ind_csh_type 					= "INTEGRITY_WINNER_SHARE"
gen ind_tr_buyer_name_type 			= "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type 		= "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type 		= "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type 	= "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type 			= "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type 				= "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type 				= "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type				= "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type 			= "TRANSPARENCY_AWARD_DATE_MISSING"

************************************

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
	replace `var' = lower(`var')
	replace `var' = "true" 	if inlist(`var',"true","t")
	replace `var' = "false" if inlist(`var',"false","f")
}

************************************

foreach var of varlist buyer_id bidder_id {
	tostring `var', replace
	replace `var' = "" if `var'=="."
}
br  buyer_id bidder_id

************************************

keep tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

order tender_id lot_number bid_number bid_iswinning tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  notice_url  source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count tender_estimatedpriceUsd tender_estimatedprice ten_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type  ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

********************************************************************************

export delimited "${country_folder}/MT_mod.csv", replace

********************************************************************************
*END