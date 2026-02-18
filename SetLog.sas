
%Macro SetLog;
libname Templib "K:\china\Kadoorie\Analysis\macros\Cox Log";
libname Templib1 "K:\china\kadoorie\Analysis\CorinnaHong\Macros\Cox Model System\Routines\Cox Log Data";
%Let User = %sysfunc(compress(&sysuserid,,kn));

%IF %EVAL(%SYSFUNC(exist(templib1.&User)) ne 1) %THEN %DO;
proc sql;
   create table templib1.&User (write = red alter = yellow)
       (DateTime num format = datetime19.,
		ControlFile char(500),
	    PDF char(500),
		RunType char(5),
        Analysis char(15),
        Project char(8),
		ProjDesc char(500),
		RunDesc char(500),
		InputDir  char(500),
		InputFile char(32),
		OutputDir char(500),
		ID char(32),
		LowFU char(9),
		HighFU char(9),
		StartDate char(9),
		EndDate char(9),
		LowAge char(9),
		HighAge char(9),
		WhereStmt char(500),
		Outcome char(500),
		CensorValue char(200),
		CensorDate char(32),
		StudyDate char(32),
		TimeUnit char(5),
		TimeVar char(16),
		RF char(500),
		RFband char(500),
		RFmid char(500),
		Cent char(300),
		RFbase char(500),
		Covars char(500),
		CovClass char(200),
		CovOrder char(200),
		CovBase char(500),
		Strata char(32),
		DoB char(32),
		XAge char(9),
		AgeBand char(100),
		AgeMid char(100)
		);

%END;

proc sql;
insert into templib1.&User (write = red)
    values(
			&_starttime,
			"%sysget(SAS_EXECFILEPATH )",
			%IF &ProjectErr eq 0 %THEN %DO;
				"&OutputDir.\&Project &_datetime..pdf",
			%END;
			%ELSE %DO;
				"&OutputDir.\&_datetime..pdf",
			%END;
			"&RUNTYPE",
			"&ANALYSIS",
			"&PROJECT",
			"&PROJDESC",
			"&RUNDESC",
			"&INPUTDIR",
			"&INPUTFILE",
			"&OUTPUTDIR",
			"&ID",
			"&LOWFU",
			"&HIGHFU",
			"&STARTDATE",
			"&ENDDATE",
			"&LOWAGE",
			"&HIGHAGE",
			"&WHERESTMT",
			"&OUTCOME",
			"&CENSORVALUE",
			"&CENSORDATE",
			"&STUDYDATE",
			"&TIMEUNIT",
			"&TIMEVAR",
			"&RF",
			"&RFBAND",
			"&RFMID",
			"&CENT",
			"&RFBASE",
			"&COVARS",
			"&COVCLASS",
			"&COVORDER",
			"&COVBASE",
			"&STRATA",
			"&DOB",
			"&XAGE",
			"&AGEBAND",
			"&AGEMID"
			);


create table Templib.&User (write = red alter = yellow) as
select * 
from templib1.&User (write = red alter = yellow);

libname templib;
libname templib1;
%Mend SetLog;

%SetLog;

