INTRODUCTION
The code below was developed for research using the Office for National Statistics Longitudinal Study (ONS-LS).

The ONS-LS follows a sample of the England and Wales population from Census data longitudinally (1971-2021), linking administrative data (births, deaths, cancer registrations), with capacity for linkage of data at low level geographies. Members are selected based on four birthdays, providing a 1% representative sample of the population. The study is maintained as a continuous multi-cohort through addition of new births and immigrants with the same four birthdays (members leave through death or emigration). 

For more information on the ONS-LS visit: https://www.ucl.ac.uk/population-health-sciences/epidemiology-health-care/research/ucl-research-department-epidemiology-public-health/research/health-and-social-surveys-research-group/studies/celsius


CODE

clear
set more off
capture log close

sysdir set PERSONAL "P:\xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

cd "P:\xxxxxxxxxxxxxxxxxxxx"
log using "P:\xxxxxxxxxxxxxxxxxxxxxxxxxxxxx", replace

global Data "Data"
global output "output"

/*prep lang codes for merge later*/
clear
insheet using "$Data\2000705_language_code.csv"
sort value
save "$Data\2000705_language_code.dta", replace

/*prep urban rural for merge later*/
clear
use "$Data/UPDATED_2000705_Davies_xfile_Apr24.dta"
rename CORENO coreno
sort coreno
save "$Data/2000705_Davies_xfile_Apr24.dta", replace 

clear
use "$Data\20230406_merged-datasetv6"
sort coreno
merge 1:1 coreno using "$Data\finalexportSDC.dta"
drop if _merge==2
drop _merge
merge 1:1 coreno using "$Data/2000705_Davies_xfile_Apr24.dta"

/*living in communal establishment flag*/
tab hhch11
label list hhch11
gen comm_est=0
replace comm_est=1 if hhch11==-9

/***KEY DEMOGRAPHICS***/
/*age cats*/
drop if agdc3dde<18
tab agdc3dde
recode agdc3dde (18/64=1) (65/74=2) (75/84=3) (85/120=4), gen(age_cats4)
label define age_cats4 1 "18-64" 2 "65-74" 3 "75-84" 4 "85+"
label values age_cats4 age_cats4
tab age_cats4, mi
bys age_cats4: sum agdc3dde, detail
/*age bin - below 65 v 65+*/
recode agdc3dde (18/64=1) (65/120=2), gen(age_bin)
label define age_bin 1 "18-64" 2 "65+"
label values age_bin age_bin
tab age_bin, mi
bys age_bin: sum agdc3dde, detail

/*ethnicity*/
tab ethgrp11, mi
label list ethgrp11
/*6 cats*/
recode ethgrp11 (2 3 4 = 2) (5 6 7 8 =3) (9 10 11 = 4) (14 15 16 = 5) (12 13 17 18 = 6) (-9 -6=.), gen(ethnicity6)
label define ethnicity6 1 "white british" 2 "white other" 3 "mixed" 4 "indian, pakistani, bangladeshi" 5 "black" 6 "other" 
label values ethnicity6 ethnicity6
tab ethnicity6, mi
tab ethgrp11 ethnicity6, mi
/*11 cats*/
recode ethgrp11 (3 4 = 3) (5 6 7 8 =4) (9 = 5) (10 = 6) (11 = 7) (14 = 8) (15 = 9) (12 = 10) (16 13 17 18 = 11) (-9 -6=.), gen(ethnicity11)
label define ethnicity11 1 "white british" 2 "irish" 3 "white other" 4 "mixed" 5 "indian" 6 "pakistani" 7 "bangladeshi" 8 "african" 9 "caribbean" 10 "chinese" 11 "other" 
label values ethnicity11 ethnicity11
tab ethnicity11, mi
tab ethgrp11 ethnicity11, mi

