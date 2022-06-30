local country "`0'"
********************************************************************************
/*This script is early stage script that uses the tender/contract titles to find the
 relevant cpv code using keywords*/
********************************************************************************
*Data

use "${country_folder}/`country'_wip.dta", clear
********************************************************************************

*Product variable - original dataset aw_item_class_id
*Product variable - product harmonized dataset: cpv_div cpv_div_descr  

// br *title*
*Only one title varibale ten_title // ten_title_str
rename ten_title_str title
format title %35s
// br title 
// count if missing(title)
********************************************************************************
*Cleaning title

// charlist title 

// br title

local stop " "΄" "{" "}" "+" "’" "~" "!" "*" "<" ">" "[" "]" "=" "&" "(" ")" "?" "#" "^" "%"  "," "-" ":" ";" "@" "„" "´" "ʼ" "|" "`" "
foreach v of local stop {
 replace title = subinstr(title, "`v'", " ",.)
}
replace title = subinstr(title, `"""', " ",.)
replace title = subinstr(title, `"$"', " ",.) 
replace title = subinstr(title, "'", " ",.)
replace title = subinstr(title, "ʼ", " ",.)
replace title = subinstr(title, "`", " ",.) 
replace title = subinstr(title, ".", " ",.)
replace title = subinstr(title, `"/"', " ",.)
replace title = subinstr(title, `"\"', " ",.)	
replace title = subinstr(title, `"_"', " ",.)	

ereplace title = sieve(title), omit(0123456789)
replace title=lower(title) 

*Removing lone letters
*br title if regex(title," [a-z] ")
forval s = 1/122{
replace title = regexr(title," [a-z] "," ")
}
replace title = " " + title + " "
forval s = 1/2{
replace title = regexr(title," [a-z] "," ")
}
*Removing 2 letter words
replace title = " " + title + " "
forval s = 1/12{
replace title = regexr(title," [a-z][a-z] "," ")
}

forval var=1/10{
replace title = subinstr(title, "  ", " ",.)
}
replace title = stritrim(title)
replace title = strtrim(title)
// unique  title

// count if missing(ten_title)
// count if missing(title)
*Mismatch is because title had numbers instead of text
********************************************************************************
*Manual Matching from keyword list

gen cpv = ""
replace title = " " + title + " "

*First two words
replace cpv = "341000008" if regex(title," vehiculo ") & regex(title," motor ") & missing(cpv)
replace cpv = "551000001" if regex(title," servicios ") & regex(title," hotel ") & missing(cpv)
replace cpv = "501000006" if regex(title," servicio ") & regex(title," vehiculos ") & missing(cpv)
replace cpv = "501000006" if regex(title," reparacion ") & regex(title," vehiculos ") & missing(cpv)
replace cpv = "555200001" if regex(title," servicios ") & regex(title," banqueteria ") & missing(cpv)
replace cpv = "343200006" if regex(title," piezas ") & regex(title," repuesto ") & missing(cpv)
replace cpv = "501000006" if regex(title," servicio ") & regex(title," reparacion ") & missing(cpv)
replace cpv = "301900007" if regex(title," equipo ") & regex(title," oficina ") & missing(cpv)
replace cpv = "501150004" if regex(title," servicio ") & regex(title," motor ") & missing(cpv)
replace cpv = "391300002" if regex(title," muebles ") & regex(title," oficina ") & missing(cpv)
replace cpv = "501000006" if regex(title," mantenimiento ") & regex(title," coche ") & missing(cpv)
replace cpv = "301920001" if regex(title," suministros ") & regex(title," oficina ") & missing(cpv)
replace cpv = "909192004" if regex(title," limpia ") & regex(title," oficina ") & missing(cpv)
replace cpv = "398000000" if regex(title," material ") & regex(title," limpieza ") & missing(cpv)
replace cpv = "301997306" if regex(title," cartas ") & regex(title," negocios ") & missing(cpv)
replace cpv = "715200009" if regex(title," supervision ") & regex(title," construccion ") & missing(cpv)
replace cpv = "441000001" if regex(title," material ") & regex(title," construccion ") & missing(cpv)
replace cpv = "715000003" if regex(title," personal ") & regex(title," construccion ") & missing(cpv)
replace cpv = "452331206" if regex(title," construccion ") & regex(title," carreteras ") & missing(cpv)
replace cpv = "450000007" if regex(title," trabajo ") & regex(title," construccion ") & missing(cpv)
replace cpv = "300000009" if regex(title," maquinaria ") & regex(title," equipos ") & missing(cpv)
replace cpv = "411100003" if regex(title," agua ") & regex(title," potable ") & missing(cpv)
replace cpv = "797100004" if regex(title," servicios ") & regex(title," seguridad ") & missing(cpv)
replace cpv = "446000006" if regex(title," deposito ") & regex(title," agua ") & missing(cpv)
replace cpv = "710000008" if regex(title," servicios ") & regex(title," consultoria ") & missing(cpv)
replace cpv = "302000001" if regex(title," equipos ") & regex(title," informaticos ") & missing(cpv)
replace cpv = "300000009" if regex(title," equipo ") & regex(title," oficina ") & missing(cpv)
replace cpv = "452331419" if regex(title," mantenimiento ") & regex(title," rutina ") & missing(cpv)
replace cpv = "452331419" if regex(title," mantenimiento ") & regex(title," carreteras ") & missing(cpv)
replace cpv = "452500004" if regex(title," central ") & regex(title," electrica ") & missing(cpv)
replace cpv = "600000008" if regex(title," alquiler ") & regex(title," transporte ") & missing(cpv)
replace cpv = "713000001" if regex(title," consultoria ") & regex(title," agua ") & missing(cpv)
replace cpv = "905132008" if regex(title," residuo ") & regex(title," solido ") & missing(cpv)
replace cpv = "430000003" if regex(title," equipo ") & regex(title," trabajo ") & missing(cpv)
replace cpv = "351217005" if regex(title," sistema ") & regex(title," alarma ") & missing(cpv)
replace cpv = "351200001" if regex(title," sistema ") & regex(title," seguridad ") & missing(cpv)
replace cpv = "665122004" if regex(title," seguro ") & regex(title," salud ") & missing(cpv)
replace cpv = "804100001" if regex(title," entrega ") & regex(title," escuela ") & missing(cpv)
replace cpv = "349200002" if regex(title," equipo ") & regex(title," carretera ") & missing(cpv)

* Two words originally one word 
replace cpv = "501000006" if regex(title," reparacion ") & regex(title," motor ") & missing(cpv)
replace cpv = "349800000" if regex(title," boleto ") & regex(title," aereo ") & missing(cpv)
replace cpv = "349800000" if regex(title," volvemos ") & regex(title," aire ") & missing(cpv)
replace cpv = "551200007" if regex(title," instalaciones ") & regex(title," conferencias ") & missing(cpv)
replace cpv = "452000009" if regex(title," obras ") & regex(title," civiles ") & missing(cpv)
replace cpv = "501000006" if regex(title," servicio ") & regex(title," reparacion ") & missing(cpv)
replace cpv = "909100009" if regex(title," servicios ") & regex(title," limpieza ") & missing(cpv)
replace cpv = "425100004" if regex(title," aire ") & regex(title," acondicionado ") & missing(cpv)
replace cpv = "331000001" if regex(title," ensayos ") & regex(title," reactivos ") & missing(cpv)
replace cpv = "703000004" if regex(title," lugar ") & regex(title," eventos ") & missing(cpv)
replace cpv = "302000001" if regex(title," medios ") & regex(title," comunicacion ") & missing(cpv)
replace cpv = "302000001" if regex(title," ordenador ") & regex(title," portatil ") & missing(cpv)
replace cpv = "551200007" if regex(title," facililty ") & regex(title," conferencia ") & missing(cpv)
replace cpv = "425120008" if regex(title," condititioner ") & regex(title," aire ") & missing(cpv)
replace cpv = "904000001" if regex(title," aguas ") & regex(title," residuales ") & missing(cpv)
replace cpv = "336000006" if regex(title," para ") & regex(title," drogas ") & missing(cpv)

*One words
replace cpv = "450000007" if regex(title," construccion ") & missing(cpv)
replace cpv = "798100005" if regex(title," impresion ") & missing(cpv)
replace cpv = "302000001" if regex(title," computadora ") & missing(cpv)
replace cpv = "330000000" if regex(title," medico ") & missing(cpv)
replace cpv = "800000004" if regex(title," formacion ") & missing(cpv)
replace cpv = "551000001" if regex(title," hotel ") & missing(cpv)
replace cpv = "480000008" if regex(title," software ") & missing(cpv)
replace cpv = "343500005" if regex(title," llantas ") & missing(cpv)
replace cpv = "390000002" if regex(title," mueble ") & missing(cpv)
replace cpv = "228000008" if regex(title," libros ") & missing(cpv)
replace cpv = "551200007" if regex(title," conferencia ") & missing(cpv)
replace cpv = "391100006" if regex(title," sillas ") & missing(cpv)
replace cpv = "800000004" if regex(title," taller ") & missing(cpv)
replace cpv = "150000008" if regex(title," comida ") & missing(cpv)
replace cpv = "301000000" if regex(title," impresora ") & missing(cpv)
replace cpv = "301000000" if regex(title," virador ") & missing(cpv)
replace cpv = "311000007" if regex(title," generador ") & missing(cpv)
replace cpv = "330000000" if regex(title," pruebas ") & missing(cpv)
replace cpv = "150000008" if regex(title," comidas ") & missing(cpv)
replace cpv = "660000000" if regex(title," seguro ") & missing(cpv)
replace cpv = "320000003" if regex(title," radio ") & missing(cpv)
replace cpv = "330000000" if regex(title," laboratorio ") & missing(cpv)
replace cpv = "150000008" if regex(title," almuerzo ") & missing(cpv)
replace cpv = "150000008" if regex(title," refrescos ") & missing(cpv)
replace cpv = "301200006" if regex(title," photocop ") & missing(cpv)
replace cpv = "793400009" if regex(title," publicidad ") & missing(cpv)
replace cpv = "799000003" if regex(title," viaje ") & missing(cpv)
replace cpv = "150000008" if regex(title," cafe ") & missing(cpv)
replace cpv = "310000006" if regex(title," electrico ") & missing(cpv)
replace cpv = "150000008" if regex(title," te ") & missing(cpv)
replace cpv = "421200006" if regex(title," bomba ") & missing(cpv)
replace cpv = "482000000" if regex(title," internet ") & missing(cpv)
replace cpv = "712500005" if regex(title," encuesta ") & missing(cpv)
replace cpv = "751250008" if regex(title," turismo ") & missing(cpv)
replace cpv = "93000002" if regex(title," solar ") & missing(cpv)
replace cpv = "337100000" if regex(title," bano ") & missing(cpv)
replace cpv = "800000004" if regex(title," educacion ") & missing(cpv)
replace cpv = "488000006" if regex(title," servidor ") & missing(cpv)
replace cpv = "799800007" if regex(title," suscripcion ") & missing(cpv)
replace cpv = "391000003" if regex(title," escritorios ") & missing(cpv)
replace cpv = "224000004" if regex(title," certificado ") & missing(cpv)
replace cpv = "349000006" if regex(title," seguridad ") & missing(cpv)
replace cpv = "302000001" if regex(title," digital ") & missing(cpv)
replace cpv = "791000005" if regex(title," legal ") & missing(cpv)
replace cpv = "799540006" if regex(title," partido ") & missing(cpv)
replace cpv = "906000003" if regex(title," saneamiento ") & missing(cpv)
replace cpv = "551100004" if regex(title," alojamiento ") & missing(cpv)
replace cpv = "336000006" if regex(title," drogas ") & missing(cpv)
replace cpv = "358000002" if regex(title," uniformes ") & missing(cpv)
replace cpv = "453400002" if regex(title," esgrima ") & missing(cpv)
replace cpv = "441000001" if regex(title," plomeria ") & missing(cpv)
replace cpv = "793410006" if regex(title," anuncios ") & missing(cpv)
replace cpv = "222000002" if regex(title," periodico ") & missing(cpv)
replace cpv = "398000000" if regex(title," limpieza ") & missing(cpv)
replace cpv = "722000007" if regex(title," licencia ") & missing(cpv)
replace cpv = "710000008" if regex(title," estudiar ") & missing(cpv)
replace cpv = "600000008" if regex(title," transporte ") & missing(cpv)
replace cpv = "320000003" if regex(title," telecomunicacion ") & missing(cpv)
replace cpv = "320000003" if regex(title," comunicacion ") & missing(cpv)
replace cpv = "91200006" if regex(title," gas ") & missing(cpv)
replace cpv = "391411003" if regex(title," estanteria ") & missing(cpv)
replace cpv = "330000000" if regex(title," tubo ") & missing(cpv)
replace cpv = "349800000" if regex(title," boleto ") & missing(cpv)
replace cpv = "722000007" if regex(title," configuracion ") & missing(cpv)
replace cpv = "150000008" if regex(title," botella ") & missing(cpv)
replace cpv = "452310005" if regex(title," agua ") & missing(cpv)
replace cpv = "452310005" if regex(title," tubo ") & missing(cpv)
replace cpv = "555200001" if regex(title," abastecimiento ") & missing(cpv)
replace cpv = "797100004" if regex(title," seguridad ") & missing(cpv)
replace cpv = "501000006" if regex(title," vehiculo ") & missing(cpv)
replace cpv = "452000009" if regex(title," renovacion ") & missing(cpv)
replace cpv = "183300001" if regex(title," camisas ") & missing(cpv)
replace cpv = "302000001" if regex(title," tic ") & missing(cpv)
replace cpv = "223000003" if regex(title," tarjetas ") & missing(cpv)
replace cpv = "316000002" if regex(title," fuego ") & missing(cpv)
replace cpv = "324000007" if regex(title," red ") & missing(cpv)
replace cpv = "391100006" if regex(title," silla ") & missing(cpv)
replace cpv = "302000001" if regex(title," microsoft ") & missing(cpv)
replace cpv = "146220007" if regex(title," acero ") & missing(cpv)
replace cpv = "220000000" if regex(title," impresion ") & missing(cpv)
replace cpv = "431000004" if regex(title," perforacion ") & missing(cpv)
replace cpv = "551000001" if regex(title," tienda ") & missing(cpv)
replace cpv = "661710009" if regex(title," auditoria ") & missing(cpv)
replace cpv = "452511411" if regex(title," geotermica ") & missing(cpv)
replace cpv = "430000003" if regex(title," equipar ") & missing(cpv)
replace cpv = "441631128" if regex(title," drenaje ") & missing(cpv)
replace cpv = "310000006" if regex(title," electrico ") & missing(cpv)
replace cpv = "454000001" if regex(title," edificio ") & missing(cpv)
replace cpv = "452324525" if regex(title," desague ") & missing(cpv)
replace cpv = "336000006" if regex(title," farmaceutico ") & missing(cpv)
replace cpv = "330000000" if regex(title," laboratorio ") & missing(cpv)
replace cpv = "302000001" if regex(title," datos ") & missing(cpv)
replace cpv = "301900007" if regex(title," papel ") & missing(cpv)
replace cpv = "905110002" if regex(title," residuos ") & missing(cpv)
replace cpv = "220000000" if regex(title," impreso ") & missing(cpv)
replace cpv = "340000007" if regex(title," transporte ") & missing(cpv)
replace cpv = "805210002" if regex(title," programa ") & missing(cpv)
replace cpv = "796200006" if regex(title," personal ") & missing(cpv)
replace cpv = "452113105" if regex(title," bano ") & missing(cpv)
replace cpv = "240000004" if regex(title," quimico ") & missing(cpv)
replace cpv = "441140002" if regex(title," hormigon ") & missing(cpv)
replace cpv = "909000006" if regex(title," sanit ") & missing(cpv)
replace cpv = "907221005" if regex(title," rehabilitacion ") & missing(cpv)
replace cpv = "703100007" if regex(title," alquiler ") & missing(cpv)
replace cpv = "331000001" if regex(title," miscelanea ") & missing(cpv)
replace cpv = "349220006" if regex(title," esgrima ") & missing(cpv)
replace cpv = "336900003" if regex(title," laborary ") & missing(cpv)
replace cpv = "660000000" if regex(title," financiero ") & missing(cpv)
replace cpv = "726000006" if regex(title," apoyo ") & missing(cpv)
replace cpv = "443164002" if regex(title," hardware ") & missing(cpv)
replace cpv = "228150006" if regex(title," dell ") & missing(cpv)
replace cpv = "451112134" if regex(title," despeje ") & missing(cpv)
replace cpv = "794000008" if regex(title," negocio ") & missing(cpv)
replace cpv = "451110008" if regex(title," escombros ") & missing(cpv)
replace cpv = "325000008" if regex(title," comunic ") & missing(cpv)
replace cpv = "336000006" if regex(title," pharma ") & missing(cpv)
replace cpv = "553200009" if regex(title," comida ") & missing(cpv)
replace cpv = "983410005" if regex(title," alojar ") & missing(cpv)
replace cpv = "452626409" if regex(title," cojinete ") & missing(cpv)
replace cpv = "452142002" if regex(title," colegio ") & missing(cpv)
replace cpv = "80000000" if regex(title," educat ") & missing(cpv)
replace cpv = "349282000" if regex(title," cerca ") & missing(cpv)
replace cpv = "454300000" if regex(title," piso ") & missing(cpv)
replace cpv = "452130003" if regex(title," almacen ") & missing(cpv)
replace cpv = "91341008" if regex(title," diesel ") & missing(cpv)
replace cpv = "249511006" if regex(title," manute ") & missing(cpv)
replace cpv = "442212007" if regex(title," puertas ") & missing(cpv)
replace cpv = "453143107" if regex(title," cableado ") & missing(cpv)
replace cpv = "452332221" if regex(title," asfalto ") & missing(cpv)
replace cpv = "331400003" if regex(title," tira ") & missing(cpv)
replace cpv = "331400003" if regex(title," sangre ") & missing(cpv)
replace cpv = "793420003" if regex(title," marketing ") & missing(cpv)
replace cpv = "331100004" if regex(title," radiografia ") & missing(cpv)
replace cpv = "323220006" if regex(title," multimedia ") & missing(cpv)
replace cpv = "331510003" if regex(title," oxigeno ") & missing(cpv)
replace cpv = "341444318" if regex(title," succion ") & missing(cpv)
replace cpv = "301927008" if regex(title," papeleria ") & missing(cpv)
replace cpv = "391413005" if regex(title," gabinete ") & missing(cpv)
replace cpv = "442111106" if regex(title," cabina ") & missing(cpv)
replace cpv = "249511006" if regex(title," lubricantes ") & missing(cpv)
replace cpv = "91000000" if regex(title," combustible ") & missing(cpv)
********************************************************************************

replace title = stritrim(title)
replace title = strtrim(title)

// br title cpv cpv_div if !missing(cpv) & !missing(cpv_div)
gen cpv_div2 = cpv_div + "000000"
replace cpv = cpv_div2 if !missing(cpv_div)
cap drop cpv_div2 cpv_div 
cap drop cpv_div_descr
********************************************************************************
*More Manual matching

// br title if missing(cpv)
bys title: gen X=_N
bys title: gen x=_n
gsort -X
// br title X  cpv if missing(cpv) & !missing(title) & x==1
*******************************

replace title = " " + title + " "

replace cpv="15000000"  if regex(title," abarrotes ") & missing(cpv)
replace cpv="32210000" if regex(title," transmisi ") & regex(title," eventos ") & regex(title," euipos ")  & missing(cpv)
replace cpv="64200000" if regex(title," transmisi ") & regex(title," eventos ") & missing(cpv)
replace cpv="15241300"  if regex(title," sardina ") & missing(cpv)
replace cpv="15411100" if regex(title," vegetal ") & regex(title," comestible ") & missing(cpv)
replace cpv="15710000"  if regex(title," alimentos ") & regex(title," pecuarios ") & missing(cpv)
replace cpv="73200000"  if regex(title," elaboracion ") & regex(title," avaluos ") & regex(title," servicios ") & missing(cpv)
replace cpv="39291000"  if regex(title," suavizantes ") & regex(title," tela ") & missing(cpv)
replace cpv="39291000"  if regex(title," blanqueadores ") & missing(cpv)
replace cpv="15511000"  if regex(title," leche ") & missing(cpv)
replace cpv="15800000"  if regex(title," galletas ") & missing(cpv)
replace cpv="15331131"  if regex(title," frijol ") & regex(title," envasado ") & missing(cpv)
replace cpv="15871273"  if regex(title," mayonesas ") & missing(cpv)
replace cpv="15891400"  if regex(title," consomes ") & missing(cpv)
replace cpv="15612210"  if regex(title," harina  ") & regex(title," maiz   ") & missing(cpv)
replace cpv="39225600"  if regex(title," veladoras ") & missing(cpv)
replace cpv="15400000"  if regex(title," comestible ") & regex(title," aceite ") & missing(cpv)
replace cpv="15871000"  if regex(title," salsa ") & regex(title," picante ") & missing(cpv)
replace cpv="79600000"  if regex(title," contratar ") & regex(title," servicios ") & missing(cpv)
replace cpv="79600000"  if regex(title," servicios ") & regex(title," abogados ") & missing(cpv)
replace cpv="15612150"  if regex(title," harina para hotcakes ") & missing(cpv)
replace cpv="24400000"  if regex(title," fertilizante ") & missing(cpv)
replace cpv="15980000"  if regex(title," bebidas ") & regex(title," gravados ") & missing(cpv)
replace cpv="03221230"  if regex(title," jalapenos ") & missing(cpv)
replace cpv="39225300"  if regex(title," cerillos ") & missing(cpv)
replace cpv="18213000"  if regex(title," chamarra ") & regex(title," rompevientos ") & missing(cpv)
replace cpv="15500000"  if regex(title," formula ") & regex(title," lacteas ") & missing(cpv)
replace cpv="33600000"  if regex(title," medicinas ") & regex(title," adquisici ") & missing(cpv)
replace cpv="33600000"  if regex(title," medicamento ") & regex(title," material ") & missing(cpv)
replace cpv="33600000"  if regex(title," medicinas ") & regex(title," patente ") & missing(cpv)
replace cpv="33600000"  if regex(title," medicinas ")  & missing(cpv)
replace cpv="33600000"  if regex(title," medicos ") &  regex(title," suministros ") & missing(cpv)
replace cpv="03211000"  if regex(title," amaranto ") & missing(cpv)
replace cpv="39291000"  if regex(title," detergente ") & missing(cpv)
replace cpv="37421000"  if regex(title," terapeutico ") & regex(title," mat ") & missing(cpv)
replace cpv="79600000"  if regex(title," contratacion ") & regex(title," servicios ") & regex(title," profesionales ") & missing(cpv)
replace cpv="50110000"  if regex(title," mantenimiento ") & regex(title," automotriz ") & regex(title," profesionales ") & missing(cpv)
replace cpv="50110000"  if regex(title," mantenimiento ") & regex(title," conservaci ") & regex(title," vehiculos ") & regex(title," terrestres ") & regex(title," aereos ") & missing(cpv)
replace cpv="50110000"  if regex(title," mantenimiento ") & regex(title," vehiculos ") & missing(cpv)

************************************
drop X x
replace title=strtrim(title)
replace title=strltrim(title)
********************************************************************************

save "${country_folder}/`country'_wip.dta", replace
********************************************************************************
*END