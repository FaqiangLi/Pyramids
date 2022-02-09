clear all 
set more off
capture ssc install fs


clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/people_of_india"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}

clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/member_income"

fs *.csv
foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}

clear
capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/aspirational_india"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}

clear

capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles/consumption_pyramids"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}


