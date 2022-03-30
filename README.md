<!-- # ProACT Analytics Portal data pipeline documentation -->

This repository outlines the data pipeline for producing the datasets for the [ProACT Procurement Anticorruption and Transparency platform](https://www.procurementintegrity.org/) from publicly available public procurement datasets of the Government Transparency Institute (GTI).

The project was implemented late 2020 from funding of the World Bank. This documentation allows the user to replicate the data behind the ProACT platform from the source dataset.

Below you can find instructions on navigating the repository and brief
explanations on the main functions of the scripts used.

## Data Navigation
This section describes the different datasets used to create the main output files.

1. Public Procurement data :
GTI publishes its datasets [here](http://www.govtransparency.eu/gtis-global-government-contracts-database/).
For ease of use, it is also possible to get a direct download link to all datasets by writing to info@govtransparency.eu.

2. [Utility datasets](https://github.com/GovTransparencyInstitue/ProACT-2020/tree/main/utility_data) :
 This folder contains all utility datasets used for all countries. For example, it contains the secrecy score index used to identify tax havens,
our own correspondence tables to transform different product classifications to CPV codes, and the World Bank's PPP conversion factor (code: PA.NUS.PPP).

3. Output data :
The output from running the scripts in [./country_codes/](https://github.com/GovTransparencyInstitue/ProACT-2020/tree/main/country_codes)
are the XX_mod.csv data files. These are interim files. The scripts store them in each country folder in the *./[country_codes](https://github.com/GovTransparencyInstitue/ProACT-2020/tree/main/country_codes)* directory.


## Script Navigation

1. [Utility Codes](https://github.com/GovTransparencyInstitue/ProACT-2020/tree/main/utility_codes)
The scripts in this folder are shared by all the country specific scripts.

* [Benford.R](/utility_codes/benford.R) : used to calculate corruption risk indicators based on Benford's law. Documentation of the benford.analysis R package can be found [here](https://www.rdocumentation.org/packages/benford.analysis/versions/0.1.5)

* [cri.do](/utility_codes/cri.do) : used to create the composite risk score using available indicators.

* [country-to-iso.do](/utility_codes/country-to-iso.do) : converts country names to ISO ALPHA-2 codes.

* [iso-to-country.do](/utility_codes/iso-to-country.do) : converts ISO ALPHA-2 codes to country names.

* [quick_name_cleaning](/utility_codes/quick_name_cleaning.do) : removes punctuations and corrupted unicode characters from string variables.

* [transliteration_cleaning](/utility_codes/transliteration_cleaning.do) : transliterates non-latin characters into latin.

2. [Country Specific codes](https://github.com/GovTransparencyInstitue/ProACT-2020/tree/main/country_codes)
The scripts in this folder are the main scripts used to generate the output data. They are to be run in the same alphanumeric order used as the naming convention. There are four types of codes: a) Pre-processing scripts b) Preparation scripts c) Indicator calculation scripts d) MOD scripts

a) **Pre-processing scripts**

These scripts are used in certain of countries to enhance the dataset such as improving the product classification variables and/or the location variables. They are generally named as *0_X_variable_operation_country.do/R* - where *X* refers to the order used to run the pre-processing scripts (A/B/C/D).

The main operations performed by these scripts are:

* CPV correspondence - Product classification is enhanced in three ways. First, different product classifications used in various e-procurement systems are translated into CPV-2008 [See Correspondence table_ProAct2020](/utility_data/Correspondence_table_ProAct2020.xlsx). Second, product codes are added to contracts without one. To find the best product code matches, a function called *[matchit](https://ideas.repec.org/c/boc/bocode/s457992.html)* in Stata was used, which uses the tender and contract titles and descriptions to perform a token based matching to the CPV-2008 categories. Third, a keyword-based search and matching is also implemented in certain countries on the tender and contract titles and descriptions to identify the best product codes.
Example script: `0_C_cpv_matchit_MX.do` - This script is a pre-processing script, to be run as the
third script. It performs a CPV matching by using the `matchit` program on the Mexican dataset.

* Location Fixes - For some countries, locations were run through the [HERE API](https://places.demo.api.here.com/places/) and  [GOOGLE PLACES API](https://developers.google.com/maps/documentation/places/web-service/overview) to GEO-locate some organizations, that were missing the address information on the source e-procurement platform. An ApiKey is required to access both APIs. Some location data were manually collected for certain countries. For ease of use, the organization level additional address information are stored as csvs in each country's utility data directory *./utility_data/country/XX*. The codes on location fixing simply merge the location data tables to the current working dataset.



b) **Preparation scripts**

Preparation scripts are always named as *`0_prep_XX`*. These scripts create the main filters used in the datasets (non-missing supplier organization name) and
generate all the background variables needed for the risk indicator regressions. They also compute the PPP prices - based on the PPP conversion factor, GDP (LCU per international $) indicator (code: PA.NUS.PPP) available from the [World Bank open data](https://data.worldbank.org/).
The downloaded data is restructured and stored [here](/utility_data/wb_ppp_data.dta) in .dta format.

c) **Indicator calculation scripts**

Indicator generating scripts are named *`2_indicators_XX`*. These allow to re-run all validity tests behind each individual corruption risk indicator.
This script create all the risk indicators and the composite risk score for all countries. All the assigned risk thresholds are in the [CRI_definitions_ProAct2020](/utility_data/CRI_definitions_ProAct2020.docx) sheet.

The following risk indicators were calculated whenever underlying data was available: Single bidding, Procedure type, No Call for tender, Submission period, Decision period,
Tax haven ( [The Foreign Secrecy Index](https://fsi.taxjustice.net/en/) from the Tax Justice Network was used to compile [FSI_wide_200812_fin.dta](/utility_data/FSI_wide_200812_fin.dta)),
Public organization and supplier dependency risks, Benford’s law based risk indicator, Delay & Cost Overrun.

The CRI is a standardized risk indicator, that is the average of the elementary indicators, between 0-1 (continuous). Missing values of the elementary indicators are coded as 99 to limit the estimation sample size reduction due to missing values. Missing values by themselves can be a risk category.

d) **MOD scripts**

MOD scripts restructure the datasets, rename some variables, and prepare the data for the reverse flattening tool. They are named *`3_mod_XX`*. These scripts vary between countries.

They also transform the previously calculated risk indicators to their categorical versions to be between 0 (Highest risk), 50 (Medium Risk), 100 (Lowest Risk).
The contract share integrity indicator, like the contract share risk version, is continuous.
Missing values are  coded as missing for the integrity indicators.

Transparency indicators are coded between 0 (missing) and 100 (non-missing). The current transparency indicator list includes: buyer name, title, bidder name, tender supply type, bid price, tender implementation location, national procedure types, number of bids, award decision date.

Finally, variable names and data formats are standardized to avoid any inconsistencies that might have been introduced in previous cleaning steps.

  **US** - For the US data, the [full_process_US.R](./country_codes/US/full_process_US.R) script implements the mentioned three steps in one script.

Once the data files (*_mod.csv*) are ready, they go through a conversion and standardization step. Documentation for this process can be found in [csv_to_json](csv_to_json) folder.

## Debarment

The debarment data full documentation is in the [debarment](debarment) folder.

<!-- ![Imgur](https://i.imgur.com/Armr1OH.png) -->


<img src="https://i.imgur.com/Armr1OH.png" width="200" />



## Author
Government Transparency Institute (http://www.govtransparency.eu/).
