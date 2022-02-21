**** Expense merged with Carlos' datasets
clear
set more off
set seed 123456

cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use carlos_employment_income_1618,replace

* This script bases on Carlos Feb 15 latest script on event study. I didn't change anything but just merge in household variables for analysis 

/*
*** do a description of income by nature of occupation (do self-employed loose income?)
preserve
collapse (mean) mean_income=income_of_member_from_all_source mean_wage=income_of_member_from_wages mean_pension=income_of_member_from_pension mean_dividend=income_of_member_from_dividend mean_interest=income_of_member_from_interest mean_fd_pf_insurance=income_of_member_from_fd_pf_insu (median) median_income=income_of_member_from_all_source median_wage=income_of_member_from_wages median_pension=income_of_member_from_pension median_dividend=income_of_member_from_dividend median_interest=income_of_member_from_interest median_fd_pf_insurance=income_of_member_from_fd_pf_insu, by(date_m nature)
egen id=group(nature)
xtset id date_m
*** graphs with pairwise comparison of both mean and median income across self-employed people and other groups
* july first implementation of gst

*mean pair-wise comparison
levelsof nature, local(class)
foreach group of local class {
if "`group'"~="Self Employed Entrepreneur" {
if length("`group'")>36 {
	local rows 2	
}
if length("`group'")<37 {
	local rows 1
}
local name "`=subinstr("`=subinstr("`=subinstr("`group'","-","",.)'","/","",.)'"," ","",.)'"	
twoway tsline mean_income if nature=="Self Employed Entrepreneur" || tsline mean_income if nature=="`group'", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "`group'") rows(`rows')) 

graph export Graphs\Pyramids_Comparison_Self_Employed_Others\mean_pair_wise_`name'.pdf, replace
}	
}

*median pair-wise comparison
levelsof nature, local(class)
foreach group of local class {
if "`group'"~="Self Employed Entrepreneur" {
if length("`group'")>36 {
	local rows 2	
}
if length("`group'")<37 {
	local rows 1
}
local name "`=subinstr("`=subinstr("`=subinstr("`group'","-","",.)'","/","",.)'"," ","",.)'"	
twoway tsline median_income if nature=="Self Employed Entrepreneur" || tsline median_income if nature=="`group'", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Median Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "`group'") rows(`rows')) 
graph export Graphs\Pyramids_Comparison_Self_Employed_Others\median_pair_wise_`name'.pdf, replace
}	
}
restore 

preserve
gen self_employed=nature=="Self Employed Entrepreneur"
collapse (mean) mean_income=income_of_member_from_all_source mean_wage=income_of_member_from_wages mean_pension=income_of_member_from_pension mean_dividend=income_of_member_from_dividend mean_interest=income_of_member_from_interest mean_fd_pf_insurance=income_of_member_from_fd_pf_insu (median) median_income=income_of_member_from_all_source median_wage=income_of_member_from_wages median_pension=income_of_member_from_pension median_dividend=income_of_member_from_dividend median_interest=income_of_member_from_interest median_fd_pf_insurance=income_of_member_from_fd_pf_insu, by(date_m self_employed)

xtset self_employed date_m

*** graphs with comparison of both mean and median income across self-employed people and other groups

*mean self employed vs the rest comparison
	
twoway tsline mean_income if self_employed==1 || tsline mean_income if self_employed==0, tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "Others") rows(`rows')) 
graph export Graphs\Pyramids_Comparison_Self_Employed_Others\mean_vstherest.pdf, replace


*median self employed vs the rest comparison 

twoway tsline median_income if self_employed==1 || tsline median_income if self_employed==0, tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Median Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "Others") rows(`rows')) 
graph export Graphs\Pyramids_Comparison_Self_Employed_Others\median_vstherest.pdf, replace

restore 

**** by industry

preserve
gen self_employed=nature_o=="Self Employed Entrepreneur"
bys hh_id mem_id: egen aux=max(self_employed)
keep if aux
collapse (mean) mean_income=income_of_member_from_all_source mean_wage=income_of_member_from_wages mean_pension=income_of_member_from_pension mean_dividend=income_of_member_from_dividend mean_interest=income_of_member_from_interest mean_fd_pf_insurance=income_of_member_from_fd_pf_insu (median) median_income=income_of_member_from_all_source median_wage=income_of_member_from_wages median_pension=income_of_member_from_pension median_dividend=income_of_member_from_dividend median_interest=income_of_member_from_interest median_fd_pf_insurance=income_of_member_from_fd_pf_insu, by(date_m industry self_employed)

encode industry, generate(industry)

egen id=group(industry self_employed)
xtset id date_m

*** graphs with comparison of both mean and median income across self-employed people and other groups

*mean self employed vs the rest comparison

twoway tsline mean_income if self_employed==1& industry_=="Machinery Manufacturers" || tsline mean_income if self_employed==0& industry_=="Machinery Manufacturers", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "Others") rows(`rows')) 
graph export Graphs\Pyramids_Comparison_Self_Employed_Others\mean_machinery_manufacturers_vstherest.pdf, replace

*median self employed vs the rest comparison 

twoway tsline median_income if self_employed==1& industry_=="Machinery Manufacturers" || tsline median_income if self_employed==0& industry_=="Machinery Manufacturers", tline(2017m7, lc(red) lp(dash)) yscale(titlegap(*5)) ytitle("Average Income from any Source",) xtitle(Date) xla(#20, labsize(medsmall) format(%tmMon)) xmla(#5, format(%tmCY) labsize(medsmall) tlength(*7) tlcolor(none)) legend(label(1 "Self Employed") label(2 "Others") rows(`rows')) 
graph export Graphs\Pyramids_Comparison_Self_Employed_Others\median_machinery_manufacturers_vstherest.pdf, replace
restore 

/* I don't see a lot of evidence with just this grahs to say that there is a reduction on income of self-employees in general or compared to most groups
 we should probably look inside the industry of occupation, also porbably we can do a regression of income on education, gender, age, health, controlls,and industry-year fixed effects and then do these graphs on the residuals*/
*/
*** do a survival analysis of employment arrangement (do self-employed switch out of self-employment more?)



* merge back the weight!!!!

* I add more var to help the merge
keep date_m nature month id hh_id mem_id industry state hr district region_type mem_weight_ms relation_with_hoh income_of_member_from_all_source income_of_member_from_wages

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











