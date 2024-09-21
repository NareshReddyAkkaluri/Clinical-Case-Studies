/*-------------------------------------------------------------------------------------------
PROGRAM			: CCS006
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE         : CCS006
DESCRIPTION		: Analysis dataset creation of SL (Subject Level) 
AUTHOR			: Naresh Reddy
DATE COMPLETED	: 08Sep2024
PROGRAM INPUT	: SL.xls, Base.csv 
PROGRAM OUTPUT	: SL.sas7bdat, SL_Dup.sas7bdat
PROGRAM LOG		: SL.log
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :

PROGRAM ALGORITHM:
Task 1:
	• Data cleaning
	• Remove duplicate subject from data if site also same
	• Duplicate patients data store in out dataset with name SL_dup
	• consider all the records from base dataset only
Task 2
  • Partial date:
	• If date missing consider it as 01 when month in between January to June
	• If date missing consider it as 30 when month in between July to December.
	• If Month missing considers it as 01 when date in between 1 to 15
	• If Month missing considers it as 12 when date in between 16 to 31
Task 3
  • derive variable
	• Age (years) - (start date, birth date)
	• Days (Label: No of days) - (start date, end date)
	• Months (Label: No of Months)
	• Years (Label: No of Years)
	• Round the weight variable with 1 decimal value
	 (Label: Weight (In Kgs)
Task 4
   • Decode data:
	• Convert Gender variable data values into standard data.
	• M=Male (First letter capital) F=Female (First letter capital)*/

/*----------------------------------------------------------------------------------------------*/

/*Creating log file */
proc printto log= "&output\sl.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_6\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_6\RawData ;
/*Creating permanent library*/

libname output "&output" ;

/*Importing rawdata xls and csv files into SAS datasets*/
proc import datafile="&RawData\SL.xls" 
    out=SL_Raw 
    dbms=xls replace;
    range="Sheet1$A4:Z";
    getnames=yes; 
run;

proc sql;
    create table Sl_le as
    select * 
    from SL_Raw(drop=I);  * Replace <variable_name> with the actual name of the variable you want to drop;
quit;

proc import datafile="&RawData\Base.csv"
    out=base
    dbms=csv replace;
    getnames=yes;  * Assumes the first row contains column names;
run;


/*Merging of dataset*/
proc sort data=base out=base_sort;
by subject site;
run;

proc sort data=sl_le out=SL_sort;
by subjectid site;
run;



data merges;
merge base_sort(in=a) SL_sort(in=b rename=(subjectid=subject));
by subject site;
if a;
run;


/*----------------------------------------Task1-------------------------------------*/


/*Remove duplicate subject from data if site also same and store duplicate patient data*/
proc sort data=merges out=merges_sort nodupkey dupout=output.SL_dup;
by subject site;
run;


data task2;
set merges_sort;
/*for startdate*/    
/*for date missing when month bw jan to jun consider 01*/
if scan(startdate,1,':') eq "unk" and scan(startdate,2,':') in('01','02','03','04','05','06') then do;
substr(startdate,1,3)='01';
end;
/*for date missing when month bw July to Dec consider 30*/
else if scan(startdate,1,':') eq "unk" and scan(startdate,2,':') in('07','08','09','10','11','12') then do;
substr(startdate,1,3)='30';
end;

/*If Month missing considers it as 01 when date in between 1 to 15*/
if scan(startdate,2,':')eq "unk" and scan(startdate,1,':')in('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15') then do;
substr(startdate,4,3)='01';
end;
/*If Month missing considers it as 12 when date in between 16 to 31*/
else if scan(startdate,2,':') eq "unk" and scan(startdate,1,':') in ('16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31') then do;
substr(startdate,4,3)='12';
end;

/*for null in time*/
if index(startdate,"null") ne 0 then do;  /*fun replaces "null" with "00" in the time part of the startdat*/
startdate=tranwrd(startdate,"null","00");
end;


/*for both date and month are unk replace 01*/
if scan(startdate,1,':') eq "unk" and scan(startdate,2,':') eq "unk" then do;
substr(startdate,1,3)="01";
substr(startdate,5,3)="01";
end;


/*for birthdate*/
/*for  date missing when month bw jan to jun consider 01*/
if scan(birthdate,1,'/') eq "unk" and scan(birthdate,2,'/') in('4','01','02','03','04','05','06') then do;
substr(birthdate,1,3)='01';
end;
/*for date missing when month bw July to Dec consider 30*/
else if scan(birthdate,1,'/') eq "unk" and scan(birthdate,2,'/') in('07','08','09','10','11','12') then do;
substr(birthdate,1,3)='30';
end;

/*for month*/
if scan(birthdate,2,'/')eq "unk" and scan(birthdate,1,'/')in('01','02','03','04','05','06','07','08','09','10','11','12','13','14','15') then do;
substr(birthdate,5,3)='01';
end;
else if scan(birthdate,2,'/') eq "unk" and scan(birthdate,1,'/') in ('16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31') then do;
substr(birthdate,5,3)='12';
end;
else if scan(birthdate,2,'/') eq "unk" and scan(birthdate,1,'/') in('1','4') then do;
substr(birthdate,3,3)='01';
end;
startdate=compress(startdate);	
run;


/*--------------------44444 date9.--------------------Task3-------------------------------------*/


data task3;
    set task2;

start_date=datepart(input(startdate,anydtdtm.));
end_date=datepart(input(enddate,anydtdtm.));
	

/*birth_date=input(compress(birthdate),mmddyy10.);*/

/* Clean birthdate variable */
    birthdate = compress(birthdate);
    
    /* Initialize birth_date to missing */
    birth_date = .;
    
    /* Determine format and convert birthdate */
    if index(birthdate, '/') then do;
        /* Format is MM/DD/YYYY */
        birth_date= input(birthdate, mmddyy10.);
    end;
    else if length(birthdate) in (5, 6) then do;
        /* Numeric SAS date format */
        /* Assuming format "22006" is the number of days since 01JAN1960 */
        birth_date = input(birthdate, 5.);
    end;
    else do;
        /* Invalid format */
        birth_date = .;
    end;

format start_date birth_date end_date date9.;

	
if start_date ne . and birth_date ne . then
age=intck('year',birth_date,start_date) ;

/*Calculating Days, Months and Years*/
if start_date ne . and end_date ne . then do;
days=intck('day',start_date,end_date);
months=intck('month',start_date,end_date);
years=intck('year',start_date,end_date);
end;


/*Round the weight variable with 1 decimal value*/
/* Remove "kg" and any other non-numeric characters */
wt = compress(wt, "kg");
/* Convert the cleaned weight to numeric */
wt_num = input(wt, ?? 8.2); /* Use ?? to avoid errors from invalid input */
/* Round the numeric weight to one decimal place */
if wt_num ne . then wt_num = round(wt_num, 0.1);

/*Labelling Day,Month, Years and Weight*/
label days="No. of Days"
months="No. of Months"
years="No. of Years"
wt="Weight (in kgs)"
;
run;

/*----------------------------------------Task4-------------------------------------*/
/*DECODE DATA */
data output.sl;
set task3;
if upcase(sex)in ('M','MALE') then sex='Male';
else if upcase(sex) in ('F','FEMALE') then sex='Female';
run;
/*Closing log file*/
proc printto;
run;
libname out clear;
/*cleaaring libraries*/
proc datasets lib=work kill;
quit;







