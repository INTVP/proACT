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
-Add sanctions data
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/MX_171020.dta, clear
********************************************************************************

*Sanctions

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
/*

*New sanctions data from Ahmed
gen bidder_name = w_name
merge m:1 bidder_name using $utility_data/country/MX/MX_sanctions.dta
drop bidder_name 
drop if _m==2
drop _m
format w_name %15s
br w_name n_row1-sanct_country4 if !missing(n_row1)
drop n_row*

*Manage dates
forval x =1/4 {
gen sanct_startDate`x'_f = date(sanct_startDate`x',"YMD")
gen sanct_endDate`x'_f = date(sanct_endDate`x',"YMD")
drop sanct_startDate`x' sanct_endDate`x'
rename sanct_startDate`x'_f sanct_startDate`x'
rename sanct_endDate`x'_f sanct_endDate`x'
}
format sanct_startDate* sanct_endDate* %d
br  ca_start_date sanct_startDate* sanct_endDate* if !missing(sanct_startDate1)

gen bidder_hasSanction=0
replace bidder_hasSanction=1 if !missing(sanct_startDate1)

gen bidder_previousSanction=0
replace bidder_previousSanction=1 if ca_start_date>=sanct_endDate1 & !missing(sanct_endDate1)

*Dates we only keep the latest start and end date
gen sanct_startdate = .
replace sanct_startdate = sanct_startDate1 if !missing(sanct_startDate1)
replace sanct_startdate = sanct_startDate2 if !missing(sanct_startDate2)
replace sanct_startdate = sanct_startDate3 if !missing(sanct_startDate3)
replace sanct_startdate = sanct_startDate4 if !missing(sanct_startDate4)
format sanct_startdate %d
br sanct_startdate sanct_startDate* if !missing(sanct_startDate4)

gen sanct_enddate = .
replace sanct_enddate = sanct_endDate1 if !missing(sanct_endDate1)
replace sanct_enddate = sanct_endDate2 if !missing(sanct_endDate2)
replace sanct_enddate = sanct_endDate3 if !missing(sanct_endDate3)
replace sanct_enddate = sanct_endDate4 if !missing(sanct_endDate4)
format sanct_enddate %d
br sanct_enddate sanct_endDate* if !missing(sanct_endDate4)

format sanct_enddate %d 
foreach var of varlist sanct_startdate sanct_enddate {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = yearx + "." + monthx + "." + dayx
drop dayx monthx yearx
}
replace sanct_startdate_str = "" if sanct_startdate_str=="....."
replace sanct_enddate_str = "" if sanct_enddate_str=="....."

br sanct_startdate sanct_startdate_str sanct_enddate sanct_enddate_str if !missing(sanct_startDate1)
drop sanct_startdate sanct_enddate
drop sanct_legalGround1-sanct_endDate4
rename sanct_startdate_str sanct_startdate
rename sanct_enddate_str sanct_enddate

gen sanct_name = "Comisión Federal de Competencia Económica" if !missing(sanct_startdate)

*Sanctioned corruption indicator
tab bidder_hasSanction, m
tab bidder_previousSanction, m
br ca_start_date bidder_hasSanction bidder_previousSanction  sanct_startdate sanct_enddate sanct_name if !missing(sanct_startdate)
*/

********************************************************************************
save $country_folder/MX_171020.dta , replace
********************************************************************************

*Calcluating indicators

