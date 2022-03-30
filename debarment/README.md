# Debarment
## Table of Content
1. [Requirements](#Requirements)
2. [Debarment data](#Debarment-data)
3. [Procurement data](#Procurement-data)
4. [Matching](#matching)

## Requirements

1. R-script front-end must be added to system path.
If on a Windows machine, run the [`r_cmd_add.bat`][r_cmd_add.bat] **AS ADMINISTRATOR**
2. R-packages
```r
install.packages("dplyr")
install.packages("plyr")
install.packages("readxl")
install.packages("httr")
install.packages("readr")
install.packages("lubridate")
install.packages("stringr")
install.packages("stringi")
install.packages("logger")
install.packages("snakecase")

```

## Debarment data
_The data is acquired in both forms JSON and CSV_

The data comes in two formats, HIVE and JSON. The HIVE files contain more information and thus has more debarment data. The HIVE files have a python script included to convert them to JSON.

We only converted the JSON files to CSV and used that for ease of processing. We used R for the cleaning.

_file [json_to_csv.py][json_to_csv] takes a debarment JSON and converts it to flat CSV_

_file [debarment_prep.R][debarment_prep] contains all the cleaning steps which 
cleans the data for matching_

The countries are cleaned as the following
1. Has a country and cleaned
2. Non ADB Member Country, Cleaned using address & API
3. Non ADB Member Country, Cleaned using Reg-ex Countries pattern
4. Other `countries_list` (MX,PH,PK,UG)

the cleaned file is stored in [`output/debarrment_cleaned.csv`][debarrment_cleaned]

You can run the R-script from the command line

```r
API_KEY <- "YOUR_HERE_API_KEY"
command <- sprintf("Rscript --vanilla codes/debarment_prep.R %s", API_KEY)
system(command)
```
or using `bash`
```bash
export API_KEY=YOUR_HERE_API_KEY
Rscript --vanilla codes/debarment_prep.R API_KEY
```
## Procurement data
We have debarment data for a few countries. The list can be found [here][gsheet_debarment]

For each country, you can run the R file [`main.R`][main.R] for one country cleaning.

Alternatively you can run the following R script for all countries as a subsystems command in R.

```r
country_names_tuple <-
  list(
    c(country_code = 'DE', country =  'Germany'),
    c(country_code = 'ES', country =  'Spain'),
    c(country_code = 'FR', country =  'France'),
    c(country_code = 'ID', country =  'Indonesia'),
    c(country_code = 'IN', country =  'India'),
    c(country_code = 'KE', country =  'Kenya'),
    c(country_code = 'MX', country =  'Mexico'),
    c(country_code = 'NL', country =  'Netherlands'),
    c(country_code = 'SE', country =  'Sweden'),
    c(country_code = 'UG', country =  'Uganda'),
    c(country_code = 'UK', country =  'United Kingdom'),
    c(country_code = 'US', country =  'United States'),
    c(country_code = 'IDB', country =  'IDB'),
    c(country_code = 'WB', country =  'WB')
  )

for (selected_country in country_names_tuple) {
  country_of_interest <- selected_country[["country"]]
  country_code <- selected_country[["country_code"]]
  command <- sprintf("Rscript --vanilla codes/main.R %s %s", country_code, country_of_interest)
  system(command)
}
```

We clean the bidder names in both debarment datasets and procurement datasets in the same steps to ensure no odd changes in the names.

We use exact matching to link the datasets together. The full cleaning steps are:
1. Remove countries' names in the bidder name
2. Remove extra spaces
3. Remove backslashes
4. Remove Hyperlinks starting with http
5. Remove all odd characters. The following list is separated by space: . „ “ ‚ ‘ » « › ‹
6. Standardize Legal forms using the following algorithm (in R):

_note: We collected all possible legal forms on companies in most countries we work with from various source online and from within our datasets. This is not an exhaustive list and subject to modification. The file can be found [here][company_legalforms]_
  * We first start by matching the cleaned bidder names to the legal forms and capture them using Regex. We search for the legal form in each bidder name.
    * We start with legal forms that has spaces. Note that some legal forms are a composite of two legal forms and should not be counted as two legal from. For example in Belgium we have `BV` and also `BV BVBA`, which are two different legal forms. To handle this we capture a legal form and capitalize it and put in into brackets. A bidder name with one legal form, such as, `company 1 bv bvba`, will become, `company 1 (BVBVBA)`. This ensures that `BV` is captured properly.
    * We also remove any legal forms if the bidder name starts with a legal from. This works for example, in Belgium because legal forms are reported in both Dutch and French. 
    * After that we match non-spaced legal forms, in the same way as legal forms with spaces.
    * Any heading or tailing white spaces are removed as well.
  * We do the same cleaning on the sanctioned bidders.

## Matching
Both sanctioned bidders and procurement bidders are simply matched on one to one basis and only matched bidders are kept. The output is then sent to production step after the CRIs and TRIs are calculated. Output file is a CSV where each row is a sanction occurrence. The CSV file has the following columns:
1. `bidder_name`: name of the bidder uncleaned as found in procurement data. This is used to match the sanctions' data back to the CSV that has the CRI and TRI calculations.
2. `startDate`: start date of the sanctions
3. `endDate`: end date of the sanctions
4. `name`: name of sanctioning authority
5. `bidder_hasSanction`: boolean, if the bidder has sanctions or not, 100% TRUE as all bidders in this CSV are sanctioned
6. `bidder_previousSanction`: boolean, If the bidder has more than one sanctions based on var no. 7 "n", then it is TRUE, otherwise it is FALSE.
7. `n`: the number of rows each sanctioned bidder is appearing, indicating multiple sanctions. 

**The sanctions are converted into a JSON object added to the `XX_mod_ind.csv` to be converted into JSON. The codes handling this is [here][schema] and the schema describing the structure can be found [here][indicators_json].**

[schema]: /CSV_to_JSON/validation_node.js/schemas/tender.schema.json
[indicators_json]: /CSV_to_JSON/reverse-flatten-tool_v1.1.2/indicators_json.py
[json_to_csv]: /debarment/codes/json_to_csv.py
[debarment_prep]: /debarment/codes/debarment_prep.R
[main.R]: /debarment/codes/main.R
[gsheet_debarment]: https://docs.google.com/spreadsheets/d/1K0gpBwKqpFy5DgQyFVikx9aILUsMRnArbi5oV4d1xEI/edit?usp=sharing
[codes]: /debarment/codes/
[company_legalforms]: debarment/data_raw/supplementary/company_legalforms.xlsx
[r_cmd_add.bat]: debarment/codes/r_cmd_add.bat
[debarrment_cleaned]: debarment/output/debarrment_cleaned.csv