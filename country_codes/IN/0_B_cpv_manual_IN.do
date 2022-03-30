*Macros
local dir : pwd
local root = substr("`dir'",1,strlen("`dir'")-17)
global country_folder "`dir'"
global utility_codes "`root'\utility_codes"
global utility_data "`root'\utility_data"
macro list
********************************************************************************
/*This script is early stage script that uses the tender/contract titles to find the
 relevant cpv code using keywords*/
********************************************************************************

*Data
use $country_folder/IN_wip, clear
********************************************************************************

destring cpv_code, gen (cpv_code2)
drop cpv_code
rename cpv_code2 cpv_code

replace cpv_code=24300000  if regex(title,"acetone") & missing(cpv_code)
replace cpv_descr="Basic inorganic and organic chemicals"  if regex(title,"acetone") & cpv_code==24300000

replace cpv_code=16340000  if regex(title,"crop thresher") & missing(cpv_code)
replace cpv_descr="Harvesting and threshing machinery"  if regex(title,"crop thresher") & cpv_code==16340000

replace cpv_code=45000000  if regex(title,"civil|civil works|works") & missing(cpv_code)
replace cpv_descr="Construction work"  if regex(title,"civil|civil works|works") & cpv_code==45000000


replace cpv_code="797100004"  if regex(title,"security") & regex(title,"services") & missing(cpv_code)

replace cpv_descr="Security services"  if regex(title,"security") & regex(title,"services") & cpv_code=="797100004"

replace cpv_code="722240001"  if regex(title,"consultancy services") & missing(cpv_code)
replace cpv_descr="Project management consultancy services"  if regex(title,"consultancy services") & cpv_code=="722240001"

replace cpv_code="905132008"  if regex(title,"solid") & regex(title,"waste") & missing(cpv_code)
replace cpv_descr="Urban solid-refuse disposal services"  if regex(title,"solid") & regex(title,"waste") & cpv_code=="905132008"

replace cpv_code="450000007"  if regex(title,"construction") & missing(cpv_code)
replace cpv_descr="Construction work"  if regex(title,"construction") & cpv_code=="450000007"

replace cpv_code="425120008" if regex(title,"air") & regex(title,"condit") & missing(cpv_code)
replace cpv_descr="Air-conditioning installations"  if regex(title,"air") & regex(title,"condit") & cpv_code=="425120008"

replace cpv_code="330000000" if regex(title,"medical") & missing(cpv_code)
replace cpv_descr="Medical equipments, pharmaceuticals and personal care products"  if regex(title,"medical") & cpv_code=="330000000"

replace cpv_code="500000005"  if regex(title,"maintenance|repair") & missing(cpv_code)
replace cpv_descr="Repair and maintenance services"  if regex(title,"maintenance|repair") & cpv_code=="500000005"

replace cpv_code="805000009"  if regex(title,"training") & missing(cpv_code)
replace cpv_descr="Training services"  if regex(title,"training") & cpv_code=="805000009"

replace cpv_code="430000003"  if regex(title,"equip") & regex(title,"labour") & missing(cpv_code)
replace cpv_descr="Machinery for mining, quarrying, construction equipment"  if regex(title,"equip") & regex(title,"labour") & cpv_code=="430000003"

replace cpv_code="430000003"  if regex(title,"equip") & missing(cpv_code)
replace cpv_descr="Machinery for mining, quarrying, construction equipment"  if regex(title,"equip") & cpv_code=="430000003"

replace cpv_code="900000007"  if regex(title,"cleaning") & missing(cpv_code)
replace cpv_descr="Sewage-, refuse-, cleaning-, and environmental services"  if regex(title,"cleaning") & cpv_code=="900000007"

replace cpv_code="720000005"  if regex(title,"software") & missing(cpv_code)
replace cpv_descr="IT services: consulting, software development, Internet and support"  if regex(title,"software") & cpv_code=="720000005"

replace cpv_code="480000008"  if regex(title,"software") & regex(title,"package") & missing(cpv_code)
replace cpv_descr="Software package and information systems"  if regex(title,"software") & regex(title,"package") & cpv_code=="480000008"

replace cpv_code="351217005"  if regex(title,"system") & regex(title,"alarm") & missing(cpv_code)
replace cpv_descr="Alarm systems"  if regex(title,"system") & regex(title,"alarm") & cpv_code=="351217005"

