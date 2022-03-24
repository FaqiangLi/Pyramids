**** Explore income and expenditure

*** this is the immediate product of the March 5 meeting

clear
set more off
set seed 123456

* start from member income and employment status, and produce instead the household variables, and merge with household expense to check patterns. 


* To get a household level income&employment variables, check explore_expense_merge_Carlos_hhmerge.
/* what ``carlos sample'' has?

- consistently engaged in homemaker and the like nature from 2016~2018
- nonresponse, membership status weird, age<15 

*/

capture cd "/Users/faqiangmacpro/Downloads/local_pyramids_tempfile"

capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles"

use temp_expenditure_GST, replace

************************************************************************
**** Set up proper tags
************************************************************************

*** Summary statistics to determine proper group of variables relevant for the future tags
// some can be defined directly



* household income cutoffs (for better engle curve graphing)
qui sum total_incHH_gross, detail
local tempmax=`r(max)'+1
return list
egen total_incHH_cat = cut(total_incHH_gross), at(0,3000,6000,9000,12000,15000,20000,25000,30000,35000,40000,50000,60000,75000,`tempmax')


* Tags of household composition in terms of earners
gen tag_hhinccomp = .
replace tag_hhinccomp = 0 if hhinc_all_source==0
replace tag_hhinccomp = 1 if hhinc_all_source~=0 & n_mem==1
replace tag_hhinccomp = 1 if hhinc_all_source~=0 & n_mem>1 & highest_inc_share==1
replace tag_hhinccomp = 2 if hhinc_all_source~=0 & n_mem==2 & highest_inc_share<1
replace tag_hhinccomp = 3 if hhinc_all_source~=0 & n_mem>2 & highest_inc_share<1
codebook tag_hhinccomp
tab tag_hhinccomp

* Tag zero income, hhhighest income share cutoff-type
gen tag_highest_inc_share =. 
replace tag_highest_inc_share = 0 if tag_hhinccomp == 0 // no income
replace tag_highest_inc_share = 3 if tag_hhinccomp == 1 // all income on one
replace tag_highest_inc_share = 1 if highest_inc_share>0 & highest_inc_share<=0.5
replace tag_highest_inc_share = 2 if highest_inc_share>0.5 & highest_inc_share<1

* inc change, expenditure change, and inc change tag and elasticity tag
// caveat: note that this is the income shock to all members of the households
gen tag_hh_inc_change = .
rename hhinc_loss hhinc_change
replace tag_hh_inc_change = 0 if hhinc_change==19930412
replace tag_hh_inc_change = -1 if hhinc_change<0 & hhinc_change>-0.1
replace tag_hh_inc_change = -2 if hhinc_change<=-0.1
replace tag_hh_inc_change = 1 if hhinc_change>=0 & hhinc_change<0.1
replace tag_hh_inc_change = 2 if hhinc_change>=0.1 & hhinc_change~=19930412
gen tag_hh_exp_change = .
rename hhexp_loss hhexp_change
replace tag_hh_exp_change = 0 if hhexp_change==19930412
replace tag_hh_exp_change = -1 if hhexp_change<0 & hhexp_change>-0.25
replace tag_hh_exp_change = -2 if hhexp_change<=-0.25
replace tag_hh_exp_change = 1 if hhexp_change>=0 & hhexp_change<0.25
replace tag_hh_exp_change = 2 if hhexp_change>=0.25 & hhexp_change~=19930412

****** CAVEAT: LABEL THESE VALUES. SO THAT THEY LOOK NICE IN SUMMARY STATS

****** Winsorized whenver possible !!! many outliers ***** 


* saving rate and expeindture rate cutoff-type
gen tag_hhsaver = .
replace tag_hhsaver = 0 if hhsaver==19930412
replace tag_hhsaver = 1 if hhsaver<0
replace tag_hhsaver = 2 if hhsaver>=0 & hhsaver<0.25
replace tag_hhsaver = 3 if hhsaver>=0.25 & hhsaver<0.5
replace tag_hhsaver = 4 if hhsaver>=0.5 & hhsaver~=19930412


