* MORTCALC computes absolute mortality rates for an &ENDPOINT in groups based on 
  one or more &BYVARS and age at risk groups;
%macro mortcalc(inset, outset, endpoint, 
    daborn, dos, doo, lowage, highage, agestep, 
    byvars, subset=(1 eq 1));
/*
* Variables;
	  INSET:           input dataset;
	  OUTSET:          output dataset;
	  ENDPOINT:        endpoint name.  Values not 0 or 1 will be deleted;
	  DABORN:          name of date of birth (sas date)
	  DOS:             name of date of entry (sas date)
	  DOO:             name of date of exit or death (sas date)
      LOWAGE:          lowest point of age for calculation (eg. 40)
      HIGHAGE:         first year of age _not_ in calculation (eg. 80)
      AGESTEP:         age group size (eg. 5)
      BYVARS:          variables to group by, eg. SEX SMOKING
      SUBSET:          subset, eg. (PROVINCE EQ 9)

 Notes:
	people without DOB < DOS < DOO will be deleted
	I expect there to be at least one variable in BYVARS
	Datasets created will be named mortcalc1-mortcalcn
	I make a processed version of the main dataset (mortcalc3), 
	creating several variables in the course of the analysis.  I will try to 
	have each new variable name start with 'mc' to avoid clashes with pre-existing variables. 
	(So if you have important variables that start with 'mc', worry.)

    Lowage, highage, agestep:  to do 40-49, 50-59, 60-69:
	   LOWAGE=40, HIGHAGE=70, AGESTEP=10

Output dataset:
	Each row has one combination of the levels of the &BYVARS, and several values for
	rates, person-years, and no. of events - one of each for each age at risk group.  
	_FREQ_ 		number of people with this combination of &BYVARS
	rateN		Rates per 1000 person-years, in age group N
	sumevN		Number of events in age group N
	sumpyN		Number of person-years in age group N
	&BYVARS		All the &byvars should be in the output dataset, varying by row

	The rates, events and person-years variables have labels that record the relevant age range.   
*/

* clear out old datasets;
proc datasets library=work;
   delete mortcalc1 mortcalc2 mortcalc3 mortcalc4 mortcalc5;
   run;
quit;

* Prepare analysis dataset;
data mortcalc1;
   set &inset;

   * cut down: endpoint must be 0 or 1, dates of birth, entry and exit must 
     be non missing, and dob < dos < doo;
   * also extract the subset;
   if &endpoint ne 0 and &endpoint ne 1 then delete;
   if &daborn le .z or &dos le .z or &doo le .z then delete;
   if &dos gt &daborn and &doo gt &dos;
   if &subset;

run;

* display numbers of events after exclusions;
title 'numbers after initial subsetting';
proc means data=mortcalc1 noprint nway;
   class &byvars;
   var &endpoint;
   output out=mortcalc2 n=npop sum=nevents mean=proportion;
run;

proc print data=mortcalc2;
run;

* and blank the title again...;
title;

* computation needed for array size of age groups;
%let ngroups = %eval((&highage-&lowage)/&agestep);

data mortcalc3;
   set mortcalc1;

   array pyears{&ngroups} mcpyears1-mcpyears&ngroups;
   array ev{&ngroups} mcev1-mcev&ngroups; 
   
   * loop over age groups;
   do mcag = 1 to &ngroups;
      * age at group entry, age at entry to _next_group_;
      mcagein = &lowage + (mcag-1)*&agestep;
	  mcageout = &lowage + mcag*&agestep;

	  * date of entry, last date in group (hence -1);
	  mcdatin = intnx('year', &daborn, mcagein, 'same');
      mcdatout = intnx('year', &daborn, mcageout, 'same') - 1;

      if &dos > mcdatout or &doo < mcdatin then do;
         mcpdays = .;
		 mcev = .;
		 end;
	  else do;
	     * if in=out, still record one day;
	     mcpdays = min(mcdatout, &doo) - max(mcdatin, &dos) + 1; 
         mcev = 0;
		 if mcdatin le &doo le mcdatout then mcev = &endpoint;
	  end;
	  pyears{mcag} = mcpdays/365.25;
	  ev{mcag} = mcev;

   end;
