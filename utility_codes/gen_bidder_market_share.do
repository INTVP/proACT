*Script Calculates the supplier market concentration: bidder_mkt_share
********************************************************************************
* Prepare variables

*Contract value variable - ppp version
gen c_value = `1'

*Using supplierid - generated in generate_corr_market_entry.do
*Using year_main - generated in generate_corr_market_entry.do
*Using market_id_corr - generated in generate_corr_market_entry.do


*Impute contract value for missing contracts
cap drop avg_market_value_year
bys year_main market_id_corr: egen avg_market_value_year = mean(c_value) if filter_ok & (!missing(market_id_corr) & !missing(year_main))
replace c_value= avg_market_value_year if missing(c_value)
********************************************************************************
*Calculate total market value per year & supplier value by year

cap drop total_market_value_year total_market_value_suppl_year bidder_mkt_share
bys year_main market_id_corr: egen total_market_value_year = total(c_value) if filter_ok & (!missing(market_id_corr) & !missing(year_main))
bys year_main market_id_corr supplierid: egen total_market_value_suppl_year = total(c_value) if filter_ok & (!missing(market_id_corr) & !missing(year_main) & !missing(supplierid))
gen bidder_mkt_share = total_market_value_suppl_year/total_market_value_year
********************************************************************************
*Restrict indicator

*Indicator should be undefined/missing for market/year with less than 5 contracts
cap drop nr_contracts_market_year
bys year_main market_id_corr filter_ok: gen nr_contracts_market_year = _N if filter_ok & (!missing(market_id_corr) & !missing(year_main))
replace bidder_mkt_share = . if filter_ok==0
replace bidder_mkt_share = . if nr_contracts_market_year<=10
cap drop nr_contracts_market_year 

********************************************************************************
*Clean up

cap drop total_market_value_year total_market_value_suppl_year avg_market_value_year 
cap drop market_id_corr supplierid c_value year_main
********************************************************************************
*END