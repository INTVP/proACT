local country = "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************
*Data

use "${country_folder}/`country'_wb_2011.dta", clear
********************************************************************************
*Prep for Reverse tool
********************************************************************************
*Generate tender country

gen tender_country = "HU"
************************************
*Fix bad national procedure type

do "${utility_codes}/fix_bad_national_proc_type.do"
************************************
*Create notice type for tool

cap drop tender_publications_notice_type tender_publications_award_type
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(notice_url) | !missing(tender_publications_firstcallfor)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(tender_publications_lastcontract) | !missing(tender_publications_firstdcontra)
************************************
*Create the correct nuts variables 

*Buyer NUTS
// tab  buyer_nuts if filter_ok, m
gen nutscode = buyer_nuts
merge m:1 nutscode using "${utility_data}/nuts_map.dta"
drop if _m==2
// tab buyer_nuts if missing(description)
// tab tender_year if missing(description)
// tab buyer_nuts if !missing(description)
*Bad codes : do not fit the 2013 version 00 HU11 HU110 HU12 HU120 NO011
replace description=lower(description)
rename  buyer_nuts buyer_nuts_orig

// tab buyer_city if buyer_nuts=="NO011" //Budapest
// tab nutscode if regex(description,"budapest") // HU101
gen  buyer_nuts=buyer_nuts_orig
replace  buyer_nuts="HU101" if inlist(buyer_nuts_orig,"HU11","HU110") //Budapest
replace  buyer_nuts="HU102" if inlist(buyer_nuts_orig,"HU12","HU120") // Pest county
replace  buyer_nuts="" if inlist(buyer_nuts_orig,"00") 
replace  buyer_nuts="HU1" if inlist(buyer_nuts_orig,"HU10") 
replace  buyer_nuts="HU" if inlist(buyer_nuts_orig,"HUZ") 
// tab buyer_nuts, m //All good nuts
drop  description nutscode _merge

*Bidder NUTS
// tab  bidder_nuts if filter_ok, m
gen nutscode = bidder_nuts
merge m:1 nutscode using "${utility_data}/nuts_map.dta"
drop if _m==2

// tab bidder_nuts if missing(description) & _m==1
// br bidder_nuts nutscode description if !missing(bidder_nuts)
replace description=lower(description)
rename  bidder_nuts bidder_nuts_orig

gen  bidder_nuts=bidder_nuts_orig
replace  bidder_nuts="HU101" if inlist(bidder_nuts_orig,"HU11","HU110") //Budapest
replace  bidder_nuts="HU102" if inlist(bidder_nuts_orig,"HU12","HU120") // Pest county
replace  bidder_nuts="" if inlist(bidder_nuts_orig,"00") 
replace  bidder_nuts="DED45" if inlist(bidder_nuts_orig,"DED1C") 
drop description nutscode _merge

