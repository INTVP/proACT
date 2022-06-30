 local country "`0'"
********************************************************************************
/*This script performs several post processing operations to prepare the data for
the reverse flatten tool.
1) Creates Transparency indicators from risk indicators
2) Tidy variables for reverse flatten tool
3) Exports select variable for the reverse flatten tool*/
********************************************************************************
*Data

use "${country_folder}/`country'_wb_2011.dta", clear
********************************************************************************
*Note - The compiled dataset was used for an earlier project - most of the data preperation work such as renaming variables where done in an older script. I will copy here all the relevent parts of the script and leave them commented
*The parts that are not commented are relevent for the ProAct project
********************************************************************************
*Fixing variables for reverse tool

gen tender_country = "CO"
************************************
*Is source is "https://tenders.procurement.gov.ge"
*then notice_url is also tender_publications_lastcontract
// br notice_url tender_publications_firstcallfor tender_publications_lastcontract tender_publications_firstdcontra

cap drop tender_publications_notice_type tender_publications_award_type
gen tender_publications_notice_type = "CONTRACT_NOTICE" if !missing(cft_date)
gen tender_publications_award_type = "CONTRACT_AWARD" if !missing(ca_start_date)

// br tender_publications_notice_type notice_url tender_publications_firstcallfor tender_publications_award_type tender_publications_lastcontract tender_publications_firstdcontra
************************************
*Fixing Location data

// country_string 
foreach var of varlist ca_proc_loc ca_del_loc ca_e_loc w_loc anb_loc w_county anb_county w_country w_country_iso  country {
decode `var', gen(`var'_str)
drop `var'
rename `var'_str `var'
}

*Fixing Buyer locations

// rename anb_loc_final anb_city
gen anb_city = proper(anb_loc)
replace anb_city="Alto Baudó" if anb_city=="Alto Baudo"
replace anb_city="Ancuya" if anb_city=="Ancuyá"
replace anb_city="Arenal del Sur" if anb_city=="Arenal"
replace anb_city="Bajo Baudó" if anb_city=="Bajo Baudó/Pizarro"
replace anb_city="Belén de Andaquies" if anb_city=="Belen de Los Andaquies"
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
replace anb_city="Bogotá" if anb_city=="Bogota"

local country "CO"
cap drop _m
merge m:m anb_city using "${utility_data}/country/`country'/CO_buyer_city.dta", keep(1 3)
cap drop _m
*https://en.wikipedia.org/wiki/Natural_regions_of_Colombia
*https://en.wikipedia.org/wiki/List_of_cities_and_towns_in_Colombia

*rename buyer_NUTS3 buyer_geocodes
// rename anb_loc_final anb_city
rename Department anb_departm

// decode anb_county, gen(anb_countystr)
replace anb_county = subinstr(anb_county, "Â ", "", .) 
replace anb_county = subinstr(anb_county, ".", "", .) 
replace anb_county = subinstr(anb_county, "-", "", .)
gen anb_cnty_str = anb_county if regexm(anb_county, "([a-zA-Z])")

replace anb_departm=anb_cnty_str if anb_departm=="" & anb_cnty_str!=""
// tab anb_departm
cap drop anb_cnty_str

replace anb_departm="Atlántico" if anb_departm=="AtlĂˇntico" 
replace anb_departm="Bolívar" if anb_departm=="BolĂ­var" 
replace anb_departm="Boyacá" if anb_departm=="BoyacĂˇ" 
replace anb_departm="Caquetá" if anb_departm=="CaquetĂˇ" 
replace anb_departm="Chocó" if anb_departm=="ChocĂł" 
replace anb_departm="Córdoba" if anb_departm=="CĂłrdoba" 
replace anb_departm="Guainía" if anb_departm=="GuainĂ­a" 
replace anb_departm="Nariño" if anb_departm=="Narino" 
replace anb_departm="Quindío" if anb_departm=="QuindĂ­o" 

replace anb_departm = ustrltrim(anb_departm)
replace anb_departm = "" if inlist(anb_departm,"country level","other")

