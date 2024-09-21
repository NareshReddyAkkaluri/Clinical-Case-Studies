/*-------------------------------------------------------------------------------------------
PROGRAM			: CSS003
SAS VERSION		: 9.4
CLIENT			: Cliplab
CASE STUDY CODE : CCS003
DESCRIPTION		: Eligibility criteria and create inclusive criteria, exclusion criteria and
                  disposition patient’s profile.
AUTHOR			: Naresh Reddy Akkaluri
DATE COMPLETED	: 06Sep2024
PROGRAM INPUT	: Screen_pat.txt, Medication.txt, Dispose.txt
PROGRAM OUTPUT	: incl.sas7bdat,excl.sas7bdat,ds.sas7bdat
PROGRAM LOG		: incl.log, excl.log, ds.log 
REVIEWER NAME   : 
REVIEW DATE		: 
  Comments      :



PROGRAM ALGORITHM:
Task 3
Follow the eligibility criteria and create inclusive criteria, exclusion
criteria and disposition patient’s profile.

Eligibility:
Ages Eligible for Study : 30 Years and older
Genders Eligible for Study : Both
Accepts only Healthy Volunteers: yes

Criteria:
Inclusion Criteria:
• Diabetes mellitus type 2 defined by the criteria of the American Diabetes
Association
• Fasted plasma glucose greater than 126 mg/dL
• Plasma glucose levels greater than 200 mg/dL 2 hours after OGT
• Casual plasma glucose greater than 200 mg/dL combined with diabetic
symptoms.
• Endothelial dysfunction defined by FMD <4%
• No changes of medication for 2 months
• Significant PAOD (level IIb, III)

Exclusion Criteria:
• Ejection fraction <30%
• Malignoms
• Terminal renal failure with hemodialysis
• Relevant cardiac arrhythmias
• Acute inflammation defined as CRP >0,5 mg/dl
• PAOD (level IV).*/

/*----------------------------------------------------------------------------------------------*/

/*Creating log file*/
proc printto log= "&output\CCS003.log" new;
run;


/*Creating macros for convience directory changes*/
%let output =D:\Clinical-Case-Studies\Case_study_3\output;
%let RawData=D:\Clinical-Case-Studies\Case_study_3\RawData ;

/*Creating permanent library*/
libname mylib "&output" ;
libname output "&output" ;

/* Import the dataset from the text file */

data mylib.dispose;
infile "&RawData\dispose.txt" dlm=',' firstobs=2 dsd;
    input pat $ dscat & $50. ;
run;

data mylib.Medication;
infile "&RawData\medication.txt" dlm=',' firstobs=2 dsd;
    input pat $ height weight arm $ ;
run;

data mylib.screen_pat;
    infile "&RawData\screen_pat.txt" dlm=',' firstobs=2 dsd;
    input pat $ visit:$10. sex $ age location:$3. status $ criteria $ criteria_des & $77.;
run;

/*Creating formats to be applied to variables as per specification logic*/
proc format;
value $ status
'h'='Healthy'
'p'='Patient'
;
value $ gender
'male'='M'
'female'='F'
;
value $ arm
'p'='placebo'
'a'='active'
's'='standard'
;
value $ location
'us'='USA'
;
run;

proc sort data=mylib.screen_pat;
by pat;
run;
proc sort data=mylib.medication;
by pat;
run;
proc sort data=mylib.dispose;
by pat;
run;

/*Match merging created datasets by pat variable and applying formats*/
data merges;
merge mylib.screen_pat mylib.medication mylib.dispose;
format sex $gender. status $status. arm $arm. location $location.;
label pat='SUBJECT' visit='VISIT' age='AGE' sex='SEX' location='LOCATION' status='STATUS' height='HEIGHT' weight='WEIGHT' arm='ARM' criteria='CRITERIA' dscat='DISPOSITION CRITERIA';
by pat;	
run;

/*Creating dataset based on eligibility criteria*/
data output.eligibility;
set merges;
where age>=30 and status='h';
run;

/*Creating inclusion criteria dataset and generating log*/
proc printto log="&output\incl.log" new;
run;
data output.incl;
set eligibility;
if criteria='inc';
run;
proc printto;
run;


/*Creating exclusion criteria dataset and generating log*/
proc printto log="&output\excl.log" new;
run;
data output.excl;
set eligibility;
if criteria='exl';
run;
proc printto;
run;


/*creating disposition patients profile dataset based on specification and generating log*/
proc printto log="&output\ds.log" new;
run;
data output.ds;
set eligibility;
if dscat ne ' ';
run;
proc printto;
run;

/*Clearing the rawdata library specified*/
libname out clear;

/*Cleared the work library*/
proc datasets lib=work kill;
quit;
