%Macro CSV;
%DO r = 1 %TO &N_RF;
	%DO o = 1 %TO &N_Outcome;
		%IF &ParamError le 0 and %UPCASE(&RunType) eq RUN and &&PhErrr&r.o&o. eq 0 and &&Statusr&r.o&o. eq 0 %THEN %DO; *********************;
			%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));			/***; %PUT Outcome = &ThisOutcome;*/
			%LET ThisRF = %SYSFUNC(strip(%UPCASE(&&RF&r)));			/***; %PUT RF = &ThisRF;*/
			%LET ThisRFType = &&RFType&r;							


			%IF &&FarUsedr&r.o&o. eq 1 %THEN %DO;
				proc sql stimer;
				create table _CSV_Datar&r.o&o._ as
				select distinct RF %IF &ALY ne MUL %THEN %DO;	,RF_Level %END; %ELSE %DO; , d.Mean_RF as RF_Level %END;
				%IF &ALY eq MUL %THEN %DO;/*********************    AgeBandr&r.o&o. N_AgeBandr&r.o&o. &&N_AgeMidr&r.o&o. &&AgeMidr&r.o&o.        *********************/
					,case 	%DO am = 1 %TO &&N_AgeMidr&r.o&o.;
							when AgeBand = %SCAN(&&AgeMidr&r.o&o.,&am,%STR( )) then "%SCAN(&&AgeBandr&r.o&o.,&am,%STR( ))%STR(-)%EVAL(%SCAN(&&AgeBandr&r.o&o.,%EVAL(&am+1),%STR( ))-1)"
							%END;
					end as AgeBand 
					,a.CrossGrp				
				%END;
				,NEvents, NObs, PYears
				,b.Estimate,  
				case when b.Estimate = 0 and c.StdErr = 0 then . else c.StdErr end as StdErr, 
				QStdErr as F_StdErr, HR, QLowerCL as LowerCL, QUpperCL as UpperCL
				from _CSr&r.o&o._ a, work.FAR_&ThisRF._&ThisOutcome. b  , work.PE_&ThisRF._&ThisOutcome. c 
				%IF &ALY eq MUL %THEN %DO;
					, (select distinct CrossGrp, Mean(&ThisRF) as Mean_RF 
						from Data_&ThisRF._&ThisOutcome 
						group by 1) as d
				%END;
				%IF &ALY ne MUL %THEN %DO;
					where a.RF_Level = b.Group  and a.RF_Level = c.ClassVal0 and c.Parameter = a.RF
				%END;
				%ELSE %DO;
					where a.CrossGrp = b.Group  and a.CrossGrp = c.ClassVal0 and a.CrossGrp = d.CrossGrp and c.Parameter = "CrossGrp"
				%END;
				order by 	RF %IF &ALY eq MUL %THEN %DO;	,CrossGrp %END;, RF_Level		
				;
			%END;
			%ELSE %DO; 
				proc sql stimer;
				create table _CSV_Datar&r.o&o._ as
				select distinct RF,	RF_Level, 
				%IF &ALY eq MUL %THEN %DO;
					case 	%DO am = 1 %TO &&N_AgeMidr&r.o&o.;
							when AgeBand = %SCAN(&&AgeMidr&r.o&o.,&am,%STR( )) then "%SCAN(&&AgeBandr&r.o&o.,&am,%STR( ))%STR(-)%EVAL(%SCAN(&&AgeBandr&r.o&o.,%EVAL(&am+1),%STR( ))-1)"
							%END;
					end as AgeBand, 
				%END;
				NEvents, NObs, PYears,
				Estimate, StdErr as StdErr, 
				case when HazardRatio = . then 1 else HazardRatio end as HR, 
				HRLowerCL as LowerCL, HRUpperCL as UpperCL
				from _CSr&r.o&o._ a left outer join 
					(select * 
						from work.PE_&ThisRF._&ThisOutcome. 
						%IF &ALY ne MUL %THEN %DO;
							%IF %UPCASE(&ThisRFType) eq CONTINUOUS %THEN %DO;
								where upcase(Parameter) = upcase("&&ThisRF.")
							%END;
							%ELSE %DO;
								where upcase(Parameter) = upcase("&&ThisRF.Grp")
							%END;
						%END;
						%ELSE %DO;
							where upcase(Parameter) = upcase("CrossGrp")
						%END;
					) as b
				%IF &ALY ne MUL %THEN %DO;
					%IF %UPCASE(&ThisRFType) eq CONTINUOUS %THEN %DO;
						on upcase(a.RF) = upcase(b.Parameter)
					%END;
					%ELSE %DO;
						on upcase(a.RF) = upcase(b.Parameter) and a.RF_Level = b.ClassVal0 
					%END;
				%END;
				%ELSE %DO;
					on upcase(a.CrossGrp) = upcase(b.ClassVal0)
				%END;
				order by 	a.RF    %IF &ALY eq MUL %THEN %DO;	,CrossGrp %END;, a.RF_Level	
				;
			%END;
			quit;

			%LET dsid=%SYSFUNC(open(work._CSV_Datar&r.o&o._)); 	/*	%PUT dsid = &dsid;*/
			%LET NLObs=%SYSFUNC(attrn(&dsid,NLOBS)); 			/*	%PUT NLObs = &NLObs;*/
			%LET Dclose= %SYSFUNC(close(&dsid));				/*	%PUT Dclose = &Dclose;*/
			%IF %EVAL(&NLObs eq 1) %THEN %DO;
				Data CSV_&ThisRF._&ThisOutcome. ;
					set _CSV_Datar&r.o&o._ 	;
					REGTIM = 0 ;
					FIRST = 0;
					LAST = 999;
				run;
			%END;
			%ELSE %DO;
				Data CSV_&ThisRF._&ThisOutcome. ;
					set _CSV_Datar&r.o&o._ 	;
				run;
			%END;

			%IF %sysfunc(exist(CSV_&ThisRF._&ThisOutcome.)) %THEN %DO;
				data _fileCreateInfo_;
					dsid=open("CSV_&ThisRF._&ThisOutcome.");
					FileTime = ATTRN(dsid, "MODTE");
					FileObs = ATTRN(dsid,"NLOBS"); 
					rc=close(dsid);
				run;

				proc sql noprint;
					insert into __DataCreated__
					select "SAS Dataset", "Work","CSV_&ThisRF._&ThisOutcome.", FileTime
					from _fileCreateInfo_
					where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

				%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
					proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
				%END;
			%END;


			%LET InParam = %NRSTR(&RunType &Analysis &Project &ProjDesc &RunDesc &InputDir &InputFile &OutputDir &ID
								&LowFU &HighFU &StartDate &EndDate &LowAge &HighAge &WhereStmt &Outcome &CensorValue &CensorDate &StudyDate
								&Covars &CovClass &CovOrder &CovBase &Strata &Dob &XAge &AgeBand &AgeMid);
			Data _NULL_; call symput('N_InParam' , 1 + count(strip(compbl("&InParam")),' '));	run; 

			Data _NULL_;
				format Key best12.;
				length Parameter $12. Value $1000;
				if _n_=1 then do;
					declare hash h(ordered:'a');	
					h.definekey('Key');
					h.definedata('Key','Parameter','Value');
					h.definedone();
					call missing(Key,Parameter,Value);
				end;
					%DO _i = 1 %TO 20;
						Key = &_i.;
						Parameter = "%qsubstr(%qSCAN(&InParam,&_i,%STR( )),2)";
						%IF &_i ne 17 %THEN %DO;
							Value = "%BQUOTE(%CMPRES(%qSCAN(&InParam,&_i,%STR( ))))";
						%END;
						%ELSE %DO;
							Value = "%BQUOTE(%SCAN(%CMPRES(%qSCAN(&InParam,&_i,%STR( ))),&o,%STR( )))";
						%END;
						rca=h.add();
					%END;
				 	%DO _j = &r %TO &r;
						Key = %EVAL(6*(&_j.-1)+1 +20);
						Parameter = "RF&_j";
						Value = "%CMPRES(&&RF&_j)";
						rca=h.add();
						Key = %EVAL(6*(&_j.-1)+2 +20);
						Parameter = "RFtype&_j";
						Value = "%CMPRES(&&RFtype&_j)";
						rca=h.add();
						Key = %EVAL(6*(&_j.-1)+3 +20);
						Parameter = "RFband&_j";
						Value = "%CMPRES(&&RFband&_j)";
						rca=h.add();
						Key = %EVAL(6*(&_j.-1)+4 +20);
						Parameter = "RFmid&_j";
						Value = "%CMPRES(&&RFmid&_j)";
						rca=h.add();
						Key = %EVAL(6*(&_j.-1)+5 +20);
						Parameter = "Cent&_j";
						Value = "%CMPRES(&&Cent&_j)";
						rca=h.add();
						Key = %EVAL(6*(&_j.-1)+6 +20);
						Parameter = "RFbase&_j";
						Value = "%CMPRES(&&RFbase&_j)";
						rca=h.add();
					%END;
					%DO _k = 21 %TO &N_InParam;
						Key = %EVAL(&_k. + 20 +  &N_RF*6);
						Parameter = "%qsubstr(%qSCAN(&InParam,&_k,%STR( )),2)";
						Value = "%CMPRES(%SCAN(&InParam,&_k,%STR( )))";
						rca=h.add();
					%END;
					Key = Key +1;
					Parameter = "Model";
					Value = "&&PStmtr&r.o&o.";
					rca=h.add();

				*** Class statement;
					%IF "&&CStmtr&r.o&o." ne " " %THEN %DO;
						Key = Key +1;
						Parameter = "Model";
						Value = "&&CStmtr&r.o&o.";
						rca=h.add();
					%END;
				*** Model statement;
					Key = Key +1;
					Parameter = "Model";
					Value = "&&MStmtr&r.o&o.";
					rca=h.add();
				*** Strata statement;
					%IF ("&ALY" eq "SIM" or "&ALY" eq "MUL")  and  "&Strata" eq "&Space" %THEN %DO; %END;
					%ELSE %DO;
						Key = Key +1;
						Parameter = "Model";
						Value = "&&SStmtr&r.o&o.";
						rca=h.add();
					%END;
				*** Run statement;
					Key = Key +1;
					Parameter = "Model";
					Value = "&Rstmt";
					rca=h.add();

				*** Control file path and name;
					%Let cf = %sysget(SAS_EXECFILEPATH);
					Key = Key +1;
					Parameter = "Control file";
					Value = "&cf";
					rca=h.add();

					rco = h.output(dataset: "work._CSVheadr&r.o&o._");
				stop;
			run; quit;

			proc template;
			define tagset tagsets.newcsv;
			parent = tagsets.csv;
			notes "This is the CSV definition";
			define event table;
			end;

			define event row;
			finish:/* We added finish: */
			put NL;/* This makes it so that the line is put at the finish of the even row instead of every event row.*/
			end;
			end;
			run;

			PROC PRINTTO PRINT= "%sysfunc(Getoption(WORK))\csv_result000000000000000.txt";

			ODS RESULTS OFF; 
			ods tagsets.newcsv body="&OutputDir.\&Project &ThisRF. &ThisOutcome. &_datetime..csv" ;

			proc print data = work._CSVheadr&r.o&o._ noobs;
			var Parameter value;
			run;

			proc sql;
				select distinct 
					case when a.DF ne . then 'Fit_Statistics'
						 else 'ENDHEADER'
					end as Fit_Statistics
					, Test, Criterion, WithoutCovariates, WithCovariates, ChiSq, a.DF, ProbChiSq
				from work.Fit_&ThisRF._&ThisOutcome	as a union join (select distinct . as DF from work.Fit_&ThisRF._&ThisOutcome) as b
				order by DF desc
				;

			%IF %EVAL(&NLObs eq 1) %THEN %DO;
			proc print data = CSV_&ThisRF._&ThisOutcome. noobs;
				var RF	NEvents	NObs	PYears	Estimate	StdErr	HR	LowerCL	UpperCL	REGTIM	FIRST	LAST;
			run;
			%END;
			%ELSE %DO;
			proc print data = CSV_&ThisRF._&ThisOutcome. noobs;
			run;
			%END;

			ods tagsets.newcsv close;
			ODS RESULTS ON; 

			PROC PRINTTO PRINT= PRINT;

			filename tempout "%sysfunc(Getoption(WORK))\csv_result000000000000000.txt";
			data _NULL_;
			rc = fdelete('tempout');		
			run;
			filename tempout clear;

			%IF %SYSFUNC(fileexist("&OutputDir.\&Project &ThisRF. &ThisOutcome. &_datetime..csv")) %THEN %DO;
				Filename Tfile "&OutputDir.\&Project &ThisRF. &ThisOutcome. &_datetime..csv";
				Data _fileCreateInfo_;
					Format FileTime datetime20.;
					Open = FOPEN('Tfile');
					Time = FINFO(Open,'Last Modified');
					FileTime = input(scan(Time,1,' ')||substr(scan(Time,2,' '),1,3)||scan(Time,3,' ')||':'||scan(Time,4,' '),datetime20.);
					Close = FCLOSE(Open);
					Drop Time;
				run;
				Filename Tfile clear;

				Proc SQL noprint;
					insert into __DataCreated__
					select "CSV", "&OutputDir.","&Project &ThisRF. &ThisOutcome. &_datetime..csv", FileTime
					from _fileCreateInfo_
					where Open > 0 and FileTime > &_starttime;
			%END;
		%END;
	%END;
%END;
quit;

%MEND CSV;

%CSV;