/*imd*/
gen dep_dec=imd15_dec
replace dep_dec=wimd14_dec if dep_dec==.
replace dep_dec=. if dep_dec==-9
gen income_dec=imd15_income_dec
replace income_dec=wimd15_income_dec if income_dec==.
replace income_dec=. if income_dec==-9
/*quints*/
recode dep_dec (1 2=1) (3 4=2) (5 6=3) (7 8=4) (9 10=5), gen(dep_quints)
recode income_dec (1 2=1) (3 4=2) (5 6=3) (7 8=4) (9 10=5), gen(income_quints)
tab dep_dec dep_quints, mi
tab income_dec income_quints, mi
/*flip the income quints for use in the mediation model - helpful to have consistnt direction*/
recode income_quints (5=1) (4=2) (3=3) (2=4) (1=5), gen(income_quints_flip)
tab income_quints_flip income_quints, mi

/*ns-sec*/
tab oldnssp11, mi
recode oldnssp11 (1 2=1) (3.1/3.4=2) (4.1/6=3) (7.1/7.4=4) (8.1/9.2 = 5) (10/11.2 =6) (12.1/12.7=7) (13.1/13.5=8) (14.1/14.2=9) (15 -6 -9=.), gen(nssec_per)
tab nssec_pe, mi
tab oldnssp11 nssec_per, mi
label define nssec 1 "employers in large est/higher managerial" 2 "higher professionals" 3 "lower professionals and technical" 4 "intermediate" 5 "employers in small orgs" 6 "lower supervisory" 7 "semi routine" 8 "routine" 9 "never worked/long-term unemployed" 
label values nssec_per nssec
tab nssec_per, mi
/*household*/
tab oldnssh11, mi
destring oldnssh11, gen(oldnssh11_2)
tab oldnssh11_2, mi
recode oldnssh11_2 (1 2=1) (3.1/3.4=2) (4.1/6=3) (7.1/7.4=4) (8.1/9.2 = 5) (10/11.2 =6) (12.1/12.7=7) (13.1/13.5=8) (14.1/14.2=9) (15 -6 -9=.), gen(nssec_hh)
tab nssec_hh, mi
tab oldnssh11_2 nssec_hh, mi
label values nssec_hh nssec
tab nssec_hh, mi

/***HOUSING***/
/*housing deprivation*/
tab dephsh11, mi
encode dephsh11, gen(hous_dep2)
tab hous_dep2, mi
label list hous_dep2
recode hous_dep2 (1 2 = .) (3 = 0) (4 = 1), gen(hous_dep)
tab hous_dep2 hous_dep, mi
drop hous_dep2

/*gen overcrowding*/
tab norh11
replace norh11=. if norh11<0
tab roomsreq11
replace roomsreq11=. if roomsreq11<0
gen overcrowding=norh11-roomsreq11
gen overcrowding_bin=0
replace overcrowding_bin=1 if overcrowding<=-1

/*no central heating*/
tab cnhh11, mi
label list cnhh11
gen no_centralheat=0
replace no_centralheat=1 if cnhh11==1
replace no_centralheat=. if cnhh11==-9
tab cnhh11 no_centralheat, mi

/*self contained accom*/
tab scah11
recode scah11 (-9=.) (1=0) (2=1), gen(self_cont)
label define self_cont 0 "yes, self-contained" 1 "not self-contained"
label values self_cont self_cont
tab self_cont, mi

/*tenure deprivation - LA, social, charitable, housing co-op or housing association landlord*/
tab deptnh11, mi 
tab tend11 deptnh11, row
label list tend11
recode tend11 (0=1) (1=2) (2=3) (3 4 =4) (5 6 7 8 =5) (9=6) (-6 -9 = .), gen(tenure)
label define tenure 1 "owns outright" 2 "owns with mortgage/loan" 3 "shared ownership" 4 "social rented" 5 "private rented" 6 "lives rent free"
label values tenure tenure
tab tend11 tenure, mi
/**/
encode deptnh11, gen(social_hou2)
label list social_hou2
recode social_hou (1 2 = .) (3 = 0) (4 = 1), gen(social_hous)
tab tend11 social_hous, row mi
tab social_hou2 social_hous, mi
drop social_hou2

