/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS004.sas
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS004
DESCRIPTION		: To screen healthy volunteers for clinical trials
AUTHOR			: Naresh Reddy Akkaluri
DATE COMPLETED	: 07Sep2024
PROGRAM INPUT	: dm
PROGRAM OUTPUT	: demo.sas7bdat,  demog.rtf
PROGRAM LOG		: CCS004.log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task 4
1. Study mock shell
2. Age: summary statistics, Gender: frequencies & percentages; by treatment arm.
Give title as Demographics Characteristics*/

/*----------------------------------------------------------------------------------------------*/


/*Creating log file*/
proc printto log= "&output\CCS004.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_4\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_4\RawData ;
/*Creating permanent library*/
libname Input "&RawData" ;
libname output "&output" ;

/* Define formats for later use*/
proc format;
value  gender 1= "Male" 2= "Female" ;
value  arm 1= "Active" 0="Placebo" ;
run;


/* Calculate Age Summary Statistics by Treatment Arm */
proc freq data=Input.dm noprint;
tables gender*arm/outpct out=gender1 ;
format gender gender.;
run;


/*Calculation of Title*/
proc sql noprint;
select count(distinct pat) into:id1 from Input.dm where arm=0;
select count(distinct pat) into:id2 from Input.dm where arm=1;
%let tot=%eval(&id1+&id2);
%let per1 = %sysfunc(putn(%sysevalf((&id1/&tot)*100),2.));
%let per2 = %sysfunc(putn(%sysevalf((&id2/&tot)*100),2.));
%put &id1, &id2, &tot, &per1, &per2;
quit;


/*Variable for displaying statistics as per mock report*/
data gender2;
set gender1;
length a $20;
a=strip(count||" ("|| put(PCT_ROW,2.)||" %)");
run;

/*transposing dataset*/
proc sort data=gender2;
by gender;
run;
proc transpose data=gender2 out=gender3(drop=_name_) prefix=arm;
by gender;
var a; 
id arm; 
run;

/*Labelling*/
data label1;
length label $20 ;
label="Gender";
run;

/*Final Gender section*/
data gender_final (drop=gender);
length label $20;
set label1 gender3;
if _n_>1 then label="  "||put(gender,gender.);
key=label;
run;
proc means data=input.dm noprint N Mean Std Median Q1 Q3 Min;
class arm;
var age;
output out=age_stats(drop=_type_ _freq_)
n=n1
mean=mean1
std=std1
median=median1
Q1=q11
Q3=q31
min=min1
max=max1;
run;

/*converting stats to character values*/
data age_char;
length n q1_q3 min_max mean std median $20;
set age_stats;
n=put(n1,5.);
mean=put(mean1,5.1);
std=put(std1,5.1);
median=put(median1,5.1);
format q11 4.1 q31 4.1;
q1_q3=catx('-',q11,q31);
min_max=catx('-',min1,max1);
if arm ne' ';
keep arm n mean std median q1_q3 min_max;
run;

/*transposing dataset*/
proc sort data=age_char;
by arm;
run;

/*transposing*/
proc transpose data=age_char out=age_t prefix=arm;
var n mean std median q1_q3 min_max;
id arm;
run;

data age_t1;
length _name_ $20;
set age_t;
if _NAME_='n' then _NAME_='N';
if _NAME_='mean' then _NAME_='Mean';
if _NAME_='std' then _NAME_='S.D.';
if _NAME_='median' then _NAME_='Median';
if _NAME_='q1-q3' then _NAME_='Q1 - Q3';
if _NAME_='min_max' then _NAME_='Min_Max';
run;

data label;
length _name_ $20;
_name_='Age';
run;

data age_final;
set label age_t1;
if _n_ >1 then _name_ = "  "||_name_;
key=_name_;
run;


data report (keep= key arm0 arm1 ind);
set gender_final (in=a) age_final (in=b);
ind=sum(a*1,b*2);
run;

data output.demog;
retain key ind;
set report;
run;

/*generating rtf file*/
ods listing close;
ods rtf file="&output\demog.rtf";
options nodate nonumber;
title1 j=left "Table 4: Demographic Characteristics";
proc report data=output.demog headline headskip 
style(report)=[bordercolor=white]
style(header)=[backgroundcolor=white];
columns ind key arm0 arm1;
define ind/order noprint;
define key/display '' width=32;
define arm0/display "Active /N= %cmpres(&id1(&per1 %))";
define arm1/display "Placebo / N= %cmpres(&id2(&per2 %))";
compute after ind;
line " ";
line " ";
endcomp;

compute before;
line "______________________________________________________";
line " ";
line " ";
endcomp;
compute after;
line "______________________________________________________";
endcomp;
run;
ods rtf close;
ods listing;

/* Clear work library and deassign libnames */
proc datasets lib=work kill;
quit;
libname _all_ clear;