cap drop x y z
gen x = "CO" if !missing(anb_city) | !missing(anb_departm)
*Generating a new grouping for natural regions
gen y = .
replace y = 1 if inlist(anb_departm,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace y = 2 if inlist(anb_departm,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace y = 3 if inlist(anb_departm,"Nariño","Cauca","Valle del Cauca","Chocó")
replace y = 4 if inlist(anb_departm,"Meta","Arauca","Casanare","Vichada")
replace y = 5 if inlist(anb_departm,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace y = 6 if inlist(anb_departm,"San Andrés y Providencia")
// tab anb_departm y , m
tostring y, replace
replace y ="" if y=="."
// tab anb_departm if !missing(anb_departm) & missing(y)

*departments
cap drop z
gen z=1 if anb_departm=="Boyacá" | anb_departm=="La Guajira" | anb_departm=="Narino" | anb_departm=="Nariño" | anb_departm=="Meta" | anb_departm=="Amazonas" | anb_departm=="San Andrés y Providencia"
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
// tab anb_departm if !missing(anb_departm) & missing(z)

// br x y z  anb_departm
cap drop buyer_nuts
gen buyer_nuts  = x+y+z

preserve
	keep buyer_nuts anb_departm
	rename buyer_nuts geocodes
	rename anb_departm region
	duplicates drop 
	drop if missing(geocodes)
	export delimited "${utility_data}/country/`country'/`country'_region_labels.csv", replace
restore

cap drop buyer_geocodes
gen buyer_geocodes=buyer_nuts
replace buyer_geocodes = subinstr(buyer_geocodes, ".", "", .)
replace  buyer_geocodes = "["+ `"""' + buyer_geocodes + `"""' +"]"
replace buyer_geocodes="" if !regexm(buyer_geocodes, "CO")
*if buyer nuts is missing it shoud be empty
*for bidder and impl also
*before that check nuts all nuts code and assigned city in a new sheet
************************************
*Fixing IMPL nuts

decode impl_region, gen(impl_dpt)
// tab impl_departm
// gen impl_dpt = substr(impl_departm, 1, strpos(impl_departm, "-") - 1) 
*gen impl_city = regexm(impl_departm, "- ") 
*gen impl_city = impl_departm if regexm(impl_departm, "(["- "]*([a-zA-Z]+)")

// decode impl_region, gen(impl_region_str)
// replace impl_dpt=impl_region_str if impl_region_str!="" & impl_dpt==""
replace impl_dpt = subinstr(impl_dpt, "Â ", "", .)
replace impl_dpt = subinstr(impl_dpt, "Ăˇ", "á", .)
replace impl_dpt = subinstr(impl_dpt, "Ă©", "é", .)
replace impl_dpt = subinstr(impl_dpt, "Ă­", "í", .)
replace impl_dpt = subinstr(impl_dpt, "Ăł", "ó", .)
replace impl_dpt = subinstr(impl_dpt, "Ă±", "n", .)
replace impl_dpt = subinstr(impl_dpt, "Ĺ„", "n", .)

replace impl_dpt=strtrim(impl_dpt)
replace impl_dpt = ustrltrim(impl_dpt)
replace impl_dpt = "" if inlist(impl_dpt,"country level","other")

replace impl_dpt = "Norte de Santander" if impl_dpt=="Norte De Santander"
replace impl_dpt = "San Andrés y Providencia" if impl_dpt=="San Andrés, Providencia y Santa Catalina"
replace impl_dpt = "Nariño" if impl_dpt=="Narino" | impl_dpt=="Narińo"

gen xi = "CO" if !missing(impl_dpt)
*Generating a new grouping for natural regions
cap drop yi
gen yi = .
replace yi = 1 if inlist(impl_dpt,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace yi = 1 if inlist(impl_dpt, "Bogotá D.C.")
replace yi = 2 if inlist(impl_dpt,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace yi = 3 if inlist(impl_dpt,"Nariño","Cauca","Valle del Cauca","Chocó")
replace yi = 4 if inlist(impl_dpt,"Meta","Arauca","Casanare","Vichada")
replace yi = 5 if inlist(impl_dpt,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace yi = 6 if inlist(impl_dpt,"San Andrés y Providencia")
// tab impl_dpt yi , m
tostring yi, replace
replace yi ="" if yi=="."
// tab impl_dpt if !missing(impl_dpt) & missing(yi)

*departments
cap drop zi
gen zi=1 if impl_dpt=="Boyacá" | impl_dpt=="La Guajira" | impl_dpt=="Nariño" | impl_dpt=="Meta" | impl_dpt=="Amazonas" | impl_dpt=="San Andrés y Providencia"
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
// tab impl_dpt if !missing(impl_dpt) & missing(zi)

gen impl_geocodes=xi+yi+zi
replace impl_geocodes = subinstr(impl_geocodes, ".", "", .)

gen tender_addressofimplementation_n = "["+ `"""' + impl_geocodes + `"""' +"]"
replace tender_addressofimplementation_n="" if impl_geocodes==""
gen tender_addressofimplementation_c=xi
// tab tender_addressofimplementation_n, m
// tab tender_addressofimplementation_c, m
************************************
*Fixing Bidder nuts

// sum w_loc w_country w_county w_country_iso 
//
// replace w_country_iso=. if w_country_iso==2
// decode w_country_iso, gen(w_iso)

// tab w_county
gen w_loc_final = w_county
replace w_loc_final = proper(w_loc_final)

gen xw = w_country_iso
 
replace w_loc_final=strtrim(w_loc_final)
replace w_loc_final = ustrltrim(w_loc_final)
replace w_loc_final = "" if inlist(w_loc_final,"Country Level","Other")

*Generating a new grouping for regions
replace w_loc_final = "Norte de Santander" if w_loc_final=="Norte De Santander"
replace w_loc_final = "San Andrés y Providencia" if w_loc_final=="San Andrés, Providencia y Santa Catalina"
replace w_loc_final = "San Andrés y Providencia" if w_loc_final=="San Andrés y Providencia"
replace w_loc_final = "San Andrés y Providencia" if w_loc_final=="San Andres Y Providencia"
replace w_loc_final = "Bolívar" if w_loc_final=="Bolivar"
replace w_loc_final = "Boyacá" if w_loc_final=="Boyaca"
replace w_loc_final = "Caquetá" if w_loc_final=="Caqueta"
replace w_loc_final = "Chocó" if w_loc_final=="Choco"
replace w_loc_final = "Córdoba" if w_loc_final=="Cordoba"
replace w_loc_final = "Guainía" if w_loc_final=="Guainia"
replace w_loc_final = "Quindío" if w_loc_final=="Quindio"
replace w_loc_final = "Valle del Cauca" if w_loc_final=="Valle Del Cauca"
replace w_loc_final = "Vaupés" if w_loc_final=="Vaupes"
replace w_loc_final = "Atlántico" if w_loc_final=="Atlantico"
replace w_loc_final = "Nariño" if w_loc_final=="Narino"

cap drop yw
gen yw = .
replace yw = 1 if inlist(w_loc_final,"Boyacá","Caldas","Capital District","Cundinamarca","Huila", "Norte de Santander", "Quindío", "Risaralda", "Tolima")
replace yw = 1 if inlist(w_loc_final, "Bogotá D.C.")
replace yw = 2 if inlist(w_loc_final,"La Guajira","Bolívar","Atlántico","Cesar","Magdalena","Sucre", "Santander", "Córdoba", "Antioquia")
replace yw = 3 if inlist(w_loc_final,"Nariño","Cauca","Valle del Cauca","Chocó")
replace yw = 4 if inlist(w_loc_final,"Meta","Arauca","Casanare","Vichada")
replace yw = 5 if inlist(w_loc_final,"Amazonas","Caquetá","Guainía","Putumayo","Guaviare", "Vaupés")
replace yw = 6 if inlist(w_loc_final,"San Andrés y Providencia")
// replace yw = 7 if w_country_iso!="CO"
// tab w_loc_final yw , m
tostring yw, replace
replace yw ="" if yw=="."
// tab w_loc_final if !missing(w_loc_final) & missing(yw)

cap drop zw
gen zw=1 if w_loc_final=="Boyacá" | w_loc_final=="La Guajira" | w_loc_final=="Narino" | w_loc_final=="Nariño" | w_loc_final=="Meta" | w_loc_final=="Amazonas" | w_loc_final=="San Andrés y Providencia"
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
// replace zw="A" if w_loc_final=="Bogotá D.C."
// replace zw="F" if w_iso!="CO"
// tab w_loc_final if !missing(w_loc_final) & missing(zw)

cap drop bidder_nuts
gen bidder_nuts  = xw+yw+zw

cap drop bidder_geocodes
gen bidder_geocodes=bidder_nuts
replace bidder_geocodes="" if w_loc_final==""
replace bidder_geocodes="" if bidder_geocodes=="7F"

// tab bidder_geocodes

replace bidder_geocodes = "["+ `"""' + bidder_geocodes + `"""' +"]"
replace bidder_geocodes="" if w_loc_final!="" & w_country_iso==""
replace bidder_geocodes="" if bidder_geocodes==`"[""]"'

// levels buyer_nuts, local(ass)
// foreach x in `ass'{
// tab anb_departm if buyer_nuts=="`x'"
// tab w_loc_final if bidder_nuts=="`x'"
// }
************************************
*Buyer location (city/country)

cap drop buyer_city
gen buyer_city = anb_city
replace buyer_city = proper(buyer_city)
gen buyer_country = "CO" if !missing(buyer_city)

*Bidder location (city/country)
br *w_loc* bidder_city *country*
cap drop bidder_city
gen bidder_city = w_loc_final
replace bidder_city = proper(bidder_city)
gen bidder_country = w_country_iso
************************************

*Procedure type
// br ca_procedure
decode ca_procedure_nat, gen(tender_nationalproceduretype)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Â ", "", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ăˇ", "á", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ă©", "é", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ă­", "í", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ăł", "ó", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ă±", "n", .)
replace tender_nationalproceduretype = subinstr(tender_nationalproceduretype, "Ĺ„", "n", .)

decode ca_procedure, gen(tender_proceduretype)
replace tender_proceduretype="NEGOTIATED_WITHOUT_PUBLICATION" if tender_proceduretype=="direct"
replace tender_proceduretype="RESTRICTED" if tender_proceduretype=="limited"
replace tender_proceduretype="OPEN" if tender_proceduretype=="open"
replace tender_proceduretype="OTHER" if tender_proceduretype=="other"
replace tender_proceduretype="OTHER" if tender_proceduretype=="request"
replace tender_proceduretype="RESTRICTED" if tender_proceduretype=="selective"
************************************
* Title

// br *title*
decode ten_title, gen(tender_title)
replace tender_title = subinstr(tender_title, "Â ", "", .)
replace tender_title = subinstr(tender_title, "Ăˇ", "á", .)
replace tender_title = subinstr(tender_title, "Ă©", "é", .)
replace tender_title = subinstr(tender_title, "Ă­", "í", .)
replace tender_title = subinstr(tender_title, "Ăł", "ó", .)
replace tender_title = subinstr(tender_title, "Ă±", "n", .)
replace tender_title = subinstr(tender_title, "Ĺ„", "n", .)
replace tender_title = subinstr(tender_title, "Äâ€ś", "ó", .)
replace tender_title = subinstr(tender_title, "ÄĹ‚", "ó", .)
replace tender_title = subinstr(tender_title, "ÄÂ©", "é", .)
replace tender_title = subinstr(tender_title, "ÄÂ­", "í", .)
replace tender_title = subinstr(tender_title, "ÄĹź", "ú", .)
replace tender_title = subinstr(tender_title, "Äâ€™", "o", .)
replace tender_title = subinstr(tender_title, "Ă˘â€“", "", .)
replace tender_title = subinstr(tender_title, "Äâ€", "n", .)
replace tender_title = subinstr(tender_title, "ÄĹĄ", "í", .)
replace tender_title = subinstr(tender_title, "ÄĹˇ", "ú", .)
replace tender_title = subinstr(tender_title, "ÄË‡", "a", .)
replace tender_title = subinstr(tender_title, "Ă˘Â°", "o", .)
replace tender_title = subinstr(tender_title, "Äâ€°", "e", .)
replace tender_title = subinstr(tender_title, "Äâ€°", "e", .)
replace tender_title = subinstr(tender_title, "ÄÂ", "a", .)

replace tender_title = subinstr(tender_title,`"""',"",.)
replace tender_title =  subinstr(tender_title,"„","",.)
replace tender_title = proper(tender_title)
gen title = tender_title
cap drop tender_title
************************************
*Supply type

decode ca_type, gen(tender_supplytype)
replace tender_supplytype="SUPPLIES" if tender_supplytype=="goods"
replace tender_supplytype="" if tender_supplytype=="other" |  tender_supplytype=="not defined"
replace tender_supplytype="SERVICES" if tender_supplytype=="services"
replace tender_supplytype="WORKS" if tender_supplytype=="works"
************************************
*Buyer type

gen buyer_buyertype="" if anb_type==99
replace buyer_buyertype="REGIONAL_AGENCY" if anb_type==11
replace buyer_buyertype="NATIONAL_AUTHORITY" if anb_type==1 | anb_type == 8
replace buyer_buyertype="NATIONAL_AGENCY" if anb_type==9
replace buyer_buyertype="REGIONAL_AUTHORITY" if anb_type>=2 & anb_type<=7
replace buyer_buyertype="REGIONAL_AUTHORITY" if anb_type==10

// tab buyer_buyertype
************************************
*Source

rename source source_old
gen source="https://www.colombiacompra.gov.co/secop-ii" if source_old==2
replace source="https://www.contratos.gov.co/puc/buscador.html" if source_old==1

*Url
decode ten_url, gen(tender_publications_lastcontract)
************************************
* Product codes
gen lot_productCode=tender_cpvs
gen lot_localProductCode =  tender_unspsc_original
gen lot_localProductCode_type = "UNSPSC" if !missing(lot_localProductCode)

replace lot_productCode = "99100000" if missing(lot_productCode) & tender_supplytype=="SUPPLIES"
replace lot_productCode = "99200000" if missing(lot_productCode) & tender_supplytype=="SERVICES"
replace lot_productCode = "99300000" if missing(lot_productCode) & tender_supplytype=="WORKS"
replace lot_productCode = "99000000" if missing(lot_productCode) & missing(tender_supplytype)
************************************
*Dates
*year-month-day as a string 

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

rename aw_start_date_str tender_awarddecisiondate 
rename ca_sign_date_str tender_contractsignaturedate 
rename cft_deadline_str tender_biddeadline 
rename aw_date_str tender_publications_firstdcontra
// br tender_publications_firstcallfor  tender_biddeadline tender_contractsignaturedate tender_awarddecisiondate tender_publications_firstdcontra
************************************
*Prices

desc bid_price
rename bid_price_ppp bid_priceUsd
decode ca_curr, gen(bid_pricecurrency)
replace bid_priceUsd = . if bid_priceUsd>18000000000
replace bid_priceUsd = . if bid_priceUsd>18000000000
************************************

// br tender_recordedbidscount lot_bidscount
gen bids_count = ca_nrbid
************************************
*Names

decode buyer_name, gen(buyer_name_str)
cap drop buyer_name
rename buyer_name_str buyer_name
replace buyer_name = "" if buyer_name=="."

decode w_name, gen(bidder_name)
cap drop w_name
decode w_replegal_name, gen(bidder_name_legal)
cap drop w_replegal_name
replace bidder_name = "" if bidder_name=="."

replace bidder_name = bidder_name_legal if missing(bidder_name)

foreach var of varlist buyer_name bidder_name {
replace `var' = subinstr(`var', "Äâ€ś", "ó", .)
replace `var' = subinstr(`var', "ÄĹ‚", "ó", .)
replace `var' = subinstr(`var', "ÄÂ©", "é", .)
replace `var' = subinstr(`var', "ÄÂ­", "í", .)
replace `var' = subinstr(`var', "ÄĹź", "ú", .)
replace `var' = subinstr(`var', "Äâ€™", "o", .)
replace `var' = subinstr(`var', "Ă˘â€“", "", .)
replace `var' = subinstr(`var', "Äâ€", "n", .)
replace `var' = subinstr(`var', "ÄĹĄ", "í", .)
replace `var' = subinstr(`var', "ÄĹˇ", "ú", .)
replace `var' = subinstr(`var', "ÄË‡", "a", .)
replace `var' = subinstr(`var', "Ă˘Â°", "o", .)
replace `var' = subinstr(`var', "Äâ€°", "e", .)
replace `var' = subinstr(`var', "Äâ€°", "e", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = subinstr(`var', "ÄÂ", "a", .)
replace `var' = "" if `var'=="not awarded"
}

foreach var of varlist buyer_name bidder_name {
replace `var' = ustrupper(`var')
}

*Check if titles/names start with "" or []
foreach var of varlist title buyer_name bidder_name {
replace `var' = subinstr(`var',"[","",.) if regex(`var',"^[")
replace `var' = subinstr(`var',"]","",.) if regex(`var',"^]")
replace `var' = subinstr(`var',`"""',"",.) if regex(`var',`"^""')
}
************************************
*Ids

