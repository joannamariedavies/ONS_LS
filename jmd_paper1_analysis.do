/* The following code was written to undertake analysis using a sample of study 
members from the Office for National Statistics Longitudinal Study (ONS LS).

The ONS LS  links census records to life events of the members (deaths, births and
cancer registrations). Members are selected based on four birthdates resulting in a
1% representative sample of the population of England and Wales.
The dataset commences from the 1971 census and continues to the 1981, 1991, 2001 and
2011 census, providing up to 40 years of data on approximately 1 million sample members.
New members enter the study either by being born on those dates or through immigration.

ACKNOWLEDGEMENT/ DISCLAIMER
The permission of the Office for National Statistics to use the ONS LS is gratefully
acknowledged, as is the help provided by staff of the Centre for Longitudinal Study
Information & User Support (CeLSIUS). CeLSIUS is funded by the ESRC under project ES/V003488/1. The authors alone are responsible for the interpretation of the data
*/

clear
set more off
capture log close

sysdir set PERSONAL "xxxx\ado\personal"

cd "xxxx\Working"
log using "xxxx\Working\Logs\jmd", replace

global Data "Data"
global output "output\paper1"

/*full pop*/
clear
use "$Data/deaths_since2011census"

tab pod2 pod_hospital, mi
drop if pod_hospital==.

/*table 1*/
table1, by(income_quints) vars(agdc3dde conts \ age_cats4 cat \ sex cat \ ethnicity6 cat \ ethnicity11 cat \ cod_cat6 cat \ gor11 cat \ pod2 cat ) one mis cmis saving("$output\table_1.xls", sheet(by_imd) sheetreplace)

table1, vars(agdc3dde conts \ age_cats4 cat \ sex cat \ ethnicity6 cat \ ethnicity11 cat \ cod_cat6 cat \ gor11 cat \ pod2 cat ) one mis cmis saving("$output\table_1.xls", sheet(overall) sheetreplace)

/*for supplementary file*/
table1, by(pod_hospital) vars(ethnicity6 cat \ ethnicity11 cat \ cod_cat6 cat) one mis cmis saving ("$output\table_1.xls", sheet(suppl_pod) sheetreplace)

table1, by(income_quints) vars(dep_quints cat) one mis cmis saving ("$output\table_1.xls", sheet(suppl_imd) sheetreplace)

/*age and sex standardised rates of difference causes of death for deprivation quints*/
preserve
mlogit cod_cat6 sex agdc3dde ib5.income_quints 
tempfile tmp
margins income_quints, atmeans saving ("`tmp'")
use "`tmp'", clear 
keep _margin _ci_lb _ci_ub _m1 _predict
rename _m1 income_quints
rename _predict cod_cat6
rename _margin predicted_mean
rename _ci_lb lci
rename _ci_ub uci
order cod_cat6 income_quints 
label define cod_cat62 1 cancer 2 dementia 3 cardiovascular 4 respiratory 5 other 6 "sudden causes"
label values cod_cat6 cod_cat62
reshape wide predicted_mean lci uci, i(cod_cat6) j(income_quints)
export excel using "$output\margins_codcat.xls", firstrow(var) replace 
restore

/*age and sex standardised rate of cancer death*/
poisson cancer sex agdc3dde ib5.income_quints
margins income_quints, atmeans

/*multinomial*/
mlogit pod2 agdc3dde sex ib5.income_quints i.cod_cat6 if pod2!=5, base(2) 
/*shows that q1 sig less likely to die at home, hospice & care home v hospital*/

/*main effects*/
/*non linear*/
poisson pod_hospital agdc3dde sex ib5.income_quints, irr vce(robust)
margins income_quints, atmeans
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age and sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") graphregion(color(white))
graph save "$output/income_hosppod", replace

