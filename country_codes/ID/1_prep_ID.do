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
use $country_folder/ID_wip.dta, clear
********************************************************************************

*Filter ok main - not missing bidder name

decode w_name, gen(w_name2)
replace w_name2="" if w_name2=="."
drop w_name
rename w_name2 w_name

cap drop filter_ok
gen filter_ok=0
replace filter_ok =1 if !missing(w_name) 

tab filter_ok, m //all included
tab bid_iswinning if filter_ok, m

sort ten_id
br ten_id  ca_nrbid lot_nrbid  buyer_name w_name *value* if  filter_ok


count if missing(ca_url) & filter_ok==1
//0 obs with missing contract url but bidder_name is not missing
************************************
unique ten_id  if filter_ok
bys ten_id: gen x=_N
br x ten_id  ca_nrbid lot_nrbid  buyer_name w_name *value* if  filter_ok & x>1
drop x
*Duplicate ten_id: looks like its a consortium or a framework aggreement
************************************

*Check tender final price - contract price

decode ten_id, gen(ten_id2)
replace ten_id2="" if ten_id2=="."
drop ten_id
rename ten_id2 ten_id

sort  ten_id 
format ten_id buyer_name w_name ten_title_str  %15s
br ten_id  ca_nrbid lot_nrbid  buyer_name w_name *value* ten_title_str if filter_ok 

count if missing(ca_contract_value) & filter_ok
count if missing(ca_tender_est_value) & filter_ok

*Fix currency 
tab ca_currency if filter_ok, m
save $country_folder/ID_wip.dta, replace
********************************************************************************
*Inidcator name: PPP conversion factor, GDP (LCU per international $)
use $utility_data/wb_ppp_data.dta, clear
keep if inlist(countryname,"Indonesia")
drop if ppp==.
keep year ppp
save  $country_folder/ppp_data_id.dta, replace
********************************************************************************
use  $country_folder/ID_wip.dta,clear

tab year, m //fix missing year

*Fixing dates: transforming from num to date format
*Dates
foreach var of varlist ca_signdate cft_date_first cft_date_last cft_deadline  aw_dec_date {
decode `var', gen(`var'2)
replace `var'2="" if `var'2=="."
gen `var'3=date(`var'2, "DMY")
drop `var'2 `var' 
rename `var'3 `var'
format `var' %d
}
br ca_signdate cft_date_first cft_date_last cft_deadline  aw_dec_date if missing(year)

*Use dec date, sign date, deadline 
replace year=year(aw_dec_date) if missing(year)
replace year=year(ca_signdate) if missing(year)
replace year=year(cft_deadline) if missing(year)
************************************
 
*for the missing currency if source is ted then assume EUR
merge m:1 year using  $country_folder/ppp_data_id.dta
drop if _m==2
tab year if _m==1, m //only 3 missing with missing year data
tabstat ppp, by(year)
drop _m 
rename ppp ppp_id
************************************

decode ca_currency, gen(ca_currency2)
replace ca_currency2="" if ca_currency2=="."
drop ca_currency
rename ca_currency2 ca_currency

tab ca_currency if filter_ok,m
br ca_contract_value ca_tender_est_value ca_currency if missing(ca_currency)
 
gen bid_price_ppp = ca_contract_value/ppp_id if ca_currency=="IDR"
gen lot_estimatedprice_ppp = ca_tender_est_value/ppp_id if ca_currency=="IDR"

********************************************************************************
*Preparing Controls 
*contract value, buyer type, tender year, market id, contract supply type, Locations
************************************

*Contract Value
hist bid_price_ppp if filter_ok
hist bid_price_ppp if filter_ok & bid_price_ppp<1000000
hist bid_price_ppp if filter_ok & bid_price_ppp>1000000 & !missing(bid_price_ppp) & bid_price_ppp!=.
cap drop lca_contract_value ca_contract_value10
gen lca_contract_value = log(bid_price_ppp)
hist lca_contract_value if filter_ok
xtile ca_contract_value10 = bid_price_ppp if filter_ok, nq(10)
replace ca_contract_value10 = 99 if missing(bid_price_ppp)

tabstat bid_price_ppp if filter_ok, m by(ca_contract_value10) stat(min max n)
************************************

*Buyer type
tab anb_type, m  
decode anb_type, gen (buyer_type_temp)
replace buyer_type_temp="" if buyer_type_temp=="."
gen buyer_type="NATIONAL_AUTHORITY" if buyer_type_temp=="national authority"
replace buyer_type="NATIONAL_AGENCY" if buyer_type_temp=="independent agency"
replace buyer_type="REGIONAL_AUTHORITY" if buyer_type_temp=="regional authority"
replace buyer_type="REGIONAL_AGENCY" if buyer_type_temp=="local body"
replace buyer_type="PUBLIC_BODY" if buyer_type_temp=="armed forces"
replace buyer_type="OTHER" if buyer_type_temp=="other"
drop buyer_type_temp
rename buyer_type buyer_buyertype
tab buyer_buyertype, m  //use this for the output
rename anb_type anb_type_Nori

gen buyer_type = buyer_buyertype
replace buyer_type="NA" if missing(buyer_type)
encode buyer_type, gen(anb_type)
drop buyer_type
tab anb_type, m
************************************

*Tender year
tab year if filter_ok, m
rename year tender_year
************************************

*Contract type
tab ca_type, m
decode ca_type, gen(tender_supplytype)
replace tender_supplytype="" if tender_supplytype=="."
replace tender_supplytype="" if tender_supplytype=="OTHER"
drop ca_type
************************************

*Supply type
gen supply_type = tender_supplytype
replace supply_type="NA" if missing(tender_supplytype)
encode supply_type, gen(ca_type)
drop supply_type
tab ca_type, m
************************************

*Markets
gen market_id=substr(cpv_code,1,2)
*Clean Market id
tab market_id, m
*Two product codes systems in data
gen market_id2 = market_id if inlist(market_id,"03","09","14","15","16","18","19") | inlist(market_id,"22","24","30","31","32","33","34","35","37") | inlist(market_id,"38","39","41","42","43","44","45","48","50") | inlist(market_id,"51","55","60","63","64","65","66","70") | inlist(market_id,"71","72","73","75","76","77","79","80") | inlist(market_id,"85","90","92","98","99") 
tab market_id2, m

*replace bad codes as missing  - dropping bad codes //937 observations
rename cpv_code tender_cpvs_original
gen tender_cpvs= tender_cpvs_original
replace tender_cpvs = "99100000" if missing(market_id2) & tender_supplytype=="SUPPLIES"
replace tender_cpvs = "99200000" if missing(market_id2) & tender_supplytype=="SERVICES"
replace tender_cpvs = "99300000" if missing(market_id2) & tender_supplytype=="WORKS"
replace tender_cpvs = "99000000" if missing(market_id2) & missing(tender_supplytype)
drop market_id market_id2

gen market_id=substr(tender_cpvs,1,2)
*Clean Market id
tab market_id, m
replace market_id="NA" if missing(market_id)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
tab market_id, m
*Use tender_cpvs as the main product code variable
************************************

*Locations
*Three level Nuts-like variable 
gen anb_location1 = buyer_province
replace anb_location1="NA" if missing(anb_location1)
encode anb_location1, gen(anb_location)
drop anb_location1
tab anb_location, m //used for regressions
********************************************************************************

save $country_folder/ID_wip.dta , replace
********************************************************************************
*END