*Buyer
// br *id*
// br anb_id anb_id_secop anb_addid_id
decode anb_id, gen(buyer_masterid)
tostring anb_id_secop, gen(buyer_id)
replace buyer_id = "" if buyer_id =="."
decode anb_addid_id, gen(buyer_id2)
replace buyer_id = buyer_id2 if missing(buyer_id)
replace buyer_id = "" if buyer_id =="ND"
replace buyer_masterid = buyer_id if missing(buyer_masterid)

foreach var in buyer_masterid buyer_id{
replace `var' = "" if `var'=="."
replace `var'="" if `var'=="RÄ‚â€™MULO EFRAÄ‚ĹšN NIÄ‚â€O NEISA"
replace `var'="" if `var'=="not awarded"
}

*Bidder
br w_id w_replegal_id bidder_masterid
replace bidder_masterid="" if bidder_masterid=="not awarded"
replace bidder_masterid="" if bidder_masterid=="RÄ‚â€™MULO EFRAÄ‚ĹšN NIÄ‚â€O NEISA"
decode w_replegal_id, gen(bidder_id)
replace bidder_id = "" if bidder_id =="."
************************************

gen ind_nocft_type = "INTEGRITY_CALL_FOR_TENDER_PUBLICATION"
gen ind_singleb_type = "INTEGRITY_SINGLE_BID"
gen ind_taxhav2_type = "INTEGRITY_TAX_HAVEN"
gen ind_corr_proc_type = "INTEGRITY_PROCEDURE_TYPE"
gen ind_corr_submp_type = "INTEGRITY_ADVERTISEMENT_PERIOD"
gen ind_corr_decp_type = "INTEGRITY_DECISION_PERIOD"
gen ind_corr_ben_type = "INTEGRITY_BENFORD"
gen ind_csh_type = "INTEGRITY_WINNER_SHARE"
gen ind_roverrun2_type = "INTEGRITY_COST_OVERRUN"
gen ind_delay_type = "INTEGRITY_DELAY"

