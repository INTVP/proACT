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
use $country_folder/wb_in_cri201118.dta, clear
********************************************************************************
*Calcluating indicators

sum singleb corr_submp corr_proc corr_desc corr_ben proa_ycsh if filter_ok==1

tab singleb , m 
tab corr_submp, m
tab corr_desc, m

foreach var of varlist singleb corr_submp corr_desc {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  
}
tab ind_singleb_val  singleb, m
tab ind_corr_submp_val  corr_submp, m
tab ind_corr_desc_val  corr_desc, m
************************************

tab corr_proc, m 
tab corr_ben, m 
foreach var of varlist corr_proc corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_ben_val  corr_ben, m
************************************

*Contract Share
sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
gen ind_csh_status = "CALCULATED"
replace ind_csh_status = "INSUFFICIENT DATA" if missing(proa_ycsh)
replace ind_csh_status = "UNDEFINED" if missing(proa_ycsh4) & !missing(proa_ycsh)
 ************************************
 
*Transparency
*gen tender_addressofimplementation_n=""
*gen impl= tender_addressofimplementation_n
gen proc = ca_procedure_nat

gen tender_supplytype=ca_type 
gen tender_proceduretype=ca_proc_simp 
rename ten_title tender_title 
rename anb_name buyer_name 
rename w_name bidder_name

foreach var of varlist buyer_name tender_title bidder_name tender_supplytype bid_price proc aw_date {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2

rename lot_nrbid lot_bidscount

gen ind_tr_bids_val = 0 if lot_bidscount==.
replace ind_tr_bids_val= 100 if lot_bidscount!=.

********************************************************************************
save $country_folder/wb_in_cri201118.dta, replace
********************************************************************************


*Fixing variables for reverse tool

gen tender_country = "IN"
************************************

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date_first)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(aw_date)

br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************

*year-month-day as a string 

foreach var of varlist cft_deadline cft_date_first cft_date_last aw_date ca_signdate {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx="0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen `var'_str = yearx + "-" + monthx + "-" + dayx
	replace `var'_str ="" if `var'_str ==".-0.-0."
	drop dayx monthx yearx len_mon len_day
	drop `var'
	rename `var'_str `var'
}
************************************

rename bid_price_ppp bid_priceUsd
gen bid_pricecurrency  = currency
gen ten_est_pricecurrency = currency
gen lot_est_pricecurrency = currency
************************************

rename cpv_code lot_productCode
gen lot_localProductCode =  lot_productcode
replace lot_localProductCode = substr(lot_localProductCode,1,8)
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

br tender_title lot_title
gen title = tender_title
************************************

br tender_recordedbidscount lot_bidscount
gen bids_count = lot_bidscount
*replace bids_count = tender_recordedbidscount if missing(bids_count)

********************************************************************************
save $country_folder/wb_in_cri201118.dta, replace
********************************************************************************

*Exporting for the rev flatten tool\

*Indicators
rename ind_corr_proc_val c_INTEGRITY_PROCEDURE_TYPE
rename ind_corr_submp_val  c_INTEGRITY_ADVERTISEMENT_PERIOD
rename ind_nocft_val  c_INTEGRITY_CALL_FOR_TENDER_PUB
rename ind_singleb_val  c_INTEGRITY_SINGLE_BID
rename ind_csh_val  c_INTERGIRTY_WINNER_SHARE
rename ind_corr_ben_val c_INTEGRITY_BENFORD

rename ind_tr_tender_title_val c_TRANSPARENCY_TITLE_MISSING
rename ind_tr_bid_price_val c_TRANSPARENCY_VALUE_MISSING
rename ind_tr_bids_val c_TRANSPARENCY_BID_NR_MISSING
rename ind_tr_buyer_name_val c_TRANSPARENCY_BUYER_NAME_MIS
rename ind_tr_bidder_name_val c_TRANSPARENCY_BIDDER_NAME_MIS
rename ind_tr_tender_supplytype_val c_TRANSPARENCY_SUPPLY_TYPE_MIS
rename ind_tr_proc_val c_TRANSPARENCY_PROC_METHOD_MIS
rename ind_tr_aw_date_val c_TRANSPARENCY_AWARD_DATE_MIS

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

