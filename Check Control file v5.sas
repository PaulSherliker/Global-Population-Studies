


%Macro CheckInParam;
%LET Df = %NRSTR(RunTypeDf AnalysisDf ProjectDf ProjDescDf RunDescDf InputDirDf InputFileDf OutputDirDf IDDf
						LowFUDf HighFUDf StartDateDf EndDateDf LowAgeDf HighAgeDf WhereStmtDf OutcomeDf CensorValueDf CensorDateDf StudyDateDf TimeUnitDf  TimeVarDf
						RFDf RFbandDf RFmidDf CentDf RFbaseDf
						CovarsDf CovClassDf CovOrderDf CovBaseDf StrataDf DobDf XAgeDf AgeBandDf AgeMidDf);

%DO _df = 1 %TO %EVAL(1 + %QSYSFUNC(Count(%cmpres(&Df),%STR( ))));
	%GLOBAL %SCAN(&Df,&_df,%STR( ));
	%LET %SCAN(&Df,&_df,%STR( )) = 0;
%END;

%CheckPart1;**;
%CheckTimeVar;
%RequiredFilled;
%DirExist(InputDir);
%DirExist(OutputDir); 
%IF &NonExistInputDir ne 0 and &NonExistOutputDir ne 0 %THEN %DO; 
	%GLOBAL OutputDir;
	%LET OutputDir =  %_grabpath_; 
%END;
%IF &NonExistInputDir = 0 and &NonExistOutputDir ne 0 %THEN %DO; 
	%GLOBAL OutputDir;
	%LET OldOutputDir = &OutputDir;
	%LET OutputDir = %CMPRES(&InputDir\Output &_date);
	%DirExist(OutputDir);
	%IF &NonExistOutputDir = 1 %THEN %DO;
		Data _NULL_;
			OutputDir=dcreate("Output &_date","&InputDir\");
		run;
	%END;
	%LET NonExistOutputDir = 1;
	%LET OutputDirDf = 1;
	%IF &OldOutputDir eq &Space %THEN %DO;********;
		%LET NonExistOutputDir = 0;********;
	%END;********;
%END;

%IF &ReqUnfilled = 1 or &NonExistInputDir ne 0 %THEN %DO;	%GOTO Exit;	%END;
%ELSE %DO; 
	%FileExist;
	%IF &NonExistInputFile ne 0 %THEN %DO; %GOTO Exit; %END;
	%ELSE %DO;
		%CheckVarName(ID);
		%CheckVarName(Outcome);
		%CheckVarName(CensorDate);
		%CheckVarName(StudyDate);
		%CheckVarName(RF);
		%CheckVarName(Covars);
		%CheckVarName(Strata);
		%CheckVarName(Dob);
		%IF %EVAL	(&IDNameErr + &OutcomeNameErr + &CensorDateNameErr + &StudyDateNameErr + &RFNameErr + &CovarsNameErr + &StrataNameErr + &DobNameErr
					+ &Part1Err + &TimeErr) = 0 %THEN %DO;
			%DataNameLen;
			%IF %EVAL(&DataNameLenErr = 0) %THEN %DO;
				%CheckQuote(%bquote(&WhereStmt),WhereErr);
				%IF %EVAL(&WhereErr = 0) %THEN %DO;
					%CheckVarExist;
					%CheckCensorDate;
					%CheckStudyDate;
					%CheckDob;
					%CheckID;
					%CheckVarEqual;
					%CheckRFequal;
					%IF &NonExistVar ne 0 or &MatchVarErr ne 0 or &CensorDateErr ne 0 or &StudyDateErr ne 0 or &IDerr ne 0 or &DobErr ne 0 or &RFequalErr ne 0 %THEN %DO; %GOTO Exit; %END;
					%ELSE %DO;  
						%CheckPart2;**;
						%CheckPart3;
						%CheckRF; **;
						%CheckCV;
						%IF %SYMEXIST(Strata) =0 or "&Strata" eq "&Empty"  or "&Strata" eq "&Space" %THEN %DO;
							%LET StrataDf = 1;
							%LET Strata = &Space;
						%END;
						%CheckAge;
					%END;
				%END;
			%END;
		%END;
	%END;
%END; 
%EXIT: ;;
%mend CheckInParam;

%CheckInParam;



%Macro AnyError;
%GLOBAL ParamError;
%Let ErrorMV =	ReqUnfilled NonExistInputDir NonExistInputFile  
				IDNameErr OutcomeNameErr RFNameErr CovarsNameErr StrataNameErr DobNameErr CensorDateNameErr StudyDateNameErr DataNameLenErr
				CensorDateErr StudyDateErr DobErr IDErr NonExistVar MatchVarErr RFequalErr WhereErr
				Part1Err Part2Err Part3Err RFerr CVerr AgeErr TimeErr
				AnyObsDataErr NoCensorVal; *NonExistOutputDir;
%Let N_ErrorMV = %EVAL(%QSYSFUNC(count(%cmpres(&ErrorMV),%STR( ))) + 1);

%DO d = 1 %TO &N_ErrorMV;
	%LET ThisErr = %CMPRES(%SCAN(&ErrorMV,&d,%STR( )));
	%IF %SYMEXIST(&ThisErr) = 0 %THEN %DO;	%GLOBAL &ThisErr; %LET &ThisErr = 0; %END;
%END;

/*Check Control file macro variables*/
%IF %EVAL(( &ReqUnfilled + &NonExistInputDir + &NonExistInputFile  + &DataNameLenErr + 
			&IDNameErr + &OutcomeNameErr + &RFNameErr + &CovarsNameErr + &StrataNameErr + &DobNameErr + &CensorDateNameErr + &StudyDateNameErr +
			&CensorDateErr + &StudyDateErr + &DobErr + &IDErr + &NonExistVar + &MatchVarErr + &RFequalErr + &WhereErr +
			&Part1Err + &Part2Err + &Part3Err + &RFerr + &CVerr + &AgeErr + &TimeErr +
			&AnyObsDataErr + &NoCensorVal 
			) > 0) %THEN %DO; *+ &NonExistOutputDir;
	%LET ParamError = 1; 
%END;
%ELSE %DO; 
	%LET ParamError = 0; 
%END; 
/*%PUT ParamError = &ParamError;*/
%Mend AnyError;

%AnyError;

