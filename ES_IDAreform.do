*** Event study Industrial Dispute Act labor reform on various outcomes

clear
set more off

capture log close
log using "/storage/work/f/fxl146/Pyramids/IDA_summarystat_trialexpost.smcl", replace


* identifiers
// i : individual (a hh_id-mem-id)
// t : period (a month slot in the base dataset)
// s : state i lives in 
// d : district i lives in 
// hr: homogenous region i lives in 


********************************************************************************
*********** Sample selection **** 
********************************************************************************


* Sample from people of India (see clean_trim_merge_append.do)
clear
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use concise_1419_labor_1p,replace

* Drop the obs of two ambigous states, AP and Jharkhand&
drop if state == "Andhra Pradesh" | state == "Jharkhand"  // around 6%

* disaggregation level (income is at id-monthslot-month level)
duplicates report id month_slot month
duplicates report id month_slot 

* reformat dates
gen date=date(month_slot, "MY")
format date %d
gen date_m = month(date)
gen date_y = year(date)
tostring date_m date_y, replace
replace date_m = "0"+date_m if strlen(date_m)==1
gen date_str = date_y + date_m

destring date_m date_y,replace
rename month month_of_income_data

* Drop extra dates
drop if date_y>2019

* Now, use the mean income to match people of india time label
rename income_of_member_from_* inc_*
foreach var in inc_all_source inc_wages inc_pension inc_dividend inc_interest inc_fd_pf_insu{
	bysort id date: egen mean_`var' = mean(`var')
}
duplicates report id date
bysort id date: keep if _n==1


* Drop students, and retired observation
**** CAVEAT: this needs more careful treatment in the future because status of student, homemaker and retired observation is a dynamic ones.
**** in this version, I drop ever-students and ever-retired
gen temp_student = 1 if nature_of_occupation=="Student"
bysort id (date_y date_m): egen temp_ever_student = sum(temp_student)
gen temp_retired = 1 if nature_of_occupation=="Retired/Aged"
bysort id (date_y date_m): egen temp_ever_retired = sum(temp_retired)

drop if temp_ever_retired>0 | temp_ever_student>0
drop temp_ever_retired temp_ever_student temp_student temp_retired
// I don't drop home maker


* regenerate some id (after having done all the sample selection)
egen id_date = group(date_str)
egen id_state = group(state)
egen id_hr = group(hr)
egen id_dist= group(district)

* organize data
sort id hh_id mem_id date_y date_m id_date month_of_income
order id hh_id mem_id date_y date_m id_date month_of_income


* inspect data
count
codebook id

********************************************************************************
***********  Variable construction
********************************************************************************


* first observation of an individual
bysort id (id_date): gen period = _n

* rename nature and industry

// occupation
rename nature_of_occupation nature
qui tab nature, generate(nature_)
rename nature_2 nature_business
rename nature_5 nature_industrialw
rename nature_10 nature_qualified
rename nature_12 nature_self
rename nature_14 nature_small
rename nature_17 nature_unoccupied
rename nature_18 nature_wage

// industry
rename industry_of_occupation inds
qui tab inds, generate(inds)

// not applicable
rename inds25 inds_notapplicable

//CAVEAT: there could be missing variables !! do this later!!!!

// factories
rename inds2 inds_auto
rename inds3 inds_construction
rename inds4 inds_chemical
rename inds12 inds_foodinds
rename inds13 inds_leather
rename inds21 inds_machinery
rename inds28 inds_pharma
rename inds34 inds_soap
rename inds35 inds_textile

