clear all 
set more off
capture ssc install fs


* These are drawing the coefficients of the following regression
* reg RelativeEvent RelativeEventxNatureDummy RelativeEventxPastDummy, controlling for some fixed effects

cd "C:\Users\carlo\Dropbox\India_Dev"
foreach type in self {
* busi small qual wage all indw {
import excel Tables\Results\graph_`type'_event_unoccupied, clear

drop  A B C EU HR HT HU HV HW HX AB AC AF AG AH AI AJ AK AN AO AP AQ AR AS ///
AV AW AX AY AZ BA BD BE BF BG BH BI BL BM BN BO BP BQ BT BU BV BW BX BY CB ///
CC CD CE CF CG CJ CK CL CM CN CO CR CS CT CU CV CW CZ DA DB DC DD DE DH DI ///
DJ DK DL DM DP DQ DR DS DT DU DZ EA EB EC ED EE EH EI EJ EK EL EM EP EQ ER ///
ES ET EX EY EZ FA FB FC FF FG FH FI FJ FK FN FO FP FQ FR FS FV FW FX FY FZ ///
GA GD GE GF GG GH GI GL GM GN GO GP GQ GT GU GV GW GX GY HB HC HD HE HF HG ///
HJ HK HL HM HN HO 


* but coefficient plot will be clearer, right? and we should show fuller history --- I recommend using the package. 

* Basically, there are pre post event point estimates and their standard error, and then cross it with nature (express as indicator) with the event , and the "past nature" indicators
rename (D E F G H I J K L M N O P Q R S T U V W X Y Z AA AD AE AL AM AT AU ///
BB BC BJ BK BR BS BZ CA CH CI CP CQ CX CY DF DG DN DO DV DW DX DY EF EG EN ///
EO EV EW FD FE FL FM FT FU GB GC GJ GK GR GS GZ HA HH HI HP HQ HS) 		   ///
(c_event_1 sd_event_1 ///
c_event_2 sd_event_2 ///
c_event_3 sd_event_3 ///
c_event_4 sd_event_4 ///
c_event_5 sd_event_5 ///
c_event_6 sd_event_6 ///
c_event_neg_1 sd_event_neg_1 ///
c_event_neg_2 sd_event_neg_2 ///
c_event_neg_3 sd_event_neg_3 ///
c_event_neg_4 sd_event_neg_4 ///
c_event_neg_5 sd_event_neg_5 ///
c_event_neg_6 sd_event_neg_6 ///
c_nature_`type' sd_nature_`type' ///
c_nature_`type'xevent_1 sd_nature_`type'xevent_1 ///
c_nature_`type'xevent_2 sd_nature_`type'xevent_2 ///
c_nature_`type'xevent_3 sd_nature_`type'xevent_3 ///
c_nature_`type'xevent_4 sd_nature_`type'xevent_4 ///
c_nature_`type'xevent_5 sd_nature_`type'xevent_5 ///
c_nature_`type'xevent_6 sd_nature_`type'xevent_6 ///
c_nature_`type'xevent_neg_1 sd_nature_`type'xevent_neg_1 ///
c_nature_`type'xevent_neg_2 sd_nature_`type'xevent_neg_2 ///
c_nature_`type'xevent_neg_3 sd_nature_`type'xevent_neg_3 ///
c_nature_`type'xevent_neg_4 sd_nature_`type'xevent_neg_4 ///
c_nature_`type'xevent_neg_5 sd_nature_`type'xevent_neg_5 ///
c_nature_`type'xevent_neg_6 sd_nature_`type'xevent_neg_6 ///
c_past_nature_`type' sd_past_nature_`type' ///
c_past_nature_`type'xevent_1 sd_past_nature_`type'xevent_1 ///
c_past_nature_`type'xevent_2 sd_past_nature_`type'xevent_2 ///
c_past_nature_`type'xevent_3 sd_past_nature_`type'xevent_3 ///
c_past_nature_`type'xevent_4 sd_past_nature_`type'xevent_4 ///
c_past_nature_`type'xevent_5 sd_past_nature_`type'xevent_5 ///
c_past_nature_`type'xevent_6 sd_past_nature_`type'xevent_6 ///
c_past_nature_`type'xevent_neg_1 sd_past_nature_`type'xevent_neg_1 ///
c_past_nature_`type'xevent_neg_2 sd_past_nature_`type'xevent_neg_2 ///
c_past_nature_`type'xevent_neg_3 sd_past_nature_`type'xevent_neg_3 ///
c_past_nature_`type'xevent_neg_4 sd_past_nature_`type'xevent_neg_4 ///
c_past_nature_`type'xevent_neg_5 sd_past_nature_`type'xevent_neg_5 ///
c_past_nature_`type'xevent_neg_6 sd_past_nature_`type'xevent_neg_6 ///
Obs)  

drop in 1

ds *

local varlist "`r(varlist)'"

foreach var of local varlist {
	replace `var'=subinstr(,`var',"(","",.)
	replace `var'=subinstr(,`var',")","",.)
	replace `var'=subinstr(,`var',"*","",.)
	replace `var'=subinstr(,`var',",","",.)
}
destring *, replace

**** CI

* these are estimates of non-interaction terms
drop c_nature_`type' sd_nature_`type' c_past_nature_`type' sd_past_nature_`type'

gen id=_n
reshape long c_event sd_event c_nature_`type'xevent sd_nature_`type'xevent /// 
			 c_past_nature_`type'xevent sd_past_nature_`type'xevent, i(id) j(time) s
			 
replace time=subinstr(time,"neg","-",.)
replace time=subinstr(time,"_","",.)
destring time, replace
replace time=time+690
format time %tm
sort id time 

foreach j in event nature_`type'xevent past_nature_`type'xevent{
    gen lb_`j' = c_`j' - invttail(Obs, 0.025)*sd_`j'
	gen ub_`j' = c_`j' + invttail(Obs, 0.025)*sd_`j'
}


* Different id corresponds to different types of graph, this is nothing but literally drawing the coefficient plot.

twoway (line c_nature_`type'xevent time if id==1) || ///
	   (rcap lb_nature_`type'xevent ub_nature_`type'xevent time if id==1), ///
	   legend(off) yti("Coefficient + 95% CI")
graph export Tables\Results\event_nature_`type'_idfe.pdf, as(pdf) replace

twoway (line c_nature_`type'xevent time if id==2) || ///
	   (rcap lb_nature_`type'xevent ub_nature_`type'xevent time if id==2), ///
	   legend(off) yti("Coefficient + 95% CI")
graph export Tables\Results\event_nature_`type'_hhfe.pdf, as(pdf) replace
	   
twoway (line c_past_nature_`type'xevent time if id==3) || ///
	   (rcap lb_past_nature_`type'xevent ub_past_nature_`type'xevent time if id==3), ///
	   legend(off) yti("Coefficient + 95% CI")
graph export Tables\Results\event_past_nature_`type'_idfe.pdf, as(pdf) replace
	   
twoway (line c_past_nature_`type'xevent time if id==4) || ///
	   (rcap lb_past_nature_`type'xevent ub_past_nature_`type'xevent time if id==4), ///
	   legend(off) yti("Coefficient + 95% CI")
graph export Tables\Results\event_past_nature_`type'_hhfe.pdf, as(pdf) replace
}
