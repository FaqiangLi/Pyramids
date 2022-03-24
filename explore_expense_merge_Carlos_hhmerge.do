**** Expense merged with Carlos' datasets, summarizing employment status in the household level

clear
set more off
set seed 123456

* This script bases on Carlos Feb 15 latest script on event study. I didn't change anything before his Feb 15 version in terms of the initial sample selection and variable selection. I did two things in extra,
// 1. Summarize monthly income related variable within a household (and so later we can -duplicates drop hh_id date_m-)
// 2. Merge in monthly expenditure data. I rough picked the variables in the clean_expense.do (previously named "explore_expense.do")


* I also keep some clips of the original Carlos' codes for event study at the bottom of this script.

capture cd "/Users/faqiangmacpro/Downloads/local_pyramids_tempfile"

capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles"


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


* Feb23 note: Note that temp_carlos_m_expense_1618 include more years. Need to tell Carlos to prolong his original sample to include more years.

**** CAVEAT: NEVER SORT month_slot and month!!! They are strings!!!! 



merge m:1 hh_id month using household_income_1419
keep if _merge==3
drop _merge


* Use incHH to denote that the data come from household dataset
rename total_income total_incHH
rename (income_of_all_members_from_all_s income_of_all_members_from_wages income_of_all_members_from_pensi income_of_all_members_from_divid income_of_all_members_from_inter) (incHH_allmem_alls incHH_allmem_wages incHH_allmem_pension incHH_allmem_div incHH_allmem_int)
rename (income_of_household_from_all_sou income_of_household_from_rent income_of_household_from_self_pr income_of_household_from_private income_of_household_from_governm income_of_household_from_busines income_of_household_from_sale_of income_of_household_from_gamblin income_of_all_members_from_fd_pf) (incHH_hh_alls  incHH_hh_rent incHH_hh_selfprod incHH_hh_privtrans incHH_hh_govtrans incHH_hh_business incHH_hh_saleasset incHH_hh_gamble incHH_hh_fdpf)


************************************************************************
* Fundamental variables construction
************************************************************************


* sort and order
sort hh_id mem_id date_m
order id hh_id mem_id date_m 


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

capture rename  nature_1 nature_agricultural
capture rename  nature_2 nature_business
capture rename  nature_3 nature_homemaker
capture rename  nature_4 nature_homeworker
capture rename  nature_5 nature_industrialw
capture rename  nature_6 nature_legislatoretc
capture rename  nature_7 nature_manager
capture rename  nature_8 nature_nonindtechemp
capture rename  nature_9 nature_orgfarmer
capture rename  nature_10 nature_qualified
capture rename  nature_11 nature_retired
capture rename  nature_12 nature_self
capture rename  nature_13 nature_smallfarmer
capture rename  nature_14 nature_small
capture rename  nature_15 nature_student
capture rename  nature_16 nature_suppstaff
capture rename  nature_17 nature_unoccupied
capture rename  nature_18 nature_wage
capture rename  nature_19 nature_whitec // changed from whiteclerical to whitec
capture rename  nature_20 nature_whitep // changed from whiteprofessional to white p
capture rename  nature_of_occupation nature 

capture gen nature_all=nature_business==1|nature_industrialw==1|nature_qualified==1|nature_self==1|nature_small==1

sort hh_id mem_id date_m
bysort hh_id mem_id (date_m): gen period = _n
bysort hh_id mem_id (date_m): gen all_period = _N
bysort hh_id mem_id : egen temp_all_period_preGST=max(period) if post==0
bysort hh_id mem_id : egen all_period_preGST=min(temp_all_period_preGST)
replace all_period_preGST=0 if all_period_preGST==.
gen all_period_postGST = all_period-all_period_preGST 

// br hh_id mem_id period all_period all_period_preGST all_period_postGST post



* Todo: Define additionally migration status according to member_status




************************************************************************
* Household variables construction: income composition(or income structure)
************************************************************************

