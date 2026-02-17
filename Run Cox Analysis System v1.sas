goptions reset=all;
options orientation = PORTRAIT nodate nocenter nonumber formdlim = " " TOPMARGIN=1cm BOTTOMMARGIN= 1cm LEFTMARGIN= 1cm RIGHTMARGIN=0.5cm;
ods escapechar="^";
DATA _NULL_; call symput('___start___',datetime()); run;
%LET __path__ = %STR(K:\vep\Chennai\cox test);
%*LET __path__ = %STR(J:\Cox Model system);

/* Get Existed work datasets */
ods output members = _existData_;
ods listing close;
proc datasets library = work  ;
run;quit;
ods listing;

%macro _grabpath_ ;
%qsubstr(%sysget(SAS_EXECFILEPATH), 1, %length(%sysget(SAS_EXECFILEPATH))-%length(%sysget(SAS_EXECFILEname))-1)
%mend _grabpath_;


/*Get Existed Macro Vars */
filename mv "%sysfunc(Getoption(WORK))\global_log00000000000000.txt";
proc printto log=mv NEW; run;

%PUT _GLOBAL_;

proc printto log=log; run;

data _existedmv_ (drop = word1);
  infile mv;
  input word1 $ @;
  if word1='GLOBAL' then
     do;
        input vname:$32. ;
		if substr(vname,1,3) ne 'SYS' and substr(vname,1,2) ne '__' then output;
     end;
run;

proc sort; by vname; run;

data _NULL_;
rc = fdelete('mv');
run;
filename mv clear;

/* Get Existed Macro */
%Macro ___GetExistMacro___;
	proc catalog catalog=work.sasmacr;
	   contents out = __Macro_Names__;
	run; quit;
%MEND ___GetExistMacro___;
%___GetExistMacro___;


%GLOBAL Empty Space UndScore;
%LET Empty = %STR();
%LET Space = %STR( );
%LET UndScore = %STR(_);


%Include "&__path__\Get Existed Macro Vars v1.sas";       		/*Exclude the parameters of this system and do the checking of reserved Macro vars*/       
%Include "&__path__\Check Reserved Macro.sas";				/* Check Reserved Macro */
%Include "&__path__\Check Reserved work folder datasets.sas";	/* Check Reserved work datasets */

data _NULL_;
current = datetime(); 
_datetime = compress(year(datepart(current))||put(month(datepart(current)),z2.)||put(day(datepart(current)),z2.)||'_'||hour(current)||'h'||minute(current)||'m'||floor(second(current)));
_date = compress(year(datepart(current))||put(month(datepart(current)),z2.)||put(day(datepart(current)),z2.));
_time = compress(hour(current)||'h'||minute(current)||'m'||floor(second(current)));
_ddmmmyyyy = put(datepart(current),date9.);
call symputx("_starttime",datetime());
call symput("_datetime",strip(_datetime)); 
call symput("_date",strip(_date)); 
call symput("_time",strip(_time)); 
call symput("_ddmmmyyyy",strip(_ddmmmyyyy)); 
run;