replace cpv_code="351200001"  if regex(title,"system") & regex(title,"security") & missing(cpv_code)
replace cpv_descr="Surveillance and security systems and devices"  if regex(title,"system") & regex(title,"security") & cpv_code=="351200001"

replace cpv_code="441631128"  if regex(title,"drainage") & missing(cpv_code)
replace cpv_descr="Drainage system"  if regex(title,"drainage") & cpv_code=="441631128"

replace cpv_code="310000006"  if regex(title,"electric") & missing(cpv_code)
replace cpv_descr="Electrical machinery, apparatus, equipment and consumables; Lighting"  if regex(title,"electric") & cpv_code=="310000006"

replace cpv_code="302000001"  if regex(title,"computer") & missing(cpv_code)
replace cpv_descr="Computer equipment and supplies"  if regex(title,"computer") &cpv_code=="302000001"

replace cpv_code="454000001"  if regex(title,"building") & missing(cpv_code)
replace cpv_descr="Building completion work"  if regex(title,"building") &cpv_code=="454000001"

replace cpv_code="792120003"  if regex(title,"audit") & missing(cpv_code)
replace cpv_descr="Auditing services"  if regex(title,"audit") &cpv_code=="792120003"

replace cpv_code="452324525"  if regex(title,"drain") & missing(cpv_code)
replace cpv_descr="Drainage works"  if regex(title,"drain") &cpv_code=="452324525"

replace cpv_code="336000006"  if regex(title,"pharmaceutical") & missing(cpv_code)
replace cpv_descr="Pharmaceutical products"  if regex(title,"pharmaceutical") & cpv_code=="336000006"

replace cpv_code="330000000"  if regex(title,"lab") & missing(cpv_code)
replace cpv_descr="Medical equipments, pharmaceuticals and personal care products"  if regex(title,"lab") & cpv_code=="330000000"

replace cpv_code="450000000"  if regex(title,"water") & regex(title,"const") & missing(cpv_code)
replace cpv_descr="Construction work"  if regex(title,"water") & regex(title,"const") & cpv_code=="450000000"

replace cpv_code="798100005"  if regex(title,"printing") & missing(cpv_code)
replace cpv_descr="Printing services"  if regex(title,"printing") & cpv_code=="798100005"

replace cpv_code="665122004"  if regex(title,"health") & regex(title,"insurance") & missing(cpv_code)
replace cpv_descr="Health insurance services"  if regex(title,"health") & regex(title,"insurance") & cpv_code=="665122004"

replace cpv_code="336000006"  if regex(title,"drugs")  & missing(cpv_code)
replace cpv_descr="Pharmaceutical products"  if regex(title,"drugs") & cpv_code=="336000006"

replace cpv_code="324000007"  if regex(title,"network")  & missing(cpv_code)
replace cpv_descr="Networks"  if regex(title,"network") & cpv_code=="324000007"

replace cpv_code="421220000"  if regex(title,"pump")  & missing(cpv_code)
replace cpv_descr="Pumps"  if regex(title,"pump") & cpv_code=="421220000"

replace cpv_code="555200001"  if regex(title,"catering")  & missing(cpv_code)
replace cpv_descr="Catering services"  if regex(title,"catering") & cpv_code=="555200001"

replace cpv_code="391000003"  if regex(title,"furniture")  & missing(cpv_code)
replace cpv_descr="Furniture"  if regex(title,"furniture") & cpv_code=="391000003"

replace cpv_code="302000001"  if regex(title,"data")  & missing(cpv_code)
replace cpv_descr="Computer equipment and supplies"  if regex(title,"data") & cpv_code=="302000001"

replace cpv_code="301900007"  if regex(title,"paper")  & missing(cpv_code)
replace cpv_descr="Various office equipment and supplies"  if regex(title,"paper") & cpv_code=="301900007"

replace cpv_code="905110002" if regex(title,"waste")  & missing(cpv_code)
replace cpv_descr="Refuse collection services"  if regex(title,"waste") & cpv_code=="905110002"

replace cpv_code="220000000"  if regex(title,"printed")  & missing(cpv_code)
replace cpv_descr="Printed matter and related products"  if regex(title,"printed") & cpv_code=="220000000"

