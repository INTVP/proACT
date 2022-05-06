global github "C:\Users\wb501238\Documents\GitHub\proACT"
global utility_codes "${github}\utility_codes"
global utility_data "${github}\utility_data"

// Select a country to prepare the data

local  country  		"MT" // add 2 letter country code
global country_folder 	"${github}/country_codes/`country'" // I am not sure where this is supposed to point to 


/*******************************************************************************
This script prepares the data for Risk indicator calculation
1) Creates main filter to be used throught analysis
2) Prices ppp adjustments
3) Structures/prepares other control variables used for risk regressions
*******************************************************************************/
do "${country_folder}/1_prep_`country'.do"

/*******************************************************************************
 This script runs the risk indicator models to identify risk thresholds
*******************************************************************************/
do "${country_folder}/2_indicators_`country'.do"

/*******************************************************************************
This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
*******************************************************************************/
do "${country_folder}/3_mod_`country'.do"