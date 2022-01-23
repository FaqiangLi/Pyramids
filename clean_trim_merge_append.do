
clear all 
set more off
capture ssc install fs

local cluster_li_workspace /storage/home/fxl146/scratch/Pyramids_statafiles

**** employment and id variables
forvalues k=2014/2019 {
clear
cd `cluster_li_workspace'
fs people_of_india_`k'*.dta
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


clear
forvalues k=2014/2019{
	append using people_of_india_`k'.dta
}
save people_of_india1419,replace


clear
local which_dataset member_income
do clean_trim_merge_append_replica.do