/*type of accomodation*/
/*groups flat, tenement, coverted, commercial or temporary homes as (potentially) deprived*/
tab acch11
label list acch11
recode acch11 (-9=.) (1 2 3=1) (4=2) (5=3) (6 7=4), gen(type_accom)
label define type_accom 1 house 2 "flat or tenement" 3 "shared incl bedsit" 4 "other incl commercial building, caravan or temporary structure"
label values type_accom type_accom
tab acch11 type_accom, mi
/**/
gen type_accom_dep=0
replace type_accom_dep=1 if acch11>=4
replace type_accom_dep=. if acch11==-9
tab acch11 type_accom_dep, mi
/*gen type of housing dep*/
recode type_accom (1 = 0) (2 3 4 = 1), gen (typeho_dep)
tab type_accom typeho_dep, mi

/*housing dep count*/
tab hous_dep overcrowding_bin, mi
tab hous_dep no_centralheat, mi
tab hous_dep self_cont, mi
tab hous_dep typeho_dep, mi
egen housdep_count=rowtotal(overcrowding_bin no_centralheat self_cont typeho_dep)
replace housdep_count=. if comm_est==1


/***HOUSEHOLD DEPRIVATION - 4 VARIABLES PLUS OVERALL***/
/*housing deprivation var above 'dephsh11' is part of this group*/
/*household education deprivation - no person in household has level 2 and/or is current student*/
tab depedh11
/*household employment deprivation - any member of household is unemployed or long-term sick*/
tab depemh11
/*household health and disability deprivation - any member of household has bad or very bad general health or long-term health condition*/
tab dephdh11
/*overall household deprivation*/
tab deprivation11
destring deprivation11, force replace
recode deprivation11 (-6 -9 = .)
label define deprivation11 1 "not deprived in any domain" 2 "1 domain" 3 "2 domains" 4 "3 domains" 5 "in all 4 domains"
label values deprivation11 deprivation11
tab deprivation11, mi

/*highest qualifications*/
tab hlqp11, mi
label list hlqp11
recode hlqp11 (-9 -6 =.)

/***CO-RESIDENTS***/
/*lives alone*/
tab hhch11, mi
label list hhch11
gen lives_alone=0
replace lives_alone=1 if hhch11==1 | hhch11==2
tab lives_alone, mi
tab hhch11 lives_alone, mi

/*dependent children*/
tab dpch11, mi
labe list dpch11
gen dependent_children=0
replace dependent_children=1 if dpch11>=2
replace dependent_children=. if dpch11<0
tab dpch11 dependent_children, mi
tab dependent_children, mi

/*carers in household - CHECKING IF THIS INCLUDES THE DECEASED*/
tab cghh11, mi
label list cghh11

/*was the deceased a carer?*/
tab help11, mi
label list help11
gen carer=0
replace carer=1 if help11>=2
replace carer=. if help11<0
tab help11 carer, mi

/***LANGUAGE***/
/*main language english or welsh?/how well speaks english or welsh?*/
tab amainlangprfp11, mi
describe amainlangprfp11
label list amainlangprfp1
recode amainlangprfp11 (-9 -6 =.), gen(lang_proficiency)
label define lang_proficiency 1 "main lang is eng or welsh" 2 "speaks very well" 3 "speaks well" 4 "speaks not very well" 5 "does not speak eng or welsh" 
label values lang_proficiency lang_proficiency
tab amainlangprfp11 lang_proficiency, mi
tab lang_proficiency, mi

/*english or welsh as a main language - household language*/
tab hhldlng11, mi
recode hhldlng11 (-6 -9 = .)
label define hhldlng11 1 "all adults speak eng or welsh as main lang" 2 "at least 1 adult speaks eng or welsh" 3 "no adults, but 1 child speaks eng or welsh" 4 "no one speaks eng or welsh as main lang"
label values hhldlng11 hhldlng11
tab hhldlng11, mi

