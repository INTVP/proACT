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
* Also adding sanctions data
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/WB_wb_0920.dta, clear
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
*Checking sanction data

use $country_folder/WB_sanctions.dta, clear
drop  n_row1-n_row4 sanct_legalGround1-sanct_bodyIds4 sanct_contactPoint1-sanct_country4
save $country_folder/WB_sanctions.dta, replace
************************************

use $country_folder/WB_wb_0920.dta, clear

gen bidder_name=w1_name
merge m:1 bidder_name using $country_folder/WB_sanctions.dta
drop bidder_name _m

gen bidder_hasSanction=0
replace bidder_hasSanction=1 if !missing(sanct_startDate1)
tab bidder_hasSanction, m

forval x =1/4{
gen sanct_startDate`x'_f = date(sanct_startDate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_endDate`x',"YMD")
}
format sanct_startDate1_f-sanct_endDate4_f %d

gen bidder_previousSanction=0
replace bidder_previousSanction=1 if sign_date>=sanct_endDate1_f & !missing(sanct_endDate1_f)
tab bidder_previousSanction, m

*Dates we only keep the latest start and end date
gen sanct_startdate = .
replace sanct_startdate = sanct_startDate1_f if !missing(sanct_startDate1_f)
replace sanct_startdate = sanct_startDate2_f if !missing(sanct_startDate2_f)
replace sanct_startdate = sanct_startDate3_f if !missing(sanct_startDate3_f)
replace sanct_startdate = sanct_startDate4_f if !missing(sanct_startDate4_f)

format sanct_startdate %d
br sanct_startdate sanct_startDate* if !missing(sanct_startDate4_f)

gen sanct_enddate = .
replace sanct_enddate = sanct_endDate1_f if !missing(sanct_endDate1_f)
replace sanct_enddate = sanct_endDate2_f if !missing(sanct_endDate2_f)
replace sanct_enddate = sanct_endDate3_f if !missing(sanct_endDate3_f)
replace sanct_enddate = sanct_endDate4_f if !missing(sanct_endDate4_f)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate4_f)

foreach var of varlist sanct_startdate sanct_enddate {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = yearx + "-" + monthx + "-" + dayx
drop dayx monthx yearx
}
replace sanct_startdate_str = "" if sanct_startdate_str==".-.-."
replace sanct_enddate_str = "" if sanct_enddate_str==".-.-."

br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startDate1)
drop sanct_startdate sanct_enddate
rename sanct_startdate_str sanct_startdate
rename sanct_enddate_str sanct_enddate
drop  sanct_startDate1_f-sanct_endDate4_f sanct_startDate1-sanct_endDate4

*Sanctioning Authority name
br sanct_name1 sanct_name2 sanct_name3 sanct_name4 if !missing(sanct_startdate)
gen sanct_name = sanct_name1 if !missing(sanct_name1)
replace sanct_name= sanct_name + " & " + sanct_name2 if !missing(sanct_name2)
replace sanct_name= sanct_name + " & " + sanct_name3 if !missing(sanct_name3)
replace sanct_name= sanct_name + " & " + sanct_name4 if !missing(sanct_name4)
br sanct_name if !missing(sanct_name)
replace sanct_name="Asian Development Bank" if sanct_name=="Asian Development Bank & Asian Development Bank"
drop sanct_name1 sanct_name2 sanct_name3 sanct_name4
*Sanctioned corruption indicator
br ca_signdate bidder_hasSanction bidder_previousSanction sanct_startdate sanct_enddate sanct_name if !missing(sanct_startdate) & filter_ok==1
*/

********************************************************************************
save $country_folder/WB_wip.dta, replace
********************************************************************************

*Calcluating indicators
tab nocft , m
tab singleb , m 
tab taxhav2_x , m
tab corr_decp, m
tab corr_submp , m
tab corr_proc2, m
tab corr_ben, m
*For indicators with 1 category