* Generate income share within a households, by member
rename income_of_member_from_* inc_*
* Now construct income weight for each family member within a household
foreach type in inc_all_source inc_wages inc_pension inc_dividend inc_interest inc_fd_pf_insu{
	bysort hh_id date_m: egen hh`type'=sum(`type')
	bysort hh_id date_m: gen share_hh`type'=`type'/hh`type'
	replace share_hh`type' = -0.1 if share_hh`type'==.
	disp("`type'")
	count if hh`type'==0
}

* tag the income by industry , and generate share by industry, wrt income from all sources
ds nature_*
local varlist "`r(varlist)'"
foreach xx of local varlist {
local type "`=substr("`xx'",8,.)'"  

	gen inc_indust_`type' = inc_all_source * nature_`type'
	
	bysort hh_id date_m: egen hhinctotal_`type'= sum(inc_indust_`type' )
	gen hhincsh_`type' = hhinctotal_`type'/hhinc_all_source
	replace hhincsh_`type'=-0.1 if hhincsh_`type'==.

}


//
// * generate income share by industry of a household, wrt income from all sources, but this time time invariant using all pre-GST income.
// foreach type in all business industrialw qualified self small{
// 	gen inc_indust_`type' = inc_all_source * nature_`type'
// 	bysort hh_id date_m: egen hhinctotal_`type'= sum(inc_indust_`type' )
// 	gen hhincsh_`type' = hhinctotal_`type'/hhinc_all_source
// 	replace hhincsh_`type'=-0.1 if hhincsh_`type'==.
// }


// CAVEAT: income of all sources might not be linked firmly to the nature of the occupation . 

* roughly in this sample, there are 170k households, two times the individuals (because we exclude age<15, retired). Most of the households have one member/two members (82%)
bysort hh_id date_m: gen order_mem = _n
bysort hh_id date_m: gen n_mem =_N
tab n_mem if order_mem==1
tab n_mem if order_mem==1 & substr(month,-4,4)=="2017"
gen temp = round(mem_weight_ms)

* family highest income (which member and the ammount) from all sources, time variant
// Coding rule:
// singleton zero-income households: share=-0.1, who=0
// singleton pos-income households: share=1, who=1
// non-singletong zero-income households, share=-0.1, who=0
// non-singletong pos-income households, share<1, who=highest one
gen highest_inc_share=.  // household specific
gen highest_inc_who=.   // member specific
bysort hh_id date_m: egen rank_hhinc_share = rank(-share_hhinc_all_source) if n_mem > 1 & hhinc_all_source~=0
// highest_inc_who
replace highest_inc_who = 1 if n_mem == 1 & hhinc_all_source~=0
replace highest_inc_who = 1 if rank_hhinc_share<2 & n_mem > 1 & hhinc_all_source~=0
replace highest_inc_who = 0 if rank_hhinc_share>=2 & n_mem > 1 & hhinc_all_source~=0
replace highest_inc_who = 0 if hhinc_all_source==0
// highest_inc_share 
replace highest_inc_share = -0.1 if hhinc_all_source==0
replace highest_inc_share = 1 if n_mem == 1 & hhinc_all_source~=0
replace highest_inc_share =  share_hhinc_all_source if n_mem > 1 & hhinc_all_source~=0 & highest_inc_who==1
bysort hh_id date_m: egen temp_inc = min(highest_inc_share) if n_mem > 1 & hhinc_all_source~=0 
replace highest_inc_share = temp_inc if n_mem > 1 & hhinc_all_source~=0 
codebook highest_inc_share
codebook highest_inc_who
sum highest_inc_share, detail
sum highest_inc_share if highest_inc_share~=-0.1, detail

// check sanity
// br hh_id mem_id share_hhinc_all_source rank_hhinc_share highest_inc_share if n_mem > 1 & hhinc_all_source~=0 


* whether the HOH is the highest income owner in the non-singleton positive family (time variant)
/*
gen is_hoh = 1 if relation_with_hoh=="HOH"
replace is_hoh = 0 if is_hoh~=1
tab is_hoh highest_inc_who if n_mem > 1 & hhinc_all_source~=0 
* whether the hoh is the oldest (note these are in Carlos sample)
gen is_oldest =.
gen temp_age = age_yrs*100 + age_mths
bysort hh_id date_m: egen temp_age_rank = rank(-temp_age)
replace is_oldest = 1 if temp_age_rank==1
replace is_oldest = 0 if is_oldest==.
tab is_hoh is_oldest if n_mem > 1 & hhinc_all_source~=0 
* whether the hoh is the oldest male (note these are in Carlos sample)
tab is_hoh is_oldest if gender=="F" & n_mem > 1 & hhinc_all_source~=0 
tab is_hoh is_oldest if gender=="M" & n_mem > 1 & hhinc_all_source~=0 
*/


// caveat: wages and income from all sources should be distinguished: an old person can have little income from pension and it is his son earning the main income so this should be "close" to a singleton family.


 
* Household main income earner's industry code can be regarded as the code for this faminly
// the chance of getting the "highest income earner" badge in all pre-GST periods
// again: subtlety: some households do not have pre-GST data! So in this version, to avoid this, I use pre-post data all together to decide who is the main wage earner ---- a more proper way could be defining it pre and post -- and see if the highest wager earner change overtime due to the policy (but need to think about the ratio very properly, e.g. enter into data for one period and become main earner coincidently)
bysort hh_id mem_id: egen temp_highestperiods = sum(highest_inc_who) 
bysort hh_id mem_id: egen highestperiods=min(temp_highestperiods)
gen ratio_highestperiods = highestperiods/all_period
// define the main earner to be the member who earns the badge for sufficiently long time 
bysort hh_id: egen temp_main_earner = rank(ratio_highestperiods) if period==1 & post==0
bysort hh_id mem_id: egen main_earner = min(temp_main_earner)
replace main_earner=0 if main_earner~=1
// CAVEAT: within households, periods could differ. I ignore this subtlety here.
// main_earner is a time-invariant badge for individual


// there are other ways of defining main earners: e.g. the  one getting the highest share of total earning of all the preGST periods



* Generate the core indep variables used in event study for households' main earner
// me for main earner
ds nature_*
local varlist "`r(varlist)'"
foreach xx of local varlist {
local xxx "`=substr("`xx'",8,.)'"  // read the variable's nature
	gen temp_hh_me_`xxx' = 1 if main_earner==1 & nature_`xxx'==1
	bysort hh_id date_m: egen hh_me_`xxx'=min(temp_hh_me_`xxx')
	replace hh_me_`xxx'=0 if hh_me_`xxx'==.
}

/* Todo
1. household share of income of specific industry
2. main earner's industry tag in the last period 

4. ...(waiting for the next meeting on March 9), quantile of the regressor

These variables are household level and will be used as the core event study terms in the following exercise.
*/



************************************************************************
* Proceed to merging
************************************************************************



* note: there are some household level variables already availabe in monthly expense data!

* trimming varialbes
// keep date_m nature month id hh_id mem_id industry state hr district region_type mem_weight_ms relation_with_hoh income_of_member_from_all_source income_of_member_from_wag

* collapse to household-date_m level
drop id mem_id 
duplicates drop hh_id date_m, force

* merge wirh expenditure
merge 1:1 hh_id month_slot month using temp_carlos_m_expense_1618
keep if _merge==3
drop _merge


save temp_temp_temp, replace


use temp_temp_temp, replace

* decode size group
gen hhsize = .
replace hhsize=1 if size_group=="1 Member"
replace hhsize=2 if size_group=="2 Members"
replace hhsize=3 if size_group=="3 Members"
replace hhsize=4 if size_group=="4 Members"
replace hhsize=5 if size_group=="5 Members"
replace hhsize=6 if size_group=="6 Members"
replace hhsize=7 if size_group=="7 Members"
replace hhsize=8 if size_group=="8-10 Members"
replace hhsize=11 if size_group=="11-15 Members"
replace hhsize=15 if size_group=="> 15 Members"
tab hhsize


* decode occupation group
ta occupation_group, gen(hhnature_)
capture rename  hhnature_1 hhnature_agricultural
capture rename  hhnature_2 hhnature_business
capture rename  hhnature_3 hhnature_homemaker
capture rename  hhnature_4 hhnature_homeworker
capture rename  hhnature_5 hhnature_industrialw
capture rename  hhnature_6 hhnature_legislatoretc
capture rename  hhnature_7 hhnature_manager
capture rename  hhnature_8 hhnature_nonindtechemp
capture rename  hhnature_9 hhnature_orgfarmer
capture rename  hhnature_10 hhnature_qualified
capture rename  hhnature_11 hhnature_retired
capture rename  hhnature_12 hhnature_self
capture rename  hhnature_13 hhnature_smallfarmer
capture rename  hhnature_14 hhnature_small
capture rename  hhnature_15 hhnature_student
capture rename  hhnature_16 hhnature_suppstaff
capture rename  hhnature_17 hhnature_unoccupied
capture rename  hhnature_18 hhnature_wage
capture rename  hhnature_19 hhnature_whitec // changed from whiteclerical to whitec
capture rename  hhnature_20 hhnature_whitep // changed from whiteprofessional to white p
rename occupation_group hhnature 

capture gen hhnature_all=hhnature_business==1|hhnature_industrialw==1|hhnature_qualified==1|hhnature_self==1|hhnature_small==1


* Todo: wait for Carlos to add more years


**** For better graph, prepare summary statistics

* For tag of zero income, hhhighest income share cutoff-type
sum highest_inc_share, detail
sum highest_inc_share if highest_inc_share>0, detail
sum highest_inc_share if highest_inc_share>0 & highest_inc_share<1, detail

gen hh_weight_ms_floored=floor(hh_weight_ms)
sum highest_inc_share [fweight=hh_weight_ms_floored], detail
sum highest_inc_share if highest_inc_share>0 [fweight=hh_weight_ms_floored] , detail
sum highest_inc_share if highest_inc_share>0 & highest_inc_share<1 [fweight=hh_weight_ms_floored] , detail


* inc change, expenditure change
bysort hh_id (date_m): gen lhhinc_all_source = hhinc_all_source[_n-1]
gen hhinc_loss=.
// place holder, later used to generate tag
replace hhinc_loss = (hhinc_all_source-lhhinc_all_source)/lhhinc_all_source
replace hhinc_loss = 19930412 if lhhinc_all_source==0
sum hhinc_loss, detail
sum hhinc_loss if hhinc_loss~=19930412, detail

bysort hh_id (date_m): gen ltotal_expenditure = total_expenditure[_n-1]
gen hhexp_loss=.
replace hhexp_loss = (total_expenditure-ltotal_expenditure)/ltotal_expenditure
replace hhexp_loss = 19930412 if ltotal_expenditure==0
sum hhexp_loss, detail
sum hhexp_loss if hhexp_loss~=19930412, detail

gen exp_elasticity = .
replace exp_elasticity=(hhexp_loss/total_expenditure)/(hhinc_loss/hhinc_all_source) if hhexp_loss~=19930412 & hhinc_loss~=19930412
sum exp_elasticity, detail


// browse some distribution of 
 sum hhinc_loss if date_m==tm(2017m1) & hhinc_loss~=19930412, detail
 sum hhexp_loss if date_m==tm(2017m1) & hhexp_loss~=19930412, detail
 sum exp_elasticity if date_m==tm(2017m1) , detail

 sum hhinc_loss if date_m==tm(2017m9) & hhinc_loss~=19930412, detail
 sum hhexp_loss if date_m==tm(2017m9) & hhexp_loss~=19930412, detail
 sum exp_elasticity if date_m==tm(2017m9) , detail


* saving rate and expeindture rate cutoff-type
gen hhsave = hhinc_all_source - total_expenditure
gen hhsaver = hhsave/hhinc_all_source
replace hhsaver = 19930412 if hhinc_all_source==0
sum hhsaver, detail
sum hhsaver if hhsaver~=19930412, detail 
gen hhexpr = total_expenditure/hhinc_all_source 
replace hhexpr = 19930412 if hhinc_all_source==0
sum hhexpr, detail
sum hhexpr if hhexpr~=19930412, detail 

* expenditure per capita
gen hhexppc = total_expenditure/hhsize
sum hhexppc, detail
sum hhexppc if date_m==tm(2017m1), detail
 sum hhexppc if date_m==tm(2017m5), detail
 sum hhexppc if date_m==tm(2017m9), detail


* Define some directly usable household level income variables
rename total_incHH total_incHH_gross
gen hhsave_new = total_incHH_gross - total_expenditure
foreach inctype in rent selfprod privtrans govtrans business saleasset gamble{
	gen total_incHH_`inctype' = incHH_allmem_alls+incHH_hh_`inctype'
	gen hhsaver_totalhh_`inctype' = hhsave_new/total_incHH_`inctype'
	gen hhexpr_totalhh_`inctype' = total_expenditure/total_incHH_`inctype'
	gen hhincr_totalhh_`inctype' = incHH_hh_`inctype'/total_incHH_gross
}
gen hhsaver_totalhh_gross = hhsave_new/total_incHH_gross
gen hhexpr_totalhh_gross = total_expenditure/total_incHH_gross
gen share_meminc_to_hhinc = incHH_allmem_alls/total_incHH_gross

ds hhsaver_totalhh_* hhexpr_totalhh_* hhincr_totalhh_* share_meminc_to_hhinc
foreach var in `r(varlist)'{
	replace `var'=19930412 if `var'==.
}