/*main language - NEED TO MERGE IN CODES FOR THESE*/
tab mainlang11, mi
describe mainlang11
destring mainlang11, force replace
rename mainlang11 value
sort value
drop _merge
merge m:1 value using "$Data\2000705_language_code.dta"
drop if _merge==2
drop _merge
rename label main_language
tab main_language, mi
encode main_language, gen(main_lang2)
label list main_lang2
replace main_lang2=. if main_lang2==62 | main_lang2==64
replace main_lang2=69 if main_lang2==68
replace main_lang2=18 if main_lang2==58
replace main_lang2=999 if (main_lang2!=25 & main_lang2!=69 & main_lang2!=34 & main_lang2!=96 & main_lang2!=12 & main_lang2!=72 & main_lang2!=42 & main_lang2!=32 & main_lang2!=94 & main_lang2!=30 & main_lang2!=18 & main_lang2!=17 & main_lang2!=7 & main_lang2!=27 & main_lang2!=83 & main_lang2!=73 & main_lang2!=38 & main_lang2!=89 & main_lang2!=95 & main_lang2!=84 & main_lang2!=98 & main_lang2!=.)
tab main_lang2, mi
/**/
label list main_lang2
gen main_lang_eng=0
replace main_lang_eng=1 if main_lang2==25
replace main_lang_eng=. if main_lang2==.
tab main_lang_eng, mi

/***WELSH LANGUAGE***/
tab gor11
label list gor11
recode gor11 (1/9 = 0) (10 = 1), gen(welsh)
tab gor11 welsh, m

/*read*/
tab lanrp11 welsh, mi col
/*speak*/
tab lansp11 welsh, mi col
/*write*/
tab lanwp11 welsh, mi col
/*understand*/
tab lanup11 welsh, mi col

/***COUNTRY OF BIRTH/ARRIVAL IN UK***/
tab cobp11, mi
tab agearrp11, mi
recode agearrp11 (-6=.)
gen years_inUK = agdc3dde-agearrp11
replace years_inUK=. if agearrp11==.
replace years_inUK=-999 if agearrp11==-9
tab years_inUK, mi
replace years_inUK=. if years_inUK<0 & years_inUK!=-999
sum years_inUK if years_inUK!=-999, detail

/***RELIGION***/
tab relgp11, mi
label list relgp11
recode relgp11 (-9 -6 = .)

/***HEALTH***/
tab heap11, mi
tab illp11, mi
tab heap11 illp11, row mi 
label list heap11
recode heap11 (-9 -6 = .) (1 2 3 =0) (4 5=1), gen(bad_health)
recode heap11 (-9 -6 = .)
tab heap11 bad_health, mi
label define bad_health 0 "very good/good/fair" 1 "bad/very bad"
label values bad_health bad_health
tab bad_health, mi
/**/
label list heap11
recode heap11 (-9 -6 = .) (1 2 3 4 =0) (5=1), gen(verybad_health)
tab heap11 verybad_health, mi
label define verybad_health 0 "good/fair/bad" 1 "very bad"
label values verybad_health verybad_health
tab verybad_health, mi
/*flip health - so coded a high is good to match imd*/
recode heap11 (-9 -6 = .) (1=5) (2=4) (3=3) (4=2) (5=1), gen(heap11_flip)
label define heap11_flip 1 very_bad 2 bad 3 fair 4 good 5 very_good
label values heap11_flip heap11_flip
tab heap11 heap11_flip, mi

/*daily activities limited*/
label list illp11
recode illp11 (-9 -6 = .) (1 2 = 1) (3 = 0), gen(healthprob)
recode illp11 (-9 -6 = .)
tab illp11 healthprob, mi
tab healthprob, mi
tab illp11, mi

/*underlying cause of death*/
codebook ic10ude
icd10cm check ic10ude, gen(icd_invalid)
codebook icd_invalid
tab ic10ude if icd_invalid==99
tab ic10ude if icd_invalid==3
icd10cm clean ic10ude, gen(ucod_clean)
icd10cm gen ucod_desc = ucod_clean, description
icd10cm gen ucod_cat = ucod_clean, categor
replace ucod_clean="" if ucod_clean=="-8"
codebook ucod_clean

gen cod_cat=.
replace cod_cat=1 if ucod_clean>="C00" & ucod_clean<="D49"
replace cod_cat=2 if ucod_clean>="F00" & ucod_clean<="F03" | ucod_clean>="G30" & ucod_clean<"G31"
replace cod_cat=3 if ucod_clean>="I00" & ucod_clean<="I99"
replace cod_cat=4 if ucod_clean>="J00" & ucod_clean<="J99"
replace cod_cat=5 if cod_cat==. 