run;

proc means data=mortcalc3 noprint nway;
   class &byvars;
   var mcev1-mcev&ngroups mcpyears1-mcpyears&ngroups;
   output out=mortcalc4 sum=sumev1-sumev&ngroups sumpy1-sumpy&ngroups 
                        n=na1-na&ngroups nb1-nb&ngroups;
run;

data mortcalc5;
   set mortcalc4;
   array pyears{&ngroups} sumpy1-sumpy&ngroups;
   array ev{&ngroups} sumev1-sumev&ngroups;
   array rates{&ngroups} rate1-rate&ngroups;
   array na{&ngroups} na1-na&ngroups;
   array nb{&ngroups} nb1-nb&ngroups;

   error = 0;
   do mcag = 1 to &ngroups;
      rates{mcag} = 1000*ev{mcag}/pyears{mcag};
	  if na{mcag} ne nb{mcag} then error = error + 1;
   end;

   %do mcag = 1 %to &ngroups;
      %let age1 = %eval(&lowage + (&agestep*(&mcag-1)));
	  %let age2 = %eval(&lowage + (&agestep*&mcag) - 1);
	  label sumpy&mcag = "Pyears &age1 - &age2";
	  label sumev&mcag = "Events &age1 - &age2";
	  label rate&mcag = "Rate &age1 - &age2";
	  label na&mcag = "Pop. from events &age1 - &age2";
	  label nb&mcag = "Pop. from py &age1 - &age2";
   %end;

   drop mcag _type_;

run;

title 'Final results';
proc print data=mortcalc5;
run;

data &outset;
   set mortcalc5;
run;
%mend;

libname cuba 'K:\vep\cuba\data\current_20160503';
options nofmterr;

proc contents data=cuba.tob_alc;
run;

proc freq data=cuba.tob_alc;
   tables current;
run;


proc freq data=cuba.analysis_data;
   where smever eq 'N' or smever eq 'S';
   format smever;
   tables sex smever ep004;
run;

%mortcalc(cuba.tob_alc, test, ep004, dob, dos, doo, 40, 80, 5, sex current);

proc print data=test;
   format sumpy1-sumpy8 6.0;
   format rate1-rate8 6.2;
   var sex current _freq_ rate1-rate8 sumev1-sumev8 sumpy1-sumpy8 nb1-nb8;
run;

libname russia 'K:\vep\Russia\Data\SAS_current';

%include 'K:\vep\Russia\SAS_code\current\map_russia.sas';

%include 'K:\vep\Russia\analyses\paul\2010-08-01\SAS\russia endpoints macro.sas';

data temp;
   set russia.allphase;
   %russends;
run;

proc freq data=temp;
   tables rus006;
run;

proc contents data=temp;
run;

proc freq data=temp;
   tables sex smoke;
run;

%mortcalc(temp, rustest, rus006, dob, dos, doo, 40, 80, 5, sex smoke);
proc print data=rustest;
   format sumpy1-sumpy8 6.0;
   format rate1-rate8 6.2;
   var sex smoke _freq_ rate1-rate8 sumev1-sumev8 sumpy1-sumpy8 nb1-nb8;
run;

/*
%macro mortcalc(inset, outset, endpoint, 
    daborn, dos, doo, lowage, highage, agestep, 
    byvars, subset=(1 eq 1));
%let daborn = dob;
%let doo = doo;
%let dos = dos;
%let inset = cuba.analysis_data;
%let outset = test;
%let endpoint = ep004;
%let lowage = 40;
%let highage = 80;
%let agestep = 5;
%let byvars = sex smever;
%let subset = (smever eq 'N' or smever eq 'S');

%put &ngroups;

proc print data=mortcalc4;
run;

proc contents data=mortcalc5;
run;

%put &age1 &age2;

options mprint mlogic;
*/