gen ind_tr_buyer_name_type = "TRANSPARENCY_BUYER_NAME_MISSING"
gen ind_tr_tender_title_type = "TRANSPARENCY_TITLE_MISSING" 
gen ind_tr_bidder_name_type = "TRANSPARENCY_BIDDER_NAME_MISSING"
gen ind_tr_tender_supplytype_type = "TRANSPARENCY_SUPPLY_TYPE_MISSING" 
gen ind_tr_bid_price_type = "TRANSPARENCY_VALUE_MISSING" 
gen ind_tr_impl_type = "TRANSPARENCY_IMP_LOC_MISSING" 
gen ind_tr_proc_type = "TRANSPARENCY_PROC_METHOD_MISSING"
gen ind_tr_bids_type = "TRANSPARENCY_BID_NR_MISSING"
gen ind_tr_aw_date2_type = "TRANSPARENCY_AWARD_DATE_MISSING"

gen ind_comp_bidder_mkt_entry_type = "COMPETITION_SUPPLIER_MARKET_ENTRY"
gen ind_comp_bidder_non_local_type = "COMPETITION_NON_LOCAL_SUPPLIER"
gen ind_comp_bidder_mkt_share_type = "COMPETITION_SUPPLIER_MARKET_SHARE"
gen ind_comp_bids_count_type = "COMPETITION_NUMBER_OF_BIDDERS"
************************************
*Calcluating indicators