foreach var of varlist nocft singleb taxhav2_x corr_submp corr_decp  {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
************************************

tab ind_nocft_val  nocft if filter_ok==1, m
tab ind_singleb_val  singleb if filter_ok==1, m
tab ind_taxhav2_x_val  taxhav2_x if filter_ok==1, m
tab ind_corr_submp_val  corr_submp if filter_ok==1, m
tab ind_corr_decp_val  corr_decp if filter_ok==1, m
************************************

*For indicators with categories

foreach var of varlist corr_proc2 corr_ben  {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc2_val  corr_proc2 if filter_ok==1, m
tab ind_corr_ben_val  corr_ben if filter_ok==1, m
 
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Transparency
gen impl= pr_country
gen proc = procedure_type
gen aw_date2 = ca_signdate
gen bids =ca_bids
foreach var of varlist pr_borrower_name title w1_name ca_supplytype ca_lot_value_num impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids

********************************************************************************
save $country_folder/WB_wip.dta, replace
********************************************************************************

*Fixing variables for reverse tool

gen iso = ca_country
do $utility_codes/country-to-iso.do iso
rename iso iso_tender_country
tab tender_country if missing(iso_tender_country)
replace tender_country="" if tender_country=="World"
drop tender_country
rename iso_tender_country  tender_country
************************************

br noticetype cft_publdate cft_bid_deadline
br cft_publdate ca_signdate source_majorca source_contracts source_notices if source_notices=="1" & (source_majorca=="1" | source_contracts=="1" )

gen tender_publications_notice_type = "CONTRACT_NOTICE" if source_notices=="1"

gen tender_publications_award_type = "CONTRACT_AWARD" if (source_majorca=="1" | source_contracts=="1" )

gen source = "https://projects.worldbank.org/" if !missing(tender_publications_notice_type) | !missing(tender_publications_award_type)

br source cft_publdate source_majorca source_contracts source_notices tender_publications_notice_type tender_publications_award_type if filter_ok
************************************

*Fixing IMPL nuts
gen tender_addressofimplementation_c=pr_country
tab tender_addressofimplementation_c, m
*I run the country to iso generate nuts-like
tab tender_addressofimplementation_c if missing(iso) //11,659 have a generic location
rename iso tender_addressofimplementation_n
drop tender_addressofimplementation_c
gen tender_addressofimplementation_c= tender_addressofimplementation_n
tab tender_addressofimplementation_n, m
*replace tender_addressofimplementation_n= tender_addressofimplementation_n + "000" if !missing(tender_addressofimplementation_n)

gen  tender_addressofimplementation2 = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]" if !missing(tender_addressofimplementation_n)
drop tender_addressofimplementation_n
rename tender_addressofimplementation2 tender_addressofimplementation_n
tab tender_addressofimplementation_n, m
tab tender_addressofimplementation_c, m
*replace tender_addressofimplementation_n = "" if tender_addressofimplementation_n==`"[""]"'
************************************

*Buyer geocodes
tab anb_country
tab iso_anb
replace anb_country="" if inlist(anb_country,"AFRICA","SOUTH_EASTERN_EUROPE_AND_BALKANS","WESTERN_AFRICA")
replace iso_anb="" if inlist(iso_anb,"AFRICA","SOUTH_EASTERN_EUROPE_AND_BALKANS","WESTERN_AFRICA")
rename iso_anb iso
do $utility_codes/country-to-iso.do iso

rename iso buyer_geocodes
rename anb_country buyer_country

replace buyer_geocodes="CD" if buyer_geocodes=="ZR"

gen len=length(buyer_geocodes)
tab len, m
tab buyer_geocodes if len>2
replace buyer_geocodes="" if len>2
tab buyer_geocodes, m
drop len
*replace buyer_geocodes= buyer_geocodes + "000" if !missing(buyer_geocodes)
replace buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]" if !missing(buyer_geocodes)
tab buyer_geocodes, m


*Fixing Bidder nuts
tab w1_country
tab iso_supplier
replace w1_country=proper(w1_country)
replace  w1_country="East Timor" if w1_country=="Tp"
replace  w1_country="Libya" if w1_country=="Ly"
replace  w1_country="Caymen Islands" if w1_country=="Ky"
replace  w1_country="Virgin Islands (British)" if w1_country=="Vg"
rename w1_country bidder_country
rename bidder_country w1_country

rename iso_supplier bidder_geocodes
replace bidder_geocodes="BN" if bidder_geocodes=="Brunei Darussalam"
replace bidder_geocodes="YU" if bidder_geocodes=="Former Yugoslavia"
replace bidder_geocodes="XK" if bidder_geocodes=="Kosovo"
replace bidder_geocodes="SZ" if bidder_geocodes=="Swaziland"
replace bidder_geocodes="" if bidder_geocodes=="World"
tab bidder_geocodes, m

replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]" if !missing(bidder_geocodes)
tab bidder_geocodes, m
replace bidder_geocodes = "" if bidder_geocodes==`"[""]"'

tab bidder_country, m
gen iso = bidder_country
do $utility_codes/country-to-iso.do iso
rename iso iso_bidder
cap drop bidder_country
rename iso_bidder bidder_country
gen len=length(bidder_country)
tab len,m
drop len
************************************

br ca_contract_value_num ca_lot_value_num ca_contract_value_ppp ppp
destring ca_contract_value_ppp, replace
rename ca_contract_value_ppp bid_priceUsd
* currency variable: pr_grant_currency

*Redoing the ppp correction - using another ppp dataset utility_data/country/WB/wb_ppp_1990-2018_long.dta
rename ppp ppp_old
rename country_name country_name_old
gen country_name = country_name_old
replace country_name = pr_country if missing(country_name)
		replace country_name = "British Virgin Islands" if country_name == "Virgin Islands, British"
		replace country_name = "Congo, Dem. Rep." if country_name == "Congo, Democratic Republic of"
		replace country_name = "Congo, Rep." if country_name == "Congo, Republic of"
		replace country_name = "Egypt, Arab Rep." if country_name == "Egypt, Arab Republic of"
		replace country_name = "Iran, Islamic Rep." if country_name == "Iran, Islamic Republic of"
		replace country_name = "Korea, Dem. People's Rep." if country_name == "Korea, Democratic People's Republic of"
		replace country_name = "Korea, Rep." if country_name == "Korea, Republic of"
		replace country_name = "Lao PDR" if country_name == "Lao People's Democratic Republic"
		replace country_name = "Macedonia, FYR" if country_name == "Macedonia, former Yugoslav Republic of"
		replace country_name = "Micronesia, Fed. Sts." if country_name == "Micronesia, Federated States of"
		replace country_name = "Venezuela, RB" if country_name == "Venezuela, Republica Bolivariana de"
		replace country_name = "Yemen, Rep." if country_name == "Yemen, Republic of"
		
merge m:1 country_name year using $utility_data/country/WB/wb_ppp_1990-2018_long.dta , nogen keep(1 3)	
tab country_name if missing(ppp) & !missing(year) & year<=2018
gen bid_priceUsd_corr = ca_lot_value_num / ppp
lab var bid_priceUsd_corr "Contract value - PPP adjusted"

gen currency = "USD" if !missing(ca_lot_value_num)
************************************

rename cpv_code lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

format cft_title ca_title title  %10s
br  cft_title ca_title title if !missing(cft_title) & !missing(ca_title)
replace title = proper(title)
br title if !missing(title)
************************************

gen bids_count = ca_bids
************************************

*Fix dates for export

foreach var of varlist cft_publ bid_deadline sign_date  {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen len_mon=length(monthx)
replace monthx="0" + monthx if len_mon=1 & !missing(monthx)
gen len_day=length(dayx)
replace dayx="0" + dayx if len_day=1 & !missing(dayx)
gen `var'_str = yearx + "-" + monthx + "-" + dayx
drop dayx monthx yearx len_mon len_day
drop `var'
rename `var'_str `var'
}
br cft_publ bid_deadline sign_date
foreach var of varlist  cft_publ bid_deadline sign_date {
replace `var'="" if `var'==".-.-."
}
************************************

tab procedure_type, m
*Expand the WB data standard for these
************************************

*Using the id I generated for buyers
tostring anb_id, replace
replace anb_id= "WB" +anb_id
replace anb_id="" if anb_id=="WB"
tostring w_id, replace
replace w_id= "WB" +w_id if !missing(w_id)
replace w_id="" if w_id=="WB."
br anb_id w_id
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

rename ind_tr_pr_borrower_name_val ind_tr_buyer_name_val

************************************

foreach var of varlist bidder_hasSanction bidder_previousSanction {
gen `var'_n = "true" if `var'==1
replace `var'_n = "false" if `var'==0
drop `var'
rename `var'_n `var'
}
************************************

*Fix id for all bidders
egen w_id2 = group(w1_name)
br w_id w_id2 w1_name if missing(w_id)

********************************************************************************
save $country_folder/WB_wb_0920.dta, replace
********************************************************************************

use $country_folder/WB_wb_0920.dta, clear


*Variable Selection 

keep if filter_ok
************************************

sort ca_id lot_id
unique  ca_id lot_id if filter_ok
br ca_id lot_id w1_name ca_lot_value_num if filter_ok
bys ca_id lot_id : gen bid_number=_n if filter_ok

drop if missing(ca_id)
************************************

*Run country to iso on  tender_country
cap drop iso
gen iso = tender_country
do $utility_codes/country-to-iso.do iso
drop tender_country
rename iso tender_country

************************************
keep ca_id lot_id bid_number tender_country sign_date bid_deadline procedure_type ca_supplytype source tender_publications_notice_type cft_publ tender_publications_award_type anb_id buyer_country buyer_geocodes pr_borrower_name tender_addressofimplementation_c tender_addressofimplementation_n w_id bidder_country bidder_geocodes w1_name bid_priceUsd_corr ca_lot_value_num currency bidder_hasSanction bidder_previousSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_x_val ind_taxhav2_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc2_val ind_corr_proc_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w1_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_ca_lot_value_num_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type
************************************

order ca_id lot_id bid_number tender_country sign_date bid_deadline procedure_type ca_supplytype source tender_publications_notice_type cft_publ tender_publications_award_type anb_id buyer_country buyer_geocodes pr_borrower_name tender_addressofimplementation_c tender_addressofimplementation_n w_id bidder_country bidder_geocodes w1_name bid_priceUsd_corr ca_lot_value_num currency bidder_hasSanction bidder_previousSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_x_val ind_taxhav2_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_proc2_val ind_corr_proc_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_w1_name_val ind_tr_bidder_name_type ind_tr_ca_supplytype_val ind_tr_tender_supplytype_type ind_tr_ca_lot_value_num_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

export delimited $country_folder/WB_mod.csv, replace
********************************************************************************
*END