local inds_factory_type inds_auto inds_construction inds_chemical inds_foodinds inds_leather inds_machinery inds_pharma inds_soap inds_textile
egen temp_inds_all_factories = rowtotal(`inds_factory_type')
gen inds_all_factories = 1 if temp_inds_all_factories>0 & inds_notapplicable~=1
replace inds_all_factories = 0 if temp_inds_all_factories==0 & inds_notapplicable~=1
drop temp_inds_all_factories

// plantation
rename inds1 inds_agriculture
rename inds6 inds_cropcultiv
rename inds11 inds_fishing
rename inds14 inds_forestry
rename inds15 inds_fruitveg
rename inds29 inds_plantationcrop
rename inds30 inds_poultry

local inds_plantation_type inds_agriculture  inds_cropcultiv inds_fishing inds_forestry inds_fruitveg inds_plantationcrop inds_poultry
egen temp_inds_all_plantation = rowtotal(`inds_plantation_type')
gen inds_all_plantation = 1 if temp_inds_all_plantation>0 & inds_notapplicable~=1
replace inds_all_plantation = 0 if temp_inds_all_plantation==0 & inds_notapplicable~=1
drop temp_inds_all_plantation

// mining
rename inds23 inds_metal
rename inds24 inds_mines
rename inds37 inds_utilities

local inds_mining_type inds_metal inds_mines inds_utilities
egen temp_inds_all_mining = rowtotal(`inds_mining_type')
gen inds_all_mining = 1 if temp_inds_all_mining>0 & inds_notapplicable~=1
replace inds_all_mining = 0 if temp_inds_all_mining==0 & inds_notapplicable~=1
drop temp_inds_all_mining

// left out, to be used later
rename inds# inds_#_dropped
drop *_dropped
// rename inds5 inds_communication
// rename inds7 inds_defence
// rename inds8 inds_education
// rename inds9 inds_entertainsport
// rename inds10 inds_finance
// rename inds16 inds_gemjewellery
// rename inds17 inds_handicraft
// rename inds18 inds_healthcare
// rename inds19 inds_hotelresturant
// rename inds20 inds_IT
// rename inds22 inds_mediapublishing
// rename inds26 inds_nonprofession
// rename inds27 inds_professional
// rename inds31 inds_publicadmin
// rename inds32 inds_realestate
// rename inds33 inds_retail
// rename inds36 inds_traveltourism
// rename inds38 inds_wholesale

// relevant industry for the study
gen inds_relevant = (inds_all_mining+inds_all_plantation+inds_all_factories)>0 if inds_notapplicable~=1
gen inds_notrelevant = 1 - inds_relevant

* Treatment status: treated if for i, IDA is informed in s(i) in t 
* CAVEAT: STATE OF ORIGIN IS NOT THE STATUS WE WANT
gen reformed = 0
replace reformed = 1 if state == "Maharashtra" & ((date_m >= 11 & date_y == 2017) | date_y>2017 )
replace reformed = 1 if state == "Rajasthan" & ( (date_m >= 11 & date_y==2014) | date_y>2014  )
replace reformed = 1 if state == "Madhya Pradesh" &  ( (date_m >=11 & date_y==2017) | date_y>2017 )
replace reformed = 1 if state == "Haryana" & ( (date_m >=3 & date_y==2016) | date_y>2016 )
replace reformed = 1 if state == "Gujarat" &  ( (date_m >=9 & date_y==2020) | date_y>2020 )
replace reformed = 1 if state == "Assam" &  ( (date_m >=9 & date_y==2017) | date_y>2017 )

* treated states (this is a state level variable)
gen state_ever_treated = 1 if inlist(state,"Maharashtra","Rajasthan","Madhya Pradesh","Haryana","Gujarat","Assam")

* Ever-treated status of individual, if changed multiple times -- reflecting migration
bysort id : egen temp_ever_reformed = sum(reformed)
gen reformed_ever = temp_ever_reformed>0
drop temp_ever_reformed
tab reformed_ever if period ==1 

* Change treatment status more than once: e.g. 0,0,1,1,0,0, 1=treated
bysort id (id_date): gen temp_last_reformed = reformed[_n-1]
gen temp_last_reformed_equal = reformed~=temp_last_reformed  if temp_last_reformed~=. // an one marks a change of reform status
replace temp_last_reformed_equal=0 if temp_last_reformed_equal==.
bysort id  : egen temp_reformed_changetwice = sum(temp_last_reformed_equal)
gen reformed_changetwice = 0 if temp_reformed_changetwice==0 | temp_reformed_changetwice==1
replace reformed_changetwice = 1 if reformed_changetwice~=0

tab reformed_changetwice

* Reformed cross early affected industry (mine, planation,factory)
// replace missing for not applicable
gen reformedxinds = reformed*inds_relevant
replace reformedxinds = 0 if reformedxinds==.
gen reformedxinds_f = reformed*inds_all_factories
replace reformedxinds_f = 0 if reformedxinds_f==.
gen reformedxinds_m = reformed*inds_all_mining
replace reformedxinds_m = 0 if reformedxinds_m==.
gen reformedxinds_p = reformed*inds_all_plantation
replace reformedxinds_p = 0 if reformedxinds_p==.

* reframe the industry tags (there is no possibility of multiple industry)
gen inds_reframe = -1  // this almost equals home maker
replace inds_reframe = 1 if inds_all_factories==1
replace inds_reframe = 2 if inds_all_mining==1
replace inds_reframe = 3 if inds_all_plantation==1
replace inds_reframe = 0 if inds_notrelevant==1

* District level industry composition 
bysort id_dist id_date: egen emp_dist_date_total = count(id)
foreach type in plantation factories mining {
	bysort id_dist id_date: egen emp_dist_date_`type' = sum(inds_all_`type')
	gen share_dist_date_`type' = emp_dist_date_`type'/emp_dist_date_total
}

