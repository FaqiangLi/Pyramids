***** Main console for Faqiang's code

* I organzie the codes such that


* Severalmy specific coding habbits in stata
* - dataset_`x'p means the `x'% random sample , x=10,1,01 and  so on
* - there could be some "a" character in the code--that is just my way of setting breakpoints in runing the dofiles. This also work when submitting job in command line. 
* - An "*" is for introducing normally an action , a "//" often is used as sub-action following a * or some miscellaneous explanation.


* storing dofiles
local working_script "/storage/home/fxl146/work/Pyramids"

* storing temporary files
local workspace "/storage/home/fxl146/scratch/Pyramids_statafiles"

* storing (permanent,zipped) raw files
local rawfilestorage "/storage/home/fxl146/work/Pyramids_raw"


*******************************************************************************
* Project: General data cleaning
*******************************************************************************

* Before running data cleaning, unzip files from `rawfilestorage' to `workspace' subfolders (weekly_expense, people_of_india, monthly_expense, member_income, household_income, aspirational_india)

cd `working_script'

* Bulk transform csv raw files to dta files.
do csv2dtapyramids

* Bulk rough select and append data. The criteria is following Carlos (accepted, age>=15, member_status=="Member of the household") whenever applicable. It generates by-year by-dataset data files.
do clean_trim_merge_append

* Whenever I need to downsize(by truncating variables), random sample a dataset or bulk-codebook (and check the log) the datasets, I do them here.
do rescale_truncate_sample

*******************************************************************************
* Project: GST and its derivative
*******************************************************************************

* (Copied from Carlos) Merge and rough select (accepted, age>=15, member_status=="Member of the household"). The scripts generate temporary datafile: carlos_employment_income_1618, used below for the GST project. I maintained Carlos' early codes following the data construction.
do explore_pyramids_faqiang

* (a note to Faqiang by Faqiang)there is another dofiles I didn't see which is used to run event study regression. But the script content is subsumed in explore_expense_merge_Carlos_hhmerge.do .

* (Carlos' dofile) Making use of the excel of coefficients, draw event study graph
do event_graph
// do event_graph_Carlos   // I create this?

* explore monthly expense data and prepare data for merging with Carlos' sample
do explore_expense

* explore household head's info and decide to discard merging with monthly expense according to household heads' mem_id
do explore_hoh_in_carlos

* Actively working script on merging/exploring expense data with Carlos' sample on GST.
explore_expense_merge_Carlos_hhmerge

*******************************************************************************
* Project: Labor reform
*******************************************************************************

* Labor reform exploration. The sample construction is following clean_trim_merge_append.do instead of exactly Carlos' sample construction. They could vary slightly
do ES_IDAreform

