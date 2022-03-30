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
use $country_folder/RO_wb_2011.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m 
tab nocft2, m
*tab taxhav2 , m
tab corr_decp, m
tab corr_submp , m
tab corr_proc, m
tab corr_ben, m
************************************

*For indicators with 1 category
foreach var of varlist singleb nocft2 corr_submp  {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_taxhav2_val=.

tab ind_singleb_val  singleb, m
tab ind_nocft2_val  nocft2, m
tab ind_corr_submp_val  corr_submp, m
************************************

*For indicators with categories
tab corr_decp, m
tab corr_proc, m
tab corr_ben, m
foreach var of varlist corr_proc corr_decp corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_decp_val  corr_decp, m
tab ind_corr_ben_val  corr_ben, m
************************************

*Contract Share
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Transparency
br tender_addressofimplementation_n tender_nationalproceduretype tender_publications_firstdcontra
br *title*
*gen title =title //after creating title variable below
*replace title = tender_title if missing(title)
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =lot_bidscount
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids

save $country_folder/RO_wb_2011.dta, replace //version with CRI calculated 
********************************************************************************
*Prep for Reverse tool

*To change all string vars with "." to ""
ds, has(type string) 
foreach var of varlist `r(varlist)'{
replace `var' = "" if `var'=="."
}
************************************

*Getting a new title for export
br tender_title lot_title
gen miss_tentitle=missing(tender_title)
gen miss_lottitle=missing(lot_title)
gen state = 1 if miss_tentitle==0 &  miss_lottitle==0
replace state = 2 if miss_tentitle==0 &  miss_lottitle==1
replace state = 3 if miss_tentitle==1 &  miss_lottitle==0
replace state = 4 if miss_tentitle==1 &  miss_lottitle==1
gen title=""
bys state: replace title = tender_title + " - " + lot_title if state==1
bys state: replace title = tender_title if state==2
bys state: replace title = lot_title if state==3
bys state: replace title ="" if state==4
br tender_title lot_title title state
drop miss_tentitle miss_lottitle state 
replace title = subinstr(title,`"""',"",.)
replace title =  subinstr(title,"„","",.)
************************************

gen tender_country = "RO"
************************************

*Create notice type for tool
cap drop tender_publications_notice_type tender_publications_award_type
br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************

*Create the correct nuts variables 
*Buyer NUTS
tab  buyer_nuts if filter_ok, m
gen nutscode = buyer_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab buyer_nuts if _m==1
tab buyer_nuts if missing(description)
tab tender_year if missing(description)
tab buyer_nuts if !missing(description)
*All looks good, 35k didn't match - missing nuts codes
*1 fix
replace buyer_nuts="" if buyer_nuts=="NO011"
drop description nutscode _merge

*Bidder NUTS
tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab bidder_nuts if _m==1 //54 bidder nuts didn't match - replace to missing
replace bidder_nuts="" if _m==1
tab bidder_nuts if _m==3
drop description nutscode _merge

*Address of Implementation
tab tender_addressofimplementation_n if filter_ok
gen nutscode = tender_addressofimplementation_n
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab tender_addressofimplementation_n if _m==1  //10 bad codes - replace to missing
replace tender_addressofimplementation_n="" if _m==1


gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]" if !missing(buyer_nuts)
gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]" if !missing(bidder_nuts)
gen  impl_nuts = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]" if !missing(tender_addressofimplementation_n)
gen tender_addressofimplementation_c=substr(tender_addressofimplementation_n,1,2)
rename tender_addressofimplementation_n impl_nuts_original
rename impl_nuts tender_addressofimplementation_n

format  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n %10s
br  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n
************************************

*Buyer main acticities structure
tab buyer_mainactivities if filter_ok, m
replace buyer_mainactivities = "["+ `"""' + buyer_mainactivities + `"""' +"]" if !missing(buyer_mainactivities)
************************************

*Enumeration buyer type
tab buyer_buyertype, m //ok
************************************

*Enumeration supply type
tab tender_supplytype, m //ok
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

*Renaming price variables
rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
************************************
 
*Checking product codes
gen market_id_star=substr(tender_cpvs,1,2)
tab market_id_star if filter_ok, m //good
gen market_id2 = market_id_star if inlist(market_id_star,"03","09","14","15","16","18","19") | inlist(market_id_star,"22","24","30","31","32","33","34","35","37") | inlist(market_id_star,"38","39","41","42","43","44","45","48","50") | inlist(market_id_star,"51","55","60","63","64","65","66","70") | inlist(market_id_star,"71","72","73","75","76","77","79","80") | inlist(market_id_star,"85","90","92","98","99")
gen tender_cpvs_fixed  = tender_cpvs if !missing(market_id2)
drop market_id_star market_id2
replace tender_cpvs_fixed = "99100000" if missing(tender_cpvs_fixed) & tender_supplytype=="SUPPLIES"
replace tender_cpvs_fixed = "99200000" if missing(tender_cpvs_fixed) & tender_supplytype=="SERVICES"
replace tender_cpvs_fixed = "99300000" if missing(tender_cpvs_fixed) & tender_supplytype=="WORKS"
replace tender_cpvs_fixed = "99000000" if missing(tender_cpvs_fixed) & missing(tender_supplytype)
gen market_id2=substr(tender_cpvs_fixed,1,2)
tab market_id2, m
drop market_id2
************************************

rename tender_cpvs tender_cpvs_orig
rename tender_cpvs_fixed tender_cpvs
*Use only the first product code
rename tender_cpvs lot_productCode
replace lot_productCode=subinstr(lot_productCode,",","",.)
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

br tender_recordedbidscount lot_bidscount 
gen bids_count = lot_bidscount
*replace bids_count = tender_recordedbidscount if missing(bids_count)
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

foreach var of varlist bid_iswinning bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

*Checking ids to be used
count if missing(buyer_masterid) & filter_ok //no missings
count if missing(buyer_id) & filter_ok //missing
count if missing(bidder_masterid) & filter_ok //no missing
count if missing(bidder_id) & filter_ok //missing
************************************

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}
************************************

