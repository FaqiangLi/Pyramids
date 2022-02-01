
clear all 
set more off
capture ssc install fs


local cluster_li_workspace /storage/home/fxl146/scratch/Pyramids_statafiles
local db_member_income /storage/home/fxl146/scratch/Pyramids_statafiles/member_income
local db_people_of_india /storage/home/fxl146/scratch/Pyramids_statafiles/people_of_india
local db_aspirational_india /storage/home/fxl146/scratch/Pyramids_statafiles/aspirational_india
local db_consumption_pyramids /storage/home/fxl146/scratch/Pyramids_statafiles/consumption_pyramids



* I have not done consumption_pyramids_weekly_expense and household income



* Data disaggregation level
// member income: hh_id mem_id month_slot month
// people of india: hh_id mom_id month_slot
// aspirational : hh_id month_slot (note therefore this is a household-time speicific instead of individual specific dataset)
// consumption pyramids: hh_id month_slot month (same above)




clear
forvalues k=2014/2019 {
clear
cd `db_people_of_india'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

// only these have effective data values. Others only have identifiers.
keep if response_status=="Accepted"  

// Because normally Member of the household will only have effective data value
keep if member_status=="Member of the household"

// Working age
drop if age_yr<15

cd `cluster_li_workspace'
save people_of_india_`k', replace
}
clear

forvalues k=2014/2019{
	append using people_of_india_`k'.dta
}
save people_of_india_1419,replace



clear
forvalues k=2014/2019 {
clear
cd `db_member_income'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

keep if response_status=="Accepted"  

keep if member_status=="Member of the household"

drop if age_yr<15

cd `cluster_li_workspace'
save member_income_`k', replace
}
clear

forvalues k=2014/2019{
	append using member_income_`k'.dta
}
save member_income_1419,replace


clear
forvalues k=2014/2019 {
clear
cd `db_consumption_pyramids'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

// only these have effective data values. Others only have identifiers.
keep if response_status=="Accepted"  

cd `cluster_li_workspace'
save consumption_pyramids_`k', replace
}
clear

forvalues k=2014/2019{
	append using consumption_pyramids_`k'.dta
}
save consumption_pyramids_1419,replace




clear
forvalues k=2014/2019 {
clear
cd `db_aspirational_india'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}


keep if response_status=="Accepted"  

cd `cluster_li_workspace'
save aspirational_india_`k', replace
}
clear

forvalues k=2014/2019{
	append using aspirational_india_`k'.dta
}
save aspirational_india_1419,replace