* Browse 


// self prod is mainly from agricuture
// privtrans should have different degree of share of privtrans
// rural households should have much more govtrans
foreach inspection_type in selfprod privtrans govtrans{
	disp("`inspection_type'")
	sum hhincr_totalhh_`inspection_type', detail 
	sum hhincr_totalhh_`inspection_type' if hhincr_totalhh_`inspection_type'~=19930412, detail 
	sum hhincr_totalhh_`inspection_type' if hhincr_totalhh_`inspection_type'~=19930412 & region_type=="URBAN", detail 
	sum hhincr_totalhh_`inspection_type' if hhincr_totalhh_`inspection_type'~=19930412 & region_type=="RURAL", detail 
	}


sum share_meminc_to_hhinc , detail
sum share_meminc_to_hhinc if share_meminc_to_hhinc~=19930412, detail

foreach object in hhsaver_totalhh_gross hhexpr_totalhh_gross share_meminc_to_hhinc{
	disp("`object'")
	sum `object' if `object'~=19930412, detail 
	sum `object' if `object'~=19930412 & date_m==tm(2017m4), detail 
	sum `object' if `object'~=19930412 & date_m==tm(2017m10) , detail 
}


* Define materials for engle curve (scatter income exp_of_a_kind)
* log income and log expenditure

