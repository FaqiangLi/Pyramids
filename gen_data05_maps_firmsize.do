clear all 
set more off
capture ssc install fs


cd "C:\Users\carlo\Dropbox\India_Dev"

**** codes to names for the census data

import delim using RawData/EconomicCensus/ec05dir.txt, clear 

replace v1=subinstr(v1," * ","",.)
replace v1=subinstr(v1,"  "," ",.)
replace v1=subinstr(v1," ","_",.)
replace v1=subinstr(v1,"__"," ",.)
split v1

gen District=substr(v11,1,4)
gen STATE_UT=substr(v11,5,.)
gen NAME=substr(v12,1,length(v12)-2)

keep  STATE_UT District NAME

replace STATE_UT=subinstr(STATE_UT,"_"," ",.)
replace NAME=subinstr(NAME,"_"," ",.)
replace NAME=strrtrim(NAME)
replace NAME=strltrim(NAME)

replace STATE_UT="ANDAMAN & NICOBAR ISLAND" if STATE_UT=="ANDAMAN & NICOBAR ISLAN"

replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)

duplicates drop

tempfile name

save `name'
**** shp identifiers 
use RawData\GiS\District_05, clear 

replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)
tempfile ID
save `ID'

clear 

fs RawData\EconomicCensus\EC5thwave\*.dta

foreach ff in `r(files)' {
	append using RawData\EconomicCensus\EC5thwave/`ff'
}
gen District=ST+DT
merge m:1 District using `name', nogen
replace NAME=upper(NAME)
replace STATE_UT=upper(STATE_UT)

replace STATE_UT="ANDAMAN & NICOBAR ISLANDS" if STATE_UT=="ANDAMAN & NICOBAR ISLAND"
replace STATE_UT="TAMILNADU" if STATE_UT=="TAMIL NADU"
replace STATE_UT="ODISHA" if STATE_UT=="ORISSA"
replace STATE_UT="CHHATTISGARH" if STATE_UT=="CHHATISGARH"
replace STATE_UT="UTTARAKHAND" if STATE_UT=="UTTARANCHAL"
replace STATE_UT="PUDUCHERRY" if STATE_UT=="PONDICHERRY"

replace NAME="ANDAMAN" if STATE=="ANDAMAN & NICOBAR ISLANDS" & NAME=="ANDAMANS"

replace NAME="SRI POTTI SRIRAMULU NELLORE" if STATE=="ANDHRA PRADESH" & NAME=="NELLORE"
replace NAME="Y.S.R" if STATE=="ANDHRA PRADESH" & NAME=="CUDDAPAH"

replace NAME="BALEMU EAST KAMENG" if STATE=="ARUNACHAL PRADESH" & NAME=="EAST KAMENG"

replace NAME="PASCHIM MEDINIPUR" if STATE=="WEST BENGAL" & NAME=="PASCHIM MIDNAPOR"
replace NAME="PURBA MEDINIPUR" if STATE=="WEST BENGAL" & NAME=="PURBA MEDINIP"

replace NAME="BAKSA" if STATE=="ASSAM" & NAME=="BASKA"
replace NAME="DIMA HASAO" if STATE=="ASSAM" & NAME=="NORTH CACHAR HILLS"
replace NAME="KAMRUP METROPOLITAN" if STATE=="ASSAM" & NAME=="KAMRUP (METRO)"

replace NAME="MAHAMAYA NAGAR" if STATE=="UTTAR PRADESH" & NAME=="HATHRAS"
replace NAME="MAHRAJGANJ" if STATE=="UTTAR PRADESH" & NAME=="MAHARAJGANJ"
replace NAME="SANT RAVIDAS NAGAR (BHADOHI)" if STATE=="UTTAR PRADESH" & NAME=="SANT RAVIDAS NAGAR BHADOHI"

replace NAME="KRISHNAGIRI" if STATE=="TAMILNADU" & NAME=="KRISHNAGI"

replace NAME="HAZARIBAGH" if STATE=="JHARKHAND" & NAME=="HAZARIBAG"
replace NAME="JAMTARA" if STATE=="JHARKHAND" & NAME=="JAMTA"
replace NAME="LATEHAR" if STATE=="JHARKHAND" & NAME=="LATEH"
replace NAME="SARAIKELA-KHARSAWAN" if STATE=="JHARKHAND" & NAME=="SERAIKELA KHARSW"
replace NAME="SIMDEGA" if STATE=="JHARKHAND" & NAME=="SIMDE"

replace NAME="ANUPPUR" if STATE=="MADHYA PRADESH" & NAME=="ANUPP"
replace NAME="ASHOKNAGAR" if STATE=="MADHYA PRADESH" & NAME=="ASHOK NAG"
replace NAME="BURHANPUR" if STATE=="MADHYA PRADESH" & NAME=="BURHANP"

replace NAME="DAKSHIN BASTAR DANTEWADA" if STATE=="CHHATTISGARH" & NAME=="DANTEWADA"
replace NAME="UTTAR BASTAR KANKER" if STATE=="CHHATTISGARH" & NAME=="KANKER"
replace NAME="KABEERDHAM" if STATE=="CHHATTISGARH" & NAME=="KAWARDHA"

replace NAME="PUDUCHERRY" if STATE=="PUDUCHERRY" & NAME=="PONDICHERRY"

replace NAME="SUBARNAPUR" if STATE=="ODISHA" & NAME=="SONAPUR"

replace NAME="SHAHID BHAGAT SINGH NAGAR" if STATE=="PUNJAB" & NAME=="NAWANSHAHR"

replace NAME="ARWAL" if STATE=="BIHAR" & NAME=="ARVAL"

replace NAME="PUNCH" if STATE=="JAMMU & KASHMIR" & NAME=="POONCH"
replace NAME="RAJOURI" if STATE=="JAMMU & KASHMIR" & NAME=="RAJAURI"

replace NAME="EAST DISTRICT" if STATE=="SIKKIM" & NAME=="EAST"
replace NAME="NORTH DISTRICT" if STATE=="SIKKIM" & NAME=="NORTH"
replace NAME="SOUTH DISTRICT" if STATE=="SIKKIM" & NAME=="SOUTH"
replace NAME="WEST DISTRICT" if STATE=="SIKKIM" & NAME=="WEST"

merge m:1 NAME STATE_UT using `ID', nogen 

