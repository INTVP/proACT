*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************

*Data 
use $country_folder/PY_wip.dta, replace
********************************************************************************

*Dropping Missing variables
drop tender_isawarded tender_supplytype tender_iscentralprocurement tender_isjointprocurement tender_onbehalfof_count tender_isonbehalfof tender_npwp_reasons tender_isframeworkagreement tender_isdps tender_estimateddurationindays tender_iseufunded tender_iselectronicauction tender_iscoveredbygpa tender_eligiblebidlanguages lot_othereumemberstatescompanies lot_noneumemberstatescompaniesbi lot_foreigncompaniesbidscount lot_amendmentscount bid_issubcontracted bid_isconsortium tender_personalrequirements_leng tender_technicalrequirements_len tender_economicrequirements_leng tender_indicator_integrity_singl tender_indicator_administrative_ tender_indicator_integrity_adver tender_indicator_integrity_decis tender_iscoveredbygpa tender_indicator_integrity_call_ tender_indicator_integrity_tax_h tender_indicator_integrity_singl tender_indicator_integrity_adver tender_indicator_integrity_decis tender_indicator_integrity_call_ tender_indicator_integrity_proce tender_indicator_integrity_new_c
*drop  v92-tender_indicator_integrity_cost_
*drop  tender_cancellationdate cancellation_reason
*drop tender_selectionmethod  lot_bidscount-lot_smebidscount lot_updatedcompletiondate buyer_nuts bid_subcontractedproportion opentender payments_sum last_payment_year
********************************************************************************

*Variable transformation
rename tender_title ca_title

gen tender_biddeadline2 = subinstr(tender_biddeadline, "-", "", .)
replace tender_biddeadline2="" if tender_biddeadline2=="NA"
drop tender_biddeadline

gen cft_bid_deadline=date(tender_biddeadline2, "YMD")
format cft_bid_deadline %td
label var cft_bid_deadline "deadline for submitting bids"
drop tender_biddeadline2

rename tender_lotscount ca_lotscount
rename tender_recordedbidscount ca_recordedbidscount
rename tender_documents_count ca_documents_count

gen tender_contractsignaturedate2 = subinstr(tender_contractsignaturedate, "-", "", .)
replace tender_contractsignaturedate2="" if tender_contractsignaturedate2=="NA"

gen ca_contractsignaturedate=date(tender_contractsignaturedate2, "YMD")
format ca_contractsignaturedate %td
drop tender_contractsignaturedate tender_contractsignaturedate2

rename tender_awardcriteria_count ca_awardcritcount
label var ca_awardcritcount "Number of award criteria"

gen ca_awarddecdate=date(tender_awarddecisiondate, "YMD")
format ca_awarddecdate %td
label var ca_awarddecdate "Award decision date"
*99.9% missing
drop ca_awarddecdate
drop tender_awarddecisiondate

* Prices
rename tender_estimatedprice ca_tender_est_value_inlots
label var ca_tender_est_value_inlots "Total estimated value of all lots"

destring lot_estimatedprice, replace force
rename lot_estimatedprice ca_est_value
label var ca_est_value "Estimated value of awarded contract"
drop ca_est_value
*completely missing

rename tender_finalprice ca_tender_value
label var ca_tender_value "total value of contract award notice, PYG, without VAT"

rename bid_price ca_contract_value
label var ca_contract_value "Value of awarded contract"

destring tender_corrections_count, replace force
rename tender_corrections_count ca_corrections_count
label var ca_corrections_count "Number of corrections related to the tender"

*Structure variables
label var lot_row_nr "Unique lot identifier within a given tender"
*completely missing
drop lot_row_nr
 
rename lot_title ca_lot_title 
label var ca_lot_title "Lot title"

rename lot_bidscount ca_tbids 
label var ca_tbids "Total number of bids submitted for a given lot"
*completely missing
drop ca_tbids

rename lot_validbidscount ca_bids
label var ca_bids "Total number of valid bids submitted for a given lot"
*completely missing
drop ca_bids

rename lot_electronicbidscount ca_electronicbidscount 
label var ca_electronicbidscount "Number of electronic bids"
*completely missing
drop ca_electronicbidscount

rename lot_smebidscount ca_smebidscount 
label var ca_smebidscount "Number of sme bids count"
*completely missing
drop ca_smebidscount

* Buyer related variables
rename buyer_id anb_id
lab var anb_id "Announcing body ID from source"

rename buyer_masterid anb_masterid
lab var anb_masterid "Announcing body master ID"

// rename buyer_name anb_name
// lab var anb_name "Announcing body name"

rename buyer_nuts anb_nuts
lab var anb_nuts "Announcing body NUTS code"

rename buyer_email anb_email
lab var anb_email "Announcing body email"