************************************
*Calculating  status

*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)

*undefined if tax haven ==9 
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date_type = "TRANSPARENCY_AWARD_DATE_MISSING"

gen tender_indicator_status = "INSUFFICIENT DATA" if inlist(tender_indicator_value,99,999,.)
replace tender_indicator_status = "CALCULATED" if missing(tender_indicator_status)
replace tender_indicator_value=. if inlist(tender_indicator_value,99,999,.)

gen buyer_indicator_type = "INTEGRITY_BENFORD"
rename corr_ben buyer_indicator_value
gen buyer_indicator_status = "INSUFFICIENT DATA" if inlist(buyer_indicator_value,99,.)
replace buyer_indicator_status = "CALCULATED" if missing(buyer_indicator_status)
replace buyer_indicator_value=. if inlist(buyer_indicator_value,99,999,.)
************************************

decode bid_iswinning, gen(bid_iswinnings)
drop bid_iswinning
rename bid_iswinnings bid_iswinning
foreach var of varlist bid_iswinning {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

rename anb_id_addid buyer_id_n
rename w_id_addid bidder_id_n

foreach var of varlist buyer_id bidder_id {
decode `var', gen(`var'_str)
replace `var'_str = "" if `var'==.
}
br  buyer_id bidder_id

drop buyer_id bidder_id
rename buyer_id_str buyer_id
rename bidder_id_str bidder_id
********************************************************************************
save $country_folder/wb_in_cri201118.dta, replace
********************************************************************************

*Fixing variables for the rev flatten tool\
rename ten_id tender_id

sort tender_id 

tab bid_iswinning, m
gen miss_bidder=missing(bidder_name)
tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
************************************

bys tender_id: gen x=_N
format tender_title  bidder_name  %15s
br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1
************************************

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
count if missing(tender_lotscount)
gen lot_number = 1 if tender_isframework=="t" & missing(lot_row_nr)
replace lot_number = lot_row_nr if tender_isframework=="t" & !missing(lot_row_nr)
bys tender_id: gen lot_number=_n 
count if missing(lot_number)

sort  tender_id lot_number
br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
************************************

*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n
br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK

********************************************************************************
*Sanctions

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""

decode bidder_name, gen(bidder_name_str)
drop bidder_name
rename bidder_name_str bidder_name

replace bidder_name=proper(bidder_name)
decode bidder_name, gen(bidder_name_str)
drop bidder_name
rename bidder_name_str bidder_name
replace bidder_name=proper(bidder_name)
/*

merge m:m bidder_name using $utility_data/country/IN/IN_sanctions.dta
drop bidder_name 
drop if _m==2
drop _m
format w_name %15s
br w_name n_row1-sanct_country4 if !missing(n_row1)
drop n_row*

*Manage dates
format sanct_startDate1 sanct_startDate2 sanct_startDate3 %d

gen aw_dateD = date(aw_date,"YMD")
format aw_dateD %d

forval x =1/3 {
gen sanct_startdate`x'_f = date(sanct_startdate`x',"YMD")
gen sanct_enddate`x'_f = date(sanct_enddate`x',"YMD")
}

format sanct_startdate1_f sanct_enddate1_f sanct_startdate2_f sanct_enddate2_f sanct_startdate3_f %d

format sanct_startDate* sanct_endDate* %d
br  aw_dec_date sanct_startdate* sanct_enddate* if !missing(sanct_startdate1)
gen bidder_hasSanction="false"
replace bidder_hasSanction="true" if !missing(sanct_startdate1_f)
gen bidder_previousSanction="false"
replace bidder_previousSanction="true" if aw_dateD>=sanct_enddate1_f & !missing(sanct_enddate1_f)
replace bidder_previousSanction="" if missing(aw_dateD)
*Dates we only keep the latest start and end date
gen sanct_startdate = ""
replace sanct_startdate = sanct_startdate1 if !missing(sanct_startdate1)
replace sanct_startdate = sanct_startdate2 if !missing(sanct_startdate2)
replace sanct_startdate = sanct_startdate3 if !missing(sanct_startdate3)
*replace sanct_startdate = sanct_startDate4 if !missing(sanct_startDate4)
format sanct_startdate %d
br sanct_startdate sanct_startdate* if !missing(sanct_startdate3)
gen sanct_enddate = ""
replace sanct_enddate = sanct_enddate1 if !missing(sanct_enddate1)
replace sanct_enddate = sanct_enddate2 if !missing(sanct_enddate2)
*replace sanct_enddate = sanct_enddate3 if !missing(sanct_enddate3)
*replace sanct_enddate = sanct_endDate4 if !missing(sanct_endDate4)

br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startDate1)
*drop sanct_legalGround1-sanct_endDate3
*Sanctioning Authority name
br sanct_name1 sanct_name2 sanct_name3 if !missing(sanct_startdate)
gen sanct_name = sanct_name1 if !missing(sanct_name1)
replace sanct_name= sanct_name + " & " + sanct_name2 if !missing(sanct_name2)
replace sanct_name= sanct_name + " & " + sanct_name3 if !missing(sanct_name3)
*replace sanct_name= sanct_name + " & " + sanct_name4 if !missing(sanct_name4)
*Sanctioned corruption indicator
tab bidder_hasSanction, m
tab bidder_previousSanction, m
br aw_dec_date bidder_hasSanction bidder_previousSanction  sanct_startdate sanct_enddate sanct_name if !missing(sanct_startdate)
   
*/
********************************************************************************

*decoding categorical variables
foreach var of varlist ca_type ca_proc_simp anb_type {
decode `var', gen(`var'_str)
}

rename aw_date tender_awarddecisiondate
rename ca_signdate tender_contractsignaturedate
rename cft_deadline tender_biddeadline
rename ca_proc_simp_str tender_proceduretype
rename ca_type_str tender_supplytype
rename cft_date_first tender_publications_firstcallfor
rename anb_type_str buyer_buyertype
gen tender_publications_firstdcontra=tender_awarddecisiondate
************************************

replace tender_proceduretype="OUTRIGHT_AWARD" if tender_proceduretype=="direct"
replace tender_proceduretype="RESTRICTED" if tender_proceduretype=="limited"
replace tender_proceduretype="OPEN" if tender_proceduretype=="open"
replace tender_proceduretype="OTHER" if tender_proceduretype=="other"
tab tender_proceduretype
************************************

replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype) | tender_supplytype=="OTHER"
************************************

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra buyer_masterid buyer_id buyer_name  buyer_buyertype bidder_masterid bidder_id bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_singleb_val ind_singleb_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date_val ind_tr_aw_date_type 
************************************

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type tender_publications_firstdcontra buyer_masterid buyer_id buyer_name  buyer_buyertype bidder_masterid bidder_id bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_singleb_val ind_singleb_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date_val ind_tr_aw_date_type 
********************************************************************************

*Implementing some fixes

drop if missing(bidder_name) | bidder_name=="N/A"

replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype)

replace tender_proceduretype = "OUTRIGHT_AWARD" if tender_proceduretype=="direct"
replace tender_proceduretype = "RESTRICTED" if tender_proceduretype=="limited"
replace tender_proceduretype = "OPEN" if tender_proceduretype=="open"
replace tender_proceduretype = "OTHER" if tender_proceduretype=="other"
********************************************************************************

export delimited $country_folder/IN_mod.csv, replace
********************************************************************************
*END