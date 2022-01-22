clear all 
set more off
capture ssc install fs


cd "C:\Users\carlo\Dropbox\India_Dev"

**** codes to names for the census data

import excel using RawData/EconomicCensus/District_Code_List.xls, first clear

rename (StateName DistrictName State_DistrictUniqueCode) (STATE_UT NAME District)
drop if StateCode=="State  Code"|StateCode==""

keep  STATE_UT District NAME

replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)

duplicates drop

tempfile name

save `name'
**** shp identifiers 
use RawData\GiS\District_11, clear 

replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)
tempfile ID
save `ID'

clear 

fs RawData\EconomicCensus\EC6thwave\*.dta

foreach ff in `r(files)' {
	append using RawData\EconomicCensus\EC6thwave/`ff'
}

replace TOTAL_WORKER=Total_worker if Total_worker!=.
replace TOTAL_WORKER=total_worker if total_worker!=.

drop total_worker Total_worker

merge m:1 District using `name', nogen
replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)
replace STATE_UT="DELHI" if STATE_UT=="NCT OF DELHI"
replace STATE_UT="ANDHRA PRADESH" if STATE_UT=="TELANGANA"
replace STATE_UT="ODISHA" if STATE_UT=="ORISSA"
replace STATE_UT="DAMAN & DIU" if STATE_UT=="DAMAN AND DIU"

	
	replace NAME="HYDERABAD" if STATE=="ANDHRA PRADESH" & NAME=="HYDERABAD DISTRICT"
	replace NAME="ANANTAPUR" if STATE=="ANDHRA PRADESH" & NAME=="ANANTHAPUR"
	replace NAME="Y.S.R" if STATE=="ANDHRA PRADESH" & NAME=="KADAPA"
	replace NAME="MAHBUBNAGAR" if STATE=="ANDHRA PRADESH" & NAME=="MAHABUBNAGAR"
	replace NAME="SRI POTTI SRIRAMULU NELLORE" if STATE=="ANDHRA PRADESH" & NAME=="NELLORE"
	
	replace NAME="KOCH BIHAR" if STATE=="WEST BENGAL" & NAME=="KOCHBIHAR"
	replace NAME="NORTH TWENTY FOUR PARGANAS" if STATE=="WEST BENGAL" & NAME=="NORTHTWENTYFOURPARGANAS"
	replace NAME="PURBA MEDINIPUR" if STATE=="WEST BENGAL" & NAME=="PURBAMEDINIPUR"
	replace NAME="UTTAR DINAJPUR" if STATE=="WEST BENGAL" & NAME=="UTTARDINAJPUR"

	replace NAME="BARABANKI" if STATE=="UTTAR PRADESH" & NAME=="BARA BANKI"

	replace NAME="CHANDIGARH" if STATE=="CHANDIGARH" & NAME=="CHANDIGARH DISTRICT"

	replace NAME="BALEMU EAST KAMENG" if STATE=="ARUNACHAL PRADESH" & NAME=="EAST KAMENG"	

	replace NAME="LEH (LADAKH)" if STATE=="JAMMU & KASHMIR" & NAME=="LEH(LADAKH)"	

	replace NAME="MARIGAON" if STATE=="ASSAM" & NAME=="MORIGAON"
	
	replace NAME="NORTH & MIDDLE ANDAMAN" if STATE=="ANDAMAN & NICOBAR ISLANDS" & NAME=="NORTH  & MIDDLE ANDAMAN"

	replace NAME="NORTH DISTRICT" if STATE=="SIKKIM" & NAME=="NORTH  DISTRICT"

	replace NAME="PAKAUR" if STATE=="JHARKHAND" & NAME=="PAKUR"

	replace NAME="RI BHOI" if STATE=="MEGHALAYA" & NAME=="RIBHOI"

	replace NAME="SIBSAGAR" if STATE=="ASSAM" & NAME=="SIVASAGAR"
	
*** in 2012 2 new districts were carved out of Delhi; SHAHNDARA (from north east) and south east (from south) check folder for maps from pre and psot change. I don't have GIS data to make it into the map so I'll join them to the original districts 

	replace NAME="NORTH EAST" if STATE=="DELHI" & NAME=="SHAHDRA"

	replace NAME="SOUTH" if STATE=="DELHI" & NAME=="SOUTH EAST"
	
merge m:1 NAME STATE_UT using `ID', nogen

