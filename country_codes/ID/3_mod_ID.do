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
-Adds Sanction data
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/ID_wb_2012.dta, clear
********************************************************************************

*Calcluating indicators
tab singleb , m
tab nocft2 , m
tab corr_proc, m

*For indicators with 1 category
foreach var of varlist singleb nocft2 corr_proc {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_taxhav2_val=.
************************************

*For indicators with categories
tab corr_decp, m
tab corr_submp, m
tab corr_ben, m

foreach var of varlist corr_decp  corr_ben corr_submp {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

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
replace ten_title_str = proper(ten_title_str)
replace ten_title_str = ustrupper(ten_title_str)
************************************

decode ca_procedure_nat, gen(ca_procedure_nat2)
replace ca_procedure_nat2="" if ca_procedure_nat2=="."
drop ca_procedure_nat 
rename ca_procedure_nat2 ca_procedure_nat
************************************

gen impl=""
gen proc = ca_procedure_nat
gen aw_date2 = aw_dec_date
gen bids =ca_nrbid
gen title = ten_title_str
gen bid_price=ca_contract_value
foreach var of varlist impl buyer_name w_name title  tender_supplytype bid_price proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
cap drop impl  proc aw_date2  bids bid_price title


cap drop ind_tr_buyer_name_val ind_tr_w_name_val
foreach var of varlist buyer_name bidder_name{
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
********************************************************************************
save $country_folder/ID_wb_2012.dta, replace
********************************************************************************

*Prep for Reverse tool
use $country_folder/ID_wb_2012.dta, clear

gen tender_country = "ID"
************************************

foreach var of varlist cft_url ca_url {
decode `var', gen(`var'2)
replace `var'2="" if `var'2=="."
drop `var' 
rename `var'2 `var'
}
************************************

*Create notice type for tool
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_url) | !missing(cft_date_first)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(ca_url) | !missing(aw_dec_date)
************************************

*Create the correct nuts variables 
*Buyer NUTS
rename buyer_geocodes buyer_geocodes_orig
gen  buyer_geocodes = "["+ `"""' + buyer_geocodes_orig + `"""' +"]" if !missing(buyer_geocodes_orig)
************************************

*Enumeration buyer type
tab buyer_buyertype, m //ok
************************************

*Enumeration supply type
tab tender_supplytype, m //ok
************************************

*Enumeratiion procedure type
decode ca_procedure, gen(tender_proceduretype)
replace tender_proceduretype="" if tender_proceduretype=="."
tab tender_proceduretype, m //ok
************************************

*Renaming price variables
rename bid_price_ppp bid_priceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
gen bid_pricecurrency  = ca_currency
************************************
 
*Checking product codes
gen market_id_star=substr(tender_cpvs,1,2)
tab market_id_star if filter_ok, m //good
drop market_id_star
rename tender_cpvs lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
br lot_productCode lot_localProductCode lot_localProductCode_type
************************************

*Bid count
gen bids_count = ca_nrbid
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

br buyer_name  anb_id anb_id_addid
replace filter_ok=0 if missing(buyer_name) 
count if missing(anb_id_addid) & filter_ok // 0missing
count if missing(anb_id) & filter_ok //0missing
count if missing(buyer_name) & filter_ok //0missing
rename anb_id_addid buyer_masterid
rename anb_id buyer_id

foreach var of varlist w_id_addid w_id_old {
decode `var', gen(`var'2)
replace `var'2="" if `var'2=="."
drop `var' 
rename `var'2 `var'
}
decode bidder_name_orig, gen(bidder_name)
replace bidder_name="" if bidder_name=="."

br w_id_addid w_id_old w_id w_name
rename w_id_addid bidder_masterid
rename w_id_old bidder_id
count if missing(bidder_masterid) & filter_ok //no missing
count if missing(bidder_id) & filter_ok //missing
count if missing(bidder_name) & filter_ok //missing
************************************

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
replace `var' = "" if `var'=="N/A"
}
br buyer_masterid buyer_id bidder_masterid bidder_id buyer_name bidder_name if filter_ok
************************************

*Cleaning bidder name
br bidder_name if regex(bidder_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(bidder_name)
tab len if filter_ok,m
br bidder_name len if len<=3 & !missing(bidder_name) 
replace filter_ok=0 if bidder_name=="-"
replace filter_ok=0 if bidder_name=="."
replace filter_ok=0 if bidder_name=="/,"
replace filter_ok=0 if bidder_name==".,"
*replace bidder_name=subinstr(bidder_name,","," ",.)
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(bidder_name,"1","0","A_J","A")
replace filter_ok=0 if inlist(bidder_name,"x","xx","xxx","a","A","//","X","XX")
replace filter_ok=0 if inlist(bidder_name,"/.","-,","/",",","-")
replace bidder_name=ustrupper(bidder_name)
replace bidder_name=subinstr(bidder_name,"  "," ",.)
replace bidder_name=ustrtrim(bidder_name)
drop len
************************************

*Cleaning buyername name
br buyer_name if regex(buyer_name,"[|,|!|@|#|$|%|^|&|*|(|)|]") //ok
gen len=length(buyer_name)
tab len if filter_ok,m
br buyer_name if len<=3 & !missing(buyer_name)
replace filter_ok=0 if len==1
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
foreach var of varlist ca_signdate cft_date_first cft_date_last cft_deadline  aw_dec_date {
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
br ca_signdate cft_date_first cft_date_last cft_deadline  aw_dec_date 
************************************

*Sanctions - added later 

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""

/*
*Sanctions

merge m:1 w_name using $utility_data/country/ID/ID_sanctions.dta 
drop if _m==2
drop _m
br w_name sanct_startDate1 sanct_startDate2 sanct_endDate1 sanct_endDate2 sanct_name1 sanct_name2 if !missing(sanct_startDate1)
*Manage dates
forval x =1/2 {
gen sanct_startDate`x'_f = date(sanct_startDate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_endDate`x',"YMD")
drop sanct_startDate`x' sanct_endDate`x'
rename sanct_startDate`x'_f sanct_startDate`x'
rename sanct_endDate`x'_f sanct_endDate`x'
format sanct_endDate`x' sanct_startDate`x' %d
}

cap drop bidder_hasSanction
gen bidder_hasSanction= "false"
replace bidder_hasSanction="true" if !missing(sanct_startDate1)
tab bidder_hasSanction if filter_ok, m

gen date_award = date(aw_dec_date, "YMD")
*gen date_sign = date(ca_signdate, "YMD")
cap drop bidder_previousSanction
gen bidder_previousSanction="false"
replace bidder_previousSanction="true" if date_award>=sanct_endDate1 & !missing(sanct_endDate1)
tab bidder_previousSanction if filter_ok, m
drop date_award

*Dates we only keep the latest start and end date
cap drop sanct_startdate
gen sanct_startdate = .
replace sanct_startdate = sanct_startDate1 if !missing(sanct_startDate1)
replace sanct_startdate = sanct_startDate2 if !missing(sanct_startDate2)
format sanct_startdate %d
br sanct_startdate sanct_startDate* if !missing(sanct_startDate2)

cap drop sanct_enddate
gen sanct_enddate = .
replace sanct_enddate = sanct_endDate1 if !missing(sanct_endDate1)
replace sanct_enddate = sanct_endDate2 if !missing(sanct_endDate2)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate1)

br sanct_startdate sanct_enddate sanct_startDate1 sanct_endDate1 sanct_startDate2 sanct_endDate2 if !missing(sanct_endDate2)

foreach var of varlist sanct_startdate sanct_enddate {
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

cap drop sanct_name
gen sanct_name = ""
replace sanct_name=sanct_name1 if !missing(sanct_startDate1)
replace sanct_name=sanct_name1 + ", " + sanct_name2 if !missing(sanct_startDate2)
replace sanct_name=subinstr(sanct_name,", ","",.) if regex(sanct_name,", $")

br sanct_startdate sanct_enddate sanct_startDate1 sanct_endDate1 sanct_startDate2 sanct_endDate2 sanct_name sanct_name1 sanct_name2 if !missing(sanct_endDate2)
*Good
drop sanct_name1-sanct_endDate2
*/
************************************

*Countries
tab tender_country, m
gen buyer_country = "ID" if !missing(buyer_geocodes)
tab buyer_country, m //ok
************************************

*Generating the source variable from cft_url and ca_url

split cft_url, p("id/")
br  cft_url1 cft_url2 if !missing(cft_url2)
replace cft_url1= cft_url1+"id" if !missing(cft_url2)

split cft_url1, p(".net")
br  cft_url11 cft_url12 if !missing(cft_url12)
replace cft_url11= cft_url11+".net" if !missing(cft_url12)
br  cft_url11 cft_url12 if missing(cft_url12) & missing(cft_url2)

split cft_url11, p(".org")
br  cft_url111 cft_url112 if !missing(cft_url112)
replace cft_url111= cft_url111+".org" if !missing(cft_url112)
gen x=1 if missing(cft_url12) & missing(cft_url2) & missing(cft_url112)
replace cft_url111 ="" if missing(cft_url12) & missing(cft_url2) & missing(cft_url112)

split ca_url if x==1, p("id/") 
br  ca_url1 ca_url2 if !missing(ca_url2)
replace ca_url1= ca_url1+"id" if !missing(ca_url2)

split ca_url1 if x==1, p(".org")
br  ca_url11 ca_url12 if !missing(ca_url12)
replace ca_url11= ca_url11+".net" if !missing(ca_url12)
br  ca_url11 ca_url12 if missing(ca_url12) & missing(ca_url2)

replace ca_url11 ="" if missing(ca_url12) & missing(ca_url2)

gen source = cft_url111
replace source = ca_url11 if missing(ca_url11) & !missing(ca_url11)
drop cft_url1-ca_url12

split ca_url , p("id/") 
br  ca_url1 ca_url2 if !missing(ca_url2)
replace ca_url1= ca_url1+"id" if !missing(ca_url2)

split ca_url1 , p(".org")
br  ca_url11 ca_url12 if !missing(ca_url12)
replace ca_url11= ca_url11+".net" if !missing(ca_url12)
br  ca_url11 ca_url12 if missing(ca_url12) & missing(ca_url2)

replace ca_url11 ="" if missing(ca_url12) & missing(ca_url2)

replace source = ca_url11 if missing(source) & !missing(ca_url11)

format cft_url ca_url  %30s
br source cft_url ca_url  if missing(source)
drop ca_url1-ca_url12
************************************

replace bid_pricecurrency ="" if missing(ca_contract_value)
************************************

bys ten_id: gen x=_N
br ten_id bidder_name ca_contract_value ca_currency ca_tender_est_value lot_estimatedpriceUsd  if x>1
gen lot_est_pricecurrency=ca_currency
replace lot_est_pricecurrency="" if missing(ca_tender_est_value)
************************************

*Bid is winning
gen bid_iswinning2="true" if bid_iswinning==1
tab bid_iswinning2 bid_iswinning, m
drop bid_iswinning
rename bid_iswinning2 bid_iswinning 
********************************************************************************

save $country_folder/ID_wb_2012.dta, replace
********************************************************************************

use $country_folder/ID_wb_2012.dta, clear

keep ten_id bid_iswinning tender_country aw_dec_date ca_signdate  cft_deadline tender_proceduretype tender_supplytype tender_publications_notice_type cft_date_first cft_url source tender_publications_award_type ca_url buyer_masterid buyer_id buyer_loc_2 buyer_postal_code buyer_country buyer_geocodes buyer_name  buyer_buyertype bidder_masterid bidder_id   bidder_name bid_priceUsd ca_contract_value bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode ten_title_str bids_count lot_estimatedpriceUsd ca_tender_est_value lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ppp_id ca_currency


append using $utility_data/country/ID/indonesia_raw200316_losing_bids.dta, gen(appended)
********************************************************************************

gen lot_number=1 
************************************

*Generating bid_number

sort ten_id lot_number, gen(id)
bys id: gen bid_number = _n 
drop id

*Dropping tenders with only losing bidders
bys ten_id: egen alpha = nvals(bid_iswinning)
drop if alpha==1 & bid_iswinning=="false"
drop alpha

foreach var of varlist ppp_id ca_currency tender_country  {

bys ten_id lot_number : replace `var'=`var'[1] if missing(`var')

}
************************************

*New bid_price and lot_estimated price
cap drop bid_priceUsd  bid_pricecurrency 
gen bid_priceUsd = ca_contract_value/ppp_id if ca_currency=="IDR"
gen bid_pricecurrency=ca_currency
replace bid_pricecurrency="" if missing(ca_contract_value)

drop ppp_id ca_currency appended
************************************

replace lot_productCode = subinstr(lot_productCode,"\.0","",.)
replace lot_localProductCode = subinstr(lot_localProductCode,"\.0","",.)

keep ten_id lot_number bid_number bid_iswinning tender_country aw_dec_date ca_signdate  cft_deadline tender_proceduretype tender_supplytype tender_publications_notice_type cft_date_first cft_url source tender_publications_award_type ca_url buyer_masterid buyer_id buyer_loc_2 buyer_postal_code buyer_country buyer_geocodes buyer_name  buyer_buyertype bidder_masterid bidder_id   bidder_name bid_priceUsd ca_contract_value bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode ten_title_str bids_count lot_estimatedpriceUsd ca_tender_est_value lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 

order ten_id lot_number bid_number bid_iswinning tender_country aw_dec_date ca_signdate  cft_deadline tender_proceduretype tender_supplytype tender_publications_notice_type cft_date_first cft_url source tender_publications_award_type ca_url buyer_masterid buyer_id buyer_loc_2 buyer_postal_code buyer_country buyer_geocodes buyer_name  buyer_buyertype bidder_masterid bidder_id   bidder_name bid_priceUsd ca_contract_value bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode ten_title_str bids_count lot_estimatedpriceUsd ca_tender_est_value lot_est_pricecurrency ind_nocft2_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

*export delimited $country_folder/ID_wb_2012_v2.csv, replace
export delimited $country_folder/ID_mod.csv, replace
********************************************************************************
*END