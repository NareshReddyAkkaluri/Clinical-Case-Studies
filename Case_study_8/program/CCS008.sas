/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS008.sas
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS008
DESCRIPTION		: Generate summary reports of concomitant medication reports by using procedure Report
AUTHOR			: Naresh Reddy  Akkaluri
DATE COMPLETED	: 01Aug2021
PROGRAM INPUT	: Trt.sas, Mock shell for treatment Demographics summary report
PROGRAM OUTPUT	: Med.sas7bdat, med.rtf
PROGRAM LOG		: med. log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task 8
1. Study mock shell
2. Give title as per mock tables.*/

/*----------------------------------------------------------------------------------------------*/

/*Creating log file */
proc printto log= "&output\med.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_8\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_8\RawData ;
/*Creating permanent library*/

libname output "&output" ;
libname mylib "&RawData" ;
/*Importing dataset*/

data output.med;
set mylib.trtmentr;
run;

/*Sorting the dataset*/
proc sort data=output.med;
by lab;
run;

/*Generating rtf file*/
ods listing close;
ods rtf file="&output\med.rtf" startpage=no;

/*Assigning titles and footnotes as per mock output*/
title "Summary medication table";
footnote "****************************";
options pageno=1;

/*table 1*/
ods rtf startpage=now; 
proc report data=output.med;
column lab drug sub;
define lab/group;
define drug/group;
define sub/analysis;
break after lab/summarize;
rbreak after/summarize;
run;

/*table 2*/
ods startpage=now;
proc report data=output.med;
column lab (drug, sub) total;
define lab/group "lab" center;
define drug/across;
define total/computed;
compute total;
total=_c2_+_c3_+_c4_+_c5_;
endcomp;
compute after;
line " ";
line " ";
line "this data belongs to phase4";
endcomp;
run;

/*table 3*/
ods rtf startpage=now;
proc report data=output.med;
column lab (drug,sub) total;
define lab/group "lab";
define drug/across;
define total/computed;
compute total;
total=_c2_+_c3_+_c4_+_c5_;
endcomp;
compute before;
line " ";
line " ";
line "this data belongs to oncology";
line " ";
line "phase 4 trials";
line " ";
line " ";
endcomp;
compute after;
line " ";
line " ";
line "this data belongs to phase4";
line " ";
line " ";
endcomp;
run;

/*closing rtf file*/
ods rtf close;
ods listing;

/*Closing printto statement*/
proc printto;
run;

/*Deassigning the data*/
libname out clear;
run;