drop v1 CH_M_H CH_F_H TOTAL_H CH_M_NH CH_H_NH TOTAL_NH

gen TOTAL_WORKER=M_H+F_H+M_NH+F_NH

gen TOTAL_NH=M_NH+F_NH

/*
                       TOTAL_WORKER
-------------------------------------------------------------
      Percentiles      Smallest
 1%            1              0
 5%            1              0
10%            2              0       Obs          42,127,258
25%            2              0       Sum of Wgt.    42127258

50%            2                      Mean           3.420607
                        Largest       Std. Dev.      16.32238
75%            4          14756
90%            5          15082       Variance         266.42
95%            7          17638       Skewness       296.8776
99%           15          22901       Kurtosis       216511.1


*/

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
		keep if real(substr(MAJ_SUB,1,3))>15 // droping agicultural firms
		local sample "noagri"
	}

foreach v in 1 2 4 5 7 15 50 100 200 500 1000 {
gen lessoeq`v'=TOTAL_WORKER<=`v'
gen larger`v'=TOTAL_WORKER>`v'
}
 
gen prop_NH=TOTAL_NH/TOTAL_WORKER

collapse (mean) M_H F_H M_NH F_NH TOTAL_WORKER TOTAL_NH prop_NH (count) nestablishments=TOTAL_WORKER ///
(sum) lessoeq1 lessoeq2 lessoeq4 lessoeq5 lessoeq7 lessoeq15 lessoeq50 lessoeq100 lessoeq200 ///
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

export delim using RawData\GiS\add_fields05_`sample'.csv, replace

restore

}	

