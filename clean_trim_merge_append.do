
clear all 
set more off
capture ssc install fs


local cluster_li_workspace /storage/home/fxl146/scratch/Pyramids_statafiles

local db_member_income /storage/home/fxl146/scratch/Pyramids_statafiles/member_income

local db_people_of_india /storage/home/fxl146/scratch/Pyramids_statafiles/people_of_india

local db_aspirational_india /storage/home/fxl146/scratch/Pyramids_statafiles/aspirational_india

local db_household_income /storage/home/fxl146/scratch/Pyramids_statafiles/household_income

local db_weekly_expense /storage/home/fxl146/scratch/Pyramids_statafiles/weekly_expense

local db_monthly_expense /storage/home/fxl146/scratch/Pyramids_statafiles/monthly_expense


* Data disaggregation level
// member income: hh_id mem_id month_slot month
// people of india: hh_id mem_id month_slot
// aspirational : hh_id month_slot (note therefore this is a household-time speicific instead of individual specific dataset)
// household inocme: hh_id month_slot (or month)
// weekly expense: hh_id month_slot (or month)
// monthly expense: hh_id month_slot (or month)


********************************
* member income
********************************
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
tab month_slot

save member_income_1419,replace

********************************
* people of india
********************************
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
tab month_slot
save people_of_india_1419,replace


********************************
* aspirational india
********************************
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
tab month_slot

save aspirational_india_1419,replace



********************************
*household_income
********************************
clear
forvalues k=2014/2019 {
clear
cd `db_household_income'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

keep if response_status=="Accepted"  

cd `cluster_li_workspace'
save household_income_`k', replace
}
clear

forvalues k=2014/2019{
	append using household_income_`k'.dta
}
tab month_slot

save household_income_1419,replace



********************************
* weekly expense
********************************
clear
forvalues k=2014/2019 {
clear
cd `db_weekly_expense'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

keep if response_status=="Accepted"  

cd `cluster_li_workspace'
save weekly_expense_`k', replace
}

clear

forvalues k=2014/2019{
	append using weekly_expense_`k'
}
tab month_slot

save weekly_expense_1419,replace




********************************
* monthly expense
********************************
clear
forvalues k=2014/2019 {
clear
cd `db_monthly_expense'
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

keep if response_status=="Accepted"  

cd `cluster_li_workspace'
save monthly_expense_`k', replace
}

clear

forvalues k=2014/2019{
	append using monthly_expense_`k'
}
tab month_slot

save monthly_expense_1419,replace









