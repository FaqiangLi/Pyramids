clear all 
set more off
capture ssc install fs


* weekly expense
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/weekly_expense"

fs *.csv

foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}


* monthly expense
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/monthly_expense"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}




* hh income
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/household_income"

fs *.csv

foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}




*people of india
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/people_of_india"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}

* member income
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/member_income"

fs *.csv
foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}

* aspirational_india
clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/aspirational_india"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}


