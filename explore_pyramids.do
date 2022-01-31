clear all 
set more off
capture ssc install fs


cd "C:\Users\carlo\Dropbox\India_Dev"


***** employment and id variables
forvalues k=2016/2018 {
clear
fs RawData\Pyramids/People_of_India\*`k'*.dta
foreach ff in `r(files)' {
    append using RawData\Pyramids/People_of_India/`ff'
}
keep if response_status=="Accepted" 

keep if member_status=="Member of the household"
drop if age_yr<15
tempfile year`k'
save `year`k'' 
}
clear

forvalues k=2016/2018 {
append using `year`k''
}

/*
I'll trim the observations:
	- Non-response
	- Member no longer in the household (dead, emmigrated, etc.)
	- Children<15
	- Household members that throught the sample are unemployeed (they do not want to find work), students, home makers.
	
	
 NATURE_OF_OCCUPATION |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                  Agricultural Labourer |    179,104        2.64        2.64
                            Businessman |    239,761        3.53        6.17
                             Home Maker |  2,377,685       35.01       41.18
                      Home-based Worker |     33,094        0.49       41.67
                     Industrial Workers |    144,097        2.12       43.79
    Legislator/Social Worker/ Activists |      2,006        0.03       43.82
                                Manager |      9,631        0.14       43.96
      Non-Industrial Technical Employee |     83,456        1.23       45.19
                       Organised Farmer |    127,662        1.88       47.07
  Qualified Self Employed Professionals |     16,352        0.24       47.31
                           Retired/Aged |    433,853        6.39       53.70
             Self Employed Entrepreneur |    348,072        5.13       58.82
                           Small Farmer |    263,985        3.89       62.71
Small Trader/Hawker/ Businessman with.. |    106,440        1.57       64.28
                                Student |  1,157,504       17.04       81.32
                          Support Staff |    274,774        4.05       85.37
                             Unoccupied |     65,671        0.97       86.33
                          Wage Labourer |    617,258        9.09       95.42
        White Collar Clerical Employees |    155,348        2.29       97.71
White-Collar Professional Employees a.. |    155,616        2.29      100.00
----------------------------------------+-----------------------------------
                                  Total |  6,791,369      100.00

*/

gen aux=nature=="Home Maker"|nature=="Student"|nature=="Unoccupied"|nature=="Retired/Aged"

bys hh_id mem_id: egen drop=min(aux)

drop if drop==1

drop drop aux

gen date_m=monthly(month_slot, "MY")
format date_m %tm
egen id=group(hh_id mem_id)

xtset id date_m 

tsfill 

carryforward wave_no hh_id mem_id state hr district region_type stratum psu_id response_status reason_for_non_response mem_weight_w mem_weight_for_country_w mem_weight_for_state_w ge15_mem_weight_w ge15_mem_weight_for_country_w ge15_mem_weight_for_state_w mem_non_response_w mem_non_response_for_country_w mem_non_response_for_state_w ge15_mem_non_response_w ge15_mem_non_response_for_countr ge15_mem_non_response_for_state_ member_status gender age_yrs age_mths relation_with_hoh state_of_origin religion caste caste_category literacy education discipline nature_of_occupation industry_of_occupation employment_status is_healthy is_on_regular_medication is_hospitalised has_bank_ac has_creditcard has_kisan_creditcard has_demat_ac has_pf_ac has_lic has_health_insurance has_mobile family_shifted employment_status_since_yrs employment_status_since_mths employment_status_since_days type_of_employment employment_arrangement place_of_work time_to_start_working occupation reason_for_emigration_immigratio, replace

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

gen month=month_slot

tempfile employment
save  `employment'

keep hh_id 

duplicates drop 

tempfile id
save `id'

******* income and expenditure variables

forvalues k=2016/2018 {
clear
fs RawData\Pyramids/Member_income\*`k'*.dta
foreach ff in `r(files)' {
    append using RawData\Pyramids/Member_income/`ff'
}
keep if response_status=="Accepted" 
keep if member_status=="Member of the household"
drop if age_yr<15
merge m:1 hh_id using `id'

keep if _merge==3
drop _merge

tempfile year`k'
save `year`k'' 
}
clear

forvalues k=2016/2018 {
append using `year`k''
}


merge 1:m month hh_id mem_id using `employment'
keep if _merge==3
drop _merge


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

*** do a survival analysis of employment arrangement (do self-employed switch out of self-employment more?)

gen post=date_m>tm(2017m6)
gen aux=dofm(date_m)
gen year=year(aux)
drop aux
ta nature, gen(nature_)

rename nature_2 nature_business
rename nature_5 nature_industrialw
rename nature_10 nature_qualified
rename nature_12 nature_self
rename nature_14 nature_small
rename nature_17 nature_unoccupied
rename nature_18 nature_wage

gen nature_all=nature_business==1|nature_industrialw==1|nature_qualified==1|nature_self==1|nature_small==1

foreach xx in business industrialw qualified self small all wage{
xtset id date_m

gen L`xx'xpost=L.nature_`xx'*post
bys hh_id mem_id (date_m): gen past_`xx'=sum(nature_`xx')
replace past_`xx'=past_`xx'>0
gen past_`xx'xpost=past_`xx'*post

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