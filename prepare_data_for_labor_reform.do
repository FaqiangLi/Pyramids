*** Prepare dataset for 

clear all 
set more off
capture ssc install fs

*** *** *** *** *** *** *** *** *** *** 
*** By year merge employment dataset
*** *** *** *** *** *** *** *** *** *** 

* Append by year
forvalues k=2014/2019 {
clear
capture cd "/Users/faqiangmacpro/Dropbox/India_Dev/RawData/Pyramids/People_of_India/"
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

* Rough selection

// only these have effective data values. Others only have identifiers.
keep if response_status=="Accepted"  

// Because normally Member of the household will only have effective data value
keep if member_status=="Member of the household"

// Do not drop working age==15, possibly affecting teenager worker
// drop if age_yr<15

cd "/Users/faqiangmacpro/Dropbox/India_Dev/Workspace"
save year`k'_people_india, replace
}
clear


* Append
forvalues k=2014/2019 {
append using year`k'_people_india
}
timer on 10
egen id=group(hh_id mem_id)
timer off 10 
timer list
save temp_employment_1419_for_labor_reform,replace




*** *** *** *** *** *** *** *** *** *** 
*** By year merge income datasets 
*** *** *** *** *** *** *** *** *** *** 

* Append
forvalues k=2014/2016 {
clear
capture cd "/Users/faqiangmacpro/Dropbox/India_Dev/RawData/Pyramids/Member_income/"
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

* Same selection as before
keep if response_status=="Accepted"  
keep if member_status=="Member of the household"

cd "/Users/faqiangmacpro/Dropbox/India_Dev/Workspace"
save income_`k'_for_labor_reform,replace
}
clear


forvalues k=2017/2019 {
clear
capture cd "/Users/faqiangmacpro/Dropbox/India_Dev/RawData/Pyramids/Member_income/"
fs *`k'*.dta
foreach ff in `r(files)' {
    append using `ff'
}

* Same selection as before
keep if response_status=="Accepted"  
keep if member_status=="Member of the household"

cd "/Users/faqiangmacpro/Dropbox/India_Dev/Workspace"
save income_`k'_for_labor_reform,replace
}
clear


clear
forvalues k=2017/2019 {
append using income_`k'_for_labor_reform
}
save temp_income_1719_for_labor_reform,replace


