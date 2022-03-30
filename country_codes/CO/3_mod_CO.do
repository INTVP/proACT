*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************

*Data
use $country_folder/wb_col_cri201126.dta, clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************

replace sameloc_county=. if sameloc_county==9
replace taxhav2=. if taxhav2==9
************************************

*Calcluating indicators
tab singleb , m 
tab sameloc_county, m
tab nocft, m
tab taxhav2, m

drop xcorr_ben_bi xcorr_proc_bi xnocft xproa_ycsh5 xtaxhav2 xsameloc_county xcorr_rdelay2_bi xsingleb

foreach var of varlist singleb sameloc_county nocft taxhav2 {
tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  //tax haven undefined
}
tab ind_singleb_val  singleb, m
tab ind_sameloc_county_val  sameloc_county, m
tab ind_nocft_val  nocft, m
tab ind_taxhav2_val  taxhav2, m
************************************

tab corr_rdelay2_bi, m
tab corr_proc_bi, m
tab corr_ben_bi
foreach var of varlist corr_rdelay2_bi corr_proc_bi corr_ben_bi {
tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}
tab ind_corr_rdelay2_bi_val  corr_rdelay2_bi, m
tab ind_corr_proc_bi_val  corr_proc_bi, m
tab ind_corr_ben_bi_val  corr_ben_bi, m
************************************

*Contract Share
sum proa_ycsh5
gen ind_csh_val = proa_ycsh5*100
replace ind_csh_val = 100-ind_csh_val
*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
************************************
 
*Transparency
rename buyer_name buyer_name_old
gen buyer_name=proper(buyer_name_n)
gen bidder_name=proper(w_name_final)
decode ca_procedure, gen(ca_proc)
decode ten_title, gen(tender_title)
decode ca_type, gen(tender_supplytype)


gen impl= anb_loc_final
gen proc = ca_proc
gen aw_date2 = aw_date
foreach var of varlist buyer_name tender_title bidder_name tender_supplytype bid_price impl proc aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2

gen ind_tr_bids_val = 0 if ca_nrbid==.
replace ind_tr_bids_val= 100 if ca_nrbid!=.

*rename tr_aw_date2 ind_tr_aw_date2_val

********************************************************************************
*Fixing variables for reverse tool

gen tender_country = "CO"
************************************

*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(ca_start_date)

br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************

foreach var of varlist ca_proc_loc ca_del_loc ca_e_loc w_loc anb_loc sameloc sameloc_county w_county anb_county w_country w_country_iso country_string country sameloc_county {
decode `var', gen(`var'_str)
drop `var'
rename `var'_str `var'
}

foreach var of varlist ca_proc_loc ca_del_loc ca_e_loc w_loc anb_loc sameloc sameloc_county w_county anb_county w_country w_country_iso country_string country sameloc_county {
replace `var'=(`var'_str)
}
************************************
*Fixing Buyer locations