* new saving rate 
gen tag_hhsaver_totalhh_gross = .
replace tag_hhsaver_totalhh_gross = 0 if hhsaver_totalhh_gross==19930412
replace tag_hhsaver_totalhh_gross = 1 if hhsaver_totalhh_gross<0
replace tag_hhsaver_totalhh_gross = 2 if hhsaver_totalhh_gross>=0 & hhsaver_totalhh_gross<0.25
replace tag_hhsaver_totalhh_gross = 3 if hhsaver_totalhh_gross>=0.25 & hhsaver_totalhh_gross<0.5
replace tag_hhsaver_totalhh_gross = 4 if hhsaver_totalhh_gross>=0.5 & hhsaver_totalhh_gross~=19930412



* CAVEAT: need to consider elasticity in the future --- these are too big.
save temp_graph_hh_inc_exp,replace


*****************************************************************************
**** Graph 1: Household composition graph 
*****************************************************************************

/*
use temp_graph_hh_inc_exp,replace
sample 10
save temp_graph_hh_inc_exp_10p,replace
sample 10
save temp_graph_hh_inc_exp_1p,replace
*/


use temp_graph_hh_inc_exp,replace
gen sdate_m = string(date_m,"%tm")

capture cd "/storage/home/fxl146/work/Pyramids/Graphs/hhcomposition"

/*
preserve
tab tag_hhinccomp, gen(tag_hhinccomp_)
ds tag_hhinccomp_*
collapse(sum)`r(varlist)', by(region_type date_m sdate_m)
graph bar (asis) tag_hhinccomp_1 tag_hhinccomp_2  tag_hhinccomp_3 tag_hhinccomp_4 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: #Earner", span ) subtitle(" ") legend(label(1 "No Earner") label(2 "1 Earner") label(3 "2 Earner") label(4 ">2 Earner")) ytitle(Household Composition Percentage) saving(hhinccomp,replace)
graph export hhinccomp.pdf, replace
restore


preserve
tab tag_highest_inc_share, gen(tag_highest_inc_share_)
ds tag_highest_inc_share_*
collapse(sum)`r(varlist)', by(region_type date_m sdate_m)
graph bar (asis) tag_highest_inc_share_1 tag_highest_inc_share_2 tag_highest_inc_share_3 tag_highest_inc_share_4 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncShare of Highest Earner", span ) subtitle(" ") legend(label(1 "No Income") label(2 "s<0.5") label(3 "0.5<s<1") label(4 "s=1") ) ytitle(Household Composition Percentage) saving(highest_inc_share,replace)
graph export highest_inc_share.pdf, replace
restore


preserve
tab tag_hh_inc_change, gen(tag_hh_inc_change_)
ds tag_hh_inc_change_*
collapse(sum)`r(varlist)', by(region_type date_m sdate_m)
graph bar (asis) tag_hh_inc_change_3 tag_hh_inc_change_1 tag_hh_inc_change_2 tag_hh_inc_change_4 tag_hh_inc_change_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "Earn less by >10%") label(3 "Earn less by <10%") label(4 "Earn more by <10%") label(5 "Earn more by >10%")) ytitle(Household Composition Percentage) saving(hh_inc_change,replace)
graph export hh_inc_change.pdf, replace
restore


preserve
tab tag_hh_exp_change, gen(tag_hh_exp_change_)
ds tag_hh_exp_change_*
collapse(sum)`r(varlist)', by(region_type date_m sdate_m)
graph bar (asis) tag_hh_exp_change_3 tag_hh_exp_change_1 tag_hh_exp_change_2 tag_hh_exp_change_4 tag_hh_exp_change_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: ExpChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Expenditure Last Period") label(2 "Spend less by >25%") label(3 "Spend less by <25%") label(4 "Spend more by <25%") label(5 "Spend more by >25%")) ytitle(Household Composition Percentage) saving(hh_exp_change,replace)
graph export hh_exp_change.pdf, replace
restore


preserve
tab tag_hhsaver, gen(tag_hhsaver_)
ds tag_hhsaver_*
collapse(sum)`r(varlist)', by(region_type date_m sdate_m)
graph bar (asis) tag_hhsaver_1  tag_hhsaver_2 tag_hhsaver_3 tag_hhsaver_4 tag_hhsaver_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type) stack percent title( "HH Comp: Monthly Saving Rate:(inc-exp)/inc", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "<0 (exp>inc)") label(3 "Save <25%") label(4 "Save >25% & <50%") label(5 "Save >50%")) ytitle(Household Composition Percentage) saving(hh_saver_change,replace)
graph export hhsaver.pdf, replace
restore
*/


