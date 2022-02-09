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



/*Industry intensity (state and district level*/

*** two identifiers of industry nic3 (3 digit activity code) broad activity cod(2 digit borader activity code)
preserve
collapse (count) nplants_nic3=TOTAL_WORKER (sum) total_w_nic3=TOTAL_WORKER  total_wnh_nic3=TOTAL_NH,by(ST DT NIC3 STATE_UT NAME)
save RawData\temp\ec_nic3_dist_intensity, replace
restore 

preserve
collapse (count) nplants_nic3=TOTAL_WORKER (sum) total_w_nic3=TOTAL_WORKER  total_wnh_nic3=TOTAL_NH,by(ST NIC3 STATE_UT)
save RawData\temp\ec_nic3_state_intensity, replace
restore 

preserve
collapse (count) nplants_nbact=TOTAL_WORKER (sum) total_w_bact=TOTAL_WORKER  total_wnh_bact=TOTAL_NH,by(ST DT BACT STATE_UT NAME)
save RawData\temp\ec_bact_dist_intensity, replace
restore 

preserve
collapse (count) nplants_nbact=TOTAL_WORKER (sum) total_w_bact=TOTAL_WORKER  total_wnh_bact=TOTAL_NH,by(ST BACT STATE_UT)
save RawData\temp\ec_bact_state_intensity, replace
restore 

/*firm size intensity (state and industry level*/

preserve
collapse (count) nplants=TOTAL_WORKER (sum) total_w=TOTAL_WORKER  total_wnh=TOTAL_NH,by(ST DT STATE_UT NAME)
save RawData\temp\ec_dist_size, replace
restore 

preserve
collapse (count) nplants=TOTAL_WORKER (sum) total_w=TOTAL_WORKER  total_wnh=TOTAL_NH,by(ST STATE_UT)
save RawData\temp\ec_state_size, replace
restore 