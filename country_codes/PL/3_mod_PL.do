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
use $country_folder/PL_wip.dta, clear
********************************************************************************

*Calcluating indicators

*For indicators with 1 category
foreach var of varlist singleb  corr_submp  taxhav2 {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}

gen ind_nocft_val=. 
************************************

*For indicators with categories
foreach var of varlist corr_proc corr_decp  corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
************************************

*Contract Share
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency
*Creating Title
cap drop title
replace lot_title="" if lot_title=="null"
replace tender_title="" if tender_title=="null"
replace tender_title=lower(tender_title)
replace lot_title=lower(lot_title)
gen same=(tender_title==lot_title)
replace same=0 if missing(tender_title)
br tender_title lot_title 
br tender_title lot_title if same==1
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
replace title= tender_title if same==1 & !missing(tender_title)
br tender_title lot_title title state 
drop miss_tentitle miss_lottitle state same
replace title = subinstr(title,`"""',"",.)
replace title =  subinstr(title,"„","",.)
replace title = proper(title)

br tender_addressofimplementation_n tender_nationalproceduretype tender_publications_firstdcontra

*gen impl= tender_addressofimplementation_n
gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =lot_bidscount
foreach var of varlist  title  tender_supplytype bid_price proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  proc aw_date2  bids

*Use the final versions of buyer name and bidder_name
gen impl= tender_addressofimplementation_n 
foreach var of varlist impl buyer_name bidder_name{
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop impl
********************************************************************************

*Prep for Reverse tool
use $country_folder/PL_wip.dta, clear

gen tender_country = "PL"
************************************

*Create notice type for tool
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************

*Create the correct nuts variables 
*Buyer NUTS
tab  buyer_nuts if filter_ok, m
gen nutscode = buyer_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab buyer_nuts if _m==1 //
replace buyer_nuts="" if  _m==1
drop description nutscode _merge

*Bidder NUTS
*tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab bidder_nuts if _m==1 //
replace bidder_nuts="" if  _m==1
drop description nutscode _merge

*Address of Implementation
gen nutscode = tender_addressofimplementation_n
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab tender_addressofimplementation_n if _m==1  // ok
replace tender_addressofimplementation_n="" if  _m==1
drop description nutscode _merge

gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]" if !missing(buyer_nuts)
gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]" if !missing(bidder_nuts)
gen  impl_nuts = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]" if !missing(tender_addressofimplementation_n)
gen tender_addressofimplementation_c=substr(tender_addressofimplementation_n,1,2)
rename tender_addressofimplementation_n impl_nuts_original
rename impl_nuts tender_addressofimplementation_n

*format  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n %10s
*br  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n
************************************

*Buyer main acticities structure
*tab buyer_mainactivities if filter_ok, m
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
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
gen bid_pricecurrency  = currency
************************************ 
 
*Checking product codes
gen market_id_star=substr(tender_cpvs,1,2)
tab market_id_star if filter_ok, m //good
drop market_id_star
gen lot_productCode=""
replace lot_productCode = regexs(0) if regexm(tender_cpvs, "^([0-9]+[-]*[0-9]*,)")
replace lot_productCode=subinstr(lot_productCode,",","",.)
rename lot_productCode lot_localProductCode
gen lot_productCode = lot_localProductCode
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

*Checking ids to be used
count if missing(buyer_masterid) & filter_ok //7 missing
count if missing(bidder_masterid) & filter_ok //no missing

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
replace `var' = "" if `var'=="N/A"
}
************************************

*Cleaning bidder name
*br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(bidder_name)
*tab len if filter_ok,m
*br bidder_name len if len<=3 & !missing(bidder_name) 
replace filter_ok=0 if bidder_name=="-"
replace filter_ok=0 if bidder_name=="."
replace filter_ok=0 if bidder_name=="/,"
replace filter_ok=0 if bidder_name==".,"
*replace bidder_name=subinstr(bidder_name,","," ",.)
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(bidder_name,"x","xx","xxx","a","A","//","X","XX")
replace filter_ok=0 if inlist(bidder_name,"/.","-,","/",",","-")
replace bidder_name=ustrupper(bidder_name)
replace bidder_name=subinstr(bidder_name,"  "," ",.)
replace bidder_name=ustrtrim(bidder_name)
drop len
*Cleaning buyername name
*br buyer_name if regex(buyer_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(buyer_name)
*tab len if filter_ok,m
*br buyer_name if len<=3 & !missing(buyer_name)
replace filter_ok=0 if buyer_name=="-"
replace filter_ok=0 if buyer_name=="."
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(buyer_name,"x","xx","xxx")
replace buyer_name=ustrupper(buyer_name)
replace buyer_name=subinstr(buyer_name,"  "," ",.)
replace buyer_name=ustrtrim(buyer_name)
drop len
************************************

*Dates
*dates are good
************************************

*Countries
tab buyer_country, m //ok
replace buyer_country="AZ" if buyer_country=="Azerbejdżan"
replace buyer_country="BE" if buyer_country=="Belgia"
replace buyer_country="HR" if buyer_country=="Chorwacja"
replace buyer_country="RU" if buyer_country=="FederacjaRosyjska"
replace buyer_country="DE" if buyer_country=="Niemcy"
replace buyer_country="PL" if buyer_country=="Polska"
replace buyer_country="RU" if buyer_country=="Rosja"
replace buyer_country="HU" if buyer_country=="Wegry"
replace buyer_country="UK" if buyer_country=="WielkaBrytnia"
************************************
 

*tab bidder_country, m //ok
replace bidder_country="" if bidder_country=="Polska"
replace bidder_country="" if bidder_country=="1A"

*tab tender_addressofimplementation_c, m //ok

save $country_folder/PL_wb_201215.dta, replace
********************************************************************************
*Export for Reverse tool
use $country_folder/PL_wb_201215.dta, clear

drop if filter_ok==0
duplicates drop

bys tender_id: gen x=_N

************************************
*Generating LOT NUMBER
*format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
*br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price bid_digiwhist_price  *cons* tender_publications_lastcontract if x>1
*br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1 & missing(lot_row_nr)

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

*sort tender_id lot_number
*br tender_id lot_number tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price bid_digiwhist_price *cons* tender_publications_lastcontract 

************************************
*Generating BID NUMBER
bys tender_id lot_number: gen bid_number=_n

*sort tender_id lot_number bid_number 
*unique tender_id lot_number bid_number 
************************************

*FIXING ESTIMATED PRICE VARIABLE TO USE
*MAIN : lot_estimatedprice
*br    lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency 
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
drop lot_estimatedpriceUsd
gen lot_estimatedpriceUsd = .
replace lot_estimatedpriceUsd=lot_estimatedprice/ppp_eur  if currency=="EUR"
replace lot_estimatedpriceUsd=lot_estimatedprice/ppp_pln  if currency=="PLN"

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

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************
order tender_id lot_number bid_number tender_country tender_awarddecisiondate  tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
 
count if missing(tender_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(buyer_masterid)
count if missing(buyer_name)
count if missing(bidder_name)
count if missing(bidder_masterid)
count if missing(lot_productCode)
********************************************************************************

export delimited $country_folder/PL_mod.csv, replace
********************************************************************************
*END
