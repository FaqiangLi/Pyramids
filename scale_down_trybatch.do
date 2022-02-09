*
clear
set more off
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"


log using "/storage/work/f/fxl146/Pyramids/scale_down_record_batch_correctincome_year.smcl", replace


timer clear

* Random sample
timer on 1
use people_of_india_1419.dta,replace
sample 1
save people_of_india_1419_oneprecent,replace
use member_income_1419.dta, replace
sample 1 
save member_income_1419_oneprecent, replace
timer off 1


* Shake off identifiers
* people_of_india: hh_id mem_id month_slot
* memeber_income: hh_id mem_id month_slot month
use member_income_1419, replace
local extra_identifiers state hr district region_type stratum psu_id response_status reason_for_non_response mem_weight_ms mem_weight_for_country_ms mem_weight_for_state_ms mem_non_response_ms mem_non_response_for_country_ms mem_non_response_for_state_ms member_status
drop `extra_identifiers'
// Disaggregation level: hh_id mem_id month_slot
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


* If works, continue to generate random sample to work with it.
use concise_1419_labor, replace
sample 10
save concise_1419_labor_10p,replace
use concise_1419_labor, replace
sample 1
save concise_1419_labor_1p,replace
use concise_1419_labor, replace
sample 0.1
save concise_1419_labor_01p,replace


log close

