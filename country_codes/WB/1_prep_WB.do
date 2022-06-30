local country "`0'"
********************************************************************************
/*This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
4) Structures/prepares other control variables used for risk regressions
*/
********************************************************************************
*Data 

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************

*Sector Harmonization

drop ca_sector_new
gen sector = ca_sector
gen x = pr_sector1 + " " + pr_sector2 + " " +pr_sector3 + " " +pr_sector4 + " " +pr_sector5   
replace x = "" if missing(pr_sector1)
// tab sector, m

gen sectorx = lower(x)
replace sector="Water, Sanitation and Waste Management" if regex(sectorx,"water supply") & missing(sector)
replace sector="Water, Sanitation and Waste Management" if regex(sectorx,"sewerage") & missing(sector)
replace sector="Transportation" if regex(sectorx,"urban transport") & missing(sector)
replace sector="Energy and Extractives" if regex(sectorx,"electricity") & missing(sector)
replace sector="Energy and Extractives" if regex(sectorx,"energy") & missing(sector)
replace sector="Education" if regex(sectorx,"education") & missing(sector)
replace sector="Public Administration" if regex(sectorx,"government administration") & missing(sector)
replace sector="Water, Sanitation and Waste Management" if regex(sectorx,"waste management") & missing(sector)
replace sector="Social Protection" if regex(sectorx,"social protection") & missing(sector)
replace sector="Transportation" if regex(sectorx,"transportation") & missing(sector)
replace sector="Water, Sanitation and Waste Management" if regex(sectorx,"sanitation") & missing(sector)
replace sector="Transportation" if regex(sectorx,"roads and highways") & missing(sector)
replace sector="Transportation" if regex(sectorx,"railways") & missing(sector)
replace sector="Water, Sanitation and Waste Management" if regex(sectorx,"water, sanitation") & missing(sector)
replace sector="Health" if regex(sectorx,"health") & missing(sector)
replace sector="Financial Sector" if regex(sectorx,"financial sector") & missing(sector)
replace sector="Agriculture, Fishing and Forestry" if regex(sectorx,"agriculture") & missing(sector)
replace sector="Energy and Extractives" if regex(sectorx,"oil and gas") & missing(sector)
replace sector="Social Protection" if regex(sectorx,"pensions and insurance") & missing(sector)
replace sector="Energy and Extractives" if regex(sectorx,"mining") & missing(sector)
replace sector="Social Protection" if regex(sectorx,"law and justice") & missing(sector)
replace sector="Energy and Extractives" if regex(sectorx,"hydropower") & missing(sector)
replace sector="Agriculture, Fishing and Forestry" if regex(sectorx,"irrigation and drainage") & missing(sector)
replace sector="Information and Communications Technology" if regex(sectorx,"ict") & missing(sector)
replace sector="Public Administration" if regex(sectorx,"housing construction") & missing(sector)


// tab ca_sector, m
// tab sector, m 
drop x sectorx
********************************************************************************
*Add uncategorized codes for the missing entries

// count if missing(cpv_code)
// desc *supply* 
// tab ca_supplytype if missing(cpv_code), m
replace cpv_code = "983900003" if missing(cpv_code) & ca_supplytype=="SERVICES"
replace cpv_code = "99300000" if missing(cpv_code) & ca_supplytype=="WORKS"
replace cpv_code = "99100000" if missing(cpv_code) & ca_supplytype=="GOODS"
replace cpv_code = "99000000" if missing(cpv_code) & ca_supplytype==""
drop cpv_descr
// br cpv_code
********************************************************************************
*Generate filter_ok

// tab year, m
// tab year if !missing(w1_name), m
gen filter_ok=0
replace filter_ok=1 if !missing(w1_name) //Main filter
// tab year if filter_ok, m
********************************************************************************
*Fixing year variable 

// br cft_publdate cft_bid_deadline ca_signdate year if filter_ok==1 & missing(year)
replace year = real(substr(cft_publdate,1,4)) if missing(year) 
replace year = real(substr(ca_signdate,1,4)) if missing(year) 
// tab year if filter_ok, m
// destring year, replace
********************************************************************************
*Market 

// br *cpv*
gen market_id=substr(cpv_code,1,2)
replace market_id="NA" if missing(cpv_code)
encode market_id,gen(market_id2)
drop market_id
rename market_id2 market_id
// tab market_id, m
********************************************************************************
*supply type

// tab ca_supplytype if filter_ok==1, m
gen supply_type = ca_supplytype
replace supply_type="NA" if missing(ca_supplytype)
encode supply_type, gen(ca_supply_type)
drop supply_type
// tab ca_supply_type, m

// tab cft_methodtype if filter_ok==1, m
// tab ca_type if filter_ok==1, m
********************************************************************************
*Buyer location

// br *country* *city*
tab anb_country, m
gen anb_location1 = anb_country
replace anb_location1="NA" if missing(anb_country)
encode anb_location1, gen(anb_location)
drop anb_location1
// tab anb_location, m
********************************************************************************
*Prices

