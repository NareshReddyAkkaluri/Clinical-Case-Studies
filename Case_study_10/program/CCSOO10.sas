/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS010.sas
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS010
DESCRIPTION		: Generate vertical Graph
AUTHOR			: Naresh Reddy Akkaluri
DATE COMPLETED	: 13Sep2024
PROGRAM INPUT	: profit.sas7bdat, total.sas7bdat
PROGRAM OUTPUT	: Graph.rtf, Graph’s
PROGRAM LOG		: Graph. log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task 10
	Create vertical Graph by using input datasets
/*----------------------------------------------------------------------------------------------*/
/*Creating log file */
proc printto log= "&output\graph.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_10\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_10\RawData ;
/*Creating permanent library*/

libname output "&output" ;
libname input "&RawData" ;

/*Generating graph in jpeg format*/
goption device=jpeg;


/*Generating rft file*/
ods listing close;
ods rtf file="&output\graph.rft" startpage=no;
ods rtf startpage=now;
goptions  hsize=2 vsize=3 csymbol=red;
title 'Sales per month';
footnote 'Generated &sysdate. &sysday.';
proc gchart data=input.profit;
vbar month/sumvar=sales discrete;
pattern1 c=red;
run;
quit;
ods rtf startpage=now;

/*graph 2*/
proc format;
value mnth
1='Jan' 2='Feb' 3='Mar' 4='Apr' 5='May';
run;

legend1 across=5 down=1
position=(bottom center outside)
shape=bar(0.5,0.25)cm
label=(j=l "month")
value=(tick=1 "Jan" tick=2 "Feb" tick=3 "Mar" tick=4 "Apr" tick=5 "May");
proc gchart data=input.profit;	
vbar month/sumvar=sales discrete subgroup=month space=2 width=4;
format month mnth.;
pattern1 c=blue v=s;
pattern2 c=blue v=e;
pattern3 c=blue v=l3;
pattern4 c=blue v=r1;
pattern5 c=blue v=x3;
run;
quit;

ods rtf startpage=now;
/*graph 3*/	
proc gchart data=input.totals;
vbar site/sumvar=sales type=mean discrete subgroup=site space=2 width=4 nolegend;
format sales dollar6.;
pattern1 c=blue v=s;
pattern2 c=blue v=s;
pattern3 c=blue v=s;
run;
quit;
ods rtf close;
ods listing;

/*closing log file*/
proc printto;
run;
