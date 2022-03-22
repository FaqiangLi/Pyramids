**** Basic statistics about the expense data

clear
set more off

cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use monthly_expense_1419, replace

*******************************************************************************
*********************** Rough variable selection *************************
*******************************************************************************

* browse variable
/* glossary
ghee: india oil for cake?
saffron: a kind of daily flower spice
mithai: an India dessert
EMI: equated monthly installment

*/

* drop some variables for preliminary exploration (needs to do aggregation later)

local interest_list total_expenditure adj_total_expenditure monthly_expense_on_food adj_monthly_expense_on_food monthly_expense_on_intoxicants adj_monthly_expense_on_intoxican monthly_expense_on_cigarettes_an adj_monthly_expense_on_cigarette monthly_expense_on_cigarettes v93 monthly_expense_on_bidis adj_monthly_expense_on_bidis monthly_expense_on_other_tobacco adj_monthly_expense_on_other_tob monthly_expense_on_liquor monthly_expense_on_clothing_and_ monthly_expense_on_clothing monthly_expense_on_all_types_of_ monthly_expense_on_appliances monthly_expense_on_health monthly_expense_on_medicines monthly_expense_on_all_emis

keep `interest_list' hh_id state hr district region_type stratum psu_id month_slot month response_status reason_for_non_response hh_weight_ms hh_weight_for_country_ms hh_weight_for_state_ms hh_non_response_ms hh_non_response_for_country_ms hh_non_response_for_state_ms age_group occupation_group education_group gender_group size_group 


* tips on the adjusted expense variables.
/*
https://consumerpyramidsdx.cmie.com/kommon/bin/sr.php?kall=wkbquest&id=1655

The adjustment is done by finding the ratio of the average monthly expenses seen in the four observations of monthly expenses and the implicit monthly expenses derived by multiplying the weekly expenses by four. Specifically, an adjustment factor is derived as a ratio where the numerator is the average monthly expenses seen in the four observations of monthly expenses and the denominator is the weekly expenses inflated by four to provide an approximate monthly expenditure. Monthly expenses are divided by this adjustment factor to derive the adjusted monthly expenses.

*/

* rename 
rename monthly_expense_on_* m_expns_*
rename adj_monthly_expense_on_* m_adjexpns_*

* compare the variable label carefully!
// cigarette and tabacco
capture rename m_expns_cigarettes_an m_expns_cigtabacco
capture rename m_adjexpns_cigarette m_adjexpns_cigtabacco
capture rename m_expns_cigarettes m_expns_cig
capture rename v93 m_adjexpns_cig
// clothing
capture rename m_expns_clothing_and_ m_expns_clothfoot
capture rename m_expns_all_types_of_ m_expns_alldeterg

* Disaggregation level: hh_id month_slot month
duplicates report hh_id month_slot month

* Original dataset has 9m obs
count 


* Carlos time label
gen date_m=monthly(month_slot, "MY")
format date_m %tm

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


* recode date of the survey (I replace this later to Carlos's labeling)
/*
gen date=date(month_slot, "MY")
format date %d
gen date_m = month(date)  // survey month
gen date_y = year(date)   // survey year
tostring date_m date_y, replace
replace date_m = "0"+date_m if strlen(date_m)==1
gen date_str_survey = date_y + date_m // survey date
destring date_m date_y,replace
drop date

* recode the date of the data
gen date=date(month, "MY")
format date %d
rename month month_CMIE
gen month = month(date)  // data month
gen year = year(date)   // data year
tostring month year, replace
replace month = "0"+month if strlen(month)==1
gen date_str_var = year + month
destring month year,replace
drop date

* periods
bysort hh_id (date_str_var): gen period = _n

* sort
// year month are the data lables
// 
sort hh_id year month

* label
label variable year "Year of the variables (int)"
label variable month "Month of the variables (int)"
label variable month_CMIE "Yean and month of the variables (string)"
label variable date_str_var "Date of the variables (string)"
label variable month_slot "Surveyed month and year of the household/individual (string)"
label variable date_m "Surveyed month of the household/indivdidual (int)"
label variable date_y "Surveyed year of the household/individual (int)"
label variable date_str_var "Date of the survey (string)"
label variable period "Counting the starting month as the first period of a household/individual"

* reorder
order hh_id year month period month_slot month_CMIE district region_type stratum total_expenditure adj_total_expenditure hh_weight_ms age_group occupation_group education_group gender_group size_group 

*/

* Some useful date indicators
gen date=date(month, "MY")
format date %d
gen month_var = month(date)  // data month
gen year_var = year(date)   // data year
tostring month_var year_var, replace
replace month = "0"+month if strlen(month)==1
gen date_str_var = year + month
destring month year,replace
drop date

* Drop extra dates
drop if year>2019
drop if year<2014


* save temporary file for Feb 16/23 meeting
drop state hr district stratum psu_id response_status reason_for_non_response
save temp_carlos_m_expense_1618,replace


* browsing the data
/*
codebook date_str_var
tab date_str_var



* See what these group data represents (unique to household level dataset like the household monthly income)
foreach var in region_type age_group occupation_group education_group gender_group size_group{
	codebook `var'
	tab `var'
}

*/

********************************************************************************
**************** Generate mean data trend **************** 
********************************************************************************

* Reference line 1: 2016 November 1: date_m==682
* Reference line 2: 2017 July 1: date_m==690

* Graph by expenditure category
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use temp_carlos_m_expense_1618,replace

collapse(mean) total_expenditure adj_total_expenditure m_expns_food m_adjexpns_food m_expns_intoxicants m_adjexpns_intoxican m_expns_cigtabacco m_adjexpns_cigtabacco m_expns_cig m_adjexpns_cig m_expns_bidis m_adjexpns_bidis m_expns_other_tobacco m_adjexpns_other_tob m_expns_liquor m_expns_clothfoot m_expns_clothing m_expns_alldeterg m_expns_appliances m_expns_health m_expns_medicines m_expns_all_emis [pweight=hh_weight_ms] , by (date_m)

cd "/storage/home/fxl146/work/Pyramids/Graphs"
set graph off
rename total_expenditure m_expns_total
foreach type in total food intoxicants clothfoot health{
twoway (line m_expns_`type' date_m, sort), xtitle(Month) xline(682 690) xlabel(#13, angle(vertical)) title(Total Monthly Expenditure on `type') saving(`type'_exp,replace)
graph export `type'_exp.pdf, replace
}