rename buyer_contactname anb_contactname
lab var anb_contactname "Announcing body contact name"

rename buyer_contactpoint anb_contactpoint
lab var anb_contactpoint "Announcing body contact point"

rename buyer_city anb_city
lab var anb_city "Announcing body town"
*8 obs

rename buyer_country anb_country
lab var anb_country "Announcing body country"
*4 obs

rename buyer_postcode anb_postcode
lab var anb_postcode "Announcing body postcode"

drop tender_maincpv tender_selectionmethod cancellation_reason lot_updatedcompletiondate buyer_mainactivities bid_subcontractedproportion opentender payments_sum last_payment_year 
drop anb_nuts 

* Other vars

rename bidder_id w_id
label variable w_id "Winner ID from source"

rename bidder_masterid w_masterid
label var w_masterid "Winner master ID"

rename bidder_name w_name
label var w_name "Name of the winner" 

rename bidder_nuts w_nuts
label var w_nuts "NUTS code of the winner"

rename bidder_city w_city
label var w_city "City of the winner"

rename bidder_country w_country
label var w_country "Country of the winner"

**********************************
gen iswinningbid=.
replace iswinningbid=0 if bid_iswinning=="f"
replace iswinningbid=1 if bid_iswinning=="t"
label var iswinningbid "Whether the bid was winning"
**********************************

rename award_count ca_award_count

rename notice_count ca_cft_count

rename source source_website

rename tender_publications_lastcontract ca_url

gen ca_date_first=date(tender_publications_firstdcontra, "YMD")
format ca_date_first %td
label var ca_date_first "First contract award publication date"

rename notice_url cft_url

gen cft_date_last=date(tender_publications_lastcallfort, "YMD")
format cft_date_last %td
label var cft_date_last "date of last call for tenders"

gen cft_date_first=date(tender_publications_firstcallfor, "YMD")
format cft_date_first %td
label var cft_date_first "date of first call for tenders"

rename tender_year year

rename savings ca_savings
rename award_period_length ca_award_periodlength
rename tender_addressofimplementation_n ca_nuts
lab var ca_nuts "NUTS code of main site of work"
rename tender_description_length ca_description_length
rename lot_description_length ca_lot_description_length 
rename tender_digiwhist_price tender_price_dw
rename bid_digiwhist_price contract_price_dw
********************************************************************************

*Filter_ok
* filtering out irrelevant/unreliable observations

tab filter_ok
drop filter_ok
gen filter_ok=1
replace filter_ok=0 if missing(w_name) | bid_iswinning=="f" | bid_iswinning==""
tab filter_ok
tab year, missing, if filter_ok==1  

gen filter_drop=!missing(w_name) //*Data includes losing bidders - create a new filter for data export

*****************************

encode anb_masterid, gen(anb_masterid_n)
drop anb_masterid
rename anb_masterid_n anb_masterid

encode w_masterid, gen(w_masterid_n)
drop w_masterid
rename w_masterid_n w_masterid

encode w_id, gen(w_id_n)
sum w_id_n w_masterid

encode w_country, gen(w_country_n)
drop w_country
rename w_country_n w_country
********************************************************************************

*Buyer type

* generate missing buyer type from buyer name
gen anb_name2 = anb_name
replace anb_name2 = subinstr(anb_name, "á", "a", .) 
replace anb_name2 = subinstr(anb_name, "Á", "A", .) 
replace anb_name2 = subinstr(anb_name, "é", "e", .) 
replace anb_name2 = subinstr(anb_name, "É", "e", .) 
replace anb_name2 = subinstr(anb_name, "í", "i", .) 
replace anb_name2 = subinstr(anb_name, "Í", "i", .) 
replace anb_name2 = subinstr(anb_name, "ó", "o", .) 
replace anb_name2 = subinstr(anb_name, "Ó", "o", .) 
replace anb_name2 = subinstr(anb_name, "ú", "u", .) 
replace anb_name2 = subinstr(anb_name, "Ú", "u", .) 
replace anb_name2 = subinstr(anb_name, "ü", "u", .) 
replace anb_name2 = subinstr(anb_name, "Ü", "u", .) 
replace anb_name2 = subinstr(anb_name, "ñ", "n", .) 
replace anb_name2 = subinstr(anb_name, "Ñ", "N", .) 
replace anb_name2 = subinstr(anb_name, "Ãº", "u", .) 