rename anb_loc_final anb_city
replace anb_city="Alto Baudó" if anb_city=="Alto Baudo"
replace anb_city="Ancuya" if anb_city=="Ancuyá"
replace anb_city="Arenal del Sur" if anb_city=="Arenal"
replace anb_city="Bajo Baudó" if anb_city=="Bajo Baudó/Pizarro"
replace anb_city="Belén de Andaquies" if anb_city=="Belén de Los Andaquies"
replace anb_city="Bojayá" if anb_city=="Bojaya"
replace anb_city="Cajibio" if anb_city=="Cajibío"
replace anb_city="Calarcá" if anb_city=="Calarca"
replace anb_city="Campo de La Cruz" if anb_city=="Campo de la Cruz"
replace anb_city="Carurú" if anb_city=="Caruru"
replace anb_city="Castilla la Nueva" if anb_city=="Castilla La Nueva"
replace anb_city="Chámeza" if anb_city=="Chameza"
replace anb_city="Colosó" if anb_city=="Coloso"
replace anb_city="Duranía" if anb_city=="Durania"
replace anb_city="El Cantón de San Pablo" if anb_city=="El Cantón del San Pablo"
replace anb_city="El Piñón" if anb_city=="El Piñon"
replace anb_city="El Tablón" if anb_city=="El Tablón de Gómez"
replace anb_city="Entrerríos" if anb_city=="Entrerrios"
replace anb_city="Fuente de oro" if anb_city=="Fuente de Oro"
replace anb_city="Fómeque" if anb_city=="Fomeque"
replace anb_city="Guayabal de Síquima" if anb_city=="Guayabal de Siquima"
replace anb_city="Gámbita" if anb_city=="Gambita"
replace anb_city="Gámeza" if anb_city=="Gameza"
replace anb_city="La Playa de Belén" if anb_city=="La Playa de Belen"
replace anb_city="Lebrija" if anb_city=="Lebríja"
replace anb_city="Machetá" if anb_city=="Macheta"
replace anb_city="Magüí Payán" if anb_city=="Magüi"
replace anb_city="Medio San Juan" if anb_city=="Medio San Juan/Andagoya"
replace anb_city="Mirití-Paraná" if anb_city=="Miriti-Paraná"
replace anb_city="Roberto Payán" if anb_city=="Roberto Payán/San José"
replace anb_city="Río Iró" if anb_city=="Río Iro"
replace anb_city="Sabanas de San Ángel" if anb_city=="Sabanas de San Angel"
replace anb_city="San Andrés de Sotavento" if anb_city=="San Andrés Sotavento"
replace anb_city="San Estanislao" if anb_city=="San Estanislao de Kostka"
replace anb_city="San Juan Betulia" if anb_city=="San Juan de Betulia"
replace anb_city="Sandoná" if anb_city=="Sandona"
replace anb_city="Santa Fe de Antioquia" if anb_city=="Santafé de Antioquia"
replace anb_city="Suán" if anb_city=="Suan"
replace anb_city="Tibiritá" if anb_city=="Tibirita"
replace anb_city="Tolú" if anb_city=="Tolú Viejo"
replace anb_city="Úmbita" if anb_city=="Umbita"
replace anb_city="Valle del Guamuez" if anb_city=="Valle del Guamuez/La Hormiga"
replace anb_city="Villagarzón" if anb_city=="Villa Garzón/Villa Amazonica"
replace anb_city="Vista Hermosa" if anb_city=="Vistahermosa"
replace anb_city="Yolombó" if anb_city=="Yolombo"

cap drop _m
merge m:m anb_city using $utility_data/country/CO/CO_buyer_city.dta, keep(1 3)
cap drop _m
*https://en.wikipedia.org/wiki/Natural_regions_of_Colombia
*https://en.wikipedia.org/wiki/List_of_cities_and_towns_in_Colombia

*rename buyer_NUTS3 buyer_geocodes
rename anb_loc_final anb_city
rename Department anb_departm

decode anb_county, gen(anb_countystr)
replace anb_countystr = subinstr(anb_countystr, "Â ", "", .) 
replace anb_countystr = subinstr(anb_countystr, ".", "", .) 
replace anb_countystr = subinstr(anb_countystr, "-", "", .)
gen anb_cnty_str = anb_countystr if regexm(anb_countystr, "([a-zA-Z])")

replace anb_departm=anb_cnty_str if anb_departm=="" & anb_cnty_str!=""
tab anb_departm

replace anb_departm="Atlántico" if anb_departm=="AtlĂˇntico" 
replace anb_departm="Bolívar" if anb_departm=="BolĂ­var" 
replace anb_departm="Boyacá" if anb_departm=="BoyacĂˇ" 
replace anb_departm="Caquetá" if anb_departm=="CaquetĂˇ" 
replace anb_departm="Chocó" if anb_departm=="ChocĂł" 
replace anb_departm="Córdoba" if anb_departm=="CĂłrdoba" 
replace anb_departm="Guainía" if anb_departm=="GuainĂ­a" 
replace anb_departm="Nariño" if anb_departm=="Narino" 
replace anb_departm="Quindío" if anb_departm=="QuindĂ­o" 