* expenditure share of various bigger kinds
foreach exptype in food intoxicants clothfoot appliances health{
	gen hhexpshare_`exptype'= m_expns_`exptype'/ total_incHH_gross
	replace hhexpshare_`exptype'=19930412 if total_incHH_gross==0
	disp("hhexpshare_`exptype'")
	sum hhexpshare_`exptype' if hhexpshare_`exptype'~=19930412, detail 
	sum hhexpshare_`exptype' if hhexpshare_`exptype'~=19930412 & date_m==tm(2017m4), detail 
	sum hhexpshare_`exptype' if hhexpshare_`exptype'~=19930412 & date_m==tm(2017m10) , detail 
	gen loghhmexp_`exptype'=log(m_expns_`exptype'+1)
}
gen logtotal_incHH_gross = log(total_incHH_gross+1)

 
 * see how often the household income is coded -99
 foreach var in incHH_hh_alls incHH_hh_rent incHH_hh_selfprod incHH_hh_privtrans incHH_hh_govtrans incHH_hh_business incHH_hh_saleasset incHH_hh_gamble incHH_hh_fdpf{
 	disp("`var'")
 	count if `var'==-99
 }
 
 
 
* CAVEAT: FINER CONSUMPTIONS ARE POSSIBLE , I HAVE SELECTED ONLY A FEW AGGREGATE CATEGORIES.


save temp_expenditure_GST,replace
sample 10
save temp_expenditure_GST_10p, replace
sample 10
save temp_expenditure_GST_1p, replace
sample 10
save temp_expenditure_GST_01p, replace


************************************************************************
* Sanity check: whether the income of all members is consistent with household dataset
************************************************************************



use temp_expenditure_GST_1p, replace

// the third one is my construction, it is equal to the first one from the household dataset. Note that the second one is the household specific income , so it can be lower thant the income of all household members, the first variable
br incHH_allmem_alls incHH_hh_alls hhinc_all_source

