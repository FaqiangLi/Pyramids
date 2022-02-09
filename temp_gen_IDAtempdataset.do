*
clear


discard

set more off
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"


log using "/storage/work/f/fxl146/Pyramids/temp_scale_down_for_IDA_first_Trial.smcl", replace


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










log close