tab nocft , m
tab singleb , m 
tab taxhav2 , m
foreach var of varlist nocft singleb taxhav2 {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = . if  `var'==9  //tax haven undefined
}
replace ind_taxhav2_val = .   if  taxhav2==1 //tax haven undefined

tab ind_nocft_val  nocft, m
tab ind_singleb_val  singleb, m
tab ind_taxhav2_val  taxhav2, m
************************************

*For indicators with categories
tab corr_decp, m
tab corr_proc, m
tab corr_submp, m
tab corr_ben, m
foreach var of varlist corr_proc corr_submp corr_decp corr_ben {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_proc_val  corr_proc, m
tab ind_corr_submp_val  corr_submp, m
tab ind_corr_ben_val  corr_ben, m
************************************

*Contract Share
sum w_ycsh4
gen ind_csh_val = w_ycsh4*100
replace ind_csh_val = 100-ind_csh_val
************************************

*Framework
tab ca_framework, m
decode ca_framework, gen (ca_framework_str)
replace ca_framework_str="" if ca_framework_str=="NA"
gen ind_framework_val = 0 if ca_framework_str=="1"
replace ind_framework_val = 100 if  ca_framework_str=="0"
replace ind_framework_val = . if  ca_framework_str==""
************************************

decode ca_type, gen(ca_type_str)
tab ca_type_str, m
replace ca_type_str="" if ca_type_str=="NA"
************************************

tab ca_procedure, m
decode ca_procedure, gen(ca_procedure_str)
replace ca_procedure_str="" if ca_procedure_str=="missing"
tab ca_procedure_str, m
************************************
gen impl= ""
gen proc = ca_procedure_str
gen aw_date2 = ca_start_date
gen bids =ca_nrbid
gen buyer_name =anb_name
gen tender_title =title
gen bidder_name =title
gen tender_supplytype =ca_type_str
gen bid_price =ca_contract_value

foreach var of varlist buyer_name tender_title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids buyer_name tender_title bidder_name tender_supplytype bid_price
br ind_tr_*

********************************************************************************
save $country_folder/MX_171020.dta , replace
********************************************************************************

*Generating lot numbers
use $country_folder/MX_171020.dta, clear 

*Main filter
replace filter_ok=0 if inlist(w_name,"na","0","","no mipyme")
************************************

*Dealing with duplicates
duplicates tag tender_id ca_id, gen(d)
bys  tender_id ca_id: gen x=_n
replace filter_ok=0 if d>0 & x >1
drop d x 

unique tender_id if filter_ok
unique tender_id ca_id if filter_ok

bys tender_id filter_ok: gen x=_N if filter_ok==1
sort tender_id ca_id
br tender_id ca_id anb_name w_name ca_contract_value x if x>1 & filter_ok==1
br tender_id ca_id anb_name w_name ca_contract_value x if missing(ca_id) & filter_ok
************************************

*Creating lot_number & bid_number
bys tender_id filter_ok: gen lot_number=_n if filter_ok
*contracts treated as lots
bys tender_id ca_id filter_ok: gen bid_number=_n  if filter_ok

sort tender_id ca_id
br tender_id ca_id lot_number bid_number if filter_ok

************************************
*Renaming/Fixing variables 

replace title = proper(title)
************************************

tab ca_procedure, m
drop ca_procedure_str
gen  ca_procedure_str=""
replace ca_procedure_str = "OPEN" if ca_procedure==3
replace ca_procedure_str = "OUTRIGHT_AWARD" if ca_procedure==1
replace ca_procedure_str = "APPROACHING_BIDDERS" if ca_procedure==2
replace ca_procedure_str = "OTHER" if ca_procedure==5
replace ca_procedure_str = "" if ca_procedure==4
replace ca_procedure_str = upper(ca_procedure_str)
tab ca_procedure_str, m
************************************

decode ca_procedure_nat, gen(ca_procedure_nat_str)
tab ca_procedure_nat_str , m
replace  ca_procedure_nat_str ="" if  ca_procedure_nat_str=="NA"
br ca_procedure_nat 
tab ca_procedure_nat_str, m
************************************

br *ca_type*
drop ca_type_str
decode ca_type, gen(ca_type_str)
replace ca_type_str = "" if ca_type_str=="NA"
replace ca_type_str=upper(ca_type_str)
replace ca_type_str="SUPPLIES" if ca_type_str=="GOODS"
tab ca_type_str, m
************************************

br *type*
decode anb_type, gen(anb_type_str)
replace anb_type_str = "" if anb_type_str=="NA"
replace anb_type_str= "Administración Pública Federal" if regex(anb_type_str,"^Administrac")
replace anb_type_str= "NATIONAL_AUTHORITY" if anb_type_str=="Administración Pública Federal"
replace anb_type_str= "REGIONAL_AUTHORITY" if anb_type_str=="Gobierno Estatal"
replace anb_type_str= "REGIONAL_AUTHORITY" if anb_type_str=="Gobierno Municipal"
tab anb_type_str, m
************************************

*Dates
br ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline 
*fixed earlier
foreach var of varlist ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline  {
gen dayx = string(day(`var'))
gen monthx = string(month(`var'))
gen yearx = string(year(`var'))
gen `var'_str = yearx + "." + monthx + "." + dayx
drop dayx monthx yearx
drop `var'
rename `var'_str `var'
}
foreach var of varlist ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline  {
replace `var'="" if `var'=="....."
}
br ca_cancel_date ca_end_date ca_start_date cft_date plan_date ca_sign_date plan_modif_date ci_modif_date w_reg_date cft_deadline

drop if inlist(ca_sign_date,"1906.4.21","2021.9.13","2023.6.25","2031.8.9","2047.5.3","2021.5.22","2021.8.3")

*Fixing dates from "1999.3.2" to 1999-03-02
foreach var of varlist ca_sign_date cft_date cft_deadline ca_start_date sanct_startdate sanct_enddate {
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
br ca_sign_date cft_date cft_deadline ca_start_date sanct_startdate sanct_enddate 
************************************

*Product codes
rename cpv lot_productCode
rename aw_item_class_id lot_localproductCode
gen lot_localproductCode_type = "CUCOP" if !missing(lot_localproductCode)

br lot_productCode lot_localproductCode lot_localproductCode_type if missing(lot_localproductCode)
************************************

*Cleaning names
gen len=length(anb_name)
tab len if filter_ok,m
br buyer_name if len<=3 & !missing(anb_name)
replace filter_ok=0 if anb_name=="-"
replace filter_ok=0 if anb_name=="."
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(anb_name,"x","xx","xxx")
replace anb_name=ustrupper(anb_name)
replace anb_name=subinstr(anb_name,"  "," ",.)
replace anb_name=ustrtrim(anb_name)
drop len

gen len=length(w_name)
tab len if filter_ok,m
br w_name len if len<=3 & !missing(w_name) 
replace filter_ok=0 if w_name=="-"
replace filter_ok=0 if w_name=="."
replace filter_ok=0 if w_name=="/,"
replace filter_ok=0 if w_name==".,"
*replace bidder_name=subinstr(bidder_name,","," ",.)
replace filter_ok=0 if len==1
replace filter_ok=0 if inlist(w_name,"x","xx","xxx","a","A","//","X","XX")
replace filter_ok=0 if inlist(w_name,"/.","-,","/",",","-","na")
replace filter_ok=0 if inlist(w_name,"","-,","/",",","-")
replace w_name=ustrupper(w_name)
replace w_name=subinstr(w_name,"  "," ",.)
replace w_name=ustrtrim(w_name)
drop len
************************************

*Contract notice and award variables
cap drop tender_publications_notice_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(w_name)
gen notice_url=""
gen ca_url="https://sites.google.com/site/cnetuc/contrataciones"
gen source="https://sites.google.com/site/cnetuc/descargas"
************************************

gen tender_country = "MX"
************************************

replace aw_curr="" if aw_curr=="NA"
************************************

tab buyer_geocodes, m
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]" if !missing(buyer_geocodes)
************************************

foreach var of varlist bidder_hasSanction bidder_previousSanction {
gen `var'_n = "true" if `var'==1
replace `var'_n = "false" if `var'==0
drop `var'
rename `var'_n `var'
}
************************************

foreach var of varlist anb_id2  w_id2 w_id  {
tostring `var', replace
replace `var' = "" if `var'=="."
}
decode anb_id_detail, gen(anb_id_detail_str)
replace anb_id_detail_str = "" if anb_id_detail_str=="."
drop anb_id_detail
rename anb_id_detail_str anb_id_detail
br anb_id2 anb_id_detail  w_id2 w_id
************************************

decode w_country, gen(w_country_str)
drop w_country
rename w_country_str w_country
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
gen ind_framework_type = "ADMINISTRATIVE_FRAMEWORK_AGREEMENT"
************************************

replace buyer_country="MX" if  buyer_country=="Mexico"
************************************

local temp ""<Fa>" "<E1>""
local temp2 ""ú" "á""
local n_temp : word count `temp'
foreach var of varlist title anb_name w_name {
replace `var'=subinstr(`var',"_","",.) if regex(`var',"^_")
forval s=1/`n_temp'{
 replace `var' =subinstr(`var',"`: word `s' of `temp''","`: word `s' of `temp2''",.) 
}
}
br anb_name if regex(anb_name,"ú")
************************************

