*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script is early stage script that translates the UNSPC codes to CPV*/
********************************************************************************

*Data
use $country_folder/PY_wip.dta, clear
********************************************************************************

gen product_str =  tender_cpvs  
desc  product_str
replace product_str = strtrim(product_str)
replace product_str = stritrim(product_str)
replace product_str = strltrim(product_str)

gen cpv_div =""
replace cpv_div = "03" if regex(product_str,"^10")
replace cpv_div = "09" if regex(product_str,"^15")
replace cpv_div = "14" if regex(product_str,"^11")
replace cpv_div = "19" if regex(product_str,"^1116")
replace cpv_div = "15" if regex(product_str,"^50")
replace cpv_div = "16" if regex(product_str,"^21")
replace cpv_div = "18" if regex(product_str,"^53")
replace cpv_div = "18" if regex(product_str,"^54")
replace cpv_div = "19" if regex(product_str,"^13")
replace cpv_div = "03" if regex(product_str,"^131015")
replace cpv_div = "22" if regex(product_str,"^55")
replace cpv_div = "22" if regex(product_str,"^14")
replace cpv_div = "24" if regex(product_str,"^12")
replace cpv_div = "30" if regex(product_str,"^44")
replace cpv_div = "31" if regex(product_str,"^39")
replace cpv_div = "31" if regex(product_str,"^32")
replace cpv_div = "32" if regex(product_str,"^43")
replace cpv_div = "48" if regex(product_str,"^4323")
replace cpv_div = "32" if regex(product_str,"^4513")
replace cpv_div = "33" if regex(product_str,"^42")
replace cpv_div = "33" if regex(product_str,"^51")
replace cpv_div = "34" if regex(product_str,"^25")
replace cpv_div = "35" if regex(product_str,"^46")
replace cpv_div = "37" if regex(product_str,"^60")
replace cpv_div = "37" if regex(product_str,"^49")
replace cpv_div = "38" if regex(product_str,"^41")
replace cpv_div = "38" if regex(product_str,"^4511")
replace cpv_div = "38" if regex(product_str,"^4512")
replace cpv_div = "38" if regex(product_str,"^4514")
replace cpv_div = "39" if regex(product_str,"^56")
replace cpv_div = "39" if regex(product_str,"^52")
replace cpv_div = "39" if regex(product_str,"^47")
replace cpv_div = "41" if regex(product_str,"^4710")
replace cpv_div = "42" if regex(product_str,"^23")
replace cpv_div = "42" if regex(product_str,"^26")
replace cpv_div = "42" if regex(product_str,"^27")
replace cpv_div = "44" if regex(product_str,"^24")
replace cpv_div = "42" if regex(product_str,"^2410")
replace cpv_div = "42" if regex(product_str,"^48")
replace cpv_div = "42" if regex(product_str,"^4510")
replace cpv_div = "43" if regex(product_str,"^20")
replace cpv_div = "43" if regex(product_str,"^22")
replace cpv_div = "44" if regex(product_str,"^95")
replace cpv_div = "44" if regex(product_str,"^30")
replace cpv_div = "44" if regex(product_str,"^31")
replace cpv_div = "44" if regex(product_str,"^40")
replace cpv_div = "45" if regex(product_str,"^72")
replace cpv_div = "45" if regex(product_str,"^73")
replace cpv_div = "50" if regex(product_str,"^731521")
replace cpv_div = "50" if regex(product_str,"^7818")
replace cpv_div = "55" if regex(product_str,"^9010")
replace cpv_div = "55" if regex(product_str,"^9011")
replace cpv_div = "60" if regex(product_str,"^7811")
replace cpv_div = "63" if regex(product_str,"^9012")
replace cpv_div = "63" if regex(product_str,"^7812")
replace cpv_div = "63" if regex(product_str,"^7813")
replace cpv_div = "63" if regex(product_str,"^7814")
replace cpv_div = "63" if regex(product_str,"^7820")
replace cpv_div = "64" if regex(product_str,"^7810")
replace cpv_div = "64" if regex(product_str,"^8311")
replace cpv_div = "64" if regex(product_str,"^831216")
replace cpv_div = "64" if regex(product_str,"^831217")
replace cpv_div = "65" if regex(product_str,"^8310")
replace cpv_div = "66" if regex(product_str,"^84")
replace cpv_div = "66" if regex(product_str,"^64")
replace cpv_div = "79" if regex(product_str,"^80")
replace cpv_div = "70" if regex(product_str,"^8013")
replace cpv_div = "73" if regex(product_str,"^81")
replace cpv_div = "71" if regex(product_str,"^8110")
replace cpv_div = "72" if regex(product_str,"^8111")
replace cpv_div = "72" if regex(product_str,"^8116")
replace cpv_div = "75" if regex(product_str,"^93")
replace cpv_div = "75" if regex(product_str,"^92")
replace cpv_div = "76" if regex(product_str,"^71")
replace cpv_div = "77" if regex(product_str,"^70")
replace cpv_div = "80" if regex(product_str,"^86")
replace cpv_div = "85" if regex(product_str,"^85")
replace cpv_div = "90" if regex(product_str,"^77")
replace cpv_div = "90" if regex(product_str,"^76")
replace cpv_div = "92" if regex(product_str,"^831215")
replace cpv_div = "92" if regex(product_str,"^9013")
replace cpv_div = "92" if regex(product_str,"^9014")
replace cpv_div = "92" if regex(product_str,"^9015")
replace cpv_div = "92" if regex(product_str,"^82")
replace cpv_div = "98" if regex(product_str,"^94")
replace cpv_div = "98" if regex(product_str,"^91")
replace cpv_div = "99" if missing(product_str)
replace product_str="" if product_str=="."
********************************************************************************

