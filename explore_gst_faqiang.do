
cd "/storage/home/fxl146/scratch/Pyramids_statafiles"
use carlos_employment_income_1618,replace


/* I don't see a lot of evidence with just this grahs to say that there is a reduction on income of self-employees in general or compared to most groups
 we should probably look inside the industry of occupation, also porbably we can do a regression of income on education, gender, age, health, controlls,and industry-year fixed effects and then do these graphs on the residuals*/

*** do a survival analysis of employment arrangement (do self-employed switch out of self-employment more?)

gen post=date_m>tm(2017m6)
gen aux=dofm(date_m)
gen year=year(aux)
drop aux
ta nature, gen(nature_)

* https://consumerpyramidsdx.cmie.com/kommon/bin/sr.php?kall=wkbquest&id=1697

* why these variables?

rename nature_2 nature_business  // businessman
rename nature_5 nature_industrialw  // industrial worker
rename nature_10 nature_qualified   // qualified self employed professionals
rename nature_12 nature_self      // self employed entrepreneur
rename nature_14 nature_small     // small farmer 
rename nature_17 nature_unoccupied  // un occupied
rename nature_18 nature_wage   // wage labourer

gen nature_all=nature_business==1|nature_industrialw==1|nature_qualified==1|nature_self==1|nature_small==1


// do a transition matrix at the short window around the cutoff --- the current evidence is a bit constrained set of direction


foreach xx in business industrialw qualified self small all wage{
xtset id date_m

* generate the lag occupation indicator
gen L`xx'xpost=L.nature_`xx'*post

* generate the ``ever-become'' occupation indicator, time invariant
bys hh_id mem_id (date_m): gen past_`xx'=sum(nature_`xx')
replace past_`xx'=past_`xx'>0
gen past_`xx'xpost=past_`xx'*post


// L.nature change how frequent? do they change back and forth? if yes, what the below regression tells me? If they don't change frequently, then if we do see a within-change of occupation 

// If I remember this correctly, nature is coming from people of india --- that implies the time disaggregation level is 4 months --- but by Lag1, what we get is last month --- right? If this is the case the, possibly the following should be the regression to run.   --- easiest way is to run it with only people of india data

// can we just do date_m nature_unoccupied by occupation? -- an aggregate way of seeing the things below. 
}




a

* So now the individual fixed effect is trying to control for the time-invariant feature of an individual, and these regressions expect to show , whether being at a specific nature of work, before and after the gst, whether the outcome is changing. The window here, is two months (because LHS is current variable and RHS is last month variable). Main deviation from did: individual L.nature could also be changing overtime, i.e. it is not that a person will be constantly in a controlled occupation (similarly for the treatment occupation). The past xx is a ever-became something measure. 

foreach xx in business industrialw qualified self small all wage {
xtset id date_m

reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(hh_id date_m) vce(cl id)

reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(id date_m) vce(cl id)

reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(hh_id date_m) vce(cl id)

reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(id date_m) vce(cl id)

}



foreach xx in business industrialw qualified self small all wage {
xtset id date_m

reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(hh_id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, replace excel dec(5) nocons addtext(FE: hh date)
reghdfe nature_unoccupied L.nature_`xx' L`xx'xpost, a(id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)
reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(hh_id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hh date)
reghdfe nature_unoccupied past_`xx' past_`xx'xpost, a(id date_m) vce(cl id)
outreg2 using Tables/`xx'_employed_to_unoccupied, append excel dec(5) nocons addtext(FE: hhxmem date)

}





********** below is earlier exploration on income difference ***********


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