gen x = "CO" if !missing(anb_city) | !missing(anb_departm)
*Generating a new grouping for natural regions
gen y = .
replace y = 1 if inlist(anb_departm,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace y = 2 if inlist(anb_departm,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace y = 3 if inlist(anb_departm,"Nariño","Cauca","Valle del Cauca","Chocó")
replace y = 4 if inlist(anb_departm,"Meta","Arauca","Casanare","Vichada")
replace y = 5 if inlist(anb_departm,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace y = 6 if inlist(anb_departm,"San Andrés y Providencia")
tab anb_departm y , m
tostring y, replace
replace y ="" if y=="."

*departments
gen z=1 if anb_departm=="Boyacá" | anb_departm=="La Guajira" | anb_departm=="Narino" | anb_departm=="Meta" | anb_departm=="Amazonas" | anb_departm=="San Andrés y Providencia"
replace z=2 if anb_departm=="Caldas" | anb_departm=="Bolívar" | anb_departm=="Cauca" | anb_departm=="Arauca" | anb_departm=="Caquetá" 
replace z=3 if anb_departm=="Capital District" | anb_departm=="Atlántico" | anb_departm=="Valle del Cauca" | anb_departm=="Casanare" | anb_departm=="Guainía"
replace z=4 if anb_departm=="Cundinamarca" | anb_departm=="Cesar" | anb_departm=="Chocó" | anb_departm=="Vichada" | anb_departm=="Putumayo"
replace z=5 if anb_departm=="Huila" | anb_departm=="Magdalena" | anb_departm=="Guaviare" 
replace z=6 if anb_departm=="Norte de Santander" | anb_departm=="Sucre" | anb_departm=="Vaupés" 
replace z=7 if anb_departm=="Quindío" | anb_departm=="Santander" 
replace z=8 if anb_departm=="Risaralda" | anb_departm=="Córdoba" 
replace z=9 if anb_departm=="Tolima" | anb_departm=="Antioquia" 
tostring z, replace 
replace z ="" if z=="."


gen buyer_geocodes=x+y+z
replace buyer_geocodes = subinstr(buyer_geocodes, ".", "", .)
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]"
replace buyer_geocodes="" if !regexm(buyer_geocodes, "CO")
*if buyer nuts is missing it shoud be empty
*for bidder and impl also
*before that check nuts all nuts code and assigned city in a new sheet
************************************

*Fixing IMPL nuts
decode eje_locs1_n, gen(impl_departm)
tab impl_region
gen impl_dpt = substr(impl_departm, 1, strpos(impl_departm, "-") - 1) 
*gen impl_city = regexm(impl_departm, "- ") 
*gen impl_city = impl_departm if regexm(impl_departm, "(["- "]*([a-zA-Z]+)")

decode impl_region, gen(impl_region_str)
replace impl_dpt=impl_region_str if impl_region_str!="" & impl_dpt==""
replace impl_dpt = subinstr(impl_dpt, "Â ", "", .)
replace impl_dpt = subinstr(impl_dpt, "Ăˇ", "á", .)
replace impl_dpt = subinstr(impl_dpt, "Ă©", "é", .)
replace impl_dpt = subinstr(impl_dpt, "Ă­", "í", .)
replace impl_dpt = subinstr(impl_dpt, "Ăł", "ó", .)
replace impl_dpt = subinstr(impl_dpt, "Ă±", "n", .)
replace impl_dpt = subinstr(impl_dpt, "Ĺ„", "n", .)
replace impl_dpt = "Norte de Santander" if impl_dpt=="Norte De Santander"
replace impl_dpt = "San Andrés y Providencia" if impl_dpt=="San Andrés, Providencia y Santa Catalina"

replace impl_dpt=strtrim(impl_dpt)

gen xi = "CO" if !missing(impl_dpt)
*Generating a new grouping for natural regions
gen yi = .
replace yi = 1 if inlist(impl_dpt,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace yi = 1 if inlist(impl_dpt, "Bogotá D.C.")
replace yi = 2 if inlist(impl_dpt,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace yi = 3 if inlist(impl_dpt,"Narino","Cauca","Valle del Cauca","Chocó")
replace yi = 4 if inlist(impl_dpt,"Meta","Arauca","Casanare","Vichada")
replace yi = 5 if inlist(impl_dpt,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace yi = 6 if inlist(impl_dpt,"San Andrés y Providencia")
tab impl_dpt yi , m
tostring yi, replace
replace yi ="" if yi=="."

*departments
gen zi=1 if impl_dpt=="Boyacá" | impl_dpt=="La Guajira" | impl_dpt=="Narino" | impl_dpt=="Meta" | impl_dpt=="Amazonas" | impl_dpt=="San Andrés y Providencia"
replace zi=2 if impl_dpt=="Caldas" | impl_dpt=="Bolívar" | impl_dpt=="Cauca" | impl_dpt=="Arauca" | impl_dpt=="Caquetá" 
replace zi=3 if impl_dpt=="Capital District" | impl_dpt=="Atlántico" | impl_dpt=="Valle del Cauca" | impl_dpt=="Casanare" | impl_dpt=="Guainía"
replace zi=4 if impl_dpt=="Cundinamarca" | impl_dpt=="Cesar" | impl_dpt=="Chocó" | impl_dpt=="Vichada" | impl_dpt=="Putumayo"
replace zi=5 if impl_dpt=="Huila" | impl_dpt=="Magdalena" | impl_dpt=="Guaviare" 
replace zi=6 if impl_dpt=="Norte de Santander" | impl_dpt=="Sucre" | impl_dpt=="Vaupés" 
replace zi=7 if impl_dpt=="Quindío" | impl_dpt=="Santander" 
replace zi=8 if impl_dpt=="Risaralda" | impl_dpt=="Córdoba" 
replace zi=9 if impl_dpt=="Tolima" | impl_dpt=="Antioquia" 
tostring zi, replace 
replace zi ="" if zi=="."
replace zi="A" if impl_dpt=="Bogotá D.C."

gen impl_geocodes=xi+yi+zi
replace impl_geocodes = subinstr(impl_geocodes, ".", "", .)

gen tender_addressofimplementation_c = "["+ `"""' + impl_geocodes + `"""' +"]"
replace tender_addressofimplementation_c="" if impl_geocodes==""
gen tender_addressofimplementation_n=impl_geocodes
tab tender_addressofimplementation_n, m
tab tender_addressofimplementation_c, m
************************************

*Fixing Bidder nuts
sum w_loc w_country w_county w_country_iso w_loc_final

replace w_country_iso=. if w_country_iso==2
decode w_country_iso, gen(w_iso)

gen xw = w_iso 
*Generating a new grouping for regions
replace w_loc_final = "Norte de Santander" if w_loc_final=="Norte De Santander"
replace w_loc_final = "San Andrés y Providencia" if w_loc_final=="San Andrés, Providencia y Santa Catalina"
replace w_loc_final = "Bolívar" if w_loc_final=="Bolivar"

gen yw = .
replace yw = 1 if inlist(w_loc_final,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace yw = 1 if inlist(w_loc_final, "Bogotá D.C.")
replace yw = 2 if inlist(w_loc_final,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace yw = 3 if inlist(w_loc_final,"Narino","Cauca","Valle del Cauca","Chocó")
replace yw = 4 if inlist(w_loc_final,"Meta","Arauca","Casanare","Vichada")
replace yw = 5 if inlist(w_loc_final,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace yw = 6 if inlist(w_loc_final,"San Andrés y Providencia")
replace yw = 7 if w_iso!="CO"
tab w_loc_final yw , m
tostring yw, replace
replace yw ="" if yw=="."


gen zw=1 if w_loc_final=="Boyacá" | w_loc_final=="La Guajira" | w_loc_final=="Narino" | w_loc_final=="Meta" | w_loc_final=="Amazonas" | w_loc_final=="San Andrés y Providencia"
replace zw=2 if w_loc_final=="Caldas" | w_loc_final=="Bolívar" | w_loc_final=="Cauca" | w_loc_final=="Arauca" | w_loc_final=="Caquetá" 
replace zw=3 if w_loc_final=="Capital District" | w_loc_final=="Atlántico" | w_loc_final=="Valle del Cauca" | w_loc_final=="Casanare" | w_loc_final=="Guainía"
replace zw=4 if w_loc_final=="Cundinamarca" | w_loc_final=="Cesar" | w_loc_final=="Chocó" | w_loc_final=="Vichada" | w_loc_final=="Putumayo"
replace zw=5 if w_loc_final=="Huila" | w_loc_final=="Magdalena" | w_loc_final=="Guaviare" 
replace zw=6 if w_loc_final=="Norte de Santander" | w_loc_final=="Sucre" | w_loc_final=="Vaupés" 
replace zw=7 if w_loc_final=="Quindío" | w_loc_final=="Santander" 
replace zw=8 if w_loc_final=="Risaralda" | w_loc_final=="Córdoba" 
replace zw=9 if w_loc_final=="Tolima" | w_loc_final=="Antioquia" 
tostring zw, replace 
replace zw ="" if zw=="."
replace zw="A" if w_loc_final=="Bogotá D.C."
replace zw="F" if w_iso!="CO"

gen bidder_geocodes=xw+yw+zw
replace bidder_geocodes="" if w_loc_final==""
replace bidder_geocodes="" if bidder_geocodes=="7F"

tab bidder_geocodes

replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"
replace bidder_geocodes="" if w_loc_final!="" & w_iso==""
************************************

rename source source_old
gen source="https://www.colombiacompra.gov.co/secop-ii" if source_old==3
replace source="https://www.contratos.gov.co/puc/buscador.html" if source_old==2
************************************

gen lot_productCode=cpv_div
gen lot_localProductCode =  cpv_div
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
replace lot_localProductCode = lot_localProductCode + "000000"
replace lot_productCode = lot_productCode + "000000"
************************************

*year-month-day as a string 
    ca_start_date_str 
ca_end_date_str ci_start_date_str ci_end_date_str cft_lastdate_str 
interest_date_str draft_date_str select_date_str cft_open_date_str  cft_date_str

foreach var of varlist cft_date {
	gen dayx = string(day(`var'))
	gen monthx = string(month(`var'))
	gen yearx = string(year(`var'))
	gen len_mon=length(monthx)
	replace monthx="0" + monthx if len_mon==1 & !missing(monthx)
	gen len_day=length(dayx)
	replace dayx="0" + dayx if len_day==1 & !missing(dayx)
	gen tender_publications_firstcallfor = yearx + "-" + monthx + "-" + dayx
	replace tender_publications_firstcallfor ="" if tender_publications_firstcallfor ==".-0.-0."
	drop dayx monthx yearx len_mon len_day	
}
************************************
rename aw_start_date_str tender_awarddecisiondate 
rename ca_sign_date_str tender_contractsignaturedate 
rename cft_deadline_str tender_biddeadline 
rename aw_date_str tender_publications_firstdcontra
************************************

*Export prevsanct and has sanct anyway
gen bidder_previousSanction = "false"
gen bidder_hasSanction = "false"
gen sanct_startdate = ""
gen sanct_enddate = ""
gen sanct_name = ""
************************************

rename bid_price_ppp bid_priceUsd
rename tender_finalprice_ppp tender_finalpriceUsd
gen bid_pricecurrency  = ca_curr
gen ten_est_pricecurrency = ca_curr
gen lot_est_pricecurrency = ca_curr
************************************

gen tender_cpvs = cpv_div +  "000000" if!missing(cpv_div)
rename tender_cpvs lot_productCode
gen lot_localProductCode =  tender_unspsc_original
replace lot_localProductCode = substr(lot_localProductCode,1,8)
gen lot_localProductCode_type = "CPV2008" if !missing(lot_localProductCode)
************************************

br tender_title 
gen title = tender_title
************************************

br tender_recordedbidscount lot_bidscount
gen bids_count = ca_nrbid

********************************************************************************
save $country_folder/wb_col_cri201126.dta, replace
********************************************************************************

*Exporting for the rev flatten tool\

*Indicators

*rename tr_tender_title c_TRANSPARENCY_TITLE_MISSING
gen c_TRANSPARENCY_VALUE_MISSING=ind_tr_bid_price_val
gen c_TRANSPARENCY_IMP_LOC_MISSING=ind_tr_impl_val
gen  c_TRANSPARENCY_BID_NR_MISSING=ind_tr_bids_val
gen  c_TRANSPARENCY_BUYER_NAME_MIS=ind_tr_buyer_name_val
gen  c_TRANSPARENCY_BIDDER_NAME_MIS=ind_tr_bidder_name_val
gen  c_TRANSPARENCY_SUPPLY_TYPE_MIS=ind_tr_tender_supplytype_val
gen  c_TRANSPARENCY_PROC_METHOD_MIS=ind_tr_proc_val
gen  c_TRANSPARENCY_AWARD_DATE_MIS=ind_tr_aw_date2_val
gen c_TRANSPARENCY_TITLE_MISSING=ind_tr_tender_title_val

gen c_INTEGRITY_PROCEDURE_TYPE= ind_corr_proc_bi_val 
gen c_INTEGRITY_CALL_FOR_TENDER_PUB=ind_nocft_val
gen c_INTEGRITY_SINGLE_BID=ind_singleb_val
gen  c_INTERGIRTY_WINNER_SHARE = ind_csh_val
gen c_INTEGRITY_BENFORD = ind_corr_ben_bi_val 
gen c_INTEGRITY_TAX_HAVEN = ind_taxhav2_val
gen c_INTEGRITY_DELAY = ind_corr_rdelay2_bi_val
************************************

reshape long c_ , i(tender_id proa_ycsh proa_ycsh4 taxhav2 ) j(indicator, string)

*rename c_ tender_indicator_value
*rename indicator tender_indicator_type
*br tender_indicator_type tender_indicator_value

*Fixing Transparency indicators first
replace tender_indicator_type="TRANSPARENCY_BUYER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BUYER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_BIDDER_NAME_MISSING" if tender_indicator_type=="TRANSPARENCY_BIDDER_NAME_MIS"
replace tender_indicator_type="TRANSPARENCY_SUPPLY_TYPE_MISSING" if tender_indicator_type=="TRANSPARENCY_SUPPLY_TYPE_MIS"
replace tender_indicator_type="TRANSPARENCY_PROC_METHOD_MISSING" if tender_indicator_type=="TRANSPARENCY_PROC_METHOD_MIS"
replace tender_indicator_type="TRANSPARENCY_AWARD_DATE_MISSING" if tender_indicator_type=="TRANSPARENCY_AWARD_DATE_MIS"
************************************

*Calculating  status


*replace ind_csh_status = "INSUFFICIENT DATA" if missing(w_ycsh)
*replace ind_csh_status = "UNDEFINED" if missing(w_ycsh4) & !missing(w_ycsh)
 
*undefined if tax haven ==9 
gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
*gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
*gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"


gen tender_indicator_status = "INSUFFICIENT DATA" if inlist(tender_indicator_value,99,999,.)
replace tender_indicator_status = "CALCULATED" if missing(tender_indicator_status)
replace tender_indicator_value=. if inlist(tender_indicator_value,99,999,.)


gen buyer_indicator_type = "INTEGRITY_BENFORD"
rename corr_ben_bi buyer_indicator_value
gen buyer_indicator_status = "INSUFFICIENT DATA" if inlist(buyer_indicator_value,99,.)
replace buyer_indicator_status = "CALCULATED" if missing(buyer_indicator_status)
replace buyer_indicator_value=. if inlist(buyer_indicator_value,99,999,.)

************************************

foreach var of varlist  bidder_hasSanction bidder_previousSanction {
replace `var' = lower(`var')
replace `var' = "true" if inlist(`var',"true","t")
replace `var' = "false" if inlist(`var',"false","f")
}
************************************

foreach var of varlist buyer_id {
decode `var', gen(`var'_str)
replace `var' = "" if `var'=="."
rename `var' `var'_orig
rename `var'_str `var'
}
************************************

decode w_id, gen(bidder_id)
rename buyer_id buyer_id_orig
rename buyer_id_str buyer_id 
br  buyer_id bidder_id
*******************************************************************************

*Fixing variables for the rev flatten tool\

sort tender_id lot_row_nr

gen miss_bidder=missing(bidder_name)
tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************

drop if filter_ok==0
*drop if missing(tender_publications_lastcontract)
drop if missing(bidder_name)
************************************

bys ten_id aw_id ca_id: gen k=_N
format tender_title  bidder_name  tender_publications_lastcontract  %15s
br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1
************************************

rename ten_id tender_id
************************************

*RULE: use tender_isframework: if true 1 lot , f or missing count lots by grouping tender_id
bys tender_id aw_id ca_id: gen lot_number=_n 
count if missing(lot_number)

sort  tender_id   lot_number
br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
*OK
************************************

*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n
br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK
************************************
rename ca_proc tender_proceduretype

************************************ 

gen bidder_masterid=bidder_id
gen buyer_masterid=buyer_id
************************************

gen buyer_buyertype="" if anb_type==3
replace buyer_buyertype="REGIONAL_AGENCY" if anb_type>=4 & anb_type<=9 | anb_type==13
replace buyer_buyertype="NATIONAL_AUTHORITY" if anb_type==10
replace buyer_buyertype="NATIONAL_AGENCY" if anb_type==11
replace buyer_buyertype="REGIONAL_AUTHORITY" if anb_type==12

tab buyer_buyertype
************************************

rename anb_city buyer_city
************************************

gen buyer_country="Colombia"
rename w_country bidder_country
************************************

replace tender_proceduretype="NEGOTIATED_WITHOUT_PUBLICATION" if tender_proceduretype=="direct"
replace tender_proceduretype="RESTRICTED" if tender_proceduretype=="limited"
replace tender_proceduretype="OPEN" if tender_proceduretype=="open"
replace tender_proceduretype="OTHER" if tender_proceduretype=="other"
replace tender_proceduretype="RESTRICTED" if tender_proceduretype=="selective"
************************************

replace tender_supplytype="SUPPLIES" if tender_supplytype=="goods"
replace tender_supplytype="" if tender_supplytype=="other"
replace tender_supplytype="SERVICES" if tender_supplytype=="services"
replace tender_supplytype="WORKS" if tender_supplytype=="works"
************************************

replace bidder_id="" if bidder_id=="RÄ‚â€™MULO EFRAÄ‚ĹšN NIÄ‚â€O NEISA"
replace bidder_id="" if bidder_id=="not awarded"
gen bidder_masterid=bidder_id
************************************

replace title = subinstr(title, "Äâ€ś", "ó", .)
replace title = subinstr(title, "ÄĹ‚", "ó", .)
replace title = subinstr(title, "ÄÂ©", "é", .)
replace title = subinstr(title, "ÄÂ­", "í", .)
replace title = subinstr(title, "ÄĹź", "ú", .)
replace title = subinstr(title, "Äâ€™", "o", .)
replace title = subinstr(title, "Ă˘â€“", "", .)
replace title = subinstr(title, "Äâ€", "n", .)
replace title = subinstr(title, "ÄĹĄ", "í", .)
replace title = subinstr(title, "ÄĹˇ", "ú", .)
replace title = subinstr(title, "ÄË‡", "a", .)
replace title = subinstr(title, "Ă˘Â°", "o", .)
replace title = subinstr(title, "Äâ€°", "e", .)
replace title = subinstr(title, "Äâ€°", "e", .)
replace title = subinstr(title, "ÄÂ", "a", .)
************************************

replace buyer_name = subinstr(buyer_name, "Äâ€ś", "ó", .)
replace buyer_name = subinstr(buyer_name, "ÄĹ‚", "ó", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ©", "é", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ­", "í", .)
replace buyer_name = subinstr(buyer_name, "ÄĹź", "ú", .)
replace buyer_name = subinstr(buyer_name, "Äâ€™", "o", .)
replace buyer_name = subinstr(buyer_name, "Ă˘â€“", "", .)
replace buyer_name = subinstr(buyer_name, "Äâ€", "n", .)
replace buyer_name = subinstr(buyer_name, "ÄĹĄ", "í", .)
replace buyer_name = subinstr(buyer_name, "ÄĹˇ", "ú", .)
replace buyer_name = subinstr(buyer_name, "ÄË‡", "a", .)
replace buyer_name = subinstr(buyer_name, "Ă˘Â°", "o", .)
replace buyer_name = subinstr(buyer_name, "Äâ€°", "e", .)
replace buyer_name = subinstr(buyer_name, "Äâ€°", "e", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
************************************

replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
replace buyer_name = subinstr(buyer_name, "ÄÂ", "a", .)
************************************

tostring lot_productcode, replace
tostring lot_localproductcode, replace

replace lot_productcode = "99100000" if lot_productcode=="0" & tender_supplytype=="SUPPLIES"
replace lot_productcode = "99200000" if lot_productcode=="0" & tender_supplytype=="SERVICES"
replace lot_productcode = "99300000" if lot_productcode=="0" & tender_supplytype=="WORKS"
replace lot_productcode = "99000000" if lot_productcode=="0" & missing(tender_supplytype)
************************************

replace lot_localproductcode = "99100000" if lot_localproductcode=="0" & tender_supplytype=="SUPPLIES"
replace lot_localproductcode = "99200000" if lot_localproductcode=="0" & tender_supplytype=="SERVICES"
replace lot_localproductcode = "99300000" if lot_localproductcode=="0" & tender_supplytype=="WORKS"
replace lot_localproductcode = "99000000" if lot_localproductcode=="0" & missing(tender_supplytype)
************************************

replace lot_productcode="09000000" if lot_productcode=="9000000"
replace lot_localproductcode="09000000" if lot_localproductcode=="9000000"
replace lot_productcode="03000000" if lot_productcode=="3000000"
replace lot_localproductcode="03000000" if lot_localproductcode=="3000000"
************************************

tostring buyer_id, replace
************************************

egen w_id=group(bidder_name)
label var w_id "generated company ID"
sum w_id 
************************************

egen anb_id=group(buyer_name)
label var anb_id "generated buyer ID"
sum anb_id 
************************************

keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra  buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_proc_bi_val ind_corr_proc_type ind_corr_ben_bi_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
************************************

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor source tender_publications_award_type  tender_publications_firstdcontra  buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency bidder_previousSanction bidder_hasSanction sanct_startdate sanct_enddate sanct_name lot_productCode lot_localProductCode_type lot_localProductCode title bids_count ind_nocft_val ind_nocft_type ind_singleb_val ind_singleb_type ind_corr_proc_bi_val ind_corr_proc_type ind_corr_ben_bi_val ind_corr_ben_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_tender_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type 
********************************************************************************

*Implementing some fixes

foreach var in tender_addressofimplementation_c bidder_id bidder_name buyer_name title{

replace `var' = ustrregexra(`var',`"""'," ")

if "`var'"=="tender_addressofimplementation_c"{
replace `var' = ustrregexra(`var',"[\d]"," ")
replace `var' = ustrregexra(`var',"A"," ")
}

replace `var' = subinstr(`var',"{"," ",.)
replace `var' = subinstr(`var',"}"," ",.)

foreach char in [ ] {
di "`char'"
replace `var' = ustrregexra(`var',"`char'"," ")
}


}

destring bid_priceUsd, replace force
destring bid_price, replace force
replace bid_priceUsd = . if bid_priceUsd>18000000000
replace bid_priceUsd = . if bid_priceUsd>18000000000
cap drop _m
********************************************************************************

export delimited $country_folder/CO_mod.csv, replace
********************************************************************************
*END