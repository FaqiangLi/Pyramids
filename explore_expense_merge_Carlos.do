**** Expense merged with Carlos' datasets, but only to household's head

clear
set more off
set seed 123456

* This script bases on Carlos Feb 15 latest script on event study. I didn't change anything before his Feb 15 version and just merge in household variables for analysis 

* There is another script called explore_expense_merge_carlos_hhmerge.do  . This script merges monthly household expenditure with household heads' master dataset. The other script first transform Carlos' datasets to household levels with summary variables on household income and emeployement status and then merge directly with the monthly income data. 

cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use carlos_employment_income_1618_10p,replace
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

* CAVEAT:think about weights when collapsing the dataset.


/*
How many are hoh (full Carlos sample)? Recall that in early days some obs are truncated out.

 tab relation_with_hoh

    RELATION_WITH_HOH |      Freq.     Percent        Cum.
----------------------+-----------------------------------
              Brother |     50,963        0.79        0.79
Brother/Sister-in-law |      5,168        0.08        0.87
       Daugher-in-law |          4        0.00        0.87
             Daughter |    175,745        2.72        3.59
      Daughter-in-law |    138,141        2.14        5.73
        Domestic help |        382        0.01        5.74
               Friend |         64        0.00        5.74
           Grandchild |     46,827        0.73        6.47
                  HOH |  3,312,516       51.32       57.79
                Inlaw |      1,363        0.02       57.81
  Other non-relatives |        156        0.00       57.81
               Parent |     43,710        0.68       58.49
             Relative |      8,929        0.14       58.63
               Sister |     11,133        0.17       58.80
                  Son |  1,949,801       30.21       89.01
           Son-in-law |     12,010        0.19       89.19
               Spouse |    697,529       10.81      100.00
----------------------+-----------------------------------
                Total |  6,454,441      100.00

This is the relationship of the member with the head of the household. One member of the household is classified by the interviewer, as the head of the household. This is usually the one who takes the most important decisions in the household. In many modern households such a classification of one individual as the head of the household is facile (flexible). Nevertheless, *one person* of every household is classified as the head of the household. This is useful as it creates a reference for relationships within the household. All relationships are with respect to the head of the household.		

Definition of hoh
*/

sort hh_id mem_id month_slot month
order hh_id mem_id month_slot month

* check the stats of the head of the household

* confirmed: only one person is HOH per HH.
duplicates report hh_id mem_id month_slot month
duplicates report hh_id month_slot month if relation_with_hoh=="HOH"

* there are households not having hoh
gen temp1 = 1 if relation_with_hoh=="HOH"
replace temp1 = 0 if relation_with_hoh~="HOH"
bysort hh_id: egen temp2=sum(temp1)  // no hoh in any point in time
codebook hh_id if temp2==0
codebook hh_id if temp2~=0

* what is the image of these hoh?
foreach char in gender religion caste caste_category literacy education discipline nature_of_occupation industry_of_occupation employment_status_since_yrs type_of_employment employment_arrangement time_to_start_working{
	tab `char' 
	tab `char' if relation_with_hoh=="HOH"
	/* one can roughly see the following pattern compared to the overall population, the average HOH are more likely to be:male, to be tagged "not applicable" in discipline, to be , non-home-maker, full time.
	
	There is no difference in observation proportion in religion,caste group, education, employment arrangement.
	
	uncheck: caste , industry, employment_status_since_yrs, time to start working
	*/
}
foreach char in gender religion caste caste_category literacy education discipline nature_of_occupation industry_of_occupation employment_status_since_yrs type_of_employment employment_arrangement time_to_start_working{
	tab `char' 
	/*
	
	
	*/
}

* I add more var (additional to Carlos' original variable selection) to help the merge
keep date_m nature month id hh_id mem_id industry state hr district region_type mem_weight_ms relation_with_hoh income_of_member_from_all_source income_of_member_from_wages

* merge back the weight!!!!
temp_carlos_m_expense_1618







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











