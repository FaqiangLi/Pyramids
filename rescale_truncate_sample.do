*** Truncate and trim out variables

clear
set more off
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"

set seed 123456

capture log close

log using "/storage/work/f/fxl146/Pyramids/rescale_codebook_all_datasets.smcl", replace

foreach dataset in household_income_1419 weekly_expense_1419 monthly_expense_1419 aspirational_india_1419 {
	
use `dataset'.dta,replace
codebook
clear
}


* Random sample for every dataset
foreach dataset in member_income_1419 household_income_1419 people_of_india_1419 weekly_expense_1419 monthly_expense_1419 aspirational_india_1419 {
	
use `dataset'.dta,replace

sample 10
save `dataset'_10p,replace
use `dataset'_10p, replace
sample 10
save `dataset'_1p, replace
use `dataset'_1p, replace
sample 10
save `dataset'_01p, replace
}



* Shake off identifiers
use member_income_1419, replace
local extra_identifiers state hr district region_type stratum psu_id response_status reason_for_non_response mem_weight_ms mem_weight_for_country_ms mem_weight_for_state_ms mem_non_response_ms mem_non_response_for_country_ms mem_non_response_for_state_ms member_status
drop `extra_identifiers'
save member_income_1419_nomoreids, replace

* Merge and append
clear
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use member_income_1419_nomoreids,replace
merge m:1 hh_id mem_id month_slot using people_of_india_1419
drop if _merge==2
drop _merge
egen id = group(hh_id mem_id)
sort hh_id mem_id month_slot month
order id hh_id mem_id month_slot month
save concise_1419_labor,replace

use concise_1419_labor, replace
sample 10
save concise_1419_labor_10p,replace
use concise_1419_labor, replace
sample 1
save concise_1419_labor_1p,replace
use concise_1419_labor, replace
sample 0.1
save concise_1419_labor_01p,replace




