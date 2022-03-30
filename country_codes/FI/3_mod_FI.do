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
use $country_folder/FI_wb_2011.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m
tab corr_nocft, m 
tab taxhav2 , m 
tab corr_decp, m
tab corr_submp , m
tab corr_proc, m
************************************

*For indicators with 1 category
foreach var of varlist singleb corr_nocft taxhav2 corr_submp {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
*gen ind_nocft_val=.

tab ind_singleb_val  singleb, m
tab ind_corr_nocft_val corr_nocft, m
tab ind_corr_submp_val  corr_submp, m
tab ind_taxhav2_val taxhav2, m
************************************

*For indicators with categories
tab corr_decp, m
tab corr_proc, m
foreach var of varlist corr_proc  corr_decp corr_ben  {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_decp_val  corr_decp, m
tab ind_corr_ben_val  corr_ben, m

*Contract Share
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Transparency
br tender_addressofimplementation_n tender_nationalproceduretype tender_publications_firstdcontra
*gen title =title //after creating title variable below
*replace title = tender_title if missing(title)
replace tender_addressofimplementation_n="" if tender_addressofimplementation_n=="00"   
gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =lot_bidscount
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  impl proc aw_date2  bids
************************************

********************************************************************************
*Prep for Reverse tool

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

gen tender_country = "FI"
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
tab buyer_nuts if _m==1 //some bad codes fix them check 
replace buyer_nuts="FI1D" if buyer_nuts=="FI13"
replace buyer_nuts="FI1D1" if buyer_nuts=="FI131"
replace buyer_nuts="FI1D2" if buyer_nuts=="FI132"
replace buyer_nuts="FI1D3" if buyer_nuts=="FI133"
replace buyer_nuts="FI1D4" if buyer_nuts=="FI134"
replace buyer_nuts="FI1C" if buyer_nuts=="FI18"
replace buyer_nuts="FI1B" if buyer_nuts=="FI181"
replace buyer_nuts="FI1B1" if buyer_nuts=="FI182"
replace buyer_nuts="FI1C1" if buyer_nuts=="FI183"
replace buyer_nuts="FI1C2" if buyer_nuts=="FI184"
replace buyer_nuts="FI1C3" if buyer_nuts=="FI185"
replace buyer_nuts="FI1C4" if buyer_nuts=="FI186"
replace buyer_nuts="FI1C5" if buyer_nuts=="FI187"
replace buyer_nuts="FI1D" if buyer_nuts=="FI1A"
replace buyer_nuts="FI1D5" if buyer_nuts=="FI1A1"
replace buyer_nuts="FI1D6" if buyer_nuts=="FI1A2"
replace buyer_nuts="FI1D7" if buyer_nuts=="FI1A3"
*replace buyer_nuts=""
tab buyer_nuts if missing(description)
tab tender_year if missing(description)
tab buyer_nuts if !missing(description)
replace buyer_nuts=""  if _m==1 
drop description nutscode _merge

*Bidder NUTS
tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab bidder_nuts if _m==1 //- Fix FI, replace rest to missing
replace bidder_nuts="FI1D" if bidder_nuts=="FI13"
replace bidder_nuts="FI1D1" if bidder_nuts=="FI131"
replace bidder_nuts="FI1D2" if bidder_nuts=="FI132"
replace bidder_nuts="FI1D3" if bidder_nuts=="FI133"
replace bidder_nuts="FI1D4" if bidder_nuts=="FI134"
replace bidder_nuts="FI1C" if bidder_nuts=="FI18"
replace bidder_nuts="FI1B" if bidder_nuts=="FI181"
replace bidder_nuts="FI1B1" if bidder_nuts=="FI182"
replace bidder_nuts="FI1C1" if bidder_nuts=="FI183"
replace bidder_nuts="FI1C2" if bidder_nuts=="FI184"
replace bidder_nuts="FI1C3" if bidder_nuts=="FI185"
replace bidder_nuts="FI1C4" if bidder_nuts=="FI186"
replace bidder_nuts="FI1C5" if bidder_nuts=="FI187"
replace bidder_nuts="FI1D" if bidder_nuts=="FI1A"
replace bidder_nuts="FI1D5" if bidder_nuts=="FI1A1"
replace bidder_nuts="FI1D6" if bidder_nuts=="FI1A2"
replace bidder_nuts="FI1D7" if bidder_nuts=="FI1A3"
replace bidder_nuts="" if _m==1
tab bidder_nuts if _m==3
drop description nutscode _merge

*Address of Implementation
tab tender_addressofimplementation_n if filter_ok
gen nutscode = tender_addressofimplementation_n
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab tender_addressofimplementation_n if _m==1  // Fix FI, replace rest to missing
replace tender_addressofimplementation_n="FI1D" if tender_addressofimplementation_n=="FI13"
replace tender_addressofimplementation_n="FI1D1" if tender_addressofimplementation_n=="FI131"
replace tender_addressofimplementation_n="FI1D2" if tender_addressofimplementation_n=="FI132"
replace tender_addressofimplementation_n="FI1D3" if tender_addressofimplementation_n=="FI133"
replace tender_addressofimplementation_n="FI1D4" if tender_addressofimplementation_n=="FI134"
replace tender_addressofimplementation_n="FI1C" if tender_addressofimplementation_n=="FI18"
replace tender_addressofimplementation_n="FI1B" if tender_addressofimplementation_n=="FI181"
replace tender_addressofimplementation_n="FI1B1" if tender_addressofimplementation_n=="FI182"
replace tender_addressofimplementation_n="FI1C1" if tender_addressofimplementation_n=="FI183"
replace tender_addressofimplementation_n="FI1C2" if tender_addressofimplementation_n=="FI184"
replace tender_addressofimplementation_n="FI1C3" if tender_addressofimplementation_n=="FI185"
replace tender_addressofimplementation_n="FI1C4" if tender_addressofimplementation_n=="FI186"
replace tender_addressofimplementation_n="FI1C5" if tender_addressofimplementation_n=="FI187"
replace tender_addressofimplementation_n="FI1D" if tender_addressofimplementation_n=="FI1A"
replace tender_addressofimplementation_n="FI1D5" if tender_addressofimplementation_n=="FI1A1"
replace tender_addressofimplementation_n="FI1D6" if tender_addressofimplementation_n=="FI1A2"
replace tender_addressofimplementation_n="FI1D7" if tender_addressofimplementation_n=="FI1A3"
replace tender_addressofimplementation_n="FI196" if tender_addressofimplementation_n=="FI191"
replace tender_addressofimplementation_n="FI197" if tender_addressofimplementation_n=="FI192"

replace tender_addressofimplementation_n="" if _m==1
drop description nutscode _merge


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

*Enumeratiion procedure type
tab tender_proceduretype, m //ok
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
drop market_id_star
split tender_cpvs, p(",")
drop tender_cpvs2-tender_cpvs36
rename tender_cpvs1 lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

br tender_recordedbidscount lot_bidscount 
gen bids_count = lot_bidscount
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

foreach var of varlist  bidder_hasSanction bidder_previousSanction {
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
br buyer_masterid buyer_id bidder_masterid bidder_id buyer_name bidder_name if filter_ok
************************************

*Cleaning bidder name
br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(bidder_name)
tab len if filter_ok,m
br bidder_name if len<=3 & !missing(bidder_name)
replace filter_ok=0 if bidder_name=="-"
replace filter_ok=0 if bidder_name=="."
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(bidder_name,"x","xx","xxx")
replace bidder_name=ustrupper(bidder_name)
drop len
************************************

*Cleaning buyername name
br buyer_name if regex(buyer_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(buyer_name)
tab len if filter_ok,m
br buyer_name if len<1 & !missing(buyer_name)
replace filter_ok=0 if buyer_name=="-"
replace filter_ok=0 if buyer_name=="."
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(buyer_name,"x","xx","xxx")
replace buyer_name=ustrupper(buyer_name)
drop len
************************************

*Dates
*dates are good
/*
foreach var of varlist tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_publications_firstcallfor tender_publications_firstdcontra sanct_startdate sanct_enddate 
 {
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
*/
************************************

*Countries
tab buyer_country, m //ok
tab bidder_country, m //ok
tab tender_addressofimplementation_c, m //ok
************************************

save $country_folder/FI_wb_2011.dta, replace
********************************************************************************
*Export for Reverse tool
use $country_folder/FI_wb_2011.dta, clear

drop if filter_ok==0
ds bidder_masterid, not
duplicates drop `r(varlist)', force

bys tender_id: gen x=_N

************************************
*Generating LOT NUMBER
format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1

br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1 & missing(lot_row_nr)

*If x>1 & lot_row_nr is missing and tender_framework is t then consider it one lot
gen lot_number= lot_row_nr
replace lot_number = 1 if tender_isframe=="t" & missing(lot_number) & x>1

*If lot_number is missing and tender_lotscount==1 then consider it as 1 lot
replace lot_number = 1 if missing(lot_number) & x>1 & tender_lotscount==1

*If x>1 & lot_number is missing and tender_framework is f or missing then consider it several lots 
bys tender_id: replace lot_number = _n if inlist(tender_isframe,"f","") & missing(lot_number) & x>1

replace lot_number=1 if x==1 & missing(lot_number)
count if missing(lot_number)
drop x

sort tender_id lot_number
br tender_id lot_number tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract 

br if tender_id=="004ba938-1f55-4bf7-bf79-15b810478f54"
************************************

*Generating BID NUMBER
bys tender_id lot_number: gen bid_number=_n

sort tender_id lot_number bid_number 
unique tender_id lot_number bid_number 
************************************

*FIXING ESTIMATED PRICE VARIABLE TO USE
*MAIN : lot_estimatedprice
br tender_estimatedpriceUsd tender_estimatedprice  lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
replace lot_estimatedpriceUsd=tender_estimatedpriceUsd if lot_number==1 & missing(lot_estimatedpriceUsd)
gen lot_est_pricecurrency=currency

replace lot_est_pricecurrency="" if missing(lot_estimatedprice) | missing(lot_estimatedpriceUsd)
************************************

*Check if titles/names start with "" or []
foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

tostring tender_contractsignaturedate, replace 
replace tender_contractsignaturedate="" if tender_contractsignaturedate=="."
************************************

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_corr_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

order tender_id lot_number bid_number tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_corr_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************
 
count if missing(tender_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(buyer_masterid)
count if missing(buyer_name)
count if missing(bidder_name)
count if missing(bidder_masterid)
count if missing(lot_productCode)
************************************

replace title = ustrfix(title)
replace buyer_name = ustrfix(buyer_name)
replace bidder_name = ustrfix(bidder_name)
br title buyer_name bidder_name
************************************

export delimited $coutnry_folder/FI_mod.csv, replace
unicode convertfile $coutnry_folder/FI_mod.csv $coutnry_folder/FI_mod_fix.csv, dstencoding(utf-8) replace
********************************************************************************
*END