// br  *value*
// br  pr_id tenderid lot_id ca_id cft_sourceid  mca_buyerassignedid c_buyerassignedid pr_borrower_name w1_name ca_lot_value ca_contract_value_original cft_publdate cft_bid_deadline ca_signdate subm_p * if noticetype=="CONTRACT_AWARD"

sort tenderid ca_id lot_id
format pr_borrower_name w1_name %20s
format tenderid %10s
// br tenderid ca_id lot_id *value* pr_borrower_name w1_name if filter_ok==1

bys ca_id: gen lot_count=_N
// gen x = ca_contract_value_original==ca_lot_value
// tab x if filter_ok==1 & lot_count==1, m
// br tenderid ca_id lot_id *value* pr_borrower_name w1_name if filter_ok==1 & lot_count==1 & x==0
// drop x
*drop lot_count

replace ca_contract_value_original=. if ca_contract_value_original==0
replace ca_lot_value=. if ca_lot_value==0
// destring ca_contract_value_original, gen(ca_contract_value_num)
// destring ca_lot_value, gen(ca_lot_value_num)

sort  ca_id lot_id
// br tenderid ca_id lot_id ca_contract_value_num ca_lot_value_num pr_grant_currency pr_borrower_name w1_name if filter_ok==1 & lot_count>1
// br lot_count tenderid ca_id lot_id ca_contract_value_num ca_lot_value_num pr_grant_currency pr_borrower_name w1_name if filter_ok==1 & missing(ca_lot_value_num)


*Getting missing lot values  from contract values if only 1 lot
replace ca_lot_value= ca_contract_value if filter_ok & missing(ca_lot_value) & lot_count==1

// br tenderid ca_id lot_id ca_contract_value_num ca_lot_value_num pr_grant_currency pr_borrower_name w1_name if filter_ok==1 

*Prices are already adjusted 
*ca_contract_value is the final adjusted contract values
xtile ca_contract_value10 = ca_lot_value if filter_ok, nq(10)
replace ca_contract_value10=99 if missing(ca_lot_value )

********************************************************************************
*Dates

sort  ca_id lot_id
gen cft_publ = date(cft_publdate, "YMD")
gen bid_deadline = date(cft_bid_deadline, "YMD")
gen sign_date = date(ca_signdate, "YMD")
format cft_publ bid_deadline sign_date %d
// br tenderid ca_id lot_id cft_publ bid_deadline sign_date year ca_contract_value_num ca_lot_value_num pr_grant_currency pr_borrower_name w1_name if filter_ok==1 & !missing(bid_deadline) & !missing(cft_publ)

// br tenderid ca_id lot_id cft_publdate cft_bid_deadline ca_signdate year corr_submp if  corr_submp=="1"
*Many contracts not connected to cfts to very low submission data in filter_ok==1
********************************************************************************
*Fixing Buyer and Supplier ids

// unique mca_buyerassignedid
// unique c_buyerassignedid
// unique w1_name 
// format mca_buyerassignedid c_buyerassignedid pr_borrower_name w1_name %15s
// br mca_buyerassignedid c_buyerassignedid pr_borrower_name w1_name if filter_ok
************************************
*Creating new buyer and bidder ids

do "${utility_codes}/quick_name_cleaning.do" pr_borrower_name
*Cleaned pr_borrower_name 
egen anb_id=group(pr_borrower_name_clean)
replace anb_id=. if missing(pr_borrower_name_clean)
sort anb_id
// br pr_borrower_name name anb_id

// br pr_borrower_name ca_country pr_borrower_name_clean anb_id if pr_borrower_name_clean=="government"
replace pr_borrower_name_clean = pr_borrower_name_clean + ca_country if pr_borrower_name_clean=="government" & !missing(ca_country)

drop anb_id
egen anb_id=group(pr_borrower_name_clean)
replace anb_id=. if missing(pr_borrower_name_clean)
replace anb_id=. if pr_borrower_name_clean=="government"
// br pr_borrower_name ca_country pr_borrower_name_clean anb_id 
bys anb_id: gen x = _n
replace x = x + 2000
replace anb_id = x if missing(anb_id)
drop x pr_borrower_name_clean
// tostring anb_id, replace
// replace anb_id = "" if anb_id == "."
// unique  anb_id
// br mca_buyerassignedid c_buyerassignedid anb_id pr_borrower_name if filter_ok
// count if missing(mca_buyerassignedid)
// count if missing(anb_id)
************************************

do "${utility_codes}/quick_name_cleaning.do" w1_name
replace w1_name_clean = w1_name if missing(w1_name_clean)
cap drop w_id
egen w_id=group(w1_name_clean)
replace w_id=. if missing(w1_name_clean)
sort w_id
format w1_name_clean %30s
// br w1_name w1_name_clean w_id
// unique w_id
drop w1_name_clean
// tostring w_id, replace
// replace w_id = "" if w_id == "."
********************************************************************************
save "${country_folder}/`country'_wip.dta" , replace
********************************************************************************
*END