*Address of Implementation
// tab tender_addressofimplementation_n if filter_ok, m
gen len = length(tender_addressofimplementation_n)
// tab len if regex(tender_addressofimplementation_n,"[a-z]") 
// br tender_addressofimplementation_n len if regex(tender_addressofimplementation_n,"[a-z]")  & len<10
rename tender_addressofimplementation_n tender_impl_nuts_original
gen nuts_impl = tender_impl_nuts_original
replace nuts_impl="" if regex(tender_impl_nuts_original,"[a-z]")  & len>10
split nuts_impl, p(,)
drop nuts_impl2-nuts_impl124
format nuts_impl nuts_impl1 %15s
// br nuts_impl nuts_impl1
replace nuts_impl1= subinstr(nuts_impl1,`"""',"",.)
replace nuts_impl1= subinstr(nuts_impl1," ","",.)
replace nuts_impl1= subinstr(nuts_impl1,"–","",.)
replace nuts_impl1= upper(nuts_impl1)
replace nuts_impl1="" if nuts_impl1=="KíNA"
drop nuts_impl
split nuts_impl1, p(;)
drop nuts_impl12-nuts_impl19
format nuts_impl1 nuts_impl11 %15s
// br nuts_impl1 nuts_impl11
cap drop len
gen len = length(nuts_impl11)
// tab len
replace nuts_impl11= "" if len>5 
replace nuts_impl11= "" if regex(nuts_impl11,"^[0-9]")
replace nuts_impl11= subinstr(nuts_impl11,".","",.)
replace nuts_impl11= "HU" if regex(nuts_impl11,"^HU0")
// tab nuts_impl11 , m
cap drop len
gen len = length(nuts_impl11)
// tab len
drop nuts_impl1 len
rename nuts_impl11 tender_addressofimplementation_n
gen tender_addressofimplementation_c=substr(tender_addressofimplementation_n,1,2)


gen  buyer_geocodes = "["+ `"""' + buyer_nuts + `"""' +"]" if !missing(buyer_nuts)
gen  bidder_geocodes = "["+ `"""' + bidder_nuts + `"""' +"]" if !missing(bidder_nuts)
gen  impl_nuts = "["+ `"""' + tender_addressofimplementation_n + `"""' +"]" if !missing(tender_addressofimplementation_n)

rename tender_addressofimplementation_n  impl_nuts_cleaned
rename impl_nuts tender_addressofimplementation_n
format  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n %10s
// br  buyer_geocodes bidder_geocodes tender_addressofimplementation_c tender_addressofimplementation_n
************************************
*Buyer main acticities structure

// tab buyer_mainactivities if filter_ok, m
replace buyer_mainactivities = "["+ `"""' + buyer_mainactivities + `"""' +"]" if !missing(buyer_mainactivities)
************************************
*Enumeration buyer type

tab buyer_buyertype, m
************************************
*Enumeration supply type

tab tender_supplytype, m
************************************
*Export prevsanct and has sanct anyway

// gen bidder_previousSanction = "false"
// gen bidder_hasSanction = "false"
// gen sanct_startdate = ""
// gen sanct_enddate = ""
// gen sanct_name = ""
************************************
*Renaming price variables

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
rename lot_estimatedprice_ppp  lot_estimatedpriceUsd
rename tender_estimatedprice_ppp tender_estimatedpriceUsd
gen bid_pricecurrency  = currency
************************************
 *Checking product codes

gen market_id_star=substr(tender_cpvs_fixed,1,2)
// tab market_id_star if filter_ok, m //good
drop market_id_star
rename tender_cpvs tender_cpvs_orig
rename tender_cpvs_fixed tender_cpvs
*Use onle the first product code
rename tender_cpvs lot_productCode
split lot_productCode, p(,)
drop lot_productCode2-lot_productCode95
rename lot_productCode tender_cpvs
rename lot_productCode1 lot_productCode
gen lot_localProductCode =  lot_productCode
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
// br lot_productCode lot_localProductCode lot_localProductCode_type
************************************
*Getting a new title for export

// br tender_title lot_title
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
// br tender_title lot_title title state
drop miss_tentitle miss_lottitle state 

replace title = subinstr(title,`"""',"",.)
************************************

// br tender_recordedbidscount lot_bidscount 
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

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"
************************************

*bidder_hasSanction bidder_previousSanction
foreach var of varlist bid_iswinning  {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}


************************************
*Checking ids to be used

// count if missing(buyer_masterid) & filter_ok //we have missings
// count if missing(buyer_id) & filter_ok
// count if missing(bidder_masterid) & filter_ok
// count if missing(bidder_id) & filter_ok
//
// count if missing(buyer_masterid) & !missing(buyer_name) & filter_ok //we have missings
// br buyer_masterid buyer_name source notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra if filter_ok &  missing(buyer_masterid)

foreach var of varlist buyer_masterid buyer_id bidder_masterid bidder_id {
tostring `var', replace
replace `var' = "" if `var'=="."
}

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}

// br buyer_masterid buyer_id bidder_masterid bidder_id buyer_name bidder_name if filter_ok
replace filter_ok=0 if bidder_name=="-"
// br bidder_name if regex(bidder_name,"-")
// replace filter_ok=0 if buyer_name=="" //11k missing buyer_name dropped
************************************

// tab tender_proceduretype
// tab tender_supplytype

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
*Clean buyer_country

