**** Expense merged with Carlos' datasets, but only to household's head

clear
set more off
set seed 123456

* This script bases on Carlos Feb 15 latest script on event study. I didn't change anything before his Feb 15 version and just merge in household variables for analysis 


* There is another script called explore_expense_merge_carlos_hhmerge.do. The current script only conduct summary analysis on household heads --- later I decide to work on explore_expense_merge_carlos_hhmerge because the exercise makes much more sense by not merging  according to household heads,


cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use carlos_employment_income_1618_10p,replace

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

