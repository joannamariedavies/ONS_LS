clear
set more off
capture log close

sysdir set PERSONAL "xxx"

cd "xxx"
log using "xxx", replace

global Data "Data"
global output "output"


clear
use "$Data/deaths_since2011census"

tab pod_hospital, mi

/*drop if pod2==5
drop if ethnicity11==.
drop if dep_quints==.*/

/*heat map - pod, ethnicity and deprivation*/
tab ethnicity11 dep_quints, mi
poisson pod_hospital agdc3dde sex i.ethnicity11##ib5.dep_quints, irr vce(robust)
margins ethnicity11##dep_quints, atmeans saving("P:\Working\tmp\`tmp'", replace)
use "P:\Working\tmp", clear
keep _margin _ci_lb _ci_ub _m1 _m2
rename _m1 ethnicity
rename _m2 imd
rename _margin predicted_proportion
rename _ci_lb lci
rename _ci_ub uci
order ethnicity imd
replace imd=555 if imd==.
replace ethnicity=555 if ethnicity==.
reshape wide predicted_proportion lci uci, i(ethnicity) j(imd)
export excel using "$output\margins_ethnicity_imd.xls", firstrow(var) sheet("margins", replace)

/*table 1*/
clear
use "$Data/deaths_since2011census"
table1, vars(agdc3dde conts \ sex cat \ ethnicity11 cat \ gor11 cat \ pph_cat11 cat \ dep_quints cat \ nssec_per cat \  hlqp11 cat \ lang_proficiency cat \ cod_cat6 cat \ pod2 cat) one mis cmis saving("$output\eth_table_1.xls", sheet(overall) sheetreplace)
drop if pod_hospital==.
table1, by(pod_hospital) vars(agdc3dde conts \ sex cat \ ethnicity11 cat \ gor11 cat \ pph_cat11 cat \ dep_quints cat \ nssec_per cat \  hlqp11 cat \ lang_proficiency cat \ cod_cat6 cat) one mis cmis saving("$output\eth_table_1.xls", sheet(by_outcome) sheetreplace)

/*models*/
/*men*/
clear
use "$Data/deaths_since2011census"
drop if pod2==5
poisson pod_hospital agdc3dde i.ethnicity11 if sex==1, irr vce(robust)
regsave using "$output/1", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 if sex==1, irr vce(robust)
regsave using "$output/2", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 dep_dec nssec_per i.hlqp11 lang_proficiency  if sex==1, irr vce(robust)
regsave using "$output/3", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 dep_dec nssec_per i.hlqp11 lang_proficiency i.cod_cat6  if sex==1, irr vce(robust)
regsave using "$output/4", ci replace
cd "P:\Working\output"
local myfilelist 1 2 3 4
foreach filename of local myfilelist{
	use `filename'.dta, clear
	keep if _n>=2 & _n<=12
	keep var coef ci_lower ci_upper
	gen sex="men"
	order sex
	gen irr=exp(coef)
	gen lci=exp(ci_lower)
	gen uci=exp(ci_upper)
	drop coef ci_lower ci_upper
	rename irr irr`filename'
	rename lci lci`filename'
	rename uci uci`filename'
	rename var ethnicity
	gen n = _n
	sort n
	save new`filename'.dta, replace
}
use new1.dta, clear
merge 1:1 n ethnicity sex using new2.dta
drop _merge
merge 1:1 n ethnicity sex using new3.dta
drop _merge
merge 1:1 n ethnicity sex using new4.dta
drop _merge
label define ethnicity2 1 "white british" 2 "irish" 3 "white other" 4 "mixed" 5 "indian" 6 "pakistani" 7 "bangladeshi" 8 "african" 9 "caribbean" 10 "chinese" 11 "other" 
label values n ethnicity2
drop ethnicity
rename n ethnicity
order sex ethnicity
save ethnicity_men.dta, replace
/******************************/
/*women*/
cd "P:\Working"
global Data "Data"
global output "output"
/*men*/
clear
use "$Data/deaths_since2011census"
drop if pod2==5
poisson pod_hospital agdc3dde i.ethnicity11 if sex==2, irr vce(robust)
regsave using "$output/1", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 if sex==2, irr vce(robust)
regsave using "$output/2", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 dep_dec nssec_per i.hlqp11 lang_proficiency  if sex==2, irr vce(robust)
regsave using "$output/3", ci replace
poisson pod_hospital agdc3dde i.ethnicity11 ib7.gor11 i.pph_cat11 dep_dec nssec_per i.hlqp11 lang_proficiency i.cod_cat6  if sex==2, irr vce(robust)
regsave using "$output/4", ci replace
cd "P:\Working\output"
local myfilelist 1 2 3 4
foreach filename of local myfilelist{
	use `filename'.dta, clear
	keep if _n>=2 & _n<=12
	keep var coef ci_lower ci_upper
	gen sex="women"
	order sex
	gen irr=exp(coef)
	gen lci=exp(ci_lower)
	gen uci=exp(ci_upper)
	drop coef ci_lower ci_upper
	rename irr irr`filename'
	rename lci lci`filename'
	rename uci uci`filename'
	rename var ethnicity
	gen n = _n
	sort n
	save new`filename'.dta, replace
}
use new1.dta, clear
merge 1:1 n ethnicity sex using new2.dta
drop _merge
merge 1:1 n ethnicity sex using new3.dta
drop _merge
merge 1:1 n ethnicity sex using new4.dta
drop _merge
label define ethnicity2 1 "white british" 2 "irish" 3 "white other" 4 "mixed" 5 "indian" 6 "pakistani" 7 "bangladeshi" 8 "african" 9 "caribbean" 10 "chinese" 11 "other" 
label values n ethnicity2
drop ethnicity
rename n ethnicity
order sex ethnicity
save ethnicity_women.dta, replace
append using ethnicity_men.dta
save ethnicity_models.dta, replace
export excel using "ethnicity_models.xls", firstrow(var) sheet("models", replace)