// tab buyer_country, m
gen buyer_country_eng=buyer_country
replace buyer_country_eng  = "Austria" if buyer_country_eng =="Ausztria"
replace buyer_country_eng  = "Belgium" if buyer_country_eng =="Belgium"
replace buyer_country_eng  = "Bosnia and Herzegovina" if buyer_country_eng =="Bosznia-Hercegovina"
replace buyer_country_eng  = "Bulgaria" if buyer_country_eng =="Bulgária"
replace buyer_country_eng  = "Czech Republic" if buyer_country_eng =="Csehország"
replace buyer_country_eng  = "Denmark" if buyer_country_eng =="Dánia"
replace buyer_country_eng  = "United Arab Emirates" if buyer_country_eng =="Egyesült Arab Emírségek"
replace buyer_country_eng  = "United Kingdom" if buyer_country_eng =="Egyesült Királyság"
replace buyer_country_eng  = "Finland" if buyer_country_eng =="Finnország"
replace buyer_country_eng  = "France" if buyer_country_eng =="Franciaország"
replace buyer_country_eng  = "Netherlands" if buyer_country_eng =="Hollandia"
replace buyer_country_eng  = "Croatia" if buyer_country_eng =="Horvátország"
replace buyer_country_eng  = "India" if buyer_country_eng =="India"
replace buyer_country_eng  = "Japan" if buyer_country_eng =="Japán"
replace buyer_country_eng  = "Canada" if buyer_country_eng =="Kanada"
replace buyer_country_eng  = "China" if buyer_country_eng =="Kína"
replace buyer_country_eng  = "Poland" if buyer_country_eng =="Lengyelország"
replace buyer_country_eng  = "Latvia" if buyer_country_eng =="Lettország"
replace buyer_country_eng  = "Hungary" if buyer_country_eng =="Magyarország"
replace buyer_country_eng  = "Great Britain" if buyer_country_eng =="Nagy-Britannia"
replace buyer_country_eng  = "Norway" if buyer_country_eng =="Norvégia"
replace buyer_country_eng  = "Germany" if buyer_country_eng =="Németország"
replace buyer_country_eng  = "Italy" if buyer_country_eng =="Olaszország"
replace buyer_country_eng  = "Russia" if buyer_country_eng =="Oroszország"
replace buyer_country_eng  = "Romania" if buyer_country_eng =="Románia"
replace buyer_country_eng  = "Spain" if buyer_country_eng =="Spanyolország"
replace buyer_country_eng  = "Switzerland" if buyer_country_eng =="Svájc"
replace buyer_country_eng  = "Sweden" if buyer_country_eng =="Svédország"
replace buyer_country_eng  = "Serbia" if buyer_country_eng =="Szerbia"
replace buyer_country_eng  = "Slovakia" if buyer_country_eng =="Szlovákia"
replace buyer_country_eng  = "Slovenia" if buyer_country_eng =="Szlovénia"
replace buyer_country_eng  = "taiwan" if buyer_country_eng =="Taiwan"
replace buyer_country_eng  = "Turkey" if buyer_country_eng =="Törökország"
replace buyer_country_eng  = "New Zealand" if buyer_country_eng =="Új-Zéland"
replace buyer_country_eng = "" if inlist(buyer_country_eng,"+36 36 516 430","-","–")
replace buyer_country_eng = "HU" if regex(buyer_country_eng,"magyar|Magyar|MAGYAR|Budapest|Hungary|Magyyar|Nyíregy|HUN")
replace buyer_country_eng="US" if buyer_country_eng=="Amerikai Egyesült Államok"
replace buyer_country_eng="AT" if buyer_country_eng=="Austria"
replace buyer_country_eng="UK" if buyer_country_eng=="Anglia"
replace buyer_country_eng="CZ" if buyer_country_eng=="Cseh Köztársaság"
replace buyer_country_eng="FI" if buyer_country_eng=="Finland"
replace buyer_country_eng="FR" if buyer_country_eng=="France"
replace buyer_country_eng="DE" if buyer_country_eng=="Germany"
replace buyer_country_eng="HK" if buyer_country_eng=="Hongkong"
replace buyer_country_eng="LI" if buyer_country_eng=="Liechtenstein"
replace buyer_country_eng="SE" if buyer_country_eng=="Sweden"
replace buyer_country_eng="SK" if buyer_country_eng=="Szlovák Köztársaság"
replace buyer_country_eng="US" if buyer_country_eng=="USA"
replace buyer_country_eng="AT" if buyer_country_eng=="Östereich"
replace buyer_country_eng="IT" if buyer_country_eng=="Italy"
tab buyer_country_eng, m //use this
************************************
*Clean bidder_country

// br *bidder_country* *iso*
// tab bidder_country_eng, m
// tab iso_bidder, m //use this

