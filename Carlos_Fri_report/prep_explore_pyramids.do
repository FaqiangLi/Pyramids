clear all 
set more off
capture ssc install fs


cd "C:\Users\carlo\Dropbox\India_Dev"


***** employment and id variables
forvalues k=2016/2018 {
clear
fs RawData\Pyramids/People_of_India\*`k'*.dta
foreach ff in `r(files)' {
    append using RawData\Pyramids/People_of_India/`ff'
}
keep if response_status=="Accepted" 

keep if member_status=="Member of the household"
drop if age_yr<15
tempfile year`k'
save `year`k'' 
}
clear

forvalues k=2016/2018 {
append using `year`k''
}

/*
I'll trim the observations:
	- Non-response
	- Member no longer in the household (dead, emmigrated, etc.)
	- Children<15
	- Household members that throught the sample are unemployeed (they do not want to find work), students, home makers.
	
	
 NATURE_OF_OCCUPATION |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                  Agricultural Labourer |    179,104        2.64        2.64
                            Businessman |    239,761        3.53        6.17
                             Home Maker |  2,377,685       35.01       41.18
                      Home-based Worker |     33,094        0.49       41.67
                     Industrial Workers |    144,097        2.12       43.79
    Legislator/Social Worker/ Activists |      2,006        0.03       43.82
                                Manager |      9,631        0.14       43.96
      Non-Industrial Technical Employee |     83,456        1.23       45.19
                       Organised Farmer |    127,662        1.88       47.07
  Qualified Self Employed Professionals |     16,352        0.24       47.31
                           Retired/Aged |    433,853        6.39       53.70
             Self Employed Entrepreneur |    348,072        5.13       58.82
                           Small Farmer |    263,985        3.89       62.71
Small Trader/Hawker/ Businessman with.. |    106,440        1.57       64.28
                                Student |  1,157,504       17.04       81.32
                          Support Staff |    274,774        4.05       85.37
                             Unoccupied |     65,671        0.97       86.33
                          Wage Labourer |    617,258        9.09       95.42
        White Collar Clerical Employees |    155,348        2.29       97.71
White-Collar Professional Employees a.. |    155,616        2.29      100.00
----------------------------------------+-----------------------------------
                                  Total |  6,791,369      100.00

*/

gen aux=nature=="Home Maker"|nature=="Student"|nature=="Unoccupied"|nature=="Retired/Aged"

bys hh_id mem_id: egen drop=min(aux)

drop if drop==1

drop drop aux

gen date_m=monthly(month_slot, "MY")
format date_m %tm
egen id=group(hh_id mem_id)

xtset id date_m 

tsfill 

carryforward wave_no hh_id mem_id state hr district region_type stratum psu_id response_status reason_for_non_response mem_weight_w mem_weight_for_country_w mem_weight_for_state_w ge15_mem_weight_w ge15_mem_weight_for_country_w ge15_mem_weight_for_state_w mem_non_response_w mem_non_response_for_country_w mem_non_response_for_state_w ge15_mem_non_response_w ge15_mem_non_response_for_countr ge15_mem_non_response_for_state_ member_status gender age_yrs age_mths relation_with_hoh state_of_origin religion caste caste_category literacy education discipline nature_of_occupation industry_of_occupation employment_status is_healthy is_on_regular_medication is_hospitalised has_bank_ac has_creditcard has_kisan_creditcard has_demat_ac has_pf_ac has_lic has_health_insurance has_mobile family_shifted employment_status_since_yrs employment_status_since_mths employment_status_since_days type_of_employment employment_arrangement place_of_work time_to_start_working occupation reason_for_emigration_immigratio, replace

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

tempfile employment
save  `employment'

keep hh_id 

duplicates drop 

tempfile id
save `id'

******* income and expenditure variables

forvalues k=2016/2018 {
clear
fs RawData\Pyramids/Member_income\*`k'*.dta
foreach ff in `r(files)' {
    append using RawData\Pyramids/Member_income/`ff'
}
keep if response_status=="Accepted" 
keep if member_status=="Member of the household"
drop if age_yr<15
merge m:1 hh_id using `id'

keep if _merge==3
drop _merge

tempfile year`k'
save `year`k'' 
}
clear

forvalues k=2016/2018 {
append using `year`k''
}


merge 1:m month hh_id mem_id using `employment'
keep if _merge==3
drop _merge

save RawData\temp/explore_pyramids_carlos, replace