* state level composition 
bysort id_state id_date: egen emp_state_date_total = count(id)
foreach type in plantation factories mining {
	bysort id_state id_date: egen emp_state_date_`type' = sum(inds_all_`type')
	gen share_state_date_`type' = emp_state_date_`type'/emp_state_date_total
}


* District and state level industry employment transition of individuals, pre-post
bysort id (id_date) : gen inds_reframe_lag = inds_reframe[_n-1]


* (best way to show this is state by state by year, because some effects might wary overtime)
* (group state by treatment and control group)


save labor_reform_sample_Feb9ninght,replace


**** mind the boundary cases. boundary at the treatment date

********************************************************************************
*********** Summary stats: industry distribution and individual dynamics ******
********************************************************************************

* distribution unconditional employment 
tab inds
tab inds_notapplicable
tab inds_notrelevant
tab inds_all_factories
tab inds_all_mining
tab inds_all_plantation

******** CAVEAT all of these are not weighted --- the actual representative distribution of India should be more scrutinized. 


* What are the not applicable's occupation?
// after deleting ever-students and ever-retired, 94% of the not applicable are homemaker
tab nature if inds == "Not Applicable"

* roughly industry employment distribution for the treated states
tab state inds_reframe if state_ever_treated == 1

* Summary stats about the reform
codebook reformed
tab reformed
tab state reformed  
tab state reformed if state_ever_treated == 1
local list_states_treated Maharashtra Rajasthan "Madhya Pradesh" Haryana Gujarat Assam
foreach var in `list_states_treated'{
	disp("*************************")
	disp("Current State is `var'")
	disp("*************************")
tab inds if state =="`var'"
}


******* Caveat: this needs to be done controlling for occupation: we don't care managers in factories's moving around. 



* Transition
tab inds_reframe_lag inds_reframe if reformed==1, row
tab inds_reframe_lag inds_reframe if reformed==0, row
tab inds_reframe_lag inds_reframe if reformed==1 & state_ever_treated==1, row
tab inds_reframe_lag inds_reframe if reformed==0 & state_ever_treated==1, row


* Share trend overtime using collapsed-sample



* check data range, type, missing
codebook 



********************************************************************************
*********** Tests ******
********************************************************************************

* collapse to district level data
use labor_reform_sample_Feb9ninght,replace
duplicates drop  id_dist id_date, force
sort id_dist id_date 
order id_dist id_date
save labor_reform_sample_Feb9ninght_distdate, replace

* Distrct/state level did regression on employment share 
// (note that reform is defined at the state and time level so duplicates drop will not give different district different treatment status)
use labor_reform_sample_Feb9ninght_distdate,replace
reghdfe share_dist_date_factories reformed , a(id_dist id_date) vce(cl id_state)
reghdfe share_dist_date_mining reformed , a(id_dist id_date) vce(cl id_state)
reghdfe share_dist_date_plantation reformed , a(id_dist id_date) vce(cl id_state)
gen share_dist_date_relevant = share_dist_date_factories+share_dist_date_mining+share_dist_date_plantation
reghdfe share_dist_date_relevant reformed , a(id_dist id_date) vce(cl id_state)

/// (do I need to weight it...? and when collapsing, I also probably need to weight each district -- how to properly do that....(given that each individual is actually having weight))

/// (need district tag from economic census on the rate of big firms!!!interacting that with reformed...)

/// (later: try using event study specification (relative periods))

* 
use labor_reform_sample_Feb9ninght,replace

* income
reghdfe inc_all_source reformed , a(id id_date) vce(cl id_dist)
reghdfe inc_all_source reformed [pweight=mem_weight_w], a(id month_slot) vce(cl id_state)

* linear probability  (could it be more sophisticated?)
reghdfe inds_all_factories reformed , a(id id_date) vce(cl id_dist)
reghdfe inds_all_mining reformed , a(id id_date) vce(cl id_dist)
reghdfe inds_all_plantation reformed , a(id id_date) vce(cl id_dist)

reghdfe inc_all_source reformed [pweight=mem_weight_w], a(id month_slot) vce(cl id_state)


* Today's task2: pick 3 outcomes to check and run the following regression and coefficient plot
egen kkk = group(date_str)
reg inc_all_source ib1.kkk if state == "Rajasthan", nocons
coefplot   make it horizontal and add vertical line