/*
preserve
tab tag_hhinccomp, gen(tag_hhinccomp_)
ds tag_hhinccomp_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_hhinccomp_1 tag_hhinccomp_2  tag_hhinccomp_3 tag_hhinccomp_4 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: #Earner", span ) subtitle(" ") legend(label(1 "No Earner") label(2 "1 Earner") label(3 "2 Earner") label(4 ">2 Earner")) ytitle(Household Composition Percentage) saving(hhinccomp_weighted,replace)
graph export hhinccomp_weighted.pdf, replace
restore


preserve
tab tag_highest_inc_share, gen(tag_highest_inc_share_)
ds tag_highest_inc_share_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_highest_inc_share_1 tag_highest_inc_share_2 tag_highest_inc_share_3 tag_highest_inc_share_4 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncShare of Highest Earner", span ) subtitle(" ") legend(label(1 "No Income") label(2 "s<0.5") label(3 "0.5<s<1") label(4 "s=1") ) ytitle(Household Composition Percentage) saving(highest_inc_share_weighted,replace)
graph export highest_inc_share_weighted.pdf, replace
restore


preserve
tab tag_hh_inc_change, gen(tag_hh_inc_change_)
ds tag_hh_inc_change_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_hh_inc_change_3 tag_hh_inc_change_1 tag_hh_inc_change_2 tag_hh_inc_change_4 tag_hh_inc_change_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "Earn less by >10%") label(3 "Earn less by <10%") label(4 "Earn more by <10%") label(5 "Earn more by >10%")) ytitle(Household Composition Percentage) saving(hh_inc_change_weighted,replace)
graph export hh_inc_change_weighted.pdf, replace
restore


preserve
tab tag_hh_exp_change, gen(tag_hh_exp_change_)
ds tag_hh_exp_change_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_hh_exp_change_3 tag_hh_exp_change_1 tag_hh_exp_change_2 tag_hh_exp_change_4 tag_hh_exp_change_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: ExpChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Expenditure Last Period") label(2 "Spend less by >25%") label(3 "Spend less by <25%") label(4 "Spend more by <25%") label(5 "Spend more by >25%")) ytitle(Household Composition Percentage) saving(hh_exp_change_weighted,replace)
graph export hh_exp_change_weighted.pdf, replace
restore


preserve
tab tag_hhsaver, gen(tag_hhsaver_)
ds tag_hhsaver_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_hhsaver_1  tag_hhsaver_2 tag_hhsaver_3 tag_hhsaver_4 tag_hhsaver_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type) stack percent title( "HH Comp: Monthly Saving Rate:(inc-exp)/inc", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "<0 (exp>inc)") label(3 "Save <25%") label(4 "Save >25% & <50%") label(5 "Save >50%")) ytitle(Household Composition Percentage) saving(hh_saver_change_weighted,replace)
graph export hhsaver_weighted.pdf, replace
restore

*/


