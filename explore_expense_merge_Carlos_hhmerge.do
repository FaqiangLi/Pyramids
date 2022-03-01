**** Expense merged with Carlos' datasets, summarizing employment status in the household level

clear
set more off
set seed 123456

* This script bases on Carlos Feb 15 latest script on event study. I didn't change anything before his Feb 15 version and just merge in household variables for analysis 

* There is another script called explore_expense_merge_carlos.do  . That script merges monthly household expenditure with household heads' master dataset. This script first transform Carlos' datasets to household levels with summary variables on household income and emeployement status and then merge directly with the monthly income data. 

cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use carlos_employment_income_1618,replace
/*
sample 10 
save carlos_employment_income_1618_10p, replace
sample 10 
save carlos_employment_income_1618_1p, replace


use temp_carlos_m_expense_1618,replace
sample 10 
save temp_carlos_m_expense_1618_10p, replace
sample 10 
save temp_carlos_m_expense_1618_1p, replace
*/


* Feb23 note: Note that temp_carlos_m_expense_1618 include more years.


* sort and order
sort hh_id mem_id month_slot month
order id hh_id mem_id month_slot month

* add GST window
gen post=date_m>tm(2017m6)
forvalues k=0(1)6 {
	gen event_`k'=date_m==tm(2017m6)+`k'
}
forvalues k=1(1)6 {
	gen event_neg`k'=date_m==tm(2017m6)-`k'
}
gen aux=dofm(date_m)
gen year=year(aux)
drop aux


* recode nature of occupation

ta nature, gen(nature_)

rename nature_1 nature_agricultural
rename nature_2 nature_business
rename nature_3 nature_homemaker
rename nature_4 nature_homeworker
rename nature_5 nature_industrialw
rename nature_6 nature_legislatoretc
rename nature_7 nature_manager
rename nature_8 nature_nonindtechemp
rename nature_9 nature_orgfarmer
rename nature_10 nature_qualified
rename nature_11 nature_retired
rename nature_12 nature_self
rename nature_13 nature_smallfarmer
rename nature_14 nature_small
rename nature_15 nature_student
rename nature_16 nature_suppstaff
rename nature_17 nature_unoccupied
rename nature_18 nature_wage
rename nature_19 nature_whiteclerical
rename nature_20 nature_whiteprofesional

rename nature_of_occupation nature 

gen nature_all=nature_business==1|nature_industrialw==1|nature_qualified==1|nature_self==1|nature_small==1


* Generate income share within a households, by member
rename income_of_member_from_* inc_*


* Now construct income weight for each family member
foreach type in inc_all_source inc_wages inc_pension inc_dividend inc_interest inc_fd_pf_insu{
	bysort hh_id month_slot month: egen hh`type'=sum(`type')
	bysort hh_id month_slot month: gen share_hh`type'=`type'/hh`type'
	replace share_hh`type' = -1 if share_hh`type'==.
	disp("`type'")
	count if hh`type'==0
}


* tag the income by industry , and generate share by industry, wrt income from all sources
foreach type in all business industrialw qualified self small{
	gen inc_indust_`type' = inc_all_source * nature_`type'
	
	bysort hh_id month_slot month: egen hhinctotal_`type'= sum(inc_indust_`type' )
	gen hhincsh_`type' = hhinctotal_`type'/hhinc_all_source
	replace hhincsh_`type'=-1 if hhincsh_`type'==.
}

//
// * generate income share by industry of a household, wrt income from all sources, but this time time invariant using all pre-GST income.
// foreach type in all business industrialw qualified self small{
// 	gen inc_indust_`type' = inc_all_source * nature_`type'
// 	bysort hh_id month_slot month: egen hhinctotal_`type'= sum(inc_indust_`type' )
// 	gen hhincsh_`type' = hhinctotal_`type'/hhinc_all_source
// 	replace hhincsh_`type'=-1 if hhincsh_`type'==.
// }


// CAVEAT: income of all sources might not be linked firmly to the nature of the occupation . 

* roughly in this sample, there are 170k households, two times the individuals (because we exclude age<15, retired). Most of the households have one member/two members (82%)
bysort hh_id month_slot month: gen order_mem = _n
bysort hh_id month_slot month: gen n_mem =_N
tab n_mem if order_mem==1
tab n_mem if order_mem==1 & substr(month,-4,4)=="2017"
hist share_hhinc_all_source  if substr(month,-4,4)=="2017"
gen temp = round(mem_weight_ms)
hist share_hhinc_all_source [fweight=temp] if substr(month,-4,4)=="2017"

