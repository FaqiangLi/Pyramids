clear
local cluster_li_workspace /storage/home/fxl146/scratch/Pyramids_statafiles

forvalues k=2014/2019 {
clear
cd `cluster_li_workspace'
fs `which_dataset'_`k'*.dta
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
save `which_dataset'_`k', replace
}
clear


clear
forvalues k=2014/2019{
	append using `which_dataset'_`k'.dta
}
save `which_dataset'1419,replace