* Expenditure by category and region type (rural, urban)
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use temp_carlos_m_expense_1618,replace

collapse(mean) total_expenditure adj_total_expenditure m_expns_food m_adjexpns_food m_expns_intoxicants m_adjexpns_intoxican m_expns_cigtabacco m_adjexpns_cigtabacco m_expns_cig m_adjexpns_cig m_expns_bidis m_adjexpns_bidis m_expns_other_tobacco m_adjexpns_other_tob m_expns_liquor m_expns_clothfoot m_expns_clothing m_expns_alldeterg m_expns_appliances m_expns_health m_expns_medicines m_expns_all_emis [pweight=hh_weight_ms] , by (date_m region_type)

cd "/storage/home/fxl146/work/Pyramids/Graphs"
set graph off
rename total_expenditure m_expns_total

foreach type in total food intoxicants clothfoot health{
twoway (line m_expns_`type' date_m if region_type=="URBAN", sort) (line m_expns_`type' date_m if region_type=="RURAL", sort), xtitle(Month) xline(682 690) xlabel(#13, angle(vertical)) title(Total Monthly Expenditure of Urban and Rural HH) saving(`type'_exp_urban_rural,replace)
graph export `type'_exp_urban_rural.pdf, replace
}


* Graph by occupation group

cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use temp_carlos_m_expense_1618,replace
tab occupation_group 
collapse(mean) total_expenditure adj_total_expenditure m_expns_food m_adjexpns_food m_expns_intoxicants m_adjexpns_intoxican m_expns_cigtabacco m_adjexpns_cigtabacco m_expns_cig m_adjexpns_cig m_expns_bidis m_adjexpns_bidis m_expns_other_tobacco m_adjexpns_other_tob m_expns_liquor m_expns_clothfoot m_expns_clothing m_expns_alldeterg m_expns_appliances m_expns_health m_expns_medicines m_expns_all_emis [pweight=hh_weight_ms] , by (date_m occupation_group)

* instruction about the occupation group of a household
/*
https://consumerpyramidsdx.cmie.com/kommon/bin/sr.php?kall=wkbquest&id=1702
A rule-based classification that takes into account all members of a household is better than classifying a household only on the basis of the occupation of a single member - usually the head of the household.

Households are classified as belonging to one of the following 20 occupation groups.

Business & Salaried Employees
Entrepreneurs
Qualified Self-employed Professionals
Self-employed Professionals
Self-employed Entrepreneurs
Managers/Supervisors
White-collar Professional Employees
White-collar Clerical Employees
Non-industrial Technical Employees
Industrial Workers
Support Staff
Legislators/Social Workers/Activists
Organised Farmers
Small/Marginal Farmers
Home-based Workers
Small Traders/Hawkers
Agricultural Labourers
Wage Labourers
Retired/Aged
Miscellaneous
While there are 20 occupation groups, these can be clubbed into five broader groups for a better understanding. The first five listed above are essentially business persons, the next seven are salaried employees, the next two are farmers, next four are small traders and informal daily wage earners and the last two are miscellaneous. Such clubbing is important in classifying households.


*/

* CAVEAT: these are simple mean graph, we do not take into account carefully that households' change of status of occupation group

cd "/storage/home/fxl146/work/Pyramids/Graphs"
rename total_expenditure m_expns_total
set graph off
twoway (line total_expenditure date_m if occupation_group=="Agricultural Labourers", sort)  (line total_expenditure date_m if occupation_group=="Organised Farmers", sort)  (line total_expenditure date_m if occupation_group=="Home-based Workers", sort) (line total_expenditure date_m if occupation_group=="Industrial Workers", sort) (line total_expenditure date_m if occupation_group=="Small Traders/Hawkers", sort) (line total_expenditure date_m if occupation_group=="Wage Labourers", sort), xtitle(Month) xline(682 690) xlabel(#13, angle(vertical)) title(Total Monthly Expenditure by industry type) saving(total_exp_urban_rural,replace) legend(on order(1 "Agricultural Labourers" 2 "Organised Farmers" 3 "Home-based Workers" 4 "Industrial Workers" 5 "Small Traders/Hawkers" 6 "Wage Labourers"))
graph export total_exp_by_industry.pdf, replace




* add confidence interval later!!


* need to internalize the Feb 15 meeting content!


*******************************************************************************
*********************** Ploting trends of monthly expense ****************
*******************************************************************************



* By group plotting expenditure patterns overtime





* By group plotting food expenditure patterns overtime






* By group plotting intoxicant expenditure patterns overtime




* need to incorporate Feb 16 meeting's suggestions!






