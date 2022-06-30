local country "`0'"
********************************************************************************
/*This script is early stage script that uses the e-procurment product classification and translates to cpv sectors */
********************************************************************************

*Data
use "${utility_data}/country/`country'/starting_data/dfid2_cri_uy20212.dta", clear
********************************************************************************
/*Notes
The Uruguay system is an internal system, only used in the UY e-procurement system. We used an earlier categorization for a different WB project to translate the e-procurement product classification to cpv sectors.*/

sort aw_item_class_id
********************************************************************************
*fixing missing id's

decode aw_item_class_descr, gen(str_aw_item_class_descr)
gsort str_aw_item_class_descr -aw_item_class_id
bys str_aw_item_class_descr: replace aw_item_class_id=aw_item_class_id[1] if missing(aw_item_class_id) 

replace aw_item_class_id=. if missing(str_aw_item_class_descr)

drop str_aw_item_class_descr
********************************************************************************
merge m:1 aw_item_class_id using "${utility_data}/country/`country'/product_correspondance_UY.dta"
drop if _m==2
drop _m
sort cpv_div
// br aw_item_class_id cpv_div if !missing(cpv_div)
********************************************************************************
*Unmatched - w/ nonmissing product codes

// count if !missing(aw_item_class_id) & missing(cpv_div) 

decode ca_type, gen (ca_type_str)

// tab ca_type_str if !missing(aw_item_class_id) & missing(cpv_div) , m

// replace cpv_div="99100000" if !missing(aw_item_class_id) & missing(cpv_div) & ca_type_str=="goods"
// replace cpv_div="99200000" if !missing(aw_item_class_id) & missing(cpv_div) & ca_type_str=="services"
// replace cpv_div="99000000" if !missing(aw_item_class_id) & missing(cpv_div) & missing(ca_type_str)

label var aw_item_class_id "Source product code: National system"
label var cpv_div "CPV divisions : tranlsation of original national product system"
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace 
********************************************************************************
*END