* family highest income (which member and the ammount) from all sources, time variant
gen highest_inc_share=.  // household specific
gen highest_inc_who=.   // member specific
bysort hh_id month_slot month: egen rank_hhinc_share = rank(-share_hhinc_all_source) if n_mem > 1 & hhinc_all_source~=0
// highest_inc_who
replace highest_inc_who = 1 if n_mem == 1 & hhinc_all_source~=0
replace highest_inc_who = 1 if rank_hhinc_share<2 & n_mem > 1 & hhinc_all_source~=0
replace highest_inc_who = 0 if rank_hhinc_share>=2 & n_mem > 1 & hhinc_all_source~=0
replace highest_inc_who = 0 if hhinc_all_source==0
// highest_inc_share 
replace highest_inc_share = -1 if hhinc_all_source==0
replace highest_inc_share = 1 if n_mem == 1 & hhinc_all_source~=0
replace highest_inc_share =  share_hhinc_all_source if n_mem > 1 & hhinc_all_source~=0 & highest_inc_who==1
bysort hh_id month_slot month: egen temp_inc = min(highest_inc_share) if n_mem > 1 & hhinc_all_source~=0 
replace highest_inc_share = temp_inc if n_mem > 1 & hhinc_all_source~=0 
codebook highest_inc_share
codebook highest_inc_who
// check sanity
br hh_id mem_id share_hhinc_all_source rank_hhinc_share highest_inc_share if n_mem > 1 & hhinc_all_source~=0 
// Coding rule:
// singleton zero-income households: share=-1, who=0
// singleton pos-income households: share=1, who=1
// non-singletong zero-income households, share=-1, who=0
// non-singletong pos-income households, share<1, who=highest one


* whether the HOH is the highest income owner in the non-singleton positive family (time variant)
gen is_hoh = 1 if relation_with_hoh=="HOH"
replace is_hoh = 0 if is_hoh~=1
tab is_hoh highest_inc_who if n_mem > 1 & hhinc_all_source~=0 
* whether the hoh is the oldest (note these are in Carlos sample)
gen is_oldest =.
gen temp_age = age_yrs*100 + age_mths
bysort hh_id month_slot month: egen temp_age_rank = rank(-temp_age)
replace is_oldest = 1 if temp_age_rank==1
replace is_oldest = 0 if is_oldest==.
tab is_hoh is_oldest if n_mem > 1 & hhinc_all_source~=0 
* whether the hoh is the oldest male (note these are in Carlos sample)
tab is_hoh is_oldest if gender=="F" & n_mem > 1 & hhinc_all_source~=0 
tab is_hoh is_oldest if gender=="M" & n_mem > 1 & hhinc_all_source~=0 


* how the earning pattern looks like in a family
// caveat: from the above, singleton status is a time variant notion. 
// showcase the time variant status of singleton-ness
// bysort hh_id: var_inc_singleton = 


// caveat: wages and income from all sources should be distinguished: an old person can have little income from pension and it is his son earning the main income so this should be "close" to a singleton family.


* repeat the statistics but with larger aggregation in time. 
// first generate larger month slot or year group 
 

* trimming varialbes
// keep date_m nature month id hh_id mem_id industry state hr district region_type mem_weight_ms relation_with_hoh income_of_member_from_all_source income_of_member_from_wag

* collapse to household-month_slot_month level
drop id mem_id 
duplicates drop hh_id month_slot month, force



* merge
merge 1:1 hh_id month_slot month using temp_carlos_m_expense_1618
keep if _merge==3

drop _merge



* TODO: IN THE FUTURE, NEED TO INCORPORATE more hh chars, e.g. FAM SIZE (not just work force size, which is what we are doing )



save temp_expenditure_GST,replace


a

* The following are 
ds nature_*
local varlist "`r(varlist)'"