replace aw_curr="MXN" if !missing(ca_contract_value_ppp)
************************************

drop if filter_ok==0
************************************

foreach var of varlist title w_name anb_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************

sort  tender_id lot_number bid_number

keep tender_id lot_number bid_number tender_country ca_sign_date cft_deadline ca_procedure_str ca_type_str tender_publications_notice_type cft_date notice_url  source tender_publications_award_type ca_start_date ca_url anb_id2 anb_id_detail buyer_city_api buyer_country_api buyer_geocodes anb_name anb_type_str w_id2 w_id w_country w_name ca_contract_value_ppp ca_contract_value aw_curr bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localproductCode_type lot_localproductCode title ca_nrbid ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_framework_val ind_framework_type 
************************************

order tender_id lot_number bid_number tender_country ca_sign_date cft_deadline ca_procedure_str ca_type_str tender_publications_notice_type cft_date notice_url  source tender_publications_award_type ca_start_date ca_url anb_id2 anb_id_detail buyer_city_api buyer_country_api buyer_geocodes anb_name anb_type_str w_id2 w_id w_country w_name ca_contract_value_ppp ca_contract_value aw_curr bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localproductCode_type lot_localproductCode title ca_nrbid ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_taxhav2_val ind_taxhav2_type ind_corr_proc_val ind_corr_proc_type ind_corr_submp_val ind_corr_submp_type ind_corr_decp_val ind_corr_decp_type ind_corr_ben_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_framework_val ind_framework_type 
************************************

count if missing(tender_id)
count if missing(lot_number)
count if missing(bid_number)
count if missing(anb_id2)
count if missing(anb_name)
count if missing(w_id2)
count if missing(w_name)
count if missing(lot_productCode)
********************************************************************************

export delimited $country_folder/MX_mod.csv, replace
********************************************************************************
*END