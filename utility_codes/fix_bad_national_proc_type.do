*Fix bad procedure types - data processing error

replace tender_nationalproceduretype = ustrregexra(tender_nationalproceduretype,"^f03_","",1)
replace tender_nationalproceduretype = ustrregexra(tender_nationalproceduretype,"^pt_","",1)
replace tender_nationalproceduretype = ustrregexra(tender_nationalproceduretype,"_"," ",1)
replace tender_nationalproceduretype = ustrregexra(tender_nationalproceduretype,":"," ",1)
replace tender_nationalproceduretype = "" if inlist(tender_nationalproceduretype,"0","1","2")

replace tender_nationalproceduretype = ustrupper(tender_nationalproceduretype)