gen fed_govt = regexm(anb_name2, "Ministerio") | regexm(anb_name2, "Secretaria") | regexm(anb_name2, "Presidencia") | regexm(anb_name2, "Vicepresidencia")
gen federal_body = regexm(anb_name2, "Nacional") | regexm(anb_name2, "Nac.") | regexm(anb_name2, "Servicio Nacional")
gen state_govt = regexm(anb_name2, "Gobierno Departamental") 
gen municipal_govt = regexm(anb_name2, "Municipalidad")
gen university = regexm(anb_name2, "Universidad")
gen hospital = regexm(anb_name2, "Hospital")
gen justice = regexm(anb_name2, "Justicia") | regexm(anb_name2, "Procuraduria General de la Republica") | regexm(anb_name2, "Jurado de Enjuiciamiento")
gen national_funds_banks = regexm(anb_name2, "Caja") | regexm(anb_name2, "Fondo") | regexm(anb_name2, "Banco") 
gen other = regexm(anb_name2, "Agencia Financiera") | regexm(anb_name2, "Instituto") | regexm(anb_name2, "Autoridad Reguladora") | regexm(anb_name2, "Canas Paraguayas") | regexm(anb_name2, "Compania Paraguaya") | regexm(anb_name2, "Consejo de") | regexm(anb_name2, "Contraloria General") | regexm(anb_name2, "Credito Agricola") | regexm(anb_name2, "Defensoria del") | regexm(anb_name2, "Delegacion") | regexm(anb_name2, "Delegation") | regexm(anb_name2, "Direccion de Beneficencia") | regexm(anb_name2, "Ente Regulador") | regexm(anb_name2, "Defensoria del") | regexm(anb_name2, "Honorable Camara") | regexm(anb_name2, "Industria Nacional") | regexm(anb_name2, "Petroleos") | regexm(anb_name2, "Sindicatura") | regexm(anb_name2, "Servicios Sanitarios")

gen anb_type=.
replace anb_type=1 if fed_govt==1
replace anb_type=2 if federal_body==1
replace anb_type=3 if state_govt==1
replace anb_type=4 if municipal_govt==1
replace anb_type=5 if university==1
replace anb_type=6 if hospital==1
replace anb_type=7 if justice==1
replace anb_type=8 if national_funds_banks==1
replace anb_type=9 if other==1
replace anb_type=10 if anb_type==.

label define anb_type 1 "Federal Government" 2 "Federal Body" 3 "State Government" 4 "Municipal Government" 5 "University" 6 "Hospital" 7 "Justice" 8 "National Funds and Banks" 9 "Other" 10"missing"
label var anb_type "Announcing body type"
label values anb_type anb_type 
tab anb_type, missing
*got 79% of buyers categorised
tab anb_type if filter_ok==1
drop anb_name2
********************************************************************************

*Contract value variables
br *value*
*Estimated: ca_tender_est_value_inlots
*Tender value: ca_tender_value
*Contract value: ca_contract_value- lot_updatedprice

sort tender_id ca_lotscount
format ca_lot_title %12s
br tender_id ca_lotscount ca_recordedbidscount bid_iswinning ca_lot_title ca_contract_value lot_updatedprice ca_tender_value ca_tender_est_value_inlots
*ca_contract_value is the main price variable

tab currency, m
tab source, m
tab currency if source=="http://ted.europa.eu", m
tab bid_iswinning if source=="http://ted.europa.eu", m //one tender from ted dropped
tab tender_id if source=="http://ted.europa.eu", m //one winning tender from ted dropped
drop if source=="http://ted.europa.eu"
*Assuming all currency is Local 
********************************************************************************
save $country_folder/PY_wip.dta, replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use $utility_data/wb_ppp_data.dta, clear
keep if inlist(countryname,"Paraguay")
drop if ppp==.
keep year ppp
save $country_folder/ppp_data_py.dta
********************************************************************************
use $country_folder/PY_wip.dta, clear
*Fixing the year variable
tab year if filter_ok, m //all good

merge m:1 year using $country_folder/ppp_data_py.dta
drop if _m==2
tab year if _m==1, m //2020 no ppp data
tabstat ppp, by(year)
replace ppp=2558.022 if missing(ppp) & year==2020 //used 2019
br year ppp if _m==3
drop  _m
rename ppp ppp_pyg
*****************************
br ca_contract_value lot_updatedprice ca_tender_value ca_tender_est_value_inlots currency
tab currency, m
*Local source assume PYG

foreach var of varlist ca_contract_value lot_updatedprice ca_tender_value ca_tender_est_value_inlots{
gen `var'_ppp=`var'/ppp_pyg if !missing(`var')
}

count if missing(ca_contract_value) & filter_ok
count if missing(ca_contract_value_ppp) & filter_ok //OK!

gen curr_ppp = ""
replace curr_ppp = "International Dollars" if !missing(ca_contract_value_ppp) | !missing(lot_updatedprice_ppp) | !missing(ca_tender_value_ppp) | !missing(ca_tender_est_value_inlots_ppp)

