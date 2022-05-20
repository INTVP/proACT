//Input country list to run
//Use country ISO code seperated by space
//Example: MT CY PY US
local countries PY

*Macros
local dir : pwd
global utility_codes "`dir'/utility_codes"
global utility_data "`dir'/utility_data"
global R_path_local "C:/Program Files/R/R-4.0.4/bin/x64/Rscript.exe" // Enter local path to Rscript.exe 

*Set seed 
set seed 2389911

*Required packaged installed from SSC
do "${utility_codes}/ssc_install.do"

*Main do file loop
foreach country in `countries'{

global country_folder "`dir'/country_codes/`country'"

if "`country'" != "US"{
*Pre prep scripts for CL,CO,UY,MX and PY to transform differnt product classifications to CPV2008
if inlist("`country'","CL","CO","UY","MX","PY") do "${country_folder}/0_A_cpv_correspondance_`country'.do" `country'
*Pre prep scripts for IN, WorldBank and Inter-American Development Bank data using matchit (availble from SSC) to match tender titles to CPV2008
if inlist("`country'","IN","WB","IDB") do "${country_folder}/0_A_cpv_matchit_`country'.do" `country'
*Pre prep scripts for MX and IN using keywords in the tender titles to assign CPV2008 product codes 
if inlist("`country'","MX","IN") do "${country_folder}/0_B_cpv_manual_`country'.do" `country'
*Pre prep scripts for MX using matchit (availble from SSC) to match tender titles to CPV2008 
if inlist("`country'","MX") do "${country_folder}/0_C_cpv_matchit_`country'.do" `country'
*Pre prep scripts for MX using the geolocation API to geolocate procurment authorities
if inlist("`country'","MX") do "${country_folder}/0_D_locations_buyers_api_`country'.do" `country'
*Pre prep scripts for PY to manually locate procurment authorities from an older dataset - matching
if inlist("`country'","PY") do "${country_folder}/0_B_locations_buyers_manual_`country'.do" `country'
*Pre prep scripts for WorldBank data to merge historical bidders count information from an older dataset
if inlist("`country'","WB") do "${country_folder}/0_B_singlebidding_merge_`country'.do" `country'

if inlist("`country'","ID","UG") {
*Pre prep scripts for ID and UG using keywords in the tender titles to assign CPV2008 product codes 
! "$R_path_local" "${country_folder}/0_A_cpv_manual_`country'.R" ${country_folder}
}
*Pre prep scripts for ID and UG using matchit (availble from SSC) to match tender titles to CPV2008
if inlist("`country'","ID","UG") do "${country_folder}/0_B_cpv_matchit_`country'.do" `country'
*Pre prep scripts for GE using the geolocation API to geolocate procurment authorities
if inlist("`country'","GE") do "${country_folder}/0_A_locations_buyers_`country'.do" `country'
*Pre prep scripts for ID to manually locate procurment authorities
if inlist("`country'","ID") do "${country_folder}/0_C_locations_buyers_merge_`country'.do" `country'
*Pre prep scripts for IDB using the geolocation API to geolocate procurment authorities
if inlist("`country'","IDB") do "${country_folder}/0_B_locations_suppliers_here_`country'.do" `country'

*Prep scripts to handle price conversions, creates main filters and generates control/aucillary variables used in the following scripts
do "${country_folder}/1_prep_`country'.do" `country'
*Indicator scripts used to generate all the cooruption risk indicators
do "${country_folder}/2_indicators_`country'.do" `country'
*Mod scripts to create the XX_mod.csv (final output) used by the reverse flatten tool
do "${country_folder}/3_mod_`country'.do" `country'

}

else if "`country'" == "US" {
*US is an exception and has it's own script which contains the complete process
! "$R_path_local" "${country_folder}/full_process_`country'.R" ${country_folder} ${utility_codes} ${utility_data}
}
}
*End