foreach xx of local varlist {
xtset id date_m
local xxx "`=substr("`xx'",8,.)'"  // read the variable's nature
di as red "`xxx'"  // check display each by each the xtset status
gen Lincsh`xxx'xpost=L.incsh`xx'*post

bys hh_id mem_id (date_m): gen past_`xxx'=sum(`xx')

replace past_`xxx'=past_`xxx'>0
gen past_`xxx'xpost=past_`xxx'*post
xtset id date_m
forvalues k=0/6 {
gen L`xxx'xevent_`k'=L.`xx'*event_`k' 
}
forvalues k=1/6 {
gen L`xxx'xevent_neg`k'=L.`xx'*event_neg`k' 
}
}

* group id
egen id_state=group(state)
egen id_hr=group(hr)
egen id_district=group(district)
gen is_urban=1 if region_type=="URBAN"
replace is_urban=0 if region_type=="RURAL"




****** Tests




areg expns_all i.event_neg* event_* incsh L`xxx'xevent_*  if , absorb(hh_id)



a


* The following are carlos

**************************** 
gen post=date_m>tm(2017m6)
forvalues k=0(1)6 {
	gen event_`k'=date_m==tm(2017m6)+`k'
}
forvalues k=1(1)6 {
	gen event_neg`k'=date_m==tm(2017m6)-`k'
}
gen aux=dofm(date_m)
gen year=year(aux)
drop aux
ta nature, gen(nature_)


rename nature_1 nature_agricultural
rename nature_2 nature_business
rename nature_3 nature_homemaker
rename nature_4 nature_homeworker
rename nature_5 nature_industrialw
rename nature_6 nature_legislatoretc
rename nature_7 nature_manager
rename nature_8 nature_nonindtechemp
rename nature_9 nature_orgfarmer
rename nature_10 nature_qualified
rename nature_11 nature_retired
rename nature_12 nature_self
rename nature_13 nature_smallfarmer
rename nature_14 nature_small
rename nature_15 nature_student
rename nature_16 nature_suppstaff
rename nature_17 nature_unoccupied
rename nature_18 nature_wage
rename nature_19 nature_whiteclerical
rename nature_20 nature_whiteprofesional

rename nature_of_occupation nature 

gen nature_all=nature_business==1|nature_industrialw==1|nature_qualified==1|nature_self==1|nature_small==1


ds nature_*
local varlist "`r(varlist)'"

foreach xx of local varlist {
xtset id date_m
local xxx "`=substr("`xx'",8,.)'"  // read the variable's nature
di as red "`xxx'"  // check display each by each the xtset status
gen L`xxx'xpost=L.`xx'*post
bys hh_id mem_id (date_m): gen past_`xxx'=sum(`xx')
replace past_`xxx'=past_`xxx'>0
gen past_`xxx'xpost=past_`xxx'*post
xtset id date_m
forvalues k=0/6 {
gen L`xxx'xevent_`k'=L.`xx'*event_`k' 
}
forvalues k=1/6 {
gen L`xxx'xevent_neg`k'=L.`xx'*event_neg`k' 
}
}

* group id
egen id_state=group(state)
egen id_hr=group(hr)
egen id_district=group(district)
gen is_urban=1 if region_type=="URBAN"
replace is_urban=0 if region_type=="RURAL"

save carlos_employment_income_1618_event_study, replace






***************



sample 10 
save carlos_employment_income_1618_event_study_10p, replace

sample 10
save carlos_employment_income_1618_event_study_1p, replace


use carlos_employment_income_1618_event_study, replace
merge m:1 hh_id month using temp_carlos_m_expense_1618
keep if _merge==3
drop _merge

save carlos_emp_inc_hhmonexp_1618_event_study,replace

sample 10 
save carlos_emp_inc_hhmonexp_1618_event_study_10p, replace

sample 10
save carlos_emp_inc_hhmonexp_1618_event_study_1p, replace


a


foreach xx in business industrialw qualified self small all wage {
xtset id date_m

reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(hh_id date_m) vce(cl id)
outreg2 using `xx'_employed_to_unoccupied, replace excel dec(5) nocons addtext(FE: hh date)
reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(id date_m) vce(cl id)
outreg2 using `xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)
reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(hh_id date_m) vce(cl id)
outreg2 using `xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hh date)
reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(id date_m) vce(cl id)
outreg2 using `xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)

}

a

/* excluded L.nature_wage Lwagexpost ///
 */