* new saving rate
preserve
tab tag_hhsaver_totalhh_gross, gen(tag_hhsaver_totalhh_gross_)
ds tag_hhsaver_totalhh_gross_*
collapse(sum)`r(varlist)' [pweight=hh_weight_ms], by(region_type date_m sdate_m)
graph bar (asis) tag_hhsaver_totalhh_gross_1  tag_hhsaver_totalhh_gross_2 tag_hhsaver_totalhh_gross_3 tag_hhsaver_totalhh_gross_4 tag_hhsaver_totalhh_gross_5 , over(sdate_m, sort(date_m) label(angle(270) labsize(vsmall)) ) over(region_type) stack percent title( "HH Comp: Monthly Saving Rate:(inc-exp)/inc. Inc=HHtotal", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "<0 (exp>inc)") label(3 "Save <25%") label(4 "Save >25% & <50%") label(5 "Save >50%")) ytitle(Household Composition Percentage) saving(newhh_saver_change_weighted,replace)
graph export newhhsaver_weighted.pdf, replace
restore



* consumption engle curve by rural/urban, consumption category, before and after
// compare 2016, 2017 of these months: August, November
preserve
collapse(mean) m_expns_food m_expns_intoxicants m_expns_clothfoot m_expns_health [pweight=hh_weight_ms], by(region_type date_m sdate_m total_incHH_cat)
 
 twoway (connected m_expns_food total_incHH_cat if date_m==tm(2016m8) & region_type=="RURAL" ) ||  (connected m_expns_food total_incHH_cat if date_m==tm(2016m8) & region_type=="URBAN"), legend(label(1 "RURAL") label(2 "URBAN")) title( "Engle Curve: Food, 2016m8", span ) 
graph export engle_food_2016m8.pdf, replace

  twoway (connected m_expns_food total_incHH_cat if date_m==tm(2016m11) & region_type=="RURAL" ) ||  (connected m_expns_food total_incHH_cat if date_m==tm(2016m11) & region_type=="URBAN"), legend(label(1 "RURAL") label(2 "URBAN")) title( "Engle Curve: Food, 2016m11", span ) 
graph export engle_food_2016m11.pdf, replace

   twoway (connected m_expns_food total_incHH_cat if date_m==tm(2017m8) & region_type=="RURAL" ) ||  (connected m_expns_food total_incHH_cat if date_m==tm(2017m8) & region_type=="URBAN"), legend(label(1 "RURAL") label(2 "URBAN")) title( "Engle Curve: Food, 2017m8", span ) 
graph export engle_food_2017m8.pdf, replace

     twoway (connected m_expns_food total_incHH_cat if date_m==tm(2017m11) & region_type=="RURAL" ) ||  (connected m_expns_food total_incHH_cat if date_m==tm(2017m11) & region_type=="URBAN"), legend(label(1 "RURAL") label(2 "URBAN")) title( "Engle Curve: Food, 2017m11", span ) 
graph export engle_food_2017m11.pdf, replace

 restore
 
 
 * income shock by industry type of the households?
 
 
 
 列出来之后run。然后做correlation。来得及。
 
 * For transition matrix, note that, we just need the following
 use temp_graph_hh_inc_exp,replace

 *CAVEAT: I might need to fill in the blanks because not all households have a consistent panels. They might have hole in the history of their status.
 bysort hh_id (date_m): gen ltag_hhinccomp = tag_hhinccomp[_n-1]
 tab tag_hhinccomp

*****************************************************************************
**** Graph 0: Trend graph
*****************************************************************************



*** do a description of income by nature of occupation (do self-employed loose income?)

* Do the same for expenditure on food and everything

use temp_graph_hh_inc_exp,replace


collapse (mean) hhinc_type hhexp_type (median) hhinc_type hhexp_type [pweight=hh], by(date_m nature region_type)
egen id=group(nature)
xtset id date_m

* set baseline number for each occupation at the begining period
foreach nature in 
	gen baseline_`nature'= if tm(date_m)==2016m1
	bysort date_m : 
	

