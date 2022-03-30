

local components = "`0'"


// local n_components : word count `components'
// forval s=1/`n_components'{
//  di " `: word `s' of `components'' "
// }

cap drop yy*
foreach y in `components '{
di "`y' is included in the CRI"
}

cap drop yy*
foreach y in `components '{
gen yy`y'=`y'
replace yy`y'=. if `y'==.
replace yy`y'=. if `y'==9
replace yy`y'=. if `y'==99
}

cap drop cri
egen cri = rowmean(yy*) if filter_ok

cap drop yy*