label define cod_cat 1 cancer 2 dementia 3 cardiovascular 4 respiratory 5 other
label values cod_cat cod_cat
tab cod_cat, mi

/*ucod - using Murtagh et al categories for non-sudden & sudden causes*/
gen ucod_clean3 = substr(ucod_clean, 1, 3)
gen ucod_10 = .
replace ucod_10 = 1 if ucod_clean3>="C00" & ucod_clean3<="C97"
replace ucod_10 = 2 if (ucod_clean3>="I00" & ucod_clean3<="I52") & ucod_clean3!="I12" & ucod_clean3!="I13"
replace ucod_10 = 3 if (ucod_clean3>="J40" & ucod_clean3<="J47") | ucod_clean3=="J96"
replace ucod_10 = 4 if ucod_clean3=="I12" | ucod_clean3=="I13" | ucod_clean3=="N17" | ucod_clean3=="N18" | ucod_clean3=="N28"
replace ucod_10 = 5 if ucod_clean3>="K70" & ucod_clean3<="K77"
replace ucod_10 = 6 if ucod_clean3=="F01" | ucod_clean3=="F03" | ucod_clean3=="G30" | ucod_clean3=="R54"
replace ucod_10 = 7 if ucod_clean3=="G10" | ucod_clean=="G12.2" | ucod_clean3=="G20" | ucod_clean=="G23.1" | ucod_clean3=="G35" | ucod_clean=="G90.3"
replace ucod_10 = 8 if ucod_clean3>="I60" & ucod_clean3<="I69"
replace ucod_10 = 9 if ucod_clean3>="B20" & ucod_clean3<="B24"
replace ucod_10 = 10 if ucod_10==. & ucod_clean3!=""
label define ucod_10 1 "cancer malignant" 2 "heart disease" 3 "respiratory disease" 4 "reno-vascular disease" 5 "liver disease" 6 "dementia/Alzheimers/senility" 7 "neurodegenerative" 8 "stroke" 9 "HIV" 10 "sudden causes"
label values ucod_10 ucod_10
tab ucod_10, mis
tab ucod_10 cod_cat, mi

/*combine murtagh classification of sudden with wider cats*/
gen cod_cat6=cod_cat
replace cod_cat6=ucod_10 if ucod_10==10
label define cod_cat6 1 cancer 2 dementia 3 cardiovascular 4 respiratory 5 other 10 "sudden causes"
label values cod_cat6 cod_cat6
tab cod_cat cod_cat6, mi
tab cod_cat6, mi

/*cancer non-cancer*/
gen cancer=0
replace cancer=1 if cod_cat6==1
replace cancer=. if cod_cat6==.
tab cod_cat6 cancer, mi

/***OUTCOME - PLACE OF DEATH***/
label list pod
tab pod, mi
recode pod (1 3 4 = 0) (5 6 7 = .) (2 = 1), gen(pod_hospital)
tab pod pod_hospital, mi
label define pod_hospital 0 "home,hospice,carehome" 1 "hospital"
label values pod_hospital pod_hospital
/**/
recode pod (5 6 7 = 5), gen(pod2)
label define pod2 1 home 2 hospital 3 hospice 4 "care home" 5 "other/elswhere"
label values pod2 pod2
tab pod pod2, mi
tab pod2, mi

/*SAVE DATASETS*/
/*all deaths following 2011 census*/
keep if (deyrbde==2011 & demtbde>=3) |  deyrbde>2011
save "$Data/deaths_since2011census", replace

/*all deaths in 24 months following 2011 census*/
tab deyrbde demtbde, mi
keep if (deyrbde==2011 & demtbde>=3) | (deyrbde==2012) | (deyrbde==2013 & demtbde<=3)
save "$Data/deaths_24m_since2011_inclcommest", replace

/*all deaths in 12 months following 2011 census*/
tab deyrbde demtbde, mi
keep if (deyrbde==2011 & demtbde>=3) | (deyrbde==2012 & demtbde<=3)
save "$Data/deaths_12m_since2011_inclcommest", replace

/*exclude people living in communal establishments*/
drop if comm_est==1
save "$Data/deaths_12m_since2011_exclcommest.dta", replace
/************************************************************************/