xtset id date_m
reghdfe nature_unoccupied L.nature_agricultural Lagriculturalxpost ///
L.nature_business Lbusinessxpost ///
L.nature_homemaker Lhomemakerxpost ///
L.nature_homeworker Lhomeworkerxpost ///
L.nature_industrialw Lindustrialwxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_legislatoretc Llegislatoretcxpost ///
L.nature_manager Lmanagerxpost ///
L.nature_nonindtechemp Lnonindtechempxpost ///
L.nature_orgfarmer Lorgfarmerxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_retired Lretiredxpost ///
L.nature_self Lselfxpost ///
L.nature_smallfarmer Lsmallfarmerxpost ///
L.nature_small Lsmallxpost ///
L.nature_student Lstudentxpost ///
L.nature_suppstaff Lsuppstaffxpost ///
L.nature_whiteclerical Lwhiteclericalxpost ///
L.nature_whiteprofesional Lwhiteprofesionalxpost ///
, a(hh_id date_m) vce(cl id) 
outreg2 using fullnature_to_unoccupied, replace excel dec(5) nocons addtext(FE: hh date)
xtset id date_m
reghdfe nature_unoccupied L.nature_agricultural Lagriculturalxpost ///
L.nature_business Lbusinessxpost ///
L.nature_homemaker Lhomemakerxpost ///
L.nature_homeworker Lhomeworkerxpost ///
L.nature_industrialw Lindustrialwxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_legislatoretc Llegislatoretcxpost ///
L.nature_manager Lmanagerxpost ///
L.nature_nonindtechemp Lnonindtechempxpost ///
L.nature_orgfarmer Lorgfarmerxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_retired Lretiredxpost ///
L.nature_self Lselfxpost ///
L.nature_smallfarmer Lsmallfarmerxpost ///
L.nature_small Lsmallxpost ///
L.nature_student Lstudentxpost ///
L.nature_suppstaff Lsuppstaffxpost ///
L.nature_whiteclerical Lwhiteclericalxpost ///
L.nature_whiteprofesional Lwhiteprofesionalxpost ///
, a(hh_id date_m) vce(cl id) 
outreg2 using fullnature_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)

**** 

xtset id date_m
reghdfe nature_unoccupied L.nature_agricultural Lagriculturalxpost ///
L.nature_business Lbusinessxpost ///
L.nature_homemaker Lhomemakerxpost ///
L.nature_homeworker Lhomeworkerxpost ///
L.nature_industrialw Lindustrialwxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_legislatoretc Llegislatoretcxpost ///
L.nature_manager Lmanagerxpost ///
L.nature_nonindtechemp Lnonindtechempxpost ///
L.nature_orgfarmer Lorgfarmerxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_retired Lretiredxpost ///
L.nature_self Lselfxpost ///
L.nature_smallfarmer Lsmallfarmerxpost ///
L.nature_small Lsmallxpost ///
L.nature_student Lstudentxpost ///
L.nature_suppstaff Lsuppstaffxpost ///
L.nature_whiteclerical Lwhiteclericalxpost ///
L.nature_whiteprofesional Lwhiteprofesionalxpost ///
, a(hh_id date_m) vce(cl id) 
outreg2 using fullnature_to_unoccupied, replace excel dec(5) nocons addtext(FE: hh date)
xtset id date_m
reghdfe nature_unoccupied L.nature_agricultural Lagriculturalxpost ///
L.nature_business Lbusinessxpost ///
L.nature_homemaker Lhomemakerxpost ///
L.nature_homeworker Lhomeworkerxpost ///
L.nature_industrialw Lindustrialwxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_legislatoretc Llegislatoretcxpost ///
L.nature_manager Lmanagerxpost ///
L.nature_nonindtechemp Lnonindtechempxpost ///
L.nature_orgfarmer Lorgfarmerxpost ///
L.nature_qualified Lqualifiedxpost ///
L.nature_retired Lretiredxpost ///
L.nature_self Lselfxpost ///
L.nature_smallfarmer Lsmallfarmerxpost ///
L.nature_small Lsmallxpost ///
L.nature_student Lstudentxpost ///
L.nature_suppstaff Lsuppstaffxpost ///
L.nature_whiteclerical Lwhiteclericalxpost ///
L.nature_whiteprofesional Lwhiteprofesionalxpost ///
, a(hh_id date_m) vce(cl id) 
outreg2 using fullnature_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)

reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(hh_id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hh date)
reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)











