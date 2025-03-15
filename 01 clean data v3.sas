* v2 narrow to events that happen in Y1
	add in new date of death data
	add in new HTN and OAC data;
* v3 remove imputation;

libname in "H:/vital/original data/";
libname out "H:/vital/processed data/";

data baseline; set in.baseline;run;

data b2; set baseline;
drop EPIC_PMRN MRN_Type MRNs EMPI PerProtocol 
AsTreated provider white black asian hawaiian
amind other unknown Religion country
meds_Flecainide
meds_Propafenone
meds_Sotalol
meds_Dronedarone
meds_Amiodarone
meds_Dofetilide
meds_Disopyramide
language
Marital_status
Insurance_combined;
lang_english = (language = "English-ENGLISH");
run;

proc contents order = varnum; run;

proc freq nlevels; table mrn / noprint; run;

%LET catvars = lang_english gender PrevalentAF CurrentSmoker
HTN CAD DBM CHF PriorSTR VAS Anemia Bleed Renal
meds_htn meds_oac meds_RateControl meds_Antiarrhythmic
ecg12L_prior1y ICD_prior3y ablation_prior3y
cardioversion_prior3y LAAO_prior3y;

%let contvars = age height_cm weight_kg SBP
DBP HR pcpvsts_prior1y ;

proc freq;  tables &catvars  / missing; run;
proc means n nmiss mean std min max maxdec = 1; var &contvars; run;

proc print data = baseline(obs=10);
var mrn group fstvisit_date end_date;run;

data i; set in.af_inc;
run;
data i2; set i;
keep year af_dx_date outcome mrn_n included;
outcome = 1;
mrn_n = mrn +0;
where included = 1; ** added this in v2;
run;

proc sort noduprec;  by mrn_n year af_dx_date; run;
proc freq nlevels; table mrn_n / noprint; run;

** revised death data v2;
data d ;
rename mrn_n = mrn
dod = date_of_death;
set in.death;
mrn_n = mrn +0;
drop mrn;
run;

data htn; rename mrn_n = mrn;
set in.meds_htn_oac;
mrn_n = mrn +0;
drop mrn;
run;

data b2; set b2;
drop meds_htn meds_oac date_of_death;
run;

proc sql;
create table work 
as select * from b2
left join i2 on
b2.mrn = i2.mrn_n

left join d on 
b2.mrn = d.mrn

left join htn on
b2.mrn = htn.mrn;
quit;

data work; set work;
if meds_htn = . then meds_htn = 0;
run;


data out.analytic_20240312; set work.work; 
if outcome ne 1 then outcome = 0;
run;