replace cpv_code="301000000"  if regex(title,"printer")  & missing(cpv_code)
replace cpv_descr="Office machinery, equipment and supplies except computers, printers and furniture"  if regex(title,"printer") & cpv_code=="301000000"

replace cpv_code="349200002"  if regex(title,"road")  & missing(cpv_code)
replace cpv_descr="Road equipment"  if regex(title,"road") & cpv_code=="349200002"

replace cpv_code="340000007"  if regex(title,"transport")  & missing(cpv_code)
replace cpv_descr="Transport equipment and auxiliary products to transportation" if regex(title,"transport") & cpv_code=="340000007"

replace cpv_code="441142200"  if regex(title,"pipe")  & missing(cpv_code)
replace cpv_descr="Concrete pipes and fittings"  if regex(title,"pipe") & cpv_code=="441142200"

replace cpv_code="805210002"  if regex(title,"programme")  & missing(cpv_code)
replace cpv_descr="Training programme services"  if regex(title,"programme") & cpv_code=="805210002"

replace cpv_code="796200006"  if regex(title,"staff")  & missing(cpv_code)
replace cpv_descr="Supply services of personnel including temporary staff"  if regex(title,"staff") & cpv_code=="796200006"

replace cpv_code="713550001"  if regex(title,"survey")  & missing(cpv_code)
replace cpv_descr="Surveying services"  if regex(title,"survey") & cpv_code=="713550001"

replace cpv_code="452113105"  if regex(title,"bathroom")  & missing(cpv_code)
replace cpv_descr="Bathrooms construction work"  if regex(title,"bathroom") & cpv_code=="452113105"

/*replace cpv_code=91340007  if regex(title,"gas")  & missing(cpv_code)
replace cpv_descr=""  if regex(title,"gas") & cpv_code==91340007*/

replace cpv_code="240000004"  if regex(title,"chemical")  & missing(cpv_code)
replace cpv_descr="Chemical products"  if regex(title,"chemical") & cpv_code=="240000004"

replace cpv_code="441140002"  if regex(title,"concrete")  & missing(cpv_code)
replace cpv_descr="Concrete"  if regex(title,"concrete") & cpv_code=="441140002"

replace cpv_code="909000006"  if regex(title,"sanit")  & missing(cpv_code)
replace cpv_descr="Cleaning and sanitation services"  if regex(title,"sanit") & cpv_code=="909000006"

replace cpv_code="907221005"  if regex(title,"rehabilitation")  & missing(cpv_code)
replace cpv_descr="Industrial site rehabilitation"  if regex(title,"rehabilitation") & cpv_code=="907221005"

replace cpv_code="703100007"  if regex(title,"rental")  & missing(cpv_code)
replace cpv_descr="Building rental or sale services"  if regex(title,"rental") & cpv_code=="703100007"

replace cpv_code="331000001"  if regex(title,"sundries")  & missing(cpv_code)
replace cpv_descr="Medical equipments"  if regex(title,"sundries") & cpv_code=="331000001"

replace cpv_code="331000001"  if regex(title,"fencing")  & missing(cpv_code)
replace cpv_descr="Road-marking equipment"  if regex(title,"fencing") & cpv_code=="331000001"

replace cpv_code="301220000"  if regex(title,"machine") & regex(title,"cop")  & missing(cpv_code)
replace cpv_descr="Office-type offset printing machinery"  if regex(title,"machine") & regex(title,"cop") & cpv_code=="301220000"

replace cpv_code="301220000"  if regex(title,"machine") & regex(title,"ray")  & missing(cpv_code)
replace cpv_descr="Imaging equipment for medical, dental and veterinary use"  if regex(title,"machine") & regex(title,"ray") & cpv_code=="301220000"

replace cpv_code="500000005"  if regex(title,"renovation")  & missing(cpv_code)
replace cpv_descr="Repair and maintenance services"  if regex(title,"renovation") & cpv_code=="500000005"

replace cpv_code="336900003"  if regex(title,"laborary")  & missing(cpv_code)
replace cpv_descr="Various medicinal products"  if regex(title,"laborary") & cpv_code=="336900003"