br buyer_masterid buyer_id bidder_masterid bidder_id buyer_name bidder_name if filter_ok
replace filter_ok=0 if bidder_name=="-"
br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
************************************

tab tender_proceduretype, m
tab tender_supplytype, m
************************************

*Dates
*dates are good


*Countries
tab buyer_country, m //ok
tab bidder_country, m //ok
tab tender_addressofimplementation_c, m //ok
********************************************************************************
save $country_folder/RO_wb_2011.dta, replace
********************************************************************************
*Export for Reverse tool
use $country_folder/RO_wb_2011.dta, clear

drop if filter_ok==0
duplicates drop

bys tender_id: gen x=_N

************************************
*Generating LOT NUMBER
format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1


*If x>1 & lot_row_nr is missing and tender_framework is t then consider it one lot
gen lot_number= lot_row_nr
replace lot_number = 1 if tender_isframe=="TRUE" & missing(lot_number) & x>1

*If lot_number is missinf and tender_lotscount==1 then consider it as 1 lot
replace lot_number = 1 if missing(lot_number) & x>1 & tender_lotscount==1

*If x>1 & lot_number is missing and tender_framework is f or missing then consider it several lots (checked a few links and its tru)
bys tender_id: replace lot_number = _n if inlist(tender_isframe,"FALSE","") & missing(lot_number) & x>1

replace lot_number=1 if x==1 & missing(lot_number)
count if missing(lot_number)
drop x

sort tender_id lot_number
br tender_id lot_number tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract 
************************************

*Generating BID NUMBER
bys tender_id lot_number: gen bid_number=_n

sort tender_id lot_number bid_number 
unique tender_id lot_number bid_number 

*FIXING ESTIMATED PRICE VARIABLE TO USE
*MAIN : lot_estimatedprice
br tender_estimatedpriceUsd tender_estimatedprice  lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
replace lot_estimatedpriceUsd=tender_estimatedpriceUsd if lot_number==1 & missing(lot_estimatedpriceUsd)
gen lot_est_pricecurrency=currency

replace buyer_id="" if buyer_id=="Romania"

replace lot_est_pricecurrency="" if missing(lot_estimatedprice) | missing(lot_estimatedpriceUsd)
************************************

*Check if titles/names start with "" or []
foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************
order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type
************************************
 
count if missing(tender_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(buyer_masterid)
count if missing(bidder_masterid)
********************************************************************************

export delimited $country_folder/RO_mod.csv, replace
********************************************************************************
*END