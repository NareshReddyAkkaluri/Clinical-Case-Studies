/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS007
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE         : CCS007
DESCRIPTION		:Summary of Treatment (Subject Level) 
AUTHOR			: Tejaswini Oka
DATE COMPLETED	: 08Sep2024
PROGRAM INPUT	: trt.sas7bdat, trt2.xls
PROGRAM OUTPUT	:trt.sas7bdat,trt2.sas7bdat, trt.rtf,trt2.rtf
PROGRAM LOG		: finla_Trt.log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :


PROGRAM ALGORITHM:
Task:
1. Study mock shell
2. Give title as per mock tables.

/*Creating log file */
proc printto log= "&output\finla_Trt.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_7\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_7\RawData ;
/*Creating permanent library*/

libname output "&output" ;
libname mylib "&RawData" ;

proc format;
value visitfmt 1="visit1" 2="visit2" 3="visit3" 4="visit4"
                5="visit5" 6="visit6" 7="visit7";
		run;

data output.trt;
	set mylib.trt;
	drug=lowcase(drug);
	drug1=tranwrd(drug,'asp','IBPX');
	format visit visitfmt.;
run;

ods listing close;
ods rtf file="&output\trt.rtf" startpage=no;

title1 'Summary of Treatment';
title2 'CCS007';
title3 'Generate summary reports of treatment reports by using precedure tabulate';
footnote1 " Naresh Reddy Akkaluri &sysday &sysdate";
ods rtf startpage=no;
proc tabulate data=output.trt;
	class lab;
	var sub;
	table lab="lab_Group_Group",sub*( N Mean);
run;

ods rtf startpage=now;
proc tabulate data=output.trt;
	class visit drug1; 
	var sub;
	table visit="visit"*drug1="drug",sub*(N Sum Mean Max Min Std);
	run;

ods rtf close;
ods listing;



/*Adhoc Reports: ( If trainer requires)*/
/*Importing rawdata trt2 xls  files into SAS datasets*/
proc import datafile="&RawData\trt2.xls" 
    out=output.trt2  
    dbms=xls replace;
    getnames=yes; 
run;




ods listing close;
ods rtf file="&output\trt2.rtf" startpage=no;

title1 'Summary of Treatment';
title2 'CCS007';
title3 'Generate summary reports of treatment reports by using precedure tabulate';
footnote1 " Naresh Reddy Akkaluri &sysday &sysdate";
ods rtf startpage=no;
proc tabulate data=output.trt2 ;
	class trt sex;
	table trt="TRT" all,
		  (sex="Gender(count)" all)*N 
		  (sex="Gender(%)" all)*PctN/box=[label="Example of using PCTN"];
run;

ods rtf startpage=now;
proc tabulate data=output.trt2 ;
	class trt sex;
	var aval;
	table trt="TRT" all, 
		  (sex="Gender(count)" all) * (aval="Lab_Group Result" *sum="Sum")
		  (sex="Gender(%)" all) * (aval="Lab_Group Result" *Pctsum="PctSum")
		  /box=[label="Example of using PCTSUM"];
run;

ods rtf startpage=now;
proc tabulate data=output.trt2 ;
	class trt sex;
	table trt="TRT" all,
		  (sex="Gender(Count)" all)*N  
		  (sex="Gender(%)" all)*RowPctN 
		  /box=[label="Example of using ROWPCTN"];
run;

ods rtf startpage=now;
proc tabulate data=output.trt2 ;
	class trt sex;
	var aval;
	table trt="TRT" all, 
		  (sex="Gender(Count)" all) * (aval="Lab_Group Result" *Sum)
		  (sex="Gender(%)" all)*(aval="Lab_Group Result" *rowpctsum="RowPctSum")
		  /box=[label="Example of using ROWPCTSUM"];
		  run;

ods rtf startpage=now;

proc tabulate data=output.trt2 ;
	class site trt sex avisit;
	table site="Site"*(trt="TRT" all),
		  avisit*(sex all)*PctN <trt*sex trt*all sex*all all>=" ";
		  run;
ods rtf close;
ods listing;

proc printto;
run;
libname out clear;
/*cleaaring libraries*/
proc datasets lib=work kill;
quit;
