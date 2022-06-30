local country "`4'"
************************************************
* Script calculates the market entry indicator: bidder_mkt_entry 
************************************************
*Create temp directories
cap mkdir "${country_folder}/temp"
cap mkdir "${country_folder}/temp/year"
cap mkdir "${country_folder}/temp/year_market"
************************************************
*Prepare market code

cap drop cpv_entry
gen cpv_entry = `1'  // product code - str

*Remove the generated market for missing codes
replace cpv_entry = ""  if inlist(cpv_entry,"99100000","99200000","99300000","99000000","99")
*Generate new market id
cap drop x
gen x=substr(cpv_entry,1,2)
*Clean markets that don't belong to CPV2008 - Two product codes systems in data
cap drop market_id_corr
gen market_id_corr = x if inlist(x,"03","09","14","15","16","18","19") | inlist(x,"22","24","30","31","32","33","34","35","37") | inlist(x,"38","39","41","42","43","44","45","48","50") | inlist(x,"51","55","60","63","64","65","66","70") | inlist(x,"71","72","73","75","76","77","79","80") | inlist(x,"85","90","92","98") 
drop x
************************************************

*Take year as numeric
gen year_main = `2'
destring year_main, replace

*Take id as string
*,"ID"
if inlist("`country'","PY"){
decode `3', gen(supplierid)
}
else {
gen supplierid = `3' //supplier id - str
tostring supplierid, replace

}
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*Only keeping relevent variables and dropping missing rows
* Creating temp files to identify if supplier was in the market 1 or 2 years before

keep if filter_ok == 1
keep supplierid market_id_corr year_main filter_ok
drop if missing(supplierid) | missing(market_id_corr) | missing(year_main)

*Creating Yearly datasets
levelsof year_main, local(years)
foreach year in `years' {
preserve
	keep if year_main == `year'
	save "${country_folder}/temp/year/suppliers_`year'.dta", replace
restore

}

*Creating Yearly datasets - by market
foreach year in `years' {
use "${country_folder}/temp/year/suppliers_`year'.dta", clear
levelsof market_id_corr, local(markets)
foreach market in `markets'{
	preserve
		keep if market_id_corr== "`market'"
		duplicates drop  supplierid market_id_corr, force
		rename year_main year_using
		gen bidder_mkt_entry = 0
		save "${country_folder}/temp/year_market/suppliers_`market'_`year'.dta", replace
	restore
	}
cap erase "${country_folder}/temp/year/suppliers_`year'.dta"
}

*Removing created directory + temp yearly datasets
cap rmdir "${country_folder}/temp/year/"
********************************************************************************
* Generate bidder_mkt_entry
use "${country_folder}/`country'_wip.dta", clear

gen  bidder_mkt_entry = .

forvalues i = 1/2{
gen year_using = year_main - `i'

local files : dir  "${country_folder}/temp/year_market" files "*.dta"
foreach file in `files' {
*  dir `file'
 cap drop match
quietly merge m:1 supplierid market_id_corr year_using using "${country_folder}/temp/year_market/`file'" , keep(1 3 4 5) nogen update 
}
cap drop year_using
}

replace bidder_mkt_entry = 1 if missing(bidder_mkt_entry) & !missing(supplierid) & !missing(year_main) & !missing(market_id_corr)

cap drop cpv_entry

*Clean up local directory
local files : dir  "${country_folder}/temp/year_market" files "*.dta"
foreach file in `files' {
erase "${country_folder}/temp/year_market/`file'" 
}
cap rmdir "${country_folder}/temp/year_market/"
cap rmdir "${country_folder}/temp/year/"
cap rmdir "${country_folder}/temp/"
********************************************************************************
*END