gen TOTAL_NH=M_NH+F_NH


forvalues x=1/3 {
	preserve 
	if `x'==1 {
		local sample "all" // all 
	}
	if `x'==2 {
		keep if OWN_SHIP_C~="1"&OWN_SHIP_C~="7" // droping goverment owned and non-for-profit enterprises
		local sample "priv4prof"
	}
	if `x'==3 {
		keep if real(substr(NIC3,1,3))>15 // droping agicultural firms
		local sample "noagri"
	}

foreach v in 1 2 4 5 7 15 50 100 200 500 1000 {
gen lessoeq`v'=TOTAL_WORKER<=`v'
gen larger`v'=TOTAL_WORKER>`v'
}
gen prop_NH=TOTAL_NH/TOTAL_WORKER

collapse (mean) M_H F_H M_NH F_NH TOTAL_WORKER TOTAL_NH prop_NH (count) nestablishments=TOTAL_WORKER (sum) lessoeq1 lessoeq2 lessoeq4 lessoeq5 lessoeq7 lessoeq15 lessoeq50 lessoeq100 lessoeq200 ///
lessoeq500 lessoeq1000 larger1 larger2 larger4 larger5 larger7 larger15 larger50 larger100 larger200 ///
larger500 larger1000 tot_TOTAL_WORKER=TOTAL_WORKER tot_TOTAL_NH=TOTAL_NH,by(STATE_UT NAME _ID _CX _CY DIS_ID C_CODE11)

foreach v in 1 2 4 5 7 15 50 100 200 500 1000 {

gen prop_lessoeq`v'=lessoeq`v'/nestablishments
gen prop_larger`v'=larger`v'/nestablishments

}

foreach var in M_H F_H M_NH F_NH TOTAL_WORKER TOTAL_NH nestablishments lessoeq1 larger1 ///
lessoeq2 larger2 lessoeq4 larger4 lessoeq5 larger5 lessoeq7 larger7 lessoeq15 larger15 ///
lessoeq50 larger50 lessoeq100 larger100 lessoeq200 larger200 lessoeq500 larger500 ///
lessoeq1000 larger1000 tot_TOTAL_WORKER tot_TOTAL_NH prop_NH  prop_lessoeq1 prop_larger1 ///
prop_lessoeq2 prop_larger2  prop_lessoeq4 prop_larger4 prop_lessoeq5 prop_larger5 ///
prop_lessoeq7 prop_larger7 prop_lessoeq15 prop_larger15 prop_lessoeq50 prop_larger50 ///
prop_lessoeq100 prop_larger100 prop_lessoeq200 prop_larger200 prop_lessoeq500 prop_larger500 ///
prop_lessoeq1000 prop_larger1000 {

	
	_pctile `var' if `var'~=., n(10)
	gen `var'_q=1 if `var'<`r(r1)'&`var'~=.
	replace `var'_q=2 if `var'>=`r(r1)'&`var'<`r(r2)'&`var'~=.
	replace `var'_q=3 if `var'>=`r(r2)'&`var'<`r(r3)'&`var'~=.
	replace `var'_q=4 if `var'>=`r(r3)'&`var'<`r(r4)'&`var'~=.
	replace `var'_q=5 if `var'>=`r(r4)'&`var'<`r(r5)'&`var'~=.
	replace `var'_q=6 if `var'>=`r(r5)'&`var'<`r(r6)'&`var'~=.
	replace `var'_q=7 if `var'>=`r(r6)'&`var'<`r(r7)'&`var'~=.
	replace `var'_q=8 if `var'>=`r(r7)'&`var'<`r(r8)'&`var'~=.
	replace `var'_q=9 if `var'>=`r(r8)'&`var'<`r(r9)'&`var'~=.
	replace `var'_q=10 if `var'>=`r(r9)'&`var'~=.
}

export delim using RawData\GiS\add_fields6th_priv4prof.csv, replace

restore
}
