/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS008.sas
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS009
DESCRIPTION		: Generate summary reports of concomitant medication reports by using procedure Report
AUTHOR			: Naresh Reddy  Akkaluri
DATE COMPLETED	: 13sept2024
PROGRAM INPUT	: ADAE_AA:XLS
PROGRAM OUTPUT	: ae.sas7bdat, 
PROGRAM LOG		: ae. log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task:
1. Incidence of Treatment Emergent Adverse Events by System Organ 
Class (SOC) and Preferred Term (PT

/*----------------------------------------------------------------------------------------------*/

/*Creating log file */
proc printto log= "&output\ae.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_9\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_9\RawData ;
/*Creating permanent library*/

libname output "&output" ;

/*Importing dataset*/

proc import datafile="&RawData\ADAE_AA.xls" 
    out=Adae 
    dbms=xls replace;
    getnames=yes; 
run;

/* duplicate key values were deleted and stored in adae_dummy dataset*/
proc sort data=Adae nodupkey dupout=output.adae_dummy out=sorted_adae;
	by usubjid aebodsys;
run;


proc freq data=sorted_adae ;
	tables TRT01A/out=freq1;
run;

data freq1_conc(drop=count percent);
	set freq1;
	indent="Number of subjects with at least one adverse event";
	number= put(count,1.)|| "(" || compress(put(percent,5.1)) || ")" ;
run;

proc transpose data=freq1_conc out=tran_freq1 prefix=trt;
	var number;
	id trt01a;
	by indent;
run;

proc freq data=sorted_adae;
	tables trt01a*aebodsys/out=freq2(rename=(count=count1) drop=percent);
run;

data freq_f(drop=percent count count1);
	merge freq1 freq2;
	by trt01a;
	number= put(count1,1.)|| "(" || put(count1/count*100,5.1) || ")" ;	
run;

proc sort data=freq_f out=sort_freq_f;
	by aebodsys;
run;

proc transpose data=sort_freq_f out=trans_frq_f prefix=trt;
	var number;
	by aebodsys;
	id trt01a;
run;

proc sort data=adae nodupkey out=sort_adae;
	by usubjid aedecod aebodsys;
run;

proc freq data=sort_adae ;
	tables trt01a*aebodsys*aedecod/out=freq3(rename=(count=count1));
run;

data merge_freq(drop=count1 percent);
	merge freq1 freq3;
	by trt01a;
	number= put(count1,1.)|| "(" || put(count1/count*100,5.1) || ")" ;	
run;
proc sort data=merge_freq out=frequency;
	by aebodsys aedecod;
run;
proc transpose data= frequency out=trans_frequency prefix=trt;
	var number;
	id trt01a;
	by aebodsys aedecod;
run;

data output.ae;
	retain indent trtC trtB trtA;
	set tran_freq1 trans_frq_f trans_frequency;
	array miss(3) $ trtA trtB trtC;
	do i=1 to 3;
		if miss(i)=" " then miss(i)="0";
	end;
	if aebodsys ne " " and aedecod=" " then indent=aebodsys;
	if aedecod ne " " then indent=" " || aedecod;
run;

proc sort data=output.ae (drop=_name_ aedecod i);
	by aebodsys;
run;

proc printto;
run;
/*Deassigning the data*/
libname out clear;
run;