replace cpv_code="660000000"  if regex(title,"financial")  & missing(cpv_code)
replace cpv_descr="Financial and insurance services"  if regex(title,"financial") & cpv_code=="660000000"

replace cpv_code="797100004"  if regex(title,"security")  & missing(cpv_code)
replace cpv_descr="Security services"  if regex(title,"security") & cpv_code=="797100004"

replace cpv_code="726000006"  if regex(title,"support") & regex(title,"computer")  & missing(cpv_code)
replace cpv_descr="Computer support and consultancy services"  if regex(title,"support") & regex(title,"computer") & cpv_code=="726000006"

replace cpv_code="799800007"  if regex(title,"subscription") & missing(cpv_code)
replace cpv_descr="Subscription services"  if regex(title,"subscription") & cpv_code=="799800007"

replace cpv_code="443164002"  if regex(title,"hardware") & missing(cpv_code)
replace cpv_descr="Hardware"  if regex(title,"hardware") & cpv_code=="443164002"

replace cpv_code="30210000"  if regex(title," dell ") & missing(cpv_code)
replace cpv_descr="Data-processing machines (hardware)"  if regex(title," dell ") & cpv_code=="30210000"

replace cpv_code="794000008"  if regex(title,"business") & missing(cpv_code)
replace cpv_descr="Business and management consultancy and related services"  if regex(title,"business") & cpv_code=="794000008"

replace cpv_code="904000001"  if regex(title,"sewage") & missing(cpv_code)
replace cpv_descr="Sewage services"  if regex(title,"sewage") & cpv_code=="904000001"

replace cpv_code="665100008"  if regex(title,"insurance") & missing(cpv_code)
replace cpv_descr="Insurance services"  if regex(title,"insurance") & cpv_code=="665100008"

replace cpv_code="451110008"  if regex(title,"debris") & missing(cpv_code)
replace cpv_descr="Demolition, site preparation and clearance work"  if regex(title,"debris") & cpv_code=="451110008"

replace cpv_code="150000008"  if regex(title,"food") & missing(cpv_code)
replace cpv_descr="Food, beverages, tobacco and related products"  if regex(title,"food") & cpv_code=="150000008"

replace cpv_code="325000008"  if regex(title,"communic") & missing(cpv_code)
replace cpv_descr="Telecommunications equipment and supplies"  if regex(title,"communic") & cpv_code=="325000008"

replace cpv_code="336000006"  if regex(title,"drug") & regex(title,"order") & missing(cpv_code)
replace cpv_descr="Pharmaceutical products"  if regex(title,"drug") & regex(title,"order")  & cpv_code=="336000006"

replace cpv_code="336000006"  if regex(title,"pharma") & missing(cpv_code)
replace cpv_descr="Pharmaceutical products"  if regex(title,"pharma") & cpv_code=="336000006"

replace cpv_code="553200009"  if regex(title,"meal") & missing(cpv_code)
replace cpv_descr="Meal-serving services"  if regex(title,"meal") & cpv_code=="553200009"

replace cpv_code="983410005"  if regex(title," accomm") & missing(cpv_code)
replace cpv_descr="Accommodation services"  if regex(title," accomm") & cpv_code=="983410005"

replace cpv_code="551200007"  if regex(title,"conference") & missing(cpv_code)
replace cpv_descr="Hotel meeting and conference services"  if regex(title,"conference") & cpv_code=="551200007"

replace cpv_code="146220007"  if regex(title,"steel") & missing(cpv_code)
replace cpv_descr="Steel"  if regex(title,"conference") & cpv_code=="146220007"

replace cpv_code="343500005"  if regex(title,"tyres") & missing(cpv_code)
replace cpv_descr="Tyres for heavy/light duty vehicles"  if regex(title,"tyres") & cpv_code=="343500005"

replace cpv_code="452626409"  if regex(title,"bushing") & missing(cpv_code)
replace cpv_descr="Environmental improvement works"  if regex(title,"bushing") & cpv_code=="452626409"

replace cpv_code="804100001"  if regex(title,"school") & regex(title,"delivery") & missing(cpv_code)
replace cpv_descr="Various school services"  if regex(title,"school")  & regex(title,"delivery") & cpv_code=="804100001"

