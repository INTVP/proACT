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
use $country_folder/SI_wb_2011.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m
tab nocft2 , m
tab corr_submp, m
tab taxhav2, m
************************************

*For indicators with 1 category
foreach var of varlist singleb nocft2 corr_submp taxhav2 {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
************************************

*For indicators with categories
tab corr_decp, m
tab corr_proc, m
tab corr_ben, m
foreach var of varlist corr_proc corr_decp  corr_ben {
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
*Creating Title
cap drop title
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

gen proc = tender_nationalproceduretype
gen aw_date2 = tender_publications_firstdcontra
gen bids =lot_bidscount
foreach var of varlist  title  tender_supplytype bid_price  proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop  proc aw_date2  bids


gen impl= tender_addressofimplementation_n
foreach var of varlist impl buyer_name bidder_name{
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop impl
************************************

save $country_folder/SI_wb_2011.dta, replace
********************************************************************************
*Prep for Reverse tool
use $country_folder/SI_wb_2011.dta, clear

gen tender_country = "SI"
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
tab buyer_nuts if _m==1 //
replace buyer_nuts="SI031" if buyer_nuts=="SI011"
replace buyer_nuts="SI032" if buyer_nuts=="SI012"
replace buyer_nuts="SI033" if buyer_nuts=="SI013"
replace buyer_nuts="SI034" if buyer_nuts=="SI014"
replace buyer_nuts="SI035" if buyer_nuts=="SI015"
replace buyer_nuts="SI036" if buyer_nuts=="SI016"
replace buyer_nuts="SI037" if buyer_nuts=="SI017"
replace buyer_nuts="SI038" if buyer_nuts=="SI018"
replace buyer_nuts="SI041" if buyer_nuts=="SI021"
replace buyer_nuts="SI042" if buyer_nuts=="SI022"
replace buyer_nuts="SI043" if buyer_nuts=="SI023"
replace buyer_nuts="SI044" if buyer_nuts=="SI024"
drop description nutscode _merge

*Bidder NUTS
tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab bidder_nuts if _m==1 //
replace bidder_nuts="SI031" if bidder_nuts=="SI011"
replace bidder_nuts="SI032" if bidder_nuts=="SI012"
replace bidder_nuts="SI033" if bidder_nuts=="SI013"
replace bidder_nuts="SI034" if bidder_nuts=="SI014"
replace bidder_nuts="SI035" if bidder_nuts=="SI015"
replace bidder_nuts="SI036" if bidder_nuts=="SI016"
replace bidder_nuts="SI037" if bidder_nuts=="SI017"
replace bidder_nuts="SI038" if bidder_nuts=="SI018"
replace bidder_nuts="SI041" if bidder_nuts=="SI021"
replace bidder_nuts="SI042" if bidder_nuts=="SI022"
replace bidder_nuts="SI043" if bidder_nuts=="SI023"
replace bidder_nuts="SI044" if bidder_nuts=="SI024"

replace bidder_nuts="" if  _m==1
tab bidder_nuts if _m==3
drop description nutscode _merge

*Address of Implementation
rename tender_addressofimplementation_n impl_nuts_orig
replace impl_nuts_orig="" if impl_nuts_orig=="00"
split impl_nuts_orig, p(",")
gen len1=length(impl_nuts_orig1)
gen len2=length(impl_nuts_orig2)
drop impl_nuts_orig3-impl_nuts_orig9
gen impt_nuts_holder=impl_nuts_orig1
replace impt_nuts_holder= impl_nuts_orig2 if len2>len1 & len2!=. & len1!=.
drop  len1 len2
replace impt_nuts_holder="" if impt_nuts_holder=="00"
*Main impl nuts variable //impt_nuts_holder

tab impt_nuts_holder if filter_ok
gen nutscode = impt_nuts_holder
merge m:1 nutscode using $utility_data/nuts_map.dta
drop if _m==2
tab impt_nuts_holder if _m==1  // ok
replace impt_nuts_holder="SI031" if impt_nuts_holder=="SI011"
replace impt_nuts_holder="SI032" if impt_nuts_holder=="SI012"
replace impt_nuts_holder="SI033" if impt_nuts_holder=="SI013"
replace impt_nuts_holder="SI034" if impt_nuts_holder=="SI014"
replace impt_nuts_holder="SI035" if impt_nuts_holder=="SI015"
replace impt_nuts_holder="SI036" if impt_nuts_holder=="SI016"
replace impt_nuts_holder="SI037" if impt_nuts_holder=="SI017"
replace impt_nuts_holder="SI038" if impt_nuts_holder=="SI018"
replace impt_nuts_holder="SI041" if impt_nuts_holder=="SI021"
replace impt_nuts_holder="SI042" if impt_nuts_holder=="SI022"
replace impt_nuts_holder="SI043" if impt_nuts_holder=="SI023"
replace impt_nuts_holder="SI044" if impt_nuts_holder=="SI024"

replace impt_nuts_holder="" if  _m==1
drop description nutscode _merge

gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]" if !missing(buyer_nuts)
gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]" if !missing(bidder_nuts)
gen  impl_nuts = "["+ `"""' + impt_nuts_holder + `"""' +"]" if !missing(impt_nuts_holder)
rename impl_nuts tender_addressofimplementation_n
gen tender_addressofimplementation_c=substr(impt_nuts_holder,1,2)

format  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n %10s
br  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n

*check bad endoding of the transparency indicator after changes
count if ind_tr_impl_val==0 & !missing(tender_addressofimplementation_n)
count if ind_tr_impl_val==100 & missing(tender_addressofimplementation_n)
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
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
gen bid_pricecurrency  = currency
************************************
 
*Checking product codes
gen market_id_star=substr(tender_cpvs,1,2)
tab market_id_star if filter_ok, m //good
drop market_id_star
split tender_cpvs, p(",")
drop tender_cpvs2-tender_cpvs104
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
count if missing(buyer_masterid) & filter_ok //7 missing
replace filter_ok=0 if missing(buyer_masterid)

count if missing(buyer_id) & filter_ok //missing
count if missing(bidder_masterid) & filter_ok //no missing
count if missing(bidder_id) & filter_ok //missing
************************************

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
replace `var' = "" if `var'=="N/A"
}
br buyer_masterid buyer_id bidder_masterid bidder_id buyer_name bidder_name if filter_ok

*Cleaning bidder name
br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(bidder_name)
tab len if filter_ok,m
br bidder_name len if len<=3 & !missing(bidder_name) 
replace filter_ok=0 if bidder_name=="-"
replace filter_ok=0 if bidder_name=="."
replace filter_ok=0 if bidder_name=="/,"
replace filter_ok=0 if bidder_name==".,"
replace bidder_name=subinstr(bidder_name,","," ",.)
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(bidder_name,"x","xx","xxx","a","A","//","X","XX")
replace filter_ok=0 if inlist(bidder_name,"/.","-,","/",",","-")
replace bidder_name=ustrupper(bidder_name)
replace bidder_name=subinstr(bidder_name,"  "," ",.)
replace bidder_name=ustrtrim(bidder_name)
drop len
*Cleaning buyername name
br buyer_name if regex(buyer_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(buyer_name)
tab len if filter_ok,m
br buyer_name if len<=3 & !missing(buyer_name)
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

*Countries
tab buyer_country, m //ok
replace buyer_country="SI" if buyer_country=="Slovenija"
tab bidder_country, m //no
tab iso_bidder, m //ok
tab tender_addressofimplementation_c, m //ok
************************************

save $country_folder/SI_wb_2011.dta, replace
********************************************************************************
*Export for Reverse tool
use $country_folder/SI_wb_2011.dta, clear

drop if filter_ok==0
duplicates drop

/*
ds bidder_masterid buyer_masterid, not
duplicates drop `r(varlist)', force
*/

bys tender_id: gen x=_N

************************************
*Generating LOT NUMBER
format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
br x tender_id lot_row_nr tender_lotscount lot_row_nr tender_isframe bid_iscons tender_title lot_title bidder_name bid_price bid_digiwhist_price  *cons* tender_publications_lastcontract if x>1


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
br tender_id lot_number tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price bid_digiwhist_price *cons* tender_publications_lastcontract 

************************************
*Generating BID NUMBER
bys tender_id lot_number: gen bid_number=_n

sort tender_id lot_number bid_number 
unique tender_id lot_number bid_number 
************************************

*FIXING ESTIMATED PRICE VARIABLE TO USE
*MAIN : lot_estimatedprice
br    lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency 
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
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

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id iso_bidder bidder_geocodes bidder_name bid_priceUsd bid_digiwhist_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_postcode buyer_country buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id iso_bidder bidder_geocodes bidder_name bid_priceUsd bid_digiwhist_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
 
count if missing(tender_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(buyer_masterid)
count if missing(buyer_name)
count if missing(bidder_name)
count if missing(bidder_masterid)
count if missing(lot_productCode)
********************************************************************************

export delimited $country_folder/SI_mod.csv, replace
********************************************************************************
*END