
/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS002.sas 
SAS VERSION		: 9.4
CLIENT			: KITEL
CASE STUDY CODE : CSS002
DESCRIPTION		: Outliers creation from raw data
AUTHOR			: Naresh Reddy Akkaluri
DATE COMPLETED	: 31Jul2021
PROGRAM INPUT	: AE.csv, demography.csv, dm2.csv, MH.csv
PROGRAM OUTPUT	: AE.sas7bdat, demography.sas7bdat, dm2.sas7bdat, MH.sas7bdat, demo_dup.sas7bdat, demo_dup.csv, final.sas7bdat
PROGRAM LOG		: CCS002.log
REVIEWER NAME   : <  >
REVIEW DATE		: <ddmmmyyyy>
  Comments      :


PROGRAM ALGORITHM:
Safety data:
• Create demo_dup and List out the duplicate patients data
• Weight is outside expected range Body mass index is below expected
(Check weight and height) -- (19-26)
• Age is not within expected range. (40 - 60)
• DOB is greater than the Visit date or not..?
• Gender value is a valid one or invalid. Etc (M , F else invalid)
• Retain height values where ever data values missing (all tasks)
• Weight & temperature variable requires 1 decimal data values.
/*Adverse Event
• Stop is before the start
• Overlapping adverse events for the same patient in same visit.
Vitals
• Diastolic BP > Systolic BP
Medical History
• Visit date prior to Screen date of Physical exam is normal*/

/*----------------------------------------------------------------------------------------------*/;


/*Creating log file*/
proc printto log= "&log\CCS002.log" new;
run;


/*Creating macros for convience directory changes*/
%let log =D:\KiTel_CS\Case_study_2\Log ;
%let output =D:\KiTel_CS\Case_study_2\output;
%let RawData=D:\KiTel_CS\Case_study_2\RawData ;
%let sasdatasets =D:\KiTel_CS\Case_study_2\SasDatasets;
/*Generating csv and xls files for all outliers as per specification*/

%macro export_xls_csv(data=, xls_outfile=,csv_outfile=, sheet=);
/* Export to XLS */
    proc export data=&data
        outfile="&xls_outfile"
        dbms= xls replace;
        sheet="&sheet";
    run;
/* Export to CSV */
    proc export data=&data
        outfile="&csv_outfile"
        dbms=csv replace;
    run;
%mend export_xls_csv;




/*Creating permanent library*/
libname mylib "&sasdatasets" ;

/*Step 1: Import the data files Ae.xls, Dm2.xls,MH.xls and demography.csv */
proc import datafile="&RawData\MH.xls"
    out=mylib.MH (drop = d)
    dbms=xls replace;
run;

proc import datafile="&RawData\AE.xls"
     out=mylib.AE 
     dbms=xls replace;     
run;


proc import datafile="&RawData\dm2.xls"
    out=mylib.DM2 
    dbms=xls replace;
run;
proc import datafile="&RawData\demography.csv"
    out=mylib.demo
    dbms=csv replace;
run;

/*sorting data by patid in order to merge all the data set*/
proc sort data=mylib.dm2;
   by patid;
run;

proc sort data=mylib.ae;
   by subject;
run;

proc sort data=mylib.demo;
   by patid;
run;

proc sort data=mylib.mh;
   by patid;
run;


/*merging DATA sets*/
data mylib.merges;
merge mylib.ae(in=a rename=(subject=patid)) mylib.demo(in=b) mylib.dm2(in=c) mylib.mh(in=d);
by patid;
if a & b & c & d;
run;


/*retaining the height values 
  Weight & temperature variable requires 1 decimal data values*/
data Modi_data (drop=x);
     set mylib.merges;
     by patid descending height;
     retain x;
     if height ne . then x=height;
     else if height eq . then height=x;
     weight = round(weight, 3.1);
     temp = round(temp, 3.1);
run;

