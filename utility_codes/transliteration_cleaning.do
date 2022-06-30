*cap drop `1'_clean

*Transliteration and variable cleaning
*gen `1'_clean = `1'  // replace variable names
replace `1'_clean=lower(`1'_clean)

*****************************
*Replacing special chracters
*Georgian transliteration
local temp "ა ბ გ დ ე ვ ზ თ ი კ ლ მ ნ ო პ ჟ რ ს ტ უ ფ ქ ღ ყ შ ჩ ც ძ წ ჭ ხ ჯ ჰ"
local temp2 "a b g d e v z t i k l m n o p zf r s t u p k gh q sh ch ts dz ts ch kh j h" 
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Greek and cyprus Tranliteration 
local temp "Ή Ί Ύ Χ ί Ά Έ Τ Ρ Η Υ έ ό ύ ώ ή ά Α α Β β Γ γ Δ δ Ε ε Ζ ζ η Θ θ Ι ι Κ κ Λ λ Μ μ Ν ν Ξ ξ Ο ο Π π ρ Σ σ ς τ υ Φ φ χ Ψ ψ Ω ω"
local temp2 "h y x i a e t p h y e o i o i a a a b b y y th th e e z z i th th i i k k l l m m n n x x o o p p r s s s t i f f x ps o o"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Bulgarian Tranliteration
local temp "І Е А Б б В в Г г Д д Ж ж З з И и Й й К к Л л Н н М м О о П п Р р С с Т т У у Ф ф Х х Ц ц Ч ч Ш ш Щ щ Ъ ъ Ь ь Ю ю Я я"
local temp2 "i e a b b v v g g d d zh zh z z i i y y k k l l n n m m o o p p r r s s t t y y f f h h ts ts ch ch sh sh sht sht a a y y yu yu ya ya"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace dashes leaning left(1,2)
local temp "Á É Í Ó Ú á é í ó ú Ý ý ń ő Ő ű Ű ś ń"
local temp2 "a e i o u a e i o u y y n o o u u s n"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace dashes leaning right
local temp "À È Ì Ò Ù à è ì ò ù" 
local temp2 "a e i o u a e i o u"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace hut pointing up and down
local temp "Â Ê Î Ô Û â ê î ô û Č č Ě ě ň Ř ř Š š Ž ž ă"
local temp2 "a e i o u a e i o u c c e e n r r s s z z a"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace Tilde 
local temp "Ã Ñ Õ ã ñ õ"
local temp2 "a n o a n o"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}


*Replace Umlaut - two dots - one dot
local temp "Ä Ë Ï Ö Ü Ÿ ä ë ï ö ü ÿ Ṡ Ż ż"
local temp2 "a e i o u y a e i o u y s z z"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace hinge bottom - comma bottom - top
local temp "Ç ç Ş ş ș Ș Ț ț ţ Ģ Ķ ķ Ļ ļ Ņ ņ ģ"
local temp2 "c c s s s s t t t k k l l n n g"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace horizontal dash on top
local temp "Ā Ē Ī Ū ū ā ē ī"
local temp2 "a e i u u a e i"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}

*Replace other special character 
local temp " Œ œ Ø ø Å å Æ æ Ł ł ď ů Ð ß" 
local temp2 "oe oe o o a a ae ae l l d u d ss"	
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "`: word `s' of `temp2''",.)
	}
*count if regexm(`1'_clean,"ß")==1
	
*Replace other special character with empty 
local temp "« » ‹ › Þ þ ð º ° ª ¡ ¿ ¢ £ € ¥ ƒ ¤ © ® ™ • § † ‡ ¶ & “ ” ¦ ¨ ¬ ¯ ± ² ³ ´ µ · ¸ ¹ º ¼ ½ ¾"
local n_temp : word count `temp'
forval s =1/`n_temp'{
 replace `1'_clean = subinstr(`1'_clean, "`: word `s' of `temp''", "",.)
	}

*Replace other special character with empty 
*charlist `1'_clean 
*di "`r(chars)'"
*di "`r(ascii)'"
*br buyer_name `1'_clean if  regexm(`1'_clean,"`: word 65 of `r(chars)''")==1 
//!"%'()*+,-./0123456789:;<=>@[]_`abcdefghijklmnopqrstuvwxyz|���������������������������������������������������������
* "+"
local stop " "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "_" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace `1'_clean = subinstr(`1'_clean, "`v'", "",.)
}
*Replace other special character with empty 
*charlist `1'_clean 
local stop " "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" "." ":" ";" "@" "_" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace `1'_clean = subinstr(`1'_clean, "`v'", " ",.)
}
 
replace `1'_clean = subinstr(`1'_clean, "–", " ",.)
replace `1'_clean = subinstr(`1'_clean, ".", "",.)
replace `1'_clean = subinstr(`1'_clean, "—", " ",.)
replace `1'_clean = subinstr(`1'_clean, "'", "",.)
replace `1'_clean = subinstr(`1'_clean, "ʼ", "",.)
replace `1'_clean = subinstr(`1'_clean, `"$"', "",.) 
replace `1'_clean = subinstr(`1'_clean, "`", "",.) 
replace `1'_clean = subinstr(`1'_clean, `"""', "",.)
replace `1'_clean = subinstr(`1'_clean, `"/"', "",.)
replace `1'_clean = subinstr(`1'_clean, `"\"', "",.)
replace `1'_clean = subinstr(`1'_clean, "  ", " ",.)

forval var=1/8{
replace `1'_clean = subinstr(`1'_clean, "  ", " ",.)
}