*Creating cpv2 descriptions
gen cpv_div_descr=""
replace cpv_div_descr = "Agricultural, farming, fishing, forestry and related products" if cpv_div=="03"
replace cpv_div_descr = "Petroleum products, fuel, electricity and other sources of energy" if cpv_div=="09"
replace cpv_div_descr = "Mining, basic metals and related products" if cpv_div =="14"
replace cpv_div_descr = "Food, beverages, tobacco and related products" if cpv_div =="15"
replace cpv_div_descr = "Agricultural machinery" if cpv_div =="16"
replace cpv_div_descr = "Clothing, footwear, luggage articles and accessories" if cpv_div =="18"
replace cpv_div_descr = "Leather and textile fabrics, plastic and rubber materials" if cpv_div =="19"
replace cpv_div_descr = "Printed matter and related products" if cpv_div =="22"
replace cpv_div_descr = "Chemical products" if cpv_div =="24"
replace cpv_div_descr = "Office and computing machinery, equipment and supplies except furniture and software packages" if cpv_div =="30"
replace cpv_div_descr = "Electrical machinery, apparatus, equipment and consumables; lighting" if cpv_div =="31"
replace cpv_div_descr = "Radio, television, communication, telecommunication and related equipment" if cpv_div =="32"
replace cpv_div_descr = "Medical equipments, pharmaceuticals and personal care products" if cpv_div =="33"
replace cpv_div_descr = "Transport equipment and auxiliary products to transportation" if cpv_div =="34"
replace cpv_div_descr = "Security, fire-fighting, police and defence equipment" if cpv_div =="35"
replace cpv_div_descr = "Musical instruments, sport goods, games, toys, handicraft, art materials and accessories" if cpv_div =="37"
replace cpv_div_descr = "Laboratory, optical and precision equipments (excl. glasses)" if cpv_div =="38"
replace cpv_div_descr = "Furniture (incl. office furniture), furnishings, domestic appliances (excl. lighting) and cleaning products" if cpv_div =="39"
replace cpv_div_descr = "Collected and purified water" if cpv_div =="41"
replace cpv_div_descr = "Industrial machinery" if cpv_div =="42"
replace cpv_div_descr = "Machinery for mining, quarrying, construction equipment" if cpv_div =="43"
replace cpv_div_descr = "Construction structures and materials; auxiliary products to construction (except electric apparatus)" if cpv_div =="44"
replace cpv_div_descr = "Construction work" if cpv_div =="45"
replace cpv_div_descr = "Software package and information systems" if cpv_div =="48"
replace cpv_div_descr = "Repair and maintenance services" if cpv_div =="50"
replace cpv_div_descr = "Installation services (except software)" if cpv_div =="51"
replace cpv_div_descr = "Hotel, restaurant and retail trade services" if cpv_div =="55"
replace cpv_div_descr = "Transport services (excl. Waste transport)" if cpv_div =="60"
replace cpv_div_descr = "Supporting and auxiliary transport services; travel agencies services" if cpv_div =="63"
replace cpv_div_descr = "Postal and telecommunications services" if cpv_div =="64"
replace cpv_div_descr = "Public utilities" if cpv_div =="65"
replace cpv_div_descr = "Financial and insurance services" if cpv_div =="66"
replace cpv_div_descr = "Real estate services" if cpv_div =="70"
replace cpv_div_descr = "Architectural, construction, engineering and inspection services" if cpv_div =="71"
replace cpv_div_descr = "IT services: consulting, software development, Internet and support" if cpv_div =="72"
replace cpv_div_descr = "Research and development services and related consultancy services" if cpv_div =="73"
replace cpv_div_descr = "Administration, defence and social security services" if cpv_div =="75"
replace cpv_div_descr = "Services related to the oil and gas industry" if cpv_div =="76"
replace cpv_div_descr = "Agricultural, forestry, horticultural, aquacultural and apicultural services" if cpv_div =="77"
replace cpv_div_descr = "Business services: law, marketing, consulting, recruitment, printing and security" if cpv_div =="79"
replace cpv_div_descr = "Education and training services" if cpv_div =="80"
replace cpv_div_descr = "Health and social work services" if cpv_div =="85"
replace cpv_div_descr = "Sewage, refuse, cleaning and environmental services" if cpv_div =="90"
replace cpv_div_descr = "Recreational, cultural and sporting services" if cpv_div =="92"
replace cpv_div_descr = "Other community, social and personal services" if cpv_div =="98"
replace cpv_div_descr = "Uncategorized" if cpv_div =="99"
********************************************************************************

drop product_str 
rename tender_cpvs tender_unspsc_original
label var tender_unspsc_original "Source product code - UNSPSC"
label var cpv_div "CPV division tranlsation of original UNSPSC code"
label var cpv_div_descr "CPV division description"
********************************************************************************
save $country_folder/PY_wip.dta, replace
********************************************************************************
*END