replace cpv_code="452142002"  if regex(title,"school") & missing(cpv_code)
replace cpv_descr="Construction work for school buildings"  if regex(title,"school") & cpv_code=="452142002"

replace cpv_code="80000000"  if regex(title,"educat") & missing(cpv_code)
replace cpv_descr="Education and training services"  if regex(title,"educat") & cpv_code=="80000000"

replace cpv_code="301927008"  if regex(title,"stationery") & missing(cpv_code)
replace cpv_descr="Stationery"  if regex(title,"stationery") & cpv_code=="301927008"

replace cpv_code="349282000"  if regex(title,"fence") & missing(cpv_code)
replace cpv_descr="Fences"  if regex(title,"fence") & cpv_code=="349282000"

replace cpv_code="454300000"  if regex(title,"floor") & missing(cpv_code)
replace cpv_descr="Floor and wall covering work"  if regex(title,"floor") & cpv_code=="454300000"

replace cpv_code="452130003"  if regex(title,"warehouse") & missing(cpv_code)
replace cpv_descr="Construction work for commercial buildings, warehouses and industrial buildings, buildings relating to transport"  if regex(title,"warehouse") & cpv_code=="452130003"

replace cpv_code="09100000"  if regex(title,"fuel") & missing(cpv_code)
replace cpv_descr="Fuels"  if regex(title,"fuel") & cpv_code=="09100000"

replace cpv_code="09134100"  if regex(title,"diesel") & missing(cpv_code)
replace cpv_descr="Diesel oil"  if regex(title,"diesel") & cpv_code=="09134100"

replace cpv_code="249511006"  if regex(title,"lubric") & missing(cpv_code)
replace cpv_descr="Lubricants"  if regex(title,"lubric") & cpv_code=="249511006"

replace cpv_code="442212007"  if regex(title,"doors") & missing(cpv_code)
replace cpv_descr="Doors"  if regex(title,"doors") & cpv_code=="442212007"

replace cpv_code="453143107"  if regex(title,"cabling") & missing(cpv_code)
replace cpv_descr="Installation of cable laying"  if regex(title,"cabling") & cpv_code=="453143107"

replace cpv_code="452332221"  if regex(title,"asphalt") & missing(cpv_code)
replace cpv_descr="Paving and asphalting works"  if regex(title,"asphalt") & cpv_code=="452332221"

replace cpv_code="331400003"  if regex(title,"strip |blood ") & missing(cpv_code)
replace cpv_descr="Medical consumables"  if regex(title,"strip |blood ") & cpv_code=="331400003"

replace cpv_code="791000005"  if regex(title,"legal") & missing(cpv_code)
replace cpv_descr="Legal services"  if regex(title,"legal") & cpv_code=="791000005"

replace cpv_code="793420003"  if regex(title,"marketing") & missing(cpv_code)
replace cpv_descr="Marketing services"  if regex(title,"marketing") & cpv_code=="793420003"

replace cpv_code="341000008"  if regex(title,"vehicle") & missing(cpv_code)
replace cpv_descr="Motor vehicles"  if regex(title,"vehicle") & cpv_code=="341000008"

replace cpv_code="331100004"  if regex(title,"x-ray|xray") & missing(cpv_code)
replace cpv_descr="Imaging equipment for medical, dental and veterinary use"  if regex(title,"x-ray|xray") & cpv_code=="331100004"

replace cpv_code="323220006"  if regex(title,"multimedia") & missing(cpv_code)
replace cpv_descr="Multimedia equipment"  if regex(title,"multimedia") & cpv_code=="323220006"

replace cpv_code="302000001"  if regex(title,"media") & missing(cpv_code)
replace cpv_descr="Computer equipment and supplies"  if regex(title,"media") & cpv_code=="302000001"

replace cpv_code="331510003"  if regex(title,"oxygen") & missing(cpv_code)
replace cpv_descr="Radiotherapy devices and supplies"  if regex(title,"oxygen") & cpv_code=="331510003"

replace cpv_code="341444318"  if regex(title,"suction") & missing(cpv_code)
replace cpv_descr="Suction-sweeper vehicles"  if regex(title,"suction") & cpv_code=="341444318"

count if missing(cpv_code)
********************************************************************************

save $country_folder/IN_wip, replace
********************************************************************************
*END