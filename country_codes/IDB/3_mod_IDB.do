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
use $country_folder/IDB_wb_1020.dta, clear
********************************************************************************

*Bidder Geocodes

gen x = w_iso2 
tab w_country if missing(w_iso2)
replace x="MK" if w_country=="YUGOSLAVIA"
gen bidder_geocodes= x  if !missing(x)
tab bidder_geocodes, m
replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"
replace bidder_geocodes = "" if bidder_geocodes==`"[""]"'
tab bidder_geocodes, m
************************************

*Implemenation location
desc pr_country pr_iso3
gen impl_geocodes = substr(pr_iso3,1,2)

tab impl_geocodes, m
replace impl_geocodes = "["+ `"""' + impl_geocodes + `"""' +"]"
replace impl_geocodes = "" if impl_geocodes==`"[""]"'
tab impl_geocodes, m
gen tender_addressofimplementation_c = substr(pr_iso3,1,2)
gen  tender_addressofimplementation_n = impl_geocodes

********************************************************************************
save  $country_folder/IDB_wb_1020.dta, replace
********************************************************************************

*Sanctions
*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
/*

************************************
*Checking idb_sanctions.dta
use $utility_data/country/IDB/idb_sanctions.dta, clear
rename bidder_name w_name
drop  n_row1-n_row3 sanct_contactPoint1-sanct_country3 sanct_legalGround1-sanct_bodyIds3
save $utility_data/country/IDB/idb_sactions.dta, replace
************************************

use $country_folder/IDB_wb_1020, clear
merge m:1 w_name using $utility_data/country/idb_sactions.dta

gen bidder_hasSanction=0
replace bidder_hasSanction=1 if !missing(sanct_startDate1)
tab bidder_hasSanction, m

forval x =1/3{
gen sanct_startDate`x'_f = date(sanct_startDate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_endDate`x',"YMD")
}
format sanct_startDate1_f-sanct_endDate3_f %d

gen bidder_previousSanction=0
replace bidder_previousSanction=1 if ca_signdate>=sanct_endDate1_f & !missing(sanct_endDate1_f)
tab bidder_previousSanction, m

*Dates we only keep the latest start and end date
gen sanct_startdate = .
replace sanct_startdate = sanct_startDate1_f if !missing(sanct_startDate1_f)
replace sanct_startdate = sanct_startDate2_f if !missing(sanct_startDate2_f)
replace sanct_startdate = sanct_startDate3_f if !missing(sanct_startDate3_f)
format sanct_startdate %d
br sanct_startdate sanct_startDate* if !missing(sanct_startDate3_f)

gen sanct_enddate = .
replace sanct_enddate = sanct_endDate1_f if !missing(sanct_endDate1_f)
replace sanct_enddate = sanct_endDate2_f if !missing(sanct_endDate2_f)
replace sanct_enddate = sanct_endDate3_f if !missing(sanct_endDate3_f)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate3_f)

foreach var of varlist sanct_startdate sanct_enddate {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = dayx + "/" + monthx + "/" + yearx
drop dayx monthx yearx
}
replace sanct_startdate_str = "" if sanct_startdate_str=="././."
replace sanct_enddate_str = "" if sanct_enddate_str=="././."

br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startDate1)
drop sanct_startdate sanct_enddate
rename sanct_startdate_str sanct_startdate
rename sanct_enddate_str sanct_enddate
drop _merge sanct_startDate1_f-sanct_endDate3_f sanct_startDate1-sanct_endDate3