* Tune income at the level of window start, by each different type of income (all sources and wage)
twoway tsline mean_income if nature=="Self Employed Entrepreneur" || tsline mean_income if nature=="`group'", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "`group'") rows(`rows')) 



* 

restore
preserve
collapse (mean) hhexp_type (median) hhexp_type , by(date_m nature)
egen id=group(nature)
xtset id date_m





*****************************************************************************
**** Graph 1: Household composition graph 
*****************************************************************************

use temp_graph_hh_inc_exp,replace

preserve
tab tag_hhinccomp, gen(tag_hhinccomp_)
ds tag_hhinccomp_*
collapse(sum)`r(varlist)', by(region_type date_m)
graph bar (asis) tag_hhinccomp_1 tag_hhinccomp_2  tag_hhinccomp_3 tag_hhinccomp_4 , over(date_m, sort(date_m) label(angle(90) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: #Earner", span ) subtitle(" ") legend(label(1 "No Earner") label(2 "1 Earner") label(3 "2 Earner") label(4 ">2 Earner")) ytitle(Household Composition Percentage) saving(hhinccomp,replace)
restore

preserve
tab tag_highest_inc_share, gen(tag_highest_inc_share_)
ds tag_highest_inc_share_*
collapse(sum)`r(varlist)', by(region_type date_m)
graph bar (asis) tag_highest_inc_share_1 tag_highest_inc_share_2 tag_highest_inc_share_3 tag_highest_inc_share_4 , over(date_m, sort(date_m) label(angle(90) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncShare of Highest Earner", span ) subtitle(" ") legend(label(1 "No Income") label(2 "s<0.5") label(3 "0.5<s<1") label(4 "s=1") ) ytitle(Household Composition Percentage) saving(highest_inc_share,replace)
restore


preserve
tab tag_hh_inc_change, gen(tag_hh_inc_change_)
ds tag_hh_inc_change_*
collapse(sum)`r(varlist)', by(region_type date_m)
graph bar (asis) tag_hh_inc_change_3 tag_hh_inc_change_1 tag_hh_inc_change_2 tag_hh_inc_change_4 tag_hh_inc_change_5 , over(date_m, sort(date_m) label(angle(90) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: IncChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "Earn less by >10%") label(3 "Earn less by <10%") label(4 "Earn more by <10%") label(5 "Earn more by >10%")) ytitle(Household Composition Percentage) saving(hh_inc_change,replace)
restore


preserve
tab tag_hh_exp_change, gen(tag_hh_exp_change_)
ds tag_hh_exp_change_*
collapse(sum)`r(varlist)', by(region_type date_m)
graph bar (asis) tag_hh_exp_change_3 tag_hh_exp_change_1 tag_hh_exp_change_2 tag_hh_exp_change_4 tag_hh_exp_change_5 , over(date_m, sort(date_m) label(angle(90) labsize(vsmall)) ) over(region_type)  stack percent title( "HH Comp: ExpChange of Various Degree", span ) subtitle(" ") legend(label(1 "Zero Expenditure Last Period") label(2 "Spend less by >25%") label(3 "Spend less by <25%") label(4 "Spend more by <25%") label(5 "Spend more by >25%")) ytitle(Household Composition Percentage) saving(hh_exp_change,replace)
restore


preserve
tab tag_hhsaver, gen(tag_hhsaver_)
ds tag_hhsaver_*
collapse(sum)`r(varlist)', by(region_type date_m)
graph bar (asis) tag_hhsaver_1  tag_hhsaver_2 tag_hhsaver_3 tag_hhsaver_4 tag_hhsaver_5 , over(date_m, sort(date_m) label(angle(90) labsize(vsmall)) ) over(region_type) stack percent title( "HH Comp: Monthly Saving Rate:(inc-exp)/inc", span ) subtitle(" ") legend(label(1 "Zero Income Last Period") label(2 "<0 (exp>inc)") label(3 "Save <25%") label(4 "Save >25% & <50%") label(5 "Save >50%")) ytitle(Household Composition Percentage) saving(hh_saver_change,replace)
restore





*****************************************************************************
**** Graph 2: Household composition graph 
*****************************************************************************