* Clean Address of Implementation
// tab tender_addressofimplementation_c, m
replace tender_addressofimplementation_c="" if inlist(tender_addressofimplementation_c,"-H","-")

********************************************************************************
*Calcluating indicators

// tab singleb , m 
// tab taxhav2 , m
// tab corr_decp, m
// tab corr_submp , m
// tab corr_proc, m
// tab corr_ben, m
************************************
*For indicators with 1 category

foreach var of varlist singleb taxhav2 corr_submp  {
*tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = .  if  `var'==9  //tax haven undefined
}
gen ind_corr_nocft_val=.

// tab ind_singleb_val  singleb, m
// tab ind_taxhav2_val  taxhav2, m
// tab ind_corr_submp_val  corr_submp, m
************************************
*For indicators with categories

// tab corr_decp, m
// tab corr_proc, m
// tab corr_ben, m
foreach var of varlist corr_proc corr_decp corr_ben {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
// tab ind_corr_proc_val  corr_proc, m
// tab ind_corr_ben_val  corr_ben, m

*Contract Share
// sum proa_ycsh4
gen ind_csh_val = proa_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************
*Transparency

// br tender_addressofimplementation_n tender_nationalproceduretype tender_publications_firstdcontra
// br *title*

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
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = bids_count

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************
*Export for Reverse tool

use "${country_folder}/`country'_wb_2011.dta", clear

drop if filter_ok==0
duplicates drop
drop if missing(buyer_name)

bys tender_id: gen x=_N
************************************
*Generating LOT NUMBER

format tender_title bidder_name lot_title  tender_publications_lastcontract  %15s
// br x tender_id lot_row_nr tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract if x>1

*If x>1 & lot_row_nr is missing and tender_framework is t then consider it one lot
gen lot_number= lot_row_nr
replace lot_number = 1 if tender_isframe=="t" & missing(lot_number) & x>1

*If lot_number is missinf and tender_lotscount==1 then consider it as 1 lot
replace lot_number = 1 if missing(lot_number) & x>1 & tender_lotscount==1

*If x>1 & lot_number is missing and tender_framework is f or missing then consider it several lots (checked a few links and its tru)
bys tender_id: replace lot_number = _n if inlist(tender_isframe,"f","") & missing(lot_number) & x>1

replace lot_number=1 if x==1 & missing(lot_number)
// count if missing(lot_number)
drop x

// sort tender_id lot_number
// br tender_id lot_number tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price *cons* tender_publications_lastcontract 
************************************
*Generating BID NUMBER

bys tender_id lot_number: gen bid_number=_n

sort tender_id lot_number bid_number 
// unique tender_id lot_number bid_number 
************************************
*FIXING ESTIMATED PRICE VARIABLE TO USE

*MAIN : lot_estimatedprice
// br tender_estimatedpriceUsd tender_estimatedprice  lot_estimatedpriceUsd lot_estimatedprice bid_pricecurrency
replace lot_estimatedprice=tender_estimatedprice if lot_number==1 & missing(lot_estimatedprice)
replace lot_estimatedpriceUsd=tender_estimatedpriceUsd if lot_number==1 & missing(lot_estimatedpriceUsd)
gen lot_est_pricecurrency=currency
************************************

keep tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline  tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country_eng buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id iso_bidder bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_corr_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital

order tender_id lot_number bid_number bid_iswinning tender_country  tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline  tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor notice_url source tender_publications_award_type  tender_publications_firstdcontra  tender_publications_lastcontract  buyer_masterid buyer_id buyer_city buyer_postcode buyer_country_eng buyer_geocodes buyer_name  buyer_buyertype buyer_mainactivities tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id iso_bidder bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title lot_estimatedpriceUsd lot_estimatedprice lot_est_pricecurrency ind_corr_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_proc_val ind_corr_proc_type submp ind_corr_submp_val ind_corr_submp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type  ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************

export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace
********************************************************************************
*Clean up
copy "${country_folder}/`country'_wb_2011.dta" "${utility_data}/country/`country'/`country'_wb_2011.dta", replace
local files : dir  "${country_folder}" files "*.dta"
foreach file in `files' {
cap erase "${country_folder}/`file'"
}
cap erase "${country_folder}/buyers_for_R.csv"
********************************************************************************
*END