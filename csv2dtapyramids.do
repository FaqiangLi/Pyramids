clear all 
set more off
capture ssc install fs


capture cd "/storage/home/fxl146/scratch/Pyramids_statafiles"

fs *.csv


foreach ff in `r(files)' {
    import delimited `ff', clear
	local name "`=subinstr("`ff'",".csv","",. )'"
	saveold `name', replace
}
