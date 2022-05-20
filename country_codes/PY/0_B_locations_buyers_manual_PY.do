local country "`0'"
********************************************************************************
/*This script prepares merges location data for the PY dataset*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************
*Preparing the buyer name variable for matching

rename buyer_name anb_name
lab var anb_name "Announcing body name"

*Clean names to prepare for matching with anb_name in data set
gen anb_name_edit=lower(anb_name)

*Replace Actute character //  Á É Í Ó Ú á é í ó ú Ý ý
local temp "Á É Í Ó Ú á é í ó ú Ý ý ń"
local temp2 "a e i o u a e i o u y y n"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace anb_name_edit = subinstr(anb_name_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Tilde character // Ã Ñ Õ ã ñ õ 
local temp "Ã Ñ Õ ã ñ õ"
local temp2 "a n o a n o"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace anb_name_edit = subinstr(anb_name_edit, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace anb_name_edit = subinstr(anb_name_edit, "`v'", "",.)
}
 
replace anb_name_edit = subinstr(anb_name_edit, "'", "",.)
replace anb_name_edit = subinstr(anb_name_edit, ".", "",.)
replace anb_name_edit = subinstr(anb_name_edit, `"/"', " ",.)


forval var=1/8{
replace anb_name_edit = subinstr(anb_name_edit, "    ", " ",.)

replace anb_name_edit = subinstr(anb_name_edit, "   ", " ",.)

replace anb_name_edit = subinstr(anb_name_edit, "  ", " ",.)
}

ereplace anb_name_edit = sieve(anb_name_edit), omit(0123456789)
replace anb_name_edit=subinstr(anb_name_edit,"corte suprema de justicia","",.)
replace anb_name_edit=subinstr(anb_name_edit,"csj","corte suprema de justicia",.)
replace anb_name_edit=strtrim(anb_name_edit)
replace anb_name_edit=strltrim(anb_name_edit)
replace anb_name_edit=strrtrim(anb_name_edit)


// format anb_name anb_name_edit %25s
// br anb_name anb_name_edit

egen unique_name=group(anb_name_edit)
save "${country_folder}/`country'_wip.dta", replace

keep unique_name anb_name anb_name_edit

duplicates drop anb_name_edit, force
// unique anb_name
// unique anb_name_edit
save "${country_folder}/`country'_no_dup.dta", replace
**************************************************************************
*Matching the data after dropping duplicates

use  "${country_folder}/`country'_no_dup.dta", clear

matchit unique_name anb_name_edit using "${utility_data}/country/`country'/PY_locations_archive_strategic_sourcing.dta" , idusing(unique_name_loc) txtusing(anb_name_edit_loc) sim(token) w(root) score(jaccard) g(simil_token) stopw swt(0.9) time flag(10) t(0.5) over  

bys unique_name: gen dup_count = _n
bys unique_name: gen dup_total = _N
// br unique_name dup_total dup_count if dup_total>1
gsort unique_name - simil_token
drop dup_count
bys unique_name: gen dup_count = _n
keep if dup_count==1
drop dup_total dup_count

gsort - simil_token
// format anb_name_edit anb_name_edit_loc  %50s
// br anb_name_edit anb_name_edit_loc  simil_token

*Dropping bad matches
drop if anb_name_edit=="gobierno departamental de central"
drop if anb_name_edit=="circunscripcion judicial del dpto misiones"
drop if anb_name_edit=="municipalidad de yataity del guaira"
drop if anb_name_edit=="municipalidad de mbocayaty del guaira"
drop if anb_name_edit=="instituto de trabajo social universidad nacional de asuncion"

drop simil_token
save "${country_folder}/PY_loc_matches1.dta", replace
********************************************************************************
*Performing a second match on non-matches after decreasing the search space

use "${country_folder}/PY_loc_matches1.dta", clear

merge m:1 unique_name_loc using "${utility_data}/country/`country'//PY_locations_archive_strategic_sourcing.dta" , generate(_m)
keep if _m==3
drop unique_name_loc anb_name_edit_loc anb_name _m
rename anb_town anb_city_matched
rename anb_region anb_region_matched

save "${country_folder}/PY_loc_matches2.dta", replace
********************************************************************************
*Merging matches back to the main dataset

use "${country_folder}/`country'_wip.dta", clear
merge m:1 unique_name using "${country_folder}/PY_loc_matches2.dta", generate(_m) keep(1 3)
// br unique_name anb_name anb_name_edit anb_city anb_city_matched anb_region_matched _m

********************************************************************************
*Manual fixes

*Change 1 - if buyer name contains "asuncion" -  matched to Asuncion
gen asu = regex(anb_name_edit,"asuncion")
replace anb_city_matched="asunción" if asu==1 & missing(anb_city_matched)
replace anb_region_matched="Central" if asu==1 & missing(anb_region_matched)

*Manual locations

replace anb_city_matched="asunción" if anb_name=="Auditoria General del Poder Ejecutivo (AGPE) / Presidencia de la República" & missing(anb_city_matched) 
replace anb_region_matched="Central" if anb_name=="Auditoria General del Poder Ejecutivo (AGPE) / Presidencia de la República" & missing(anb_region_matched) 

replace anb_city_matched="asunción" if anb_name=="European External Action Service (EEAS), Delegation of the European Union to Paraguay" & missing(anb_city_matched) 
replace anb_region_matched="Central" if anb_name=="European External Action Service (EEAS), Delegation of the European Union to Paraguay" & missing(anb_region_matched)

*Buyers located manually
local temp `" "Auditoria General del Poder Ejecutivo (AGPE) / Presidencia de la República" "Centro Cultural de la Republica - El Cabildo / Congreso Nacional" "Comando de la Armada Uoc 3 / Ministerio de Defensa Nacional" "Delegación de la Unión Europea en Paraguay" "Delegation of the European Union to Paraguay" "European External Action Service (EEAS), Delegation of the European Union to Paraguay" "Departamento de Licitaciones, Administración Nacional de Electricidad (ANDE)" "Dirección General de Estadisticas Encuestas y Censo (DGEEC) / Presidencia de la República" "Direccion General de Informacion Estrategica de Salud Digies-Sinais / Ministerio de Salud Pública y Bienestar Social" "Direccion General de Migraciones / Ministerio del Interior" "Direccion General de Salud Ambiental (DIGESA) / Ministerio de Salud Pública y Bienestar Social" "Direccion General del Registro del Estado Civil / Ministerio de Justicia" "Escribania Mayor de Gobierno / Presidencia de la República" "European External Action Service (EEAS), Delegation of the European Union to Paraguay" "Gabinete Civil / Presidencia de la República" "Gabinete Militar / Presidencia de la República" "'

local n_temp : word count `temp'
forval s =1/`n_temp' {
 replace anb_city_matched="asunción" if anb_name=="`: word `s' of `temp''" & missing(anb_city_matched) 
 replace anb_region_matched="Central" if anb_name=="`: word `s' of `temp''" & missing(anb_region_matched) 
	}

	
// br anb_name anb_region_matched anb_name_edit if regex(anb_name_edit,"ando de la fuerza aere") 

replace anb_city_matched="caaguazú" if regex(anb_name,"Universidad Nacional de Caaguazu") & missing(anb_city_matched)
replace anb_region_matched="Caaguazú" if regex(anb_name,"Universidad Nacional de Caaguazu") & missing(anb_region_matched)

replace anb_city_matched="ciudad del este" if regex(anb_name,"Universidad Nacional del Este") & missing(anb_city_matched)
replace anb_region_matched="Alto Paraná" if regex(anb_name,"Universidad Nacional del Este") & missing(anb_region_matched)

replace anb_city_matched="san lorenzo" if anb_name=="Direccion Nacional de Transporte (DINATRAN)" & missing(anb_city_matched) 
replace anb_region_matched="Central" if anb_name=="Direccion Nacional de Transporte (DINATRAN)" & missing(anb_region_matched) 

replace anb_city_matched="luque" if anb_name=="Comando de la Fuerza Aerea Uoc 4 / Ministerio de Defensa Nacional" & missing(anb_city_matched) 
replace anb_region_matched="Central" if anb_name=="Comando de la Fuerza Aerea Uoc 4 / Ministerio de Defensa Nacional" & missing(anb_region_matched) 

*Renaming locations using the correct names
local temp " "Alto Paraguay" "Alto Paraná" "Amambay" "Boqueron" "Caaguazú" "Caazapá" "Canindeyú" "Central" "Concepción" "Cordillera" "Guairá" "Itapúa" "Misiones" "Ñeembucú" "
local temp2 " "Alto Paraguay" "Alto Paraná" "Amambay" "Boquerón" "Caaguazú" "Caazapá" "Canindeyú" "Central" "Concepción" "Cordillera" "Guairá" "Itapúa" "Misiones" "Ñeembucú" "
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace anb_region_matched="`: word `s' of `temp2''" if regex(anb_name,"`: word `s' of `temp''") & missing(anb_region_matched) 
 replace anb_city_matched="`: word `s' of `temp2''" if regex(anb_name,"`: word `s' of `temp''") & missing(anb_city_matched) 
 }
 
replace anb_city_matched=anb_region_matched if missing(anb_city_matched) & !missing(anb_region_matched)
drop anb_name_edit  unique_name 
drop _m
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************

*More matches - manually collected 

*use "${country_folder}/`country'_wip.dta", replace

rename anb_name anb_name_orig
gen anb_name = anb_name_orig
replace anb_name = subinstr(anb_name, "á", "a", .) 
replace anb_name = subinstr(anb_name, "Á", "A", .) 
replace anb_name = subinstr(anb_name, "é", "e", .) 
replace anb_name = subinstr(anb_name, "É", "e", .) 
replace anb_name = subinstr(anb_name, "í", "i", .) 
replace anb_name = subinstr(anb_name, "Í", "i", .) 
replace anb_name = subinstr(anb_name, "ó", "o", .) 
replace anb_name = subinstr(anb_name, "Ó", "o", .) 
replace anb_name = subinstr(anb_name, "ú", "u", .) 
replace anb_name = subinstr(anb_name, "Ú", "u", .) 
replace anb_name = subinstr(anb_name, "ü", "u", .) 
replace anb_name = subinstr(anb_name, "Ü", "u", .) 
replace anb_name = subinstr(anb_name, "ñ", "n", .) 
replace anb_name = subinstr(anb_name, "Ñ", "N", .) 
replace anb_name = subinstr(anb_name, "Ãº", "u", .) 
replace anb_name = lower(anb_name)
// br anb_name_orig anb_name
merge m:1 anb_name using "${utility_data}/country/`country'//PY_locations_manual.dta", generate(_m)
// br anb_name anb_city_matched anb_region_matched anb_city_matched_man anb_region_matched_man if missing(anb_city_matched) &

drop if _m==2  //dropping unmatched from the using data

replace anb_city_matched= anb_city_matched_man if missing(anb_city_matched)
replace anb_region_matched= anb_region_matched_man if missing(anb_region_matched)
drop anb_city_matched_man anb_region_matched_man _m
// br *anb_name* anb_city_matched anb_region_matched
// br anb_name if !missing(anb_name) & missing(anb_city_matched)
********************************************************************************
*Clean up the variables and allocate a Nuts-like code

cap drop anb_country
gen anb_country="Paraguay"
gen anb_country_iso2="PY"

rename anb_city_matched anb_city
rename anb_region_matched anb_dept
********************************************************************************
*Standarizing region names

// tab anb_dept, m
replace anb_dept="Ñeembucú" if anb_dept=="neembucu"
replace anb_dept="Amambay" if regex(anb_dept,"Amambay")
replace anb_dept="Guairá" if regex(anb_dept,"guaira|guaria")
replace anb_dept="Central" if regex(anb_dept,"central")
replace anb_dept="Alto Paraná" if regex(anb_dept,"alto parana")
replace anb_dept="Itapúa" if anb_dept=="encarnacioon"
replace anb_dept="Concepción" if anb_dept=="concepcion"
replace anb_dept="Misiones" if anb_dept=="misiones"
replace anb_dept="Neembucu" if anb_dept=="ÑEembucú"
replace anb_dept=strtrim(anb_dept)
replace anb_dept=proper(anb_dept)
********************************************************************************
*Standarizing City names

// tab anb_city
replace anb_city="Encarnación" if anb_city=="encarnacioon"
replace anb_city="asunción" if anb_city=="asuncion"
replace anb_city="bella vista norte" if anb_city=="bella vista - amambay"
replace anb_city=strtrim(anb_city)
replace anb_city=proper(anb_city)
********************************************************************************
*Creating Nuts-like variable - using iso code for departments

// tab anb_dept
gen anb_dept_iso=""
local temp " "PY16" "PY10" "PY13" "PY19" "PY5" "PY6" "PY14" "PY11" "PY1" "PY3" "PY4" "PY7" "PY8" "PY12" "PY9" "PY15" "PY2" "
local temp2 " "Alto Paraguay" "Alto Paraná" "Amambay" "BoqueróN" "Caaguazú" "Caazapá" "Canindeyú" "Central" "ConcepcióN" "Cordillera" "Guairá" "ItapúA" "Misiones" "Neembucu" "Paraguarí" "Presidente Hayes" "San Pedro" "
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace anb_dept_iso="`: word `s' of `temp''" if regex(anb_dept,"`: word `s' of `temp2''") & missing(anb_dept_iso) 
 }
// tab anb_dept_iso
// tab anb_dept anb_dept_iso 

*Create nuts-like variable for cities
egen count_city=group(anb_dept_iso anb_city)
// sort anb_dept_iso anb_city
// br anb_dept_iso anb_city count_city
tostring count_city, replace
gen anb_city_iso = anb_dept_iso + count_city
// br anb_dept_iso anb_city count_city anb_city_iso
drop count_city

local temp " "PY16" "PY10" "PY13" "PY19" "PY5" "PY6" "PY14" "PY11" "PY1" "PY3" "PY4" "PY7" "PY8" "PY12" "PY9" "PY15" "PY2" "
local temp2 " "Alto Paraguay" "Alto Paraná" "Amambay" "BoqueróN" "Caaguazú" "Caazapá" "Canindeyú" "Central" "ConcepcióN" "Cordillera" "Guairá" "ItapúA" "Misiones" "Neembucu" "Paraguarí" "Presidente Hayes" "San Pedro" "
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace anb_city_iso="`: word `s' of `temp''" if regex(anb_city,"`: word `s' of `temp2''") 
 }

 // tab anb_city_iso
// drop anb_dept_iso  anb_city_iso 
********************************************************************************
save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END