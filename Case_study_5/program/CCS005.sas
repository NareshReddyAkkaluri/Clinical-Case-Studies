

/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS005.sas
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS005
DESCRIPTION		: To screen healthy volunteers for clinical trials
AUTHOR			: Naresh Reddy Akkaluri
DATE COMPLETED	: 06/09/2024
PROGRAM INPUT	: Screen.sas7bdat, lab.sas7bdat, pat_inf.sas7bdat, Mock shell for screening report
PROGRAM OUTPUT	: SC.sas7bdat, SC.lst, SC.rtf
PROGRAM LOG		: SC.log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task 5
For conducting clinical trials investigators recruit patients. Patients pass for screening
test only needs to attend for baseline..
a) Decode the data 1=Male
2= Female
b) Screening test pass patients eligible for lab tests.
c) List the column order as follows subjid age sex race spec height weight lb_test
Title & footnote:
Title: Listing 5';
Title: 'Screening Patient';
Footnote: "* 1=male & 2 = female";
Footnote: "**Created by programmer name Date Day time”*/

/*----------------------------------------------------------------------------------------------*/

/*Creating log file */
proc printto log= "&output\sc.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_5\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_5\RawData ;
/*Creating permanent library*/
libname Input "&RawData" ;
libname output "&output" ;

/*Importing  SAS dataset*/
data screen;
set Input.sc;
run;
data patients;
set Input.pat_inf;
run;
data lab;
set Input.lab;
run;

/*Modifying as per requirement*/
data scr(drop=patid);
retain site pat scr_test;
set screen;	
length pat 3;
pat=tranwrd(patid,'y',' ');
run;

/*Sorting dataset*/
proc sort data=scr;
by site pat;
run;

proc sort data=patients out=pat_inf;
by site patid;
run;

/*Merging of data*/
data merges(drop=dob dat);
merge pat_inf(in=a) scr(in=b rename=(pat=patid));
by site patid;
if a and b;
dat=input(dob,mmddyy10.);
birdt=dat;
format birdt date9.;
age=intck("year",birdt,today());	
run;

proc sql;
create table sc as select * from merges,lab
order by site,patid,lb_test;
quit;

data sc (drop=height weight);
set sc;
ht=input(height,5.1);
wt=input(weight,6.2);
run;

/*Generating report according to mock shell and specifications*/
ods listing;
ods rtf file="&output\sc.rtf";
ods listing file="&output\sc.lst";
title1 'Listing 5';
title2 'Screening Patient';
footnote1 '* 1=Male & 2=Female';
footnote2 "**Created by Naresh Reddy Akkaluri &sysdate. &sysday. &systime.";
proc report data=sc;
column site patid age sex birdt ht wt racespec lb_test;
define site/order "SITE" center;
define patid/group "PATID" center;
define age/order "AGE" center;
define sex/order "SEX" center;
define birdt/order format=date9. "BIRDT" center;
define ht/order format=5.1 "HEIGHT" center;
define wt/order format=6.2 "WEIGHT" center;
define racespec/order "RACESPEC" center;
define lb_test/display "LB_TEST" center;
run;

ods rtf close;
ods listing close;
ods listing;
/*Closing log file*/
proc printto;
run;

/*Clearing raw data library specification*/
libname _all_ clear;

/*Clearing work data library*/
proc datasets lib=work kill;
quit;