%Macro RunCoxSystem;
proc sql noprint;
	create table __Parameter_Exist__
       (Parameter_Name 	char(11),
		Exist_YesNo 	num		);

	insert into __Parameter_Exist__
		values("RunType", %SYMEXIST(RunType))
		values("Analysis", %SYMEXIST(Analysis))
		values("Project", %SYMEXIST(Project))
		values("ProjDesc", %SYMEXIST(ProjDesc))
		values("RunDesc", %SYMEXIST(RunDesc))
		values("InputDir", %SYMEXIST(InputDir))
		values("InputFile", %SYMEXIST(InputFile))
		values("OutputDir", %SYMEXIST(OutputDir))
		values("ID", %SYMEXIST(ID))
		values("LowFU", %SYMEXIST(LowFU))
		values("HighFU", %SYMEXIST(HighFU))
		values("StartDate", %SYMEXIST(StartDate))
		values("EndDate", %SYMEXIST(EndDate))
		values("LowAge", %SYMEXIST(LowAge))
		values("HighAge", %SYMEXIST(HighAge))
		values("WhereStmt", %SYMEXIST(WhereStmt))
		values("Outcome", %SYMEXIST(Outcome))
		values("CensorValue", %SYMEXIST(CensorValue))
		values("CensorDate", %SYMEXIST(CensorDate))
		values("StudyDate", %SYMEXIST(StudyDate))
		values("TimeUnit", %SYMEXIST(TimeUnit))
		values("TimeVar", %SYMEXIST(TimeVar))
		values("RF", %SYMEXIST(RF))
		values("RFband", %SYMEXIST(RFband))
		values("RFmid", %SYMEXIST(RFmid))
		values("Cent", %SYMEXIST(Cent))
		values("RFbase", %SYMEXIST(RFbase))
		values("Covars", %SYMEXIST(Covars))
		values("CovClass", %SYMEXIST(CovClass))
		values("CovOrder", %SYMEXIST(CovOrder))
		values("CovBase", %SYMEXIST(CovBase))
		values("Strata", %SYMEXIST(Strata))
		values("Dob", %SYMEXIST(Dob))
		values("XAge", %SYMEXIST(XAge))
		values("AgeBand", %SYMEXIST(AgeBand))
		values("AgeMid", %SYMEXIST(AgeMid));

	select sum(Exist_YesNo) into :__Cnt_Param__ from __Parameter_Exist__;

%IF &__Cnt_Param__ ne 36 %THEN %DO;
		ODS RESULTS ON; 
		footnote h=7pt j=l "File-> %CMPRES(%_grabpath_\Cox System Output &_datetime.).pdf" j=r "Page ^{thispage} of ^{lastpage}";
		ods pdf notoc file = "%_grabpath_\Cox System Output &_datetime..pdf";
		ods pdf text = 'The following parameters were not submitted:';	
		ods pdf text = '  ';	
		proc print data = __Parameter_Exist__ (where = (Exist_YesNo = 0))noobs;
			var Parameter_Name;
		run;
		ods pdf close;

%END;
%ELSE %DO;
	%Include "&__path__\Get system function keywords.sas";      /*Get system function keywords*/       
	%Include "&__path__\Check Control file Macros v9.sas";      /*Macros that run the checking*/       
	%Include "&__path__\Check Control file v5.sas";             /*File that call the macros to run the checking*/
	%Include "&__path__\Data preparation v13 round.sas";              	/*File that generate the datasets for Phreg*/
	%Include "&__path__\Phreg Statement v6.sas"; 				/*File that generate statements of Phreg*/
	%Include "&__path__\Floating Absolute Risk v2.sas";			/*  Floating Absolute Risk*/
/*	%Include "&__path__\Proc Template journal 5 sas 9.3.sas";			Template for PDF file*/
/*	%Include "&__path__\Proc Template journal 5 dec sas 9.3.sas";			Template for PDF file*/
	%Include "&__path__\CSV v3.sas";								/*To print out CSV files*/             
	%Include "&__path__\Print PDF on Check Control file v8 sas 9.3.sas";/*To print out the checking result in pdf*/             
	%Include "&__path__\SetLog.sas";/*To print out the checking result in pdf*/             
%END;

	%Include "&__path__\DeleteTemp v6.sas";              		/*To delete temporary macros, macro variables, and work datasets*/
	proc datasets library = work  NODETAILS NOLIST;
		delete __Parameter_Exist__;
	run;
%Mend RunCoxSystem;


%RunCoxSystem;

proc catalog cat = work.sasmacr;
	delete 	RunCoxSystem.Macro  ___GetExistMacro___.Macro _grabpath_.Macro;
run; quit;
DATA _NULL_; call symput('___end___',datetime()); run;
%LET ___duration___ = %SYSFUNC(round(%SYSEVALF((&___end___ - &___start___)/60),0.001))%STR( Min);
%PUT ___duration___ = &___duration___;

%SYMDEL ___start___ ;
%SYMDEL ___end___ ;
%SYMDEL ___duration___ ;
%SYMDEL __path__ ;

ODS RESULTS ON; 