*fixing sanc dates
foreach var of varlist sanct_startdate sanct_enddate {
gen `var'_d=date(`var',"DMY")
format `var'_d
gen dayx = string(day(`var'_d))
gen monthx = string(month(`var'_d))
gen yearx = string(year(`var'_d))
gen `var'_str = yearx + "-" + monthx + "-" + dayx if !missing(`var')
drop dayx monthx yearx `var'_d
}
br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startdate)

*Sanctioning Authority name
br sanct_name1 sanct_name2 sanct_name3 if !missing(sanct_startdate)
gen sanct_name = sanct_name1 if !missing(sanct_name1)
replace sanct_name= sanct_name + " & " + sanct_name1 if !missing(sanct_name2)
replace sanct_name= sanct_name + " & " + sanct_name3 if !missing(sanct_name3)
replace sanct_name="Asian Development Bank" if sanct_name=="Asian Development Bank & Asian Development Bank"
drop sanct_name1 sanct_name2 sanct_name3
*Sanctioned corruption indicator
br ca_signdate bidder_hasSanction bidder_previousSanction sanct_startdate_str sanct_enddate_str sanct_name if !missing(sanct_startdate_str) & filter_ok==1
*/
************************************

********************************************************************************
save  $country_folder/IDB_wb_1020.dta, replace
********************************************************************************

*Calcluating indicators

tab taxhav_x , m
tab corr_proc, m
tab corr_ben, m
*For indicators with 1 category

foreach var of varlist  corr_proc taxhav_x   {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
*For indicators with categories
************************************

foreach var of varlist corr_ben  {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_ben_val  corr_ben if filter_ok==1, m
************************************
 
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Creating missing indicators
   
gen ind_singleb_val=.
gen ind_nocft_val=.
gen ind_corr_submp_val=.
gen ind_corr_decp_val=.
************************************
 
*Transparency
gen impl= pr_country
gen proc = ca_procedure
gen aw_date2 = pr_signdate1
gen bids = ""
gen value = ca_contract_value_original

foreach var of varlist anb_name title w_name ca_supplytype  value impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids value
********************************************************************************
save  $country_folder/IDB_wb_1020.dta, replace
********************************************************************************

*Fixing variables for reverse tool

gen tender_country = pr_country
replace tender_country = anb_country if missing(tender_country)
replace tender_country = proper(tender_country)
tab tender_country, m
*Run country to iso code on tender_country
rename iso tender_country_iso
tab tender_country if missing(tender_country_iso)
tab tender_country_iso, m

************************************

*Types of publications
gen tender_publications_notice_type = "" 
drop tender_publications_notice_type
gen tender_publications_award_type = "CONTRACT_AWARD" 
gen source = "https://www.iadb.org/en/iadb_projects/form/search_awarded_contracts" if !missing(tender_publications_award_type)
************************************

br ca_contract_value* ppp
rename ca_contract_value bid_priceUsd
gen bid_pricecurrency="National currency" if !missing(ca_contract_value_original)
************************************

rename cpv_code lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

*For title using ca_type
br *title*
************************************

*Fix dates for export
cft_publ bid_deadline sign_date

foreach var of varlist ca_signdate  {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = dayx + "/" + monthx + "/" + yearx
drop dayx monthx yearx
drop `var'
rename `var'_str `var'
}
br  ca_signdate
foreach var of varlist ca_signdate {
replace `var'="" if `var'=="././."
}

*Fixing sign date
foreach var of varlist ca_signdate {
gen `var'_d=date(`var',"DMY")
format `var'_d
gen dayx = string(day(`var'_d))
gen monthx = string(month(`var'_d))
gen yearx = string(year(`var'_d))
gen `var'_str = yearx + "-" + monthx + "-" + dayx if !missing(`var')
drop dayx monthx yearx `var'_d
}
drop ca_signdate
rename ca_signdate_str ca_signdate
************************************

tab ca_procedure, m
replace ca_procedure="INTERNATIONAL_COMPETITIVE_BIDDING" if  ca_procedure=="ICB"
replace ca_procedure="NATIONAL_COMPETITIVE_BIDDING" if  ca_procedure=="NCB"
*replace ca_procedure="DESIGN_CONTEST" if  ca_procedure=="DC"

*Expand the WB data standard for these procedure types
************************************

*Using the  generated id for buyers
tostring anb_id, replace
replace anb_id= "IDB" +anb_id
replace anb_id="" if anb_id=="IDB."
tostring w_id, replace
replace w_id= "IDB" +w_id if !missing(w_id)
replace w_id="" if w_id=="IDB."
br anb_id w_id

count if missing(w_id) & filter_ok==1
count if missing(anb_id) & filter_ok==1 & !missing(anb_name)

replace anb_id="" if missing(anb_name)
************************************

gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"

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
foreach var of varlist bidder_hasSanction bidder_previousSanction {
gen `var'_n = "true" if `var'==1
replace `var'_n = "false" if `var'==0
drop `var'
rename `var'_n `var'
}
************************************

*Fixes
decode ca_supplytype, gen (ca_supplytype_str)
replace ca_supplytype_str="" if ca_supplytype_str=="."
tab ca_supplytype_str, m
tab ca_supplytype_mod, m
replace ca_supplytype_mod=upper(ca_supplytype_mod)
replace ca_supplytype_mod="SUPPLIES" if ca_supplytype_mod=="GOODS"
tab ca_supplytype_mod, m
************************************

*To replace the first sting into upper
generate str80 title2 = substr(title,2,.)
generate str80 title3 = substr(title,1,1)
replace title3=proper(title3)
gen title4 = title3 + title2
format title* %10s
br title title2 title3 title4 if missing(title)
drop  title title2 title3
rename title4 title 
************************************

********************************************************************************
save  $country_folder/IDB_wb_1020.dta, replace
********************************************************************************
*Ready for export!

*Variable Selection 
use $country_folder/IDB_wb_1020.dta, clear

keep if filter_ok==1
************************************

sort pr_id ca_id 
unique   pr_id ca_id  if filter_ok
bys pr_id ca_id : gen x=_N if filter_ok
br pr_id ca_id x anb_name w_name bid_price* if x>1


br pr_id ca_id x anb_name w_name bid_price* * if x>1 & added_dec=="2019oct" 
*There is a problem with the merge there are duplicates in the data dropping
drop if x==1 & added_dec=="2019oct"&  missing(ca_contract_value_original) & missing(anb_name)
drop if x>1 & added_dec=="2019oct" & missing(ca_contract_value_original) & missing(anb_name)
drop  x

bys pr_id ca_id : gen x=_N if filter_ok
br pr_id ca_id x added_dec anb_name w_name bid_price* * if x>1
*Duplicating anb_name and anb_id for the data
gsort ca_id -anb_name
foreach var of varlist ind_corr_ben_val ind_tr_anb_name_val ind_tr_impl_val{
bys ca_id: replace `var'=`var'[1]
} 

gsort ca_id -anb_name
foreach var of varlist anb_name anb_id anb_iso2 buyer_geocodes tender_addressofimplementation_c tender_addressofimplementation_n tender_country anb_country title{
bys ca_id: replace `var'=`var'[1] if missing(`var') 
} 
br ca_id anb_name anb_id  w_name bid_priceUsd if x>1

gen lot_id=1
bys ca_id lot_id : gen bid_number=_n if filter_ok
unique ca_id lot_id bid_number
************************************

*Fixing the anb_id
count if missing(anb_id)
count if missing(anb_name)
drop x
egen x = group(ca_id) if filter_ok & missing(anb_name) 
replace x=x+750 if !missing(x)
tostring x , replace
replace x="" if x=="."
replace x="IDB" + x if !missing(x)
replace anb_id = x if missing(anb_id) & filter_ok
sort ca_id lot_id bid_number
br ca_id lot_id bid_number anb_id anb_name x 
drop x
************************************

keep ca_id lot_id bid_number tender_country_iso ca_signdate ca_procedure ca_supplytype_mod source tender_publications_award_type anb_id anb_iso2 buyer_geocodes anb_name tender_addressofimplementation_c tender_addressofimplementation_n w_id w_iso2 bidder_geocodes  w_name bid_priceUsd ca_contract_value_original bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate_str sanct_enddate_str sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_taxhav_x_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************

order ca_id lot_id bid_number tender_country_iso ca_signdate ca_procedure ca_supplytype_mod source tender_publications_award_type anb_id anb_iso2 buyer_geocodes anb_name tender_addressofimplementation_c tender_addressofimplementation_n w_id w_iso2 bidder_geocodes  w_name bid_priceUsd ca_contract_value_original bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate_str sanct_enddate_str sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type ind_taxhav_x_val ind_taxhav2_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_anb_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_value_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

export delimited $country_folder/IDB_mod.csv, replace
********************************************************************************
*END