foreach var of varlist singleb nocft taxhav2 {
// tab `var', m
gen ind_`var'_val = 0 
replace ind_`var'_val = 0 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
replace ind_`var'_val = 9  if  `var'==9  //tax haven undefined
}
gen ind_corr_submp_val = .
gen ind_corr_decp_val = .

foreach var of varlist corr_rdelay2 corr_proc corr_ben {
// tab `var', m
gen ind_`var'_val = 0 if `var'==2
replace ind_`var'_val = 50 if `var'==1
replace ind_`var'_val = 100 if `var'==0
replace ind_`var'_val =. if missing(`var') | `var'==99
}

*Contract Share
sum proa_ycsh5
gen ind_csh_val = proa_ycsh5*100
replace ind_csh_val = 100-ind_csh_val

*Overrun
gen ind_overrun_val = roverrun2*100
************************************
*Transparency
gen impl= tender_addressofimplementation_n
gen proc = tender_proceduretype
gen aw_date2 = tender_awarddecisiondate
gen bids = bids_count
foreach var of varlist buyer_name title bidder_name tender_supplytype bid_price impl proc bids aw_date2  {
gen ind_tr_`var'_val = 0
replace  ind_tr_`var'_val = 100 if !missing(`var') 
}
drop  impl proc aw_date2 bids
************************************
*Competition Indicators