clear
forvalues k=2014/2016 {
append using income_`year'_for_labor_reform
}
save temp_income_1416_for_labor_reform,replace
append using temp_income_1719_for_labor_reform 
save temp_income_1419_for_labor_reform, replace


* Give unique id (this steps takes very long)
use temp_employment_1419_for_labor_reform
egen id=group(hh_id mem_id)
save temp_with_uniqueID_employment_1419_for_labor_reform,replace

timer on 2
use income_2015_for_labor_reform,replace
egen id=group(hh_id mem_id)
timer off 2
timer list
timer on 3
use temp_income_1419_for_labor_reform,replace
egen id=group(hh_id mem_id)
timer off 3
timer list
save temp_with_uniqueID_income_1419_for_labor_reform,replace


*** *** *** *** *** *** ***`' *** *** *** 
*** Cut datasets into managable size
*** *** *** *** *** *** *** *** *** *** 

use temp_employment_1419_for_labor_reform,replace
keep id
duplicates drop , force
gen u = runiform()
sort u 
gen random_index = _n
preserve
keep if random_index < 100000
keep id
save 100000sample_hhindex, replace
restore
keep if random_index < 10000
keep id
save 10000sample_hhindex, replace
clear
use temp_employment_1419_for_labor_reform
merge m:1 id using 100000sample_hhindex, keep(3) nogen
save 1e5sample_temp_employment_1419_for_labor_reform
clear
use temp_employment_1419_for_labor_reform
merge m:1 id using 10000sample_hhindex, keep(3) nogen
save 1e4sample_temp_employment_1419_for_labor_reform
clear

* Work using the smaller sample to check codes
use 1e4sample_temp_employment_1419_for_labor_reform, replace




*** *** *** *** *** *** *** *** *** *** 
*** More trimming and modification for exploring labor reform
*** *** *** *** *** *** *** *** *** *** 









// these are important sources of extensive margin workers potentially, no selection is needed
// gen aux=nature=="Home Maker"|nature=="Student"|nature=="Unoccupied"|nature=="Retired/Aged"
// bys hh_id mem_id: egen drop=min(aux)
// drop if drop==1
// drop drop aux



/*
xtset id date_m 

tsfill 

carryforward wave_no hh_id mem_id state hr district region_type stratum psu_id response_status reason_for_non_response mem_weight_w mem_weight_for_country_w mem_weight_for_state_w ge15_mem_weight_w ge15_mem_weight_for_country_w ge15_mem_weight_for_state_w mem_non_response_w mem_non_response_for_country_w mem_non_response_for_state_w ge15_mem_non_response_w ge15_mem_non_response_for_countr ge15_mem_non_response_for_state_ member_status gender age_yrs age_mths relation_with_hoh state_of_origin religion caste caste_category literacy education discipline nature_of_occupation industry_of_occupation employment_status is_healthy is_on_regular_medication is_hospitalised has_bank_ac has_creditcard has_kisan_creditcard has_demat_ac has_pf_ac has_lic has_health_insurance has_mobile family_shifted employment_status_since_yrs employment_status_since_mths employment_status_since_days type_of_employment employment_arrangement place_of_work time_to_start_working occupation reason_for_emigration_immigratio, replace
*/

* optimize date
gen date_m=monthly(month_slot, "MY")
format date_m %tm
replace month_slot=string(date_m, "%tm") if month_slot==""
replace month_slot="Jan "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m1"
replace month_slot="Feb "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m2"
replace month_slot="Mar "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m3"
replace month_slot="Apr "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m4"
replace month_slot="May "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m5"
replace month_slot="Jun "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m6"
replace month_slot="Jul "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m7"
replace month_slot="Aug "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m8"
replace month_slot="Sep "+substr(month_slot,1,4) if substr(month_slot,-2,.)=="m9"
replace month_slot="Oct "+substr(month_slot,1,4) if substr(month_slot,-3,.)=="m10"
replace month_slot="Nov "+substr(month_slot,1,4) if substr(month_slot,-3,.)=="m11"
replace month_slot="Dec "+substr(month_slot,1,4) if substr(month_slot,-3,.)=="m12"
gen month=month_slot



save 1e4sample_employment_1419_for_labor_reform , replace

* This also gives us our sample for statistical analysis
keep hh_id 
duplicates drop 

save hhid_1e4sample_employment_1419_for_labor_reform,replace




merge 1:m month hh_id mem_id using `employment'
keep if _merge==3
drop _merge





*** do a description of income by nature of occupation (do self-employed loose income?)
preserve
collapse (mean) mean_income=income_of_member_from_all_source mean_wage=income_of_member_from_wages mean_pension=income_of_member_from_pension mean_dividend=income_of_member_from_dividend mean_interest=income_of_member_from_interest mean_fd_pf_insurance=income_of_member_from_fd_pf_insu (median) median_income=income_of_member_from_all_source median_wage=income_of_member_from_wages median_pension=income_of_member_from_pension median_dividend=income_of_member_from_dividend median_interest=income_of_member_from_interest median_fd_pf_insurance=income_of_member_from_fd_pf_insu, by(date_m nature)
egen id=group(nature)
xtset id date_m
*** graphs with pairwise comparison of both mean and median income across self-employed people and other groups
* july first implementation of gst

*mean pair-wise comparison
levelsof nature, local(class)
foreach group of local class {
if "`group'"~="Self Employed Entrepreneur" {
if length("`group'")>36 {
	local rows 2	
}
if length("`group'")<37 {
	local rows 1
}
local name "`=subinstr("`=subinstr("`=subinstr("`group'","-","",.)'","/","",.)'"," ","",.)'"	
twoway tsline mean_income if nature=="Self Employed Entrepreneur" || tsline mean_income if nature=="`group'", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "`group'") rows(`rows')) 

graph export Graphs\Pyramids_Comparison_Self_Employed_Others\mean_pair_wise_`name'.pdf, replace
}	
}





































