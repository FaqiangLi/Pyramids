*** Event study Industrial Dispute Act labor reform on various outcomes

clear
set more off

capture log close
log using "/storage/work/f/fxl146/Pyramids/IDA_summarystat_01p.smcl", replace


* identifiers
// i : individual (a hh_id-mem-id)
// t : period (a month slot in the base dataset)
// s : state i lives in 
// d : district i lives in 
// hr: homogenous region i lives in 

* caveat
// Aspirational India and consumption data have not incorporated in. They are at the household levels. 

// note that people of india has every possible month because some households are asked in different month in a wave.


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
bysort id (date_y date_m): keep if _n==1


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

///////// check missing !! do this later!!!!

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
gen reformedxinds = reformed*inds_relevant

********************************************************************************
*********** Summary stats: industry distribution and individual dynamics ******
********************************************************************************


* industry distribution
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


* See the distribution of a cross section



* Summary statistics of the industry



* District level industry composition matrix (homogenous region is larger than district)
bysort id_


* Policy window district level transition matrix



* 
codebook reformed
tab reformed
tab state reformed  // basically we want both before and after treatment status for a state
tab state reformed 
local list_states_treated Maharashtra Rajasthan "Madhya Pradesh" Haryana Gujarat Assam
foreach var in `list_states_treated'{
	disp("*************************")
	disp("Current State is `var'")
	disp("*************************")
tab inds if state =="`var'"
}

save temp_data_Feb8ninght1p,replace
log close


* event study variable construction
use temp_data_Feb2ninght1p,replace

* Construct outcome variables
// 1. first order effect, mobility
// - across industries, so outcome is the transition probability (state/district level)
// - individual separation or transition of jobs 
// (indicator of unoccupied, indicator of choosing manufacturign occupation)
// 2. 
* I actually need a value label on the date, not

* Today task 1: pick 3 outcomes to check reform regressions
reghdfe inc_all_source reformed , a(id month_slot) vce(cl id_state)
reghdfe inc_all_source reformed [pweight=mem_weight_w], a(id month_slot) vce(cl id_state)



* Today's task2: pick 3 outcomes to check and run the following regression and coefficient plot
egen kkk = group(date_str)
reg inc_all_source ib1.kkk if state == "Rajasthan", nocons
coefplot   make it horizontal and add vertical line

(try retain value label )


// how to conveniently use date label as the value label 


egen id_date = group(date)

ciplot inc_all_source if state=="Maharashtra" 
 || ciplot inc_all_source if state=="Madhya Pradesh" , scheme(s1mono) by(date) xlabel(, angle(vertical))


twoway fpfitci inc_all_source i.id_date

 || scatter mpg weight || , by(foreign, total row(1)) 

 ciplot inc_all_source if state=="Madhya Pradesh"



* how should I use the weight 
* how should I bunch dates so I don't get so many fluctuation. 



* graph 1: time trend graph 


by industry of job



* graph 2, relative periods maybe 



* DID
areg var_outcome i.




* graph 3, coefficient plot