/*AGE*/
poisson pod_hospital sex c.agdc3dde##ib5.income_quints, irr vce(robust)
margins, at (income_quints=(1(1)5) agdc3dde=(40 60 80)) atmeans
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") legend(rows(1) subtitle("age at")) graphregion(color(white))
graph save "$output/income#age", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex ib5.income_quints) (ib5.income_quints##c.agdc3dde), irr vce(robust)

/*GENDER*/
poisson pod_hospital agdc3dde ib5.income_quints##sex, irr vce(robust)
margins sex, at(income_quints=(1(1)5)) atmeans
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") graphregion(color(white))
graph save "$output/income#sex", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex ib5.income_quints) (ib5.income_quints##sex), irr vce(robust)

/*ETHNICITY6*/
bys income_quints: tab ethnicity6 pod_hospital, mi
poisson pod_hospital agdc3dde sex i.ethnicity6##ib5.income_quints, irr vce(robust)
margins ethnicity6, at(income_quints=(1(1)5)) atmeans
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age and sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") legend(subtitle("ethnicity")) graphregion(color(white))
graph save "$output/income#ethnicity", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex i.ethnicity6 ib5.income_quints)(i.ethnicity6##ib5.income_quints), irr vce(robust)

/*DIAGNOSIS*/
bys income_quints: tab cod_cat6 pod_hospital, mi
poisson pod_hospital agdc3dde sex i.cod_cat6##ib5.income_quints, irr vce(robust)
margins cod_cat6, atmeans at(income_quints=(1(1)5)) 
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age and sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") legend(subtitle("underlying cause of death")) graphregion(color(white))
graph save "$output/income#ucod", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex i.cod_cat6 ib5.income_quints)(i.cod_cat6##ib5.income_quints), irr vce(robust)

/*SENSITIVITY DIAGNOSIS- drop hospice deaths to see how far this drives the inequality for cancer*/
preserve
drop if pod2==3
bys income_quints: tab cod_cat6 pod_hospital, mi
poisson pod_hospital agdc3dde sex i.cod_cat6##ib5.income_quints, irr vce(robust)
margins cod_cat6, atmeans at(income_quints=(1(1)5)) 
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age and sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") legend(subtitle("underlying cause of death")) graphregion(color(white))
graph save "$output/income#ucod", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex i.cod_cat6 ib5.income_quints)(i.cod_cat6##ib5.income_quints), irr vce(robust)
restore

/*REGION*/
poisson pod_hospital agdc3dde sex ib5.income_quints##i.gor11, irr vce(robust)
margins gor11, atmeans at(income_quints=(1(1)5))
marginsplot, ytitle("predicted proportion" " ") xtitle( " " "income deprivation (1 is most deprived)") title("age and sex adjusted predicted proportion of death in hospital" "(versus home, hospice or care home)") legend(subtitle("region")) graphregion(color(white))
graph save "$output/income#region", replace
/*model fit*/
nestreg: poisson pod_hospital (agdc3dde sex i.gor11 ib5.income_quints)(i.gor11##ib5.income_quints), irr vce(robust)


/*********************************************************************************/
/*heat map - pod, ethnicity and deprivation*/
poisson pod_hospital agdc3dde sex i.dep_quints##i.ethnicity11, irr vce(robust)
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
/*******************************************************************************************/

/*MEDIATION ANALYSIS*/
clear
use "$Data/deaths_12m_since2011_inclcommest"
drop if pod_hospital==.
drop if comm_est==1
keep if pod2==1 | pod2==2
keep if cod_cat6==1
tab pod2, mi

/*table 1*/
table1, by(income_quints) vars(agdc3dde conts \ age_cats4 cat \ sex cat \ lives_alone cat \ housdep_count2 cat \ heap11 cat \ heap11 conts \  pod2 cat ) one mis cmis saving("$output\table_1.2.xls", sheet(med_tab1) sheetreplace)

table1, vars(agdc3dde conts \ age_cats4 cat \ sex cat \ lives_alone cat \ housdep_count2 cat \ heap11 cat \ heap11 conts \  pod2 cat ) one mis cmis saving("$output\table_1.2.xls", sheet(overall) sheetreplace)

/*shape of association between income and hosp_death for this subgroup*/
logistic pod_hospital agdc3dde sex ib5.income_quints, vce(robust)
margins i.income_quints, atmeans
marginsplot

/*MAIN MODELS*/
/*x on m1, m2, m3*/
logistic lives_alone agdc3dde sex income_quints, vce(robust)
testparm income_quints
margins, at (income_quints=(1(1)5)) atmeans

logistic housdep_count2 agdc3dde sex income_quints, vce(robust)
testparm income_quints
margins, at (income_quints=(1(1)5)) atmeans

regress heap11 agdc3dde sex income_quints, vce(robust)
testparm income_quints
margins, at (income_quints=(1(1)5)) atmeans

logistic pod_hospital agdc3dde sex income_quints, vce(robust)
testparm income_quints
margins, at (income_quints=(1(1)5)) atmeans

logistic hh_eddep ib5.income_quints agdc3dde sex, vce(robust)

/*multiple mediation model*/
mata: mata mlib index
khb logistic pod_hospital income_quints || i.lives_alone i.hous_dep heap11, vce(robust) concomitant(agdc3dde sex) summary disentangle verbose

matrix list e(disentangle)
mat b = e(disentangle)

/*NB could have automated this using 
scalar z = b[1,1] / b[1,2]
di 2*normal(-abs(z))*/
/*living alone*/
/*get z score*/
di b[1,1]/b[1,2]
/*get p value*/
di 2*normal(-abs(-2.0414698))
/*get ci*/
di b[1,1] - invnormal(0.975)*b[1,2]
di b[1,1] + invnormal(0.975)*b[1,2]
/*housing*/
/*get z score*/
di b[2,1]/b[2,2]
/*get p value*/
di 2*normal(-abs(.24122162))
/*get ci*/
di b[2,1] - invnormal(0.975)*b[2,2]
di b[2,1] + invnormal(0.975)*b[2,2]
/*health*/
/*get z score*/
di b[3,1]/b[3,2]
/*get p value*/
di 2*normal(-abs(2.4957135))
/*get ci*/
di b[3,1] - invnormal(0.975)*b[3,2]
di b[3,1] + invnormal(0.975)*b[3,2]


/*SENSITIVITY income as cat*/
/*x on m1, m2, m3*/
logistic lives_alone agdc3dde sex ib5.income_quints, vce(robust)
testparm i.income_quints
margins income_quints, atmeans

logistic housdep_count2 agdc3dde sex ib5.income_quints, vce(robust)
testparm i.income_quints
margins income_quints, atmeans

regress heap11 agdc3dde sex ib5.income_quints, vce(robust)
testparm i.income_quints
margins income_quints, atmeans

logistic pod_hospital agdc3dde sex ib5.income_quints, vce(robust)
testparm i.income_quints
margins income_quints, atmeans

/*multiple mediation model*/
mata: mata mlib index
khb logistic pod_hospital ib5.income_quints || i.lives_alone i.hous_dep heap11, concomitant(agdc3dde sex) summary disentangle verbose

matrix list e(disentangle)
mat b = e(disentangle)

/*Q1*/
/*lives alone*/
/*get z score*/
di b[1,1]/b[1,2]
/*get p value*/
di 2*normal(-abs(1.9468585))
/*get ci*/
di b[1,1] - invnormal(0.975)*b[1,2]
di b[1,1] + invnormal(0.975)*b[1,2]
/*housing*/
/*get z score*/
di b[2,1]/b[2,2]
/*get p value*/
di 2*normal(-abs(-.18517353))
/*get ci*/
di b[2,1] - invnormal(0.975)*b[2,2]
di b[2,1] + invnormal(0.975)*b[2,2]
/*health*/
/*get z score*/
di b[3,1]/b[3,2]
/*get p value*/
di 2*normal(-abs(-2.230757))
/*get ci*/
di b[3,1] - invnormal(0.975)*b[3,2]
di b[3,1] + invnormal(0.975)*b[3,2]
/*********************/
/*Q2*/
/*lives alone*/
/*get z score*/
di b[4,1]/b[4,2]
/*get p value*/
di 2*normal(-abs(1.7900092))
/*get ci*/
di b[4,1] - invnormal(0.975)*b[4,2]
di b[4,1] + invnormal(0.975)*b[4,2]
/*housing*/
/*get z score*/
di b[5,1]/b[5,2]
/*get p value*/
di 2*normal(-abs(-.18510852))
/*get ci*/
di b[5,1] - invnormal(0.975)*b[5,2]
di b[5,1] + invnormal(0.975)*b[5,2]
/*health*/
/*get z score*/
di b[6,1]/b[6,2]
/*get p value*/
di 2*normal(-abs(-1.8005055))
/*get ci*/
di b[6,1] - invnormal(0.975)*b[6,2]
di b[6,1] + invnormal(0.975)*b[6,2]
/*********************/
/*Q3*/
/*lives alone*/
/*get z score*/
di b[7,1]/b[7,2]
/*get p value*/
di 2*normal(-abs(.97016694))
/*get ci*/
di b[7,1] - invnormal(0.975)*b[7,2]
di b[7,1] + invnormal(0.975)*b[7,2]
/*housing*/
/*get z score*/
di b[8,1]/b[8,2]
/*get p value*/
di 2*normal(-abs(-.17848271))
/*get ci*/
di b[8,1] - invnormal(0.975)*b[8,2]
di b[8,1] + invnormal(0.975)*b[8,2]
/*health*/
/*get z score*/
di b[9,1]/b[9,2]
/*get p value*/
di 2*normal(-abs(-2.013702))
/*get ci*/
di b[9,1] - invnormal(0.975)*b[9,2]
di b[9,1] + invnormal(0.975)*b[9,2]
/*********************/
/*Q4*/
/*lives alone*/
/*get z score*/
di b[10,1]/b[10,2]
/*get p value*/
di 2*normal(-abs(.38117274))
/*get ci*/
di b[10,1] - invnormal(0.975)*b[10,2]
di b[10,1] + invnormal(0.975)*b[10,2]
/*housing*/
/*get z score*/
di b[11,1]/b[11,2]
/*get p value*/
di 2*normal(-abs(-.1829289))
/*get ci*/
di b[11,1] - invnormal(0.975)*b[11,2]
di b[11,1] + invnormal(0.975)*b[11,2]
/*health*/
/*get z score*/
di b[12,1]/b[12,2]
/*get p value*/
di 2*normal(-abs(-.56706108))
/*get ci*/
di b[12,1] - invnormal(0.975)*b[12,2]
di b[12,1] + invnormal(0.975)*b[12,2]
/**********************END OF DO FILE***********************************/