br ca_contract_value lot_updatedprice ca_tender_value ca_tender_est_value_inlots currency ca_contract_value_ppp lot_updatedprice_ppp ca_tender_value_ppp ca_tender_est_value_inlots_ppp curr_ppp
********************************************************************************

*Contract Value
hist ca_contract_value_ppp if filter_ok
gen lca_contract_value = log(ca_contract_value_ppp)
hist lca_contract_value if filter_ok
xtile ca_contract_value10 = ca_contract_value_ppp if filter_ok, nq(10)
replace ca_contract_value10 = 99 if missing(ca_contract_value_ppp)
tab ca_contract_value10 if filter_ok, m

tabstat ca_contract_value_ppp if filter_ok, m by(ca_contract_value10) stat(min max n)
************************************

*CPV and Market ids
br cpv_div tender_unspsc_original
*UNSPSC codes were transformed to cpv-divisions(2 char)
*cpv_div - transform to fill code using zeros

tab cpv_div, m

replace cpv_div="99" if missing(cpv_div)
br cpv_div tender_unspsc_original if cpv_div=="99" //some of the local codes did not fit in the cpv_dic so switched to missing.
replace  cpv_div=cpv_div +"000000" if !missing(cpv_div)
rename cpv_div tender_cpvs

gen market_id=substr(tender_cpvs,1,2)
tab market_id, m
replace market_id="NA" if missing(market_id)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
tab market_id, m
************************************

*Buyer type
tab anb_type, m
label list anb_type

gen buyer_type = ""
replace buyer_type = "NATIONAL_AUTHORITY" if inlist(anb_type,1,3)
replace buyer_type = "NATIONAL_AGENCY" if inlist(anb_type,2)
replace buyer_type = "REGIONAL_AUTHORITY" if inlist(anb_type,4)
replace buyer_type = "PUBLIC_BODY" if inlist(anb_type,5,6,7)
replace buyer_type = "OTHER" if inlist(anb_type,8,9)
replace buyer_type = "" if inlist(anb_type,10) | missing(anb_type)
rename anb_type anb_type_enum1

gen buyer_type2 = buyer_type
replace buyer_type2="NA" if missing(buyer_type)
encode buyer_type2, gen(anb_type)
drop buyer_type2
tab anb_type, m //use for regression
tab anb_type_enum1, m //Nori's enumeration from the buyer name
tab buyer_type, m //use for export
************************************

*Locations
br *anb*
unique anb_dept
unique anb_city
unique anb_country

tab anb_country_iso2, m
tab anb_dept_iso , m
tab anb_city_iso, m
drop anb_dept_iso  anb_city_iso //bad codes

tab anb_dept,m
tab anb_city, m
*Standardize the names
count if missing(anb_city) & !missing(anb_dept)

*Clean dept names
replace anb_dept= ustrtitle(anb_dept)
replace anb_dept="Caaguazú" if anb_dept=="Caaguazu"
replace anb_dept="Canindeyú" if anb_dept=="Canindeyu"
replace anb_city= ustrtitle(anb_city)
*Keep the buyer dept only for the NUTS-like code because cities are too detailed

gen x = "PY" if !missing(anb_dept)
*Generating a new grouping for regions
local temp ""Alto Paraguay" "Boquerón" "Presidente Hayes" "Concepción" "Amambay" "San Pedro" "Canindeyú" "Alto Paraná" "Caaguazú" "Caazapá" "Central" "Cordillera" "Guairá" "Itapúa" "Misiones" "Neembucu" "Paraguarí""
local temp2 ""1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" "G" "H""
local n_temp : word count `temp'
gen y=""
forval s=1/`n_temp'{
 replace y = "`: word `s' of `temp2''" if anb_dept=="`: word `s' of `temp''"
}
gen buyer_geocodes=x+y if !missing(anb_dept)
br anb_dept x y buyer_geocodes if !missing(anb_dept) 
drop alpha x y 


*Two level Nuts-like variable 
gen anb_location1 = buyer_geocodes
replace anb_location1="NA" if missing(anb_location1)
encode anb_location1, gen(anb_location)
drop anb_location1
tab anb_location, m //used for regressions
************************************

* No supply type variable
************************************
*Dates
br *publi* *dead* *date*
/*
*All in date formats
cft_bid_deadline
ca_date_first -  coming from tender_publications_firstdcontra
ca_contractsignaturedate-  from tender_contractsignaturedate
cft_date_last - coming from tender_publications_lastcallfort
cft_date_first from tender_publications_firstcallfor
*/

rename cft_bid_deadline bid_deadline
rename cft_date_first first_cft_pub 
rename ca_contractsignaturedate aw_date
replace  aw_date= ca_date_first if missing(aw_date)

format bid_deadline first_cft_pub aw_date %d
********************************************************************************

save $country_folder/PY_wip.dta , replace
********************************************************************************
*END