/*Exporting modified data set to output window as xls file*/
%export_xls_csv(data=Modi_data, xls_outfile=&output\Modi_data.xls, 
csv_outfile=&output\Modi_data.csv, sheet=Modified_DATA );



/* Identify and list duplicate patients */

proc sort data=modi_data nodupkey dupout=demo_dup; 
    by PATID visit;
run; /*A sorted dataset demo_sorted is created, 
     and duplicates are outputted to demo_dup*/

/*Export duplicates to a new Excel sheet*/
%export_xls_csv(data=demo_dup, xls_outfile=&output\demo_dup.xls, 
csv_outfile=&output\demo_dup.csv, sheet=demo_dup );




/*Weight is outside expected rangeBody mass index is belowexpected 
(Check weight and height) --(19-26).*/

data bmi_outliers;
    set Modi_data;
    bmi = (weight/(height*height)*703.1); 
    if bmi < 19 or bmi > 26 ;
run;

%export_xls_csv(data=bmi_outliers, xls_outfile=&output\bmi_outliers.xls, 
csv_outfile=&output\bmi_outliers.csv, sheet=demo_dup );


/*The age is checked , if age  is not within expected range. (40 - 60.*/
data age_outliers;
    set Modi_data;
    age=intck('year',birthdt,today());
    if age < 40 or age > 60 ;
run;

%export_xls_csv(data=age_outliers, xls_outfile=&output\age_outliers.xls, 
csv_outfile=&output\age_outliers.csv, sheet=age_outliers );


/*Check if Date of Birth (DOB) is greater than Visit Date*/


data dob_check ;
    set Modi_data;
     if birthdt > visit_date ;
run;


%export_xls_csv(data=dob_check, xls_outfile=&output\dob_check.xls, 
csv_outfile=&output\dob_check.csv, sheet=dob_check );




/*Validate Gender (M/F are valid, others are invalid)*/
data gender_check;
    set Modi_data;
    if sex in ('M', 'F');
run;

%export_xls_csv(data=gender_check, xls_outfile=&output\gender_check.xls, 
csv_outfile=&output\gender_check.csv, sheet=gender_check );





/************************************Check Adverse Events **********************/
/*Stop before Start:*/
data ae_check;
    set Modi_data ;
    if end_date < start_date then output;
run;

%export_xls_csv(data=ae_check, xls_outfile=&output\ae_check.xls, 
csv_outfile=&output\ae_check.csv, sheet=ae_check );


/*Overlapping Adverse Events:*/

data ae_overlap ae_non_overlap;
    set Modi_data;
    retain prev_stop;
    
    if start_date < prev_stop then do;
        output ae_overlap;  /* Overlapping records */
    end;
    else do;
        output ae_non_overlap;  /* Non-overlapping records */
    end;
    prev_stop = end_date;
run;


%export_xls_csv(data=ae_overlap, xls_outfile=&output\ae_overlap.xls, 
csv_outfile=&output\ae_overlap.csv, sheet=ae_overlap );
%export_xls_csv(data=ae_non_overlap, xls_outfile=&output\ae_non_overlap.xls, 
csv_outfile=&output\ae_non_overlap.csv, sheet=ae_non_overlap );




/************************************Vitals**************************************/

/* Vitals - Check Diastolic BP > Systolic BP*/
data bp_check;
    set Modi_data;
    if diabp > sysbp then output;
run;
%export_xls_csv(data=bp_check, xls_outfile=&output\bp_check.xls, 
csv_outfile=&output\bp_check.csv, sheet=bp_check);


/************************************Medical History **************************************/


/*Medical History - Visit Date before Screen Date*/

data mh_check;
    set Modi_data;
    if visit_date < screen_date then output;
run;

%export_xls_csv(data=mh_check, xls_outfile=&output\mh_check.xls, 
csv_outfile=&output\mh_check.csv, sheet=mh_check);

/*Closing log file*/
proc printto;
run;

/*Clearing all libraries specified at the beginning*/
libname out clear;








