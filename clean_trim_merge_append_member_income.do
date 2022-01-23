clear
set more off

log using append_member_income

local cluster_li_workspace /storage/home/fxl146/scratch/Pyramids_statafiles


forvalues k=2014/2019 {
clear
cd `cluster_li_workspace'
fs member_income_`k'*.dta
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
save member_income_`k', replace
}
clear

timer clear
timer on 1
clear
forvalues k=2014/2019{
	append using member_income_`k'.dta
}
save member_income_1419,replace
timer off 1

log close