gen ind_comp_bidder_mkt_share_val = bidder_mkt_share*100
gen ind_comp_bids_count_val = bids_count

foreach var of varlist bidder_mkt_entry bidder_non_local  {
gen ind_comp_`var'_val = 0
replace ind_comp_`var'_val = 0 if `var'==0
replace ind_comp_`var'_val = 100 if `var'==1
replace ind_comp_`var'_val =. if missing(`var') | `var'==99
}
********************************************************************************
save "${country_folder}/`country'_wb_2011.dta", replace
********************************************************************************

*Fixing variables for the rev flatten tool\
// br  ten_id uid ca_id ten_id_byanb ca_id_byanb aw_id
decode ten_id, gen(tender_id)
replace tender_id = "" if tender_id=="."

sort tender_id
// gen miss_bidder=missing(bidder_name)
// tab miss_bidder if missing(bid_iswinning), m //all bidder names are missing if bid_iswinning is missing
// br  tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if missing(bid_iswinning)
************************************
drop if filter_ok==0
drop if missing(bidder_name)
drop if missing(buyer_name)
drop if missing(buyer_masterid)
drop if missing(bidder_masterid)
************************************
// bys ten_id aw_id ca_id: gen k=_N
// format tender_title  bidder_name  tender_publications_lastcontract  %15s
// br x tender_id tender_lotscount lot_row_nr bid_iswinning tender_isframe bid_iscons tender_title bidder_name bid_price *cons* if x>1
************************************
bys tender_id aw_id ca_id: gen lot_number=_n 
// count if missing(lot_number)

// sort  tender_id   lot_number
// br x tender_id tender_lotscount lot_row_nr lot_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price if x>1
************************************
*Bid number: Rule;
bys tender_id lot_number: gen bid_number=_n
// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount==1

// br x tender_id tender_lotscount lot_row_nr lot_number bid_number bid_iswinning tender_isframe bid_iscons tender_title lot_title bidder_name bid_price  if x>1 & tender_lotscount!=1 & tender_isframework=="t"
*OK
************************************
// rename ca_proc tender_proceduretype
// gen bidder_masterid=bidder_id
// gen buyer_masterid=buyer_id
// rename anb_city buyer_city
************************************
local country "CO"
keep tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  source tender_publications_award_type  tender_publications_firstdcontra tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type submp ind_corr_submp_val ind_corr_submp_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_rdelay2_val ind_corr_rdelay2_val ind_delay_type ind_overrun_val ind_roverrun2_type ind_corr_proc_val ind_corr_proc_type ind_corr_ben_val ind_corr_ben_type ind_taxhav2_val ind_taxhav2_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

order tender_id lot_number bid_number tender_country tender_awarddecisiondate tender_contractsignaturedate tender_biddeadline tender_nationalproceduretype tender_proceduretype tender_supplytype tender_publications_notice_type tender_publications_firstcallfor  source tender_publications_award_type  tender_publications_firstdcontra tender_publications_lastcontract buyer_masterid buyer_id buyer_city buyer_country buyer_geocodes buyer_name  buyer_buyertype tender_addressofimplementation_c tender_addressofimplementation_n bidder_masterid bidder_id bidder_country bidder_geocodes bidder_name bid_priceUsd bid_price bid_pricecurrency lot_productCode lot_localProductCode_type lot_localProductCode title ind_singleb_val ind_singleb_type ind_nocft_val ind_nocft_type submp ind_corr_submp_val ind_corr_submp_type decp ind_corr_decp_val ind_corr_decp_type ind_corr_rdelay2_val ind_corr_rdelay2_val ind_delay_type ind_overrun_val ind_roverrun2_type ind_corr_proc_val ind_corr_proc_type ind_corr_ben_val ind_corr_ben_type ind_taxhav2_val ind_taxhav2_type ind_csh_val ind_csh_type ind_tr_buyer_name_val ind_tr_buyer_name_type ind_tr_title_val ind_tr_tender_title_type ind_tr_bidder_name_val ind_tr_bidder_name_type ind_tr_tender_supplytype_val ind_tr_tender_supplytype_type ind_tr_bid_price_val ind_tr_bid_price_type ind_tr_impl_val ind_tr_impl_type ind_tr_proc_val ind_tr_proc_type ind_tr_bids_val ind_tr_bids_type ind_tr_aw_date2_val ind_tr_aw_date2_type ind_comp_bidder_mkt_share_val ind_comp_bidder_mkt_share_type ind_comp_bids_count_val ind_comp_bids_count_type ind_comp_bidder_mkt_entry_val ind_comp_bidder_mkt_entry_type ind_comp_bidder_non_local_val ind_comp_bidder_non_local_type is_capital 

assert !missing(tender_id), fast
assert !missing(lot_number), fast
assert !missing(bid_number), fast
assert !missing(buyer_masterid), fast
assert !missing(bidder_masterid), fast
********************************************************************************
local country "CO"
global utility_data "C:/Ourfolders/Aly/ProACT-2020/utility_data"

forval x=1/2{
if (`x'==1) {
local start_c = 1
local end_c = round(_N/2) //836020
}
if (`x'==2) {
local start_c = round(_N/2) + 1
local end_c = _N 
}

export excel if _n>=`start_c' & _n<=`end_c' using "${utility_data}/country/`country'/`country'_mod`x'.xlsx", firstrow(var) replace
}
// export delimited "${utility_data}/country/`country'/`country'_mod.csv", replace
********************************************************************************
*Clean up
copy "${country_folder}/`country'_wb_2011.dta" "${utility_data}/country/`country'/`country'_wb_2011.dta", replace
local files : dir  "${country_folder}" files "*.dta"
foreach file in `files' {
cap erase "${country_folder}/`file'"
}
cap erase "${country_folder}/buyers_for_R.csv"
********************************************************************************
*END