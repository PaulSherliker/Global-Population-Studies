/*========================================================================================
Part 1. - Type of run
		- Type of analysis
		- Input SAS data file for analysis and its directory
		- Output directory
========================================================================================*/
%GLOBAL NonExistVarname;
%LET NonExistVarname = %STR( );

%GLOBAL N_RF N_RFbandErr N_RFmidErr N_CentErr N_RFbaseErr RFbandBrktErr RFmidBrktErr RFfmtErr;
%LET N_RF = 0; %LET N_RFbandErr = 0;	%LET N_RFmidErr = 0;	%LET N_CentErr = 0;	%LET N_RFbaseErr = 0;
%LET RFbandBrktErr = 0; %LET  RFmidBrktErr = 0; %LET RFfmtErr = 0;

%Macro CheckMinMax(Data = , Var = );
%GLOBAL Minimum Maximum;
proc capability data =  &Data (keep = &Var) NOPRINT;
	var  &Var;
	output out = _min_max_ pctlpts= 0 100 PCTLPRE= _ ;
run;quit;

Data _NULL_;
	set _min_max_ ;
	call symput("Minimum",_0);
	call symput("Maximum",_100);
run;

proc datasets library = work  NODETAILS NOLIST;
	delete  _min_max_ ;
run; quit;
/*
%PUT Min= &Minimum Max = &Maximum;
*/
%Mend CheckMinMax;

%Macro RequiredFilled;
%GLOBAL ReqUnfilled  AnaBlank InDBlank InFBlank OutBlank  RF_Blank RFband_Blank RFmid_Blank Cent_Blank RFbase_Blank TUnit_Blank TVar_Blank;
%LET AnaBlank = 1; 
%LET InDBlank = 1; 	%LET InFBlank = 1; 
%LET OutBlank = 1; 	
%LET RF_Blank = 1; 	%LET RFband_Blank = 1;	%LET RFmid_Blank = 1;	%LET Cent_Blank = 1;	%LET  RFbase_Blank = 1;
%LET TUnit_Blank = 1; 	%LET TVar_Blank = 1;
%IF %SYMEXIST(Analysis) 	%THEN %DO; %IF "&Analysis"		ne "&Empty" and "&Analysis"		ne "&Space" %THEN %DO; %LET AnaBlank = 0; %END;	%END;	 
%IF %SYMEXIST(InputDir) 	%THEN %DO; %IF "&InputDir" 		ne "&Empty" and "&InputDir" 	ne "&Space" %THEN %DO; %LET InDBlank = 0; %END;	%END;	 
%IF %SYMEXIST(InputFile)	%THEN %DO; %IF "&InputFile"		ne "&Empty" and "&InputFile"	ne "&Space" %THEN %DO; %LET InFBlank = 0; %END;	%END;	 
%IF %SYMEXIST(Outcome) 		%THEN %DO; %IF "&Outcome" 		ne "&Empty" and "&Outcome" 		ne "&Space" %THEN %DO; %LET OutBlank = 0; %END;	%END;	 
%IF %SYMEXIST(RF) 			%THEN %DO; %IF "&RF"			ne "&Empty" and "&RF"			ne "&Space" %THEN %DO; %LET RF_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(RFband) 		%THEN %DO; %IF "&RFband"		ne "&Empty" and "&RFband"		ne "&Space" %THEN %DO; %LET RFband_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(RFmid) 		%THEN %DO; %IF "&RFmid"			ne "&Empty" and "&RFmid"		ne "&Space" %THEN %DO; %LET RFmid_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(Cent) 		%THEN %DO; %IF "&Cent"			ne "&Empty" and "&Cent"			ne "&Space" %THEN %DO; %LET Cent_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(RFbase) 		%THEN %DO; %IF "&RFbase"		ne "&Empty" and "&RFbase"		ne "&Space" %THEN %DO; %LET RFbase_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(TimeUnit) 	%THEN %DO; %IF "&TimeUnit"		ne "&Empty" and "&TimeUnit"		ne "&Space" %THEN %DO; %LET TUnit_Blank = 0; %END;	%END;	 
%IF %SYMEXIST(TimeVar) 		%THEN %DO; %IF "&TimeVar"		ne "&Empty" and "&TimeVar"		ne "&Space" %THEN %DO; %LET TVar_Blank = 0; %END;	%END;	 
%IF %EVAL((&AnaBlank + &InDBlank + &InFBlank + &OutBlank + &RF_Blank + &RFband_Blank + &RFmid_Blank + &Cent_Blank + &RFbase_Blank
			+ &TUnit_Blank + &TVar_Blank) > 0) %THEN %DO; 
	%LET ReqUnfilled = 1; 
%END;
%ELSE %DO; 
	%LET ReqUnfilled = 0; 
%END; 
%IF %SYMEXIST(RunType) = 0 or "&RunType" eq "&Empty"  or "&RunType" eq "&Space" %THEN %DO;
	%LET RunType = CHECK;
	%LET RunTypeDf = 1;
%END;
%Mend RequiredFilled;

%Macro DirExist(string);
%GLOBAL NonExist&string.;
%IF %SYMEXIST(&string.) %THEN %DO;
	%IF %QSUBSTR(&&&string,%EVAL(%LENGTH(&&&string)),1) = %STR(\) or %QSUBSTR(&&&string,%EVAL(%LENGTH(&&&string)),1) = %STR(/) %THEN %DO;
		%LET &string = %SUBSTR(&&&string,1,%EVAL(%LENGTH(&&&string)-1));
	%END;

	%LET Ref   = InDir;
	%LET Dref  = %SYSFUNC(filename(Ref,"&&&string"));	/*%Put Dref = &Dref;*/
	%LET Did = %SYSFUNC(dopen(&Ref));	/*%PUT Did = &Did;*/
		 %IF &Did = 0 %THEN %DO;	%LET NonExist&string. = 1; %END;
		 %ELSE 				%DO; 	%LET NonExist&string. = 0; %END;
	%LET Dclose= %SYSFUNC(dclose(&Did));	/*%Put Dclose = &Dclose;*/
	%IF "&&&string" = "&Empty" or "&&&string" = "&Space" %THEN %DO;	%LET NonExist&string. = 1; %END;
%END;
%ELSE %DO;
	%LET NonExist&string. = 1;
%END;
%Mend DirExist;

%Macro FileExist;
%GLOBAL NonExistInputFile;
%LET NonExistInputFile = %Sysfunc(abs(%SYSFUNC(fileexist("&InputDir.\&InputFile..SAS7BDAT"))-1)); 
/*%put NonExistInputFile = &NonExistInputFile;*/
%IF &NonExistInputFile eq 0 %THEN %DO; 
	Libname InLib "&InputDir";***********************************************************************;
	
	%let dsid=%SYSFUNC(open(InLib.&InputFile,i));
	%let anyobs = %SYSFUNC(ATTRN(&dsid,ANY)) ;
	%LET Dclose= %SYSFUNC(close(&dsid));	/*%Put Dclose = &Dclose;*/
	%IF &anyobs ne 1 %THEN %DO;
		%LET NonExistInputFile = 1;
	%END;
%END;
%Mend FileExist;

%Macro CheckVarName(Parameter);
%GLOBAL &Parameter.NameErr;
%LET &Parameter.NameErr = 0;
%IF %SYMEXIST(&Parameter) and "&&&Parameter" ne "&Empty"  and "&&&Parameter" ne "&Space" %THEN %DO;		
	Data _NULL_; 
		Array LogicSign {23} $ _TEMPORARY_ ('AND' 'OR' 'NOT' 'EQ' 'NE' 'LE' 'LT' 'GE' 'GT' 'IN'  'IF' 'THEN' 'ELSE' 'UNTIL' 'WHILE' 'DO' 'END' 'IS' 'NULL' 'MISSING' 'LIKE' 'BETWEEN' 'CONTAINS');
		AnyLogic = 0;
		String = upcase(strip(compbl("&&&Parameter")));  
		N = 1 + count(strip(compbl(String)),' ');
		do i = 1 to N;
			Varname = compbl(strip(scan(String, i, ' ')));;	
			do j = 1 to dim(LogicSign);	
				AnyLogic = AnyLogic + (Varname = LogicSign{j}); 			
			end;
			if anyfirst(Varname) ne 1 or AnyLogic > 0  then do; call symput("&Parameter.NameErr",1);  end;
			AnyLogic = 0;
		end;
	run;
%END;
/*%PUT &Parameter.NameErr = &&&Parameter.NameErr;*/
%Mend CheckVarName;

%Macro DataNameLen;
%GLOBAL DataNameLenErr DataNameLenErrV;		%LET DataNameLenErr = 0;	%LET DataNameLenErrV = ;

%LET N_O = %EVAL(%QSYSFUNC(Count(%cmpres(&Outcome dummyvar),%STR( ))));		
%LET N_R = %EVAL(%QSYSFUNC(Count(%cmpres(&RF dummyvar),%STR( ))));			

%DO i = 1 %TO &N_O;
	%DO j = 1 %TO &N_R;
		%LET ThisOutcome = %SCAN(&Outcome,&i, %STR( ));	
		%LET ThisRF = %SCAN(&RF,&j, %STR( ));			
															/*		%PUT FileNameCombination = %Substr(%SYSFUNC(compress(%UPCASE(&Analysis),,"kdlu")),1,3)_&ThisOutcome._&ThisRF;*/
		%IF %SYSFUNC(NVALID(Data_&ThisOutcome._&ThisRF)) = 0 %THEN %DO; 
			%LET DataNameLenErr = %EVAL(&DataNameLenErr + 1);
			%LET DataNameLenErrV = &DataNameLenErrV.%STR(, )&ThisOutcome.%STR( & )&ThisRF.;
		%END;
	%END;
%END;
%IF &DataNameLenErr ne 0 %THEN %DO;
	%LET DataNameLenErrV = %SUBSTR(&DataNameLenErrV.,3);
%END;
%Mend DataNameLen;

%Macro CheckCensorDate;
%Global CensorDateErr ;
%LET CensorDateErr = 0;	

%IF &CensorDateNameErr eq 0 and &NonExistVar eq 0 %THEN %DO;
	%IF %SYMEXIST(CensorDate) = 0 or "&CensorDate" eq "&Empty" or "&CensorDate" eq "&Space" %THEN %DO;
	/*	%GLOBAL CensorDate;
		%LET CensorDate = Censoring_date; 
		%LET CensorDateDf = 1;*/
	%END;
	%ELSE %DO;
		%IF %EVAL(%QSYSFUNC(Count(%cmpres(&CensorDate dummyvar),%STR( )))) ne 1 %THEN %DO;
			%LET CensorDateErr = %EVAL(&CensorDateErr + 1);
		%END;
		%ELSE %DO;
			Libname TempLib "&InputDir";
			%CheckVarFormat(Data = TempLib.&InputFile, Var=&CensorDate, Fmt= VFmt);
			%IF %SUBSTR(&Vfmt,1,1) ne D %THEN %LET CensorDateErr = %EVAL(&CensorDateErr + 1);
			Libname TempLib ;
		%END;
	%END;
%END;
%Mend CheckCensorDate;

%Macro CheckStudyDate;
%Global StudyDateErr ;
%LET StudyDateErr = 0;	

%IF &StudyDateNameErr eq 0 and &NonExistVar eq 0 %THEN %DO;
	%IF %SYMEXIST(StudyDate) = 0 or "&StudyDate" eq "&Empty" or "&StudyDate" eq "&Space" %THEN %DO;
	/*	%GLOBAL StudyDate;
		%LET StudyDate = Study_date; 
		%LET StudyDateDf = 1;*/
	%END;
	%ELSE %DO;
		%IF %EVAL(%QSYSFUNC(Count(%cmpres(&StudyDate dummyvar),%STR( )))) ne 1 %THEN %DO;
			%LET StudyDateErr = %EVAL(&StudyDatEerr + 1);
		%END;
		%ELSE %DO;
			Libname TempLib "&InputDir";
			%CheckVarFormat(Data = TempLib.&InputFile, Var=&StudyDate, Fmt= VFmt);
			%IF %SUBSTR(&Vfmt,1,1) ne D %THEN %LET StudyDateErr = %EVAL(&StudyDateErr + 1);
			Libname TempLib ;
		%END;
	%END;
%END;
%Mend CheckStudyDate;

%Macro CheckID;
%GLOBAL IDerr  IDNotUniqueErr;
%LET IDerr = 0; 	%LET IDNotUniqueErr = 0;

%IF &IDNameErr eq 0 and &NonExistVar eq 0 %THEN %DO;											
	%IF %SYMEXIST(ID) = 0 or "&ID" eq "&Empty" or "&ID" eq "&Space" %THEN %DO;					
	/*	%GLOBAL ID;
		%LET ID = StudyID;
		%LET IDDf = 1;*/
	%END;
	%ELSE %DO;																					
		%IF %EVAL(%QSYSFUNC(Count(%cmpres(&ID dummyvar),%STR( )))) ne 1 %THEN  %DO;
			%LET IDerr = 1;																		
		%END;
		%ELSE %DO;																				
			Libname TempLib "&InputDir";
			%CheckVarFormat(Data = TempLib.&InputFile, Var=&ID, Fmt= IDFmt);
			Libname TempLib ;																	
			%IF &IDFmt ne NUM and &IDFmt ne CHAR %THEN %DO;
				%LET IDerr = 1;
			%END;
			%ELSE %DO;
				Libname TempLib "&InputDir";
					proc sql noprint;
					select count(*) into:IDNotUniqueErr
					from	(	select &ID, count(*) as count
								from TempLib.&InputFile (keep = &ID)
								group by 1
								having calculated count > 1
							);
				Libname TempLib ;			
				%LET IDerr = %EVAL(&IDerr + &IDNotUniqueErr);
			%END;
		%END;
	%END;
%END;
%Mend CheckID;

%MACRO AnyMatchVar(String1,String2,ThisError);
%GLOBAL &ThisError;
%LET &ThisError = 0;
	%DO i = 1 %TO %EVAL(1 + %QSYSFUNC(Count(%cmpres(&String1),%STR( ))));
		%LET This1 = %UPCASE(%SCAN(%cmpres(&String1),&i));		
		%DO j = 1 %TO %EVAL(1 + %QSYSFUNC(Count(%cmpres(&String2),%STR( ))));	
			%LET This2 = %UPCASE(%SCAN(%cmpres(&String2),&j));	
			%IF &This1 eq &This2 %THEN %DO;
				%LET &ThisError = %EVAL(&&&ThisError + 1); 			
			%END;
		%END;
	%END;
%MEND AnyMatchVar;

%Macro CheckVarEqual;
%GLOBAL MatchVarErr;
%LET RunString = ID Outcome Outcome_Date RF Covars Strata Dob CensorDate StudyDate;
%LET MatchVarErr = 0;
%DO a = 1 %TO 9;
	%DO b = 1 %TO 9;
		%IF &a ge &b or (&a eq 2 and &b eq 3) or (&a eq 4 and &b eq 5) %THEN %DO; %END;
		%ELSE %DO;
			%LET ThisA = %SCAN(&RunString,&a,%STR( )); 		
			%LET ThisB = %SCAN(&RunString,&b,%STR( ));		
			%LET AeqB = &ThisA.eq&ThisB.; 					
			%GLOBAL &AeqB;
			%IF ("&&&ThisA" eq "&Empty" or "&&&ThisA" eq "&Space") and ("&&&ThisB" eq "&Empty" or "&&&ThisB" eq "&Space") %THEN %DO;
				%LET &AeqB = 0; 
			%END;
			%ELSE %DO;
				%AnyMatchVar(&&&ThisA, &&&ThisB, &AeqB);		
			%END;
			%LET MatchVarErr = %EVAL(&MatchVarErr + &&&AeqB);
		%END;
	%END;
%END;
%Mend CheckVarEqual;


%MACRO CheckRFequal;
%GLOBAL RFequalErr;
%LET RFequalErr = 0;
	%DO i = 1 %TO %EVAL(1 + %QSYSFUNC(Count(%cmpres(&RF),%STR( ))));
		%LET This1 = %UPCASE(%SCAN(%cmpres(&RF),&i));		
		%DO j = 1 %TO %EVAL(1 + %QSYSFUNC(Count(%cmpres(&RF),%STR( ))));	
			%LET This2 = %UPCASE(%SCAN(%cmpres(&RF),&j));	
			%IF &This1 eq &This2 and &i ne &j %THEN %DO;
				%LET RFequalErr = %EVAL(&RFequalErr + 1); 			
			%END;
		%END;
	%END;
%MEND CheckRFequal;

%Macro CheckQuote(String,Error);
%GLOBAL &Error;
	%LET countbrackets = 0;
	%LET error_nesting = 0;
	%do i = 1 %to %length(%BQUOTE(&String));				
		%if %qsubstr(%BQUOTE(&String),&i,1) eq %STR(%() %then %DO; %LET countbrackets = %EVAL(&countbrackets + 1); %END;
		%else %IF %qsubstr(%BQUOTE(&String),&i,1) eq %STR(%)) %THEN %DO; %LET countbrackets = %EVAL(&countbrackets - 1);  %END;
	%end;
	%if %EVAL(&countbrackets^=0) %then %LET error_nesting = %EVAL(&error_nesting+1); 
	%LET &Error = &error_nesting;				
%Mend CheckQuote;


%Macro DelQuotes(InString = , OutString = , delim = );
%GLOBAL &OutString;																									
       %LET original = %QSYSFUNC(translate(%SUPERQ(InString),%STR(                ), %STR(+-*/<>=¬^~,?%%))); 		
		%LET N = %LENGTH(&InString);  
       %LET OpenPos = %INDEX(&original,&delim); 
       %DO %while (&N > 0 and &OpenPos > 0);
              %LET FrontWord = %QSUBSTR(&original,1,%EVAL(&OpenPos-1));
              %LET ClosePos = %INDEX(%QSUBSTR(&original,%EVAL(&OpenPos+1)),&delim);
              %LET BackWord = %QSUBSTR(&original,%EVAL(&OpenPos+&ClosePos+1)); 
              %LET Original = &FrontWord.%STR( )&BackWord;
              %LET N = %LENGTH(&BackWord);
              %LET OpenPos = %INDEX(&original,&delim); 
       %END; 
       %LET &OutString = &Original; 
%Mend DelQuotes;

%Macro CheckVarExist;
/*----------------Get default values for ID, CensorDate, StudyDate, Dob-----------------*/
%IF %SYMEXIST(CensorDate) = 0 or "&CensorDate" eq "&Empty" or "&CensorDate" eq "&Space" %THEN %DO;
	%GLOBAL CensorDate;
	%LET CensorDate = Censoring_date; 
	%LET CensorDateDf = 1;
%END;

%IF %SYMEXIST(StudyDate) = 0 or "&StudyDate" eq "&Empty" or "&StudyDate" eq "&Space" %THEN %DO;
	%GLOBAL StudyDate;
	%LET StudyDate = Study_date; 
	%LET StudyDateDf = 1;
%END;

%IF %SYMEXIST(ID) = 0 or "&ID" eq "&Empty" or "&ID" eq "&Space" %THEN %DO;					
	%GLOBAL ID;
	%LET ID = StudyID;
	%LET IDDf = 1;
%END;

%IF %SYMEXIST(Dob) ne 1 or "&Dob" eq "&Empty" or "&Dob" eq "&Space" %THEN %DO;
	%GLOBAL Dob;
	%LET Dob = DOB;
	%LET DobDf = 1;
%END;
/*-------------------------------------------------------------------------------------------*/
%GLOBAL KeepVar NonExistVar Outcome_Date KeepVarNoRF;
%LET KeepVar = %STR( );
%IF %SYMEXIST(WhereStmt) = 0 or %LENGTH(&WhereStmt) eq 0 %THEN %DO;
	%LET final = %STR( );
%END;
%ELSE %DO;
	%DelQuotes(InString = &wherestmt, OutString = DeSingle, delim = %STR(%'));		
	%DelQuotes(InString = &DeSingle, OutString = DeDouble, delim = %STR(%"));		
	%LET wherestmt1 = %BQUOTE(%QUPCASE(&DeDouble)); 					

	%DO i = 1 %TO &N_f;
		data _null_; call symput("wherestmt1",prxchange("s/(&&F&i\s{0,}\()\s{0,}((\S{0,}?\s{0,}?){0,}\S{0,}?)\s{0,}(\))/$2/",-1, "&wherestmt1")); run;
	%END;																
	%LET wherestmt2 = %BQUOTE(&wherestmt1);								

	data _null_; call symput("wherestmt3",prxchange('s/\W\d{1,2}\D{3}\d{2,4}\WD{1}/ /',-1, "&wherestmt2")); run;		
	%LET wherestmt3 = %BQUOTE(&wherestmt3);								

	%LET final = %QSYSFUNC(translate(%SUPERQ(wherestmt3),%STR(                ), %STR(+-*/<>=¬^~,()?%%))); 			
%END;	

Data _AllKeepVar_; 
	Array LogicSign {23} $ _TEMPORARY_ ('AND' 'OR' 'NOT' 'EQ' 'NE' 'LE' 'LT' 'GE' 'GT' 'IN'  'IF' 'THEN' 'ELSE' 'UNTIL' 'WHILE' 'DO' 'END' 'IS' 'NULL' 'MISSING' 'LIKE' 'BETWEEN' 'CONTAINS');
	AnyLogic = 0;
	OutLogic = 0;
	Length Outcome_Date $2000;
	Outcome_Date = ' ';
	String = upcase(strip(compbl("&final"||" "||"&ID"||" "||"&RF"||" "||"&Covars"||" "||"&Strata"||" "||"&Dob"||" "||"&CensorDate"||" "||"&StudyDate"))); 
	N = 1 + count(strip(compbl(String)),' ');
	do i = 1 to N;
		Varname = compbl(strip(scan(String, i,' '))); 
		do j = 1 to dim(LogicSign);	
			AnyLogic = AnyLogic + indexw(Varname,LogicSign{j}); 
		end;
		if (ANYALPHA(Varname) = 1 and AnyLogic = 0) or substr(Varname,1,1) = '_' then do;  output; end;
		AnyLogic = 0;
	end;
	OutcomeString = upcase(strip(compbl("&Outcome"))); 
	M = 1 + count(strip(compbl(OutcomeString)),' ');
	do p = 1 to M;
		Varname = compbl(strip(scan(OutcomeString, p)));
		do q = 1 to dim(LogicSign);	
			OutLogic = OutLogic + indexw(Varname,LogicSign{q}); 
		end;
		if (ANYALPHA(Varname) = 1 and OutLogic = 0) or substr(Varname,1,1) = '_' then do;
			output;
			Varname = CATT(Varname,'_DATE'); 
			output;
			Outcome_Date = CATX(' ',Outcome_Date,Varname); 
		end;
		OutLogic = 0;
	end;
	call symputx ('Outcome_Date' , Outcome_Date) ;                                                 
	drop String AnyLogic N i j OutcomeString OutLogic M p q Outcome_Date; 
run;

proc sort data = _AllKeepVar_ out = _NoDupKeepVar_ nodupkey; by Varname; run;
proc sql noprint; select distinct Varname into:KeepVar separated by ' ' from _nodupkeepvar_; quit;

Libname TempLib "&InputDir";
proc contents data = TempLib.&InputFile short varnum out = _OrigAllVar_(Keep = NAME) noprint; run;
Data _OrigAllVar_; set _OrigAllVar_; Varname = upcase(NAME); drop NAME; run;
Libname TempLib ;

Data _NonExistVar_;  
	NonExistVar = 0; 
	dcl hash InData   (dataset: '_OrigAllVar_') ;                                     
	InData.defineKey  ('VarName');                                                              
	InData.defineDone () ;                                                                    
                                                                                           
	do N = 1 by 1 until (eof) ;                                                                 
		set _NoDupKeepVar_ end = eof ;                                        
		if InData.check() NE 0 then do;
			NonExistVar ++ 1 ;                                              
			output;
		end;
	end ;                                                                                       
                                                                                               
	call symputx ('NonExistVar' , NonExistVar) ;                                                 
	stop ;                                                                                      
run;   
proc sql noprint; select distinct Varname into:NonExistVarname separated by ' ' from _NonExistVar_; quit;

/*without inclusion of RF;*/
Data _KeepVarNoRF_; 
	Array LogicSign {23} $ _TEMPORARY_ ('AND' 'OR' 'NOT' 'EQ' 'NE' 'LE' 'LT' 'GE' 'GT' 'IN'  'IF' 'THEN' 'ELSE' 'UNTIL' 'WHILE' 'DO' 'END' 'IS' 'NULL' 'MISSING' 'LIKE' 'BETWEEN' 'CONTAINS');
	AnyLogic = 0;
	OutLogic = 0;
	Length Outcome_Date $2000;
	Outcome_Date = ' ';
	String = upcase(strip(compbl("&final"||" "||"&ID"||" "||"&Covars"||" "||"&Strata"||" "||"&Dob"||" "||"&CensorDate"||" "||"&StudyDate"))); 
	N = 1 + count(strip(compbl(String)),' ');
	do i = 1 to N;
		Varname = compbl(strip(scan(String, i)));
		do j = 1 to dim(LogicSign);	
			AnyLogic = AnyLogic + indexw(Varname,LogicSign{j}); 
		end;
		if (ANYALPHA(Varname) = 1 and AnyLogic = 0) or substr(Varname,1,1) = '_' then output;
		AnyLogic = 0;
	end;
	OutcomeString = upcase(strip(compbl("&Outcome"))); 
	M = 1 + count(strip(compbl(OutcomeString)),' ');
	do p = 1 to M;
		Varname = compbl(strip(scan(OutcomeString, p)));
		do q = 1 to dim(LogicSign);	
			OutLogic = OutLogic + indexw(Varname,LogicSign{q}); 
		end;
		if (ANYALPHA(Varname) = 1 and OutLogic = 0) or substr(Varname,1,1) = '_' then do;
			output;
			Varname = CATT(Varname,'_DATE'); 
			output;
			Outcome_Date = CATX(' ',Outcome_Date,Varname); 
		end;
		OutLogic = 0;
	end;
	call symputx ('Outcome_Date' , Outcome_Date) ;                                                 
	drop String AnyLogic N i j OutcomeString OutLogic M p q Outcome_Date; 
run;

proc sort data = _KeepVarNoRF_ out = _NoDupKeepVarNoRF_ nodupkey; by Varname; run;
proc sql noprint; select distinct Varname into:KeepVarNoRF separated by ' ' from _NoDupKeepVarNoRF_; quit;

/*Check reserved var names*/
Data _ReserveVar_;
	set _ReserveVar_;
	Varname = upcase(varname);
run;

data _MatchVar_; ****	Need to delete this later;
	length Varname $32;
	if _n_=1 then do;
		declare hash dr(dataset:'_ReserveVar_');
		dr.definekey("Varname");
		dr.definedata("Varname");
		dr.definedone();
		call missing(Varname);
	end;
	set _OrigAllVar_;
	rc=dr.find(key: Varname);
	if rc eq 0 then output;
	drop rc;
run;

%GLOBAL SameVarWarn;
proc sql noprint;
	select Varname into : SameVarWarn separated by ', ' from _MatchVar_;

%Mend CheckVarExist;

%Macro CheckPart1;
%GLOBAL Part1Err RunTypeErr ProjectErr AnalysisTypeErr ALY;
%LET Part1Err = 0;		%LET RunTypeErr = 0;	%LET ProjectErr = 0;	%LET AnalysisTypeErr = 0;	

%IF %SYMEXIST(Project) = 0 or "&Project" eq "&Empty" or "&Project" eq "&Space" %THEN %DO;
	%GLOBAL Project;
	%LET Project =&Empty;			
	%LET ProjectDf = 1;
%END;
%ELSE %DO;
	%IF %INDEX(%CMPRES(&Project),%STR( )) > 0 %THEN %DO;		%LET ProjectErr = %EVAL(&ProjectErr + 1);	%END;
	%IF %SYSFUNC(ANYFIRST(%CMPRES(&Project))) ne 1 %THEN %DO;	%LET ProjectErr = %EVAL(&ProjectErr + 1);	%END;
%END;

%IF %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) eq SIMPLE	%THEN %DO; 
	%LET Analysis = Simple; 
	%LET ALY = SIM; 
%END;
%ELSE %IF %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) eq AGESTRATIFIED %THEN %DO; 
	%LET Analysis = AgeStratified;	
	%LET ALY = AGE; 
%END;
%ELSE %IF  %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) eq MULTIAGEGROUP %THEN %DO; 
	%LET Analysis = MultiAgeGroup;	
	%LET ALY = MUL; 
%END;
%ELSE %LET AnalysisTypeErr = 1; 

%IF %UPCASE(&RunType) ne RUN and %UPCASE(&RunType) ne DATA and %UPCASE(&RunType) ne CHECK %THEN %DO; %LET RunTypeErr = 1; %END;

%IF %SYMEXIST(ProjDesc) = 0 or "&ProjDesc" eq "&Empty" or "&ProjDesc" eq "&Space" %THEN %DO;
	%GLOBAL ProjDesc;
	%LET ProjDesc = &Space;
	%LET ProjDescDf = 1;
%END;

%IF %SYMEXIST(RunDesc) = 0 or "&RunDesc" eq "&Empty" or "&RunDesc" eq "&Space" %THEN %DO;
	%GLOBAL RunDesc;
	%LET RunDesc = &Space;
	%LET RunDescDf = 1;
%END;

%LET Part1Err = %EVAL(&RunTypeErr + &ProjectErr + &AnalysisTypeErr); 

%Mend CheckPart1;

%Macro CheckTimeVar;
%GLOBAL TimeErr TUnitErr TVarErr;
%LET TimeErr = 0;	%LET TUnitErr = 1; 	%LET TVarErr = 1;
%IF %UPCASE(%CMPRES(&TimeUnit)) eq DAY or %UPCASE(%CMPRES(&TimeUnit)) eq WEEK or 
	%UPCASE(%CMPRES(&TimeUnit)) eq MONTH or %UPCASE(%CMPRES(&TimeUnit)) eq YEAR %THEN %DO;
		%LET TUnitErr = 0;
%END;
%IF %UPCASE(%CMPRES(&TimeVar)) eq TIME_IN TIME_OUT or %UPCASE(%CMPRES(&TimeVar)) eq TOTTIME %THEN %DO;
	%LET TVarErr = 0;
%END;
%LET TimeErr = %EVAL(&TUnitErr + &TVarErr);
%Mend CheckTimeVar;


/*========================================================================================
Part 2. - Time range of follow-up period
		- Age range
		- Selects observations that meet a particular condition for analysis
========================================================================================*/
%Macro CheckPart2;																									
%GLOBAL Part2Err;
%LET Part2Err = 0;
%LET String = LowFU HighFU StartDate EndDate LowAge HighAge;
%LET DefVal = 0 99 01JAN2004 &_ddmmmyyyy 35 89;
%DO _k = 1 %TO 6;																									
	%LET This = %SCAN(&String,&_k,%STR( )); 
	%GLOBAL &This.Err;
	%LET &This.Err =0;
	%IF %EVAL(1 + %QSYSFUNC(Count(%cmpres(&&&This),%STR( )))) = 1 %THEN %DO;										
		%IF "&&&This" eq "&Empty" or "&&&This" eq "&Space" %THEN %DO; 												
			%LET %SCAN(&String,&_k,%STR( )) = %SCAN(&DefVal,&_k,%STR( )); 
			%LET &This.Df = 1;
		%END;
		%ELSE %DO;
			%IF &_k = 1 or &_k = 2 or &_k = 5 or &_k = 6 %THEN %DO;	
				%IF %DATATYP(&&&This) = CHAR and "&&&This" ne "&Empty" and "&&&This" ne "&Space" %THEN %DO; 			
					%LET &This.Err = 1;  
				%END;
				%ELSE %DO;
					%IF &_k = 1 or &_k = 2 %THEN %DO;																	
						%IF %SYSEVALF(&&&This < 0) %THEN %LET &This.Err = 1;
						%IF %SYSEVALF(%SYSFUNC(mod(&&&This,1)) ne 0 ) %THEN %LET &This.Err = 1;
					%END;
					%IF &_k = 5 or &_k = 6 %THEN %DO;																	
						%IF %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) eq MULTIAGEGROUP %THEN %DO;
							%LET &This = &Space;
							%LET &This.Df = 1;
						%END;
						%ELSE %DO;
							%IF %SYSEVALF(&&&This < 0) %THEN %LET &This.Err = 1;										
							%IF %SYSEVALF(%SYSFUNC(mod(&&&This,1)) ne 0 ) %THEN %LET &This.Err = 1;
							%IF %SYSEVALF(&LowAge >= &HighAge) %THEN %DO;
								%LET LowAgeErr = 1;  
							%END;
						%END;
					%END;
				%END;
			%END;
			%IF &_k = 3 or &_k = 4 %THEN %DO;																	
				Data _NULL_;
					date = "&&&This";
					newdate = input(date,date9.);
					call symput("&This.Err",_Error_); 
				run;
			%END;
		%END;



	%END;
	%ELSE %DO;																									
		%LET &This.Err =1;
	%END;
%END;
%IF %SYSEVALF(&LowFU >= &HighFU) %THEN %DO;  ****;
	%LET LowFUErr = 1;  
%END;
%IF %EVAL(&StartDateErr + &EndDateErr) eq 0 %THEN %DO;
	Data _NULL_;
		date3 = "&StartDate";
		date4 = "&EndDate";
		newdate3 = input(date3,date9.);
		newdate4 = input(date4,date9.);
		if newdate3 >= newdate4 then call symput("StartDateErr",1); 
	run;
%END;
%LET Part2Err = %EVAL(&LowFUErr + &HighFUErr + &StartDateErr + &EndDateErr + &LowAgeErr + &HighAgeErr);
%Mend CheckPart2;

/*========================================================================================
Part 3. - Outcome variable
		- Censor Value
========================================================================================*/
%Macro GetTempInFile;
%GLOBAL TempInFile;
%IF %SYMEXIST(WhereStmt) = 0 or %LENGTH(&WhereStmt) eq 0 %THEN %DO;
	%GLOBAL WhereStmt;
	%LET WhereStmt = %STR(1);
	%LET WhereStmtDf = 1;
%END;
%LET TempInFile = Work._TempInFile_;*******************************************************************;
%IF %SYSFUNC(exist(&TempInFile)) = 0 %THEN %DO;*******************************************;
	proc contents data = InLib.&InputFile( Keep = &KeepVarNoRF) out = _KeepVarContents_ noprint; run;

	%LET N_KeepVarNoRF = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&KeepVarNoRF),%STR( ))));		

	proc sql noprint;
	select NAME into: KeepVarName1-:KeepVarName%sysfunc(COMPBL(&N_KeepVarNoRF)) from _KeepVarContents_ order by NAME;
	select TYPE into: KeepVarType1-:KeepVarType%sysfunc(COMPBL(&N_KeepVarNoRF)) from _KeepVarContents_ order by NAME;

	Data &TempInFile;	set InLib.&InputFile (/* Obs = 10 *//**/ Keep = &KeepVar 
												%IF &IDDf = 1 %THEN %DO; &ID %END;
												%IF &CensorDateDf = 1 %THEN %DO; &CensorDate %END;
												%IF &StudyDateDf = 1 %THEN %DO; &StudyDate %END;
												%IF &DobDf = 1 %THEN %DO; &Dob %END;
												Where  = (&WhereStmt)); 
		%DO tif = 1 %TO &N_KeepVarNoRF;
			%IF &&KeepVarType&tif = 1 %THEN %DO;
				if &&KeepVarName&tif = . then delete;
			%END;
			%ELSE %DO;
				if &&KeepVarName&tif = '' then delete;
			%END;
		%END;
	run;***********;
%END;
%Mend GetTempInFile;

%Macro CheckValueExist(Data = , Var = , Value = );
%GLOBAL ValueFound;
%LET ValueFound = 0;		

Data _CheckValueExist_;		
set  &Data(keep=&Var);
call symput ('vfmt',vformat(&Var));
run;

%LET dsid=%SYSFUNC(open(_CheckValueExist_,i));						
%LET len=%SYSFUNC(varlen(&dsid, %SYSFUNC(varnum(&dsid,&Var))));		
%LET rc=%SYSFUNC(close(&dsid));										

%IF %SUBSTR(&vfmt,1,1) eq $ and %LENGTH(%CMPRES(&value)) > &Len %THEN %LET ValueFound = 0;
%ELSE %DO;
		proc datasets library = work NODETAILS NOLIST;
		modify _CheckValueExist_;
		INDEX CREATE &Var/ nomiss ;
		run;

		Data _lookup_;
		Format &var &vfmt;
		%IF %SUBSTR(&vfmt,1,1) eq $ %THEN %DO;	&Var = "&Value";	%END;
		%IF %SUBSTR(&vfmt,1,1) ne $ %THEN %DO; 	&Var = &Value;		%END;
		run;

		data _NULL_;
		set  _lookup_;
		set  _CheckValueExist_ key = &Var;
		select (_iorc_);
		        when(%sysrc(_sok)) do;    		call symput('ValueFound','1');       end;
				otherwise;
		end;
		run; 

		proc datasets library = work NODETAILS NOLIST;
		delete _lookup_ ;
		run; quit;
%END;

proc datasets library = work NODETAILS NOLIST;
delete _lookup_ _CheckValueExist_;
run; quit;
%Mend CheckValueExist;

%Macro CheckVarFormat(Data =, Var=, Fmt=);
%GLOBAL	&Fmt;
Data _NULL_;
set &Data (keep=&Var obs = 1);
	format Fmr $8.;
	Fmr = 'UNKNOWN';
	vfmt = vformat(&Var); 				
		if upcase(substr(vfmt,1,1)) eq '$' then do; call symput ("&Fmt","CHAR");	Fmr = 'CHAR'; end;		
		if upcase(substr(vfmt,1,4)) eq 'DATE' and upcase(substr(vfmt,5,1)) ne 'T' then do; call symput ("&Fmt","DATE");			Fmr = 'DATE'; end;		
		if upcase(substr(vfmt,1,6)) eq 'DDMMYY' then do; call symput ("&Fmt","DATE");				Fmr = 'DATE'; end;			
		if upcase(substr(vfmt,1,6)) eq 'DTDATE' then do; call symput ("&Fmt","DATE");				Fmr = 'DATE'; end;		
		if upcase(substr(vfmt,1,6)) eq 'MMDDYY' then do; call symput ("&Fmt","DATE");				Fmr = 'DATE'; end;		
		if upcase(substr(vfmt,1,6)) eq 'YYMMDD' then do; call symput ("&Fmt","DATE");				Fmr = 'DATE'; end;		
		if upcase(substr(vfmt,1,8)) eq 'DATETIME' then do; call symput ("&Fmt","DATETIME");			Fmr = 'DATETIME'; end;		
		if Fmr = 'UNKNOWN' and upcase(substr(vfmt,1,1)) ne 'D' and upcase(substr(vfmt,1,1)) ne '$' then call symput ("&Fmt","NUM");
run;
%MEND CheckVarFormat;

%Macro CheckPart3;
%Global N_Outcome N_Censor Part3Err OutcomeErr CensorDimErr CensorValErr;
%LET CensorDimErr = 0;	%LET CensorValErr = 0;	%LET OutcomeErr = 0;	
Data _NULL_; call symput('N_Outcome', 1 + count(strip(compbl("&Outcome")),' '));	run; 

Libname TempLib "&InputDir";
%DO N1 = 1 %TO &N_Outcome;
	%LET This = %SCAN(&Outcome,&N1);
	%CheckVarFormat(Data = TempLib.&InputFile, Var=&This, Fmt= VFmt);
	%IF &Vfmt ne NUM %THEN %DO; 
		%LET OutcomeErr = %EVAL(&OutcomeErr + 1);
	%END;
	%LET This = %SCAN(&Outcome_Date,&N1);
	%CheckVarFormat(Data = TempLib.&InputFile, Var=&This, Fmt= VFmt);
	%IF %SUBSTR(&Vfmt,1,1) ne D %THEN %DO; 
		%LET OutcomeErr = %EVAL(&OutcomeErr + 1);
	%END;
%END;
Libname TempLib ;

%IF &OutcomeErr eq 0 %THEN %DO;
	%IF %SYMEXIST(CensorValue) = 0 or "&CensorValue" eq "&Empty" or "&CensorValue" eq "&Space" %THEN %DO;
		%GLOBAL CensorValue;
		%LET CensorValue = %SYSFUNC(REPEAT(%STR(0 ),%EVAL(&N_Outcome-1))); 
		%LET CensorValueDf = 1;
		%LET N_Censor = &N_Outcome;
	%END;
	%ELSE %DO;
		Data _NULL_; call symput('N_Censor' , 1 + count(strip(compbl("&CensorValue")),' '));run; 
	%END;
	%IF &N_Outcome	ne &N_Censor %THEN %DO;	%LET CensorDimErr = 1;	%END;	
	%ELSE %DO;
		%DO c = 1 %TO &N_Outcome;
			%GetTempInFile;
			%CheckValueExist(Data = &TempInFile, Var = %UPCASE(%SCAN(&Outcome,&c)), Value = %UPCASE(%SCAN(&CensorValue,&c)));
			%IF &ValueFound = 0 %THEN %DO;
				%LET CensorValErr = %EVAL(&CensorValErr + 1);
			%END;
		%END;
	%END;
%END;

%LET Part3Err = %EVAL(&OutcomeErr + &CensorDimErr + &CensorValErr ); 
%Mend CheckPart3;




/*========================================================================================
Part 4. - Risk factor
========================================================================================*/
%Macro CheckBrackets(String,Error);
%GLOBAL &Error;

Data _NULL_;
	Brackets = compress("&&&String",'[]','k');	
	countbrackets = 0;
	error_nesting = 0;
	do i = 1 to lengthn(Brackets);
		if substr(Brackets,i,1)="[" then countbrackets = countbrackets + 1;
		else countbrackets = countbrackets - 1;
		if mod(i,2) = 0 then do;
			if countbrackets^=0 then error_nesting++1; 
		end;
	end;
	if countbrackets^=0 then error_nesting++1;
	call symput("&Error",error_nesting);
run;
%Mend CheckBrackets;

%Macro DefaultMid(Data = , Var =, N_Var = , InString = , OutString = );
%GLOBAL &OutString;

Data _NULL_;
set  &Data(keep=&Var obs = 1);
if _N_ = 1 then do;
	call symput ('vfmt',vformat(&Var));
end;
run;

proc sql noprint;
	create table _AllMedian_	(	_50 num	informat = &vfmt format = &vfmt);

%DO _mid_ = 1 %TO %EVAL(&N_Var -1);
	%LET low = %SCAN(%cmpres(&InString),&_mid_,%STR( ));			
	%LET high = %SCAN(%cmpres(&InString),%EVAL(&_mid_+1),%STR( ));	

	proc capability data = &Data (keep = &Var where = (&low <= &Var and &Var < &high)) NOPRINT;
	    var &Var;
		output out = _median_ pctlpts= 50 PCTLPRE= _ ;
	run;		

	proc datasets library = work nolist NODETAILS;
	append base = _AllMedian_ data =_median_ force;
	run; quit;
%END;	

proc sql noprint; select  _50 format = best12.  into:&OutString   separated by ' '	from _AllMedian_ order by 1; quit;

proc datasets library = work NODETAILS NOLIST;
	delete _AllMedian_ _median_;
run; quit;
%MEND DefaultMid;


%Macro CheckRF;
%GLOBAL N_RF N_RFband N_RFmid N_Cent N_RFbase;
%GLOBAL RFerr RFfmtErr RFbandBrktErr RFmidBrktErr N_RFbandErr N_RFmidErr N_CentErr N_RFbaseErr	;
%LET RFerr = 0; 		%LET N_RF = 0;			%LET N_RFband = 0;		%LET N_RFmid = 0;		%LET N_Cent = 0;	%LET N_RFbase = 0;
%LET RFbandBrktErr = 1;	%LET RFmidBrktErr = 1; 	%LET N_RFbandErr = 0;	%LET N_RFmidErr = 0;	%LET N_CentErr = 0;	%LET N_RFbaseErr = 0;
%LET RFfmtErr = 0;		%LET RFmidErr = 0;

%LET N_RF = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&RF),%STR( ))));
Libname TempLib "&InputDir";
%DO R1 = 1 %TO &N_RF;
	%LET This = %SCAN(&RF,&R1);
	%CheckVarFormat(Data = TempLib.&InputFile, Var=&This, Fmt= VFmt);
	%IF &Vfmt ne NUM %THEN %DO; 
		%LET RFfmtErr = %EVAL(&RFfmtErr + 1);
	%END;
%END;
Libname TempLib ;
/*
%PUT RFband = &RFband;
%LET RFband = %SYSFUNC(compbl(%SYSFUNC(compress("&RFband",'[].',kads.))));	
%LET RFmid = %SYSFUNC(compbl(%SYSFUNC(compress("&RFmid",'[].',kads))));
*/
%CheckBrackets(RFband,RFbandBrktErr);		
%CheckBrackets(RFmid,RFmidBrktErr);

%LET RFerr = %EVAL(&RFerr + &RFbandBrktErr + &RFmidBrktErr + &RFfmtErr);
%IF &RFerr eq 0 %THEN %DO;

	%LET N_RFband = %QSYSFUNC(Count(%cmpres(&RFband),%QUOTE([)));					
	%IF &N_RF ne &N_RFband %THEN %DO; 	%LET N_RFbandErr = 1;	%END;

	%LET N_RFmid = %QSYSFUNC(Count(%cmpres(&RFmid),%QUOTE([)));					
	%IF &N_RF ne &N_RFmid %THEN %DO; 	%LET N_RFmidErr = 1;	%END;

	%LET N_Cent = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&Cent),%STR( ))));
	%IF &N_RF ne &N_Cent %THEN %DO; 	%LET N_CentErr = 1;	%END;

	%LET N_RFbase = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&RFbase),%STR( ))));
	%IF &N_RF ne &N_RFbase %THEN %DO; 	%LET N_RFbaseErr = 1;	%END;

	%LET RFerr = %EVAL(&RFerr + &N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr);
	%IF &RFerr eq 0 %THEN %DO;

		%DO r = 1 %TO &N_RF;
			%GLOBAL RF&r RFband&r N_RFband&r RFmid&r N_RFmid&r Cent&r RFbase&r RFtype&r;
			%GLOBAL Both_RFband_Cent&r RFbandNeeded&r CentErr&r RFbaseErr&r RFdimErr&r RFbandErr&r	RFmidErr&r	RFtypeErr&r;
			%GLOBAL RF&r.Df RFband&r.Df RFmid&r.Df Cent&r.Df RFbase&r.Df ;
			%LET Both_RFband_Cent&r = 0; 	%LET RFbandNeeded&r = 0; %LET CentErr&r = 0; %LET RFbaseErr&r = 0; 
			%LET RFdimErr&r = 0;			%LET RFbandErr&r = 0;	%LET RFtypeErr&r = 0;
			%LET RF&r.Df = 0;     %LET RFband&r.Df = 0;     %LET RFmid&r.Df = 0;     %LET Cent&r.Df = 0;     %LET RFbase&r.Df = 0;	%LET RFmidErr&r = 0;

			%LET RF&r = %UPCASE(%SCAN(%cmpres(&RF),&r,%STR( )));

			%LET WithRight = %SCAN(%cmpres(&RFband),%EVAL(&r),%STR([));			
			%LET RightSq = %INDEX(&WithRight,%STR(]));				
			%LET RFband&r = %SUBSTR(%STR(&WithRight),1,%EVAL(&RightSq - 1));		 		
			%IF %SYMEXIST(RFband&r) and "&&RFband&r" ne "&Empty"  and "&&RFband&r" ne "&Space" %THEN %DO; 
				%LET N_RFband&r = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&&RFband&r),%STR( ))));
				%DO _k = 1 %TO &&N_RFband&r;
					%LET ThisErr = 0; 
					%LET This = %SCAN(&&RFband&r,&_k,%STR( )); 
					%IF %DATATYP(&This) = CHAR and %UPCASE(&This) ne MIN and %UPCASE(&This) ne MAX %THEN %DO; %LET ThisErr = 1;  %END;
					%LET RFbandErr&r = %EVAL(&&RFbandErr&r + &ThisErr);
				%END;
				%IF &&N_RFband&r < 3 %THEN %LET	RFbandErr&r = %EVAL(&&RFbandErr&r + 1);
			%END; 
			%ELSE %DO;
				%LET N_RFband&r = 0;
			%END;

			%LET WithRight = %SCAN(%cmpres(&RFmid),%EVAL(&r),%STR([));			
			%LET RightSq = %INDEX(&WithRight,%STR(]));				
			%LET RFmid&r = %SUBSTR(%STR(&WithRight),1,%EVAL(&RightSq - 1));		 		
			%IF %SYMEXIST(RFmid&r) and  "&&RFmid&r"  ne "&Empty" and  "&&RFmid&r"  ne "&Space" %THEN %DO;  
				%LET N_RFmid&r = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&&RFmid&r),%STR( ))));
				%DO _k = 1 %TO &&N_RFmid&r;
					%LET ThisErr = 0; 
					%LET This = %SCAN(&&RFmid&r,&_k,%STR( )); 
					%IF %DATATYP(&This) = CHAR %THEN %DO; %LET ThisErr = 1;  %END;
					%LET RFmidErr&r = %EVAL(&&RFmidErr&r + &ThisErr);
				%END;
			%END;
			%ELSE %DO;
				%LET N_RFmid&r = 0;
				%LET RFmid&r.Df = 1;
			%END;

			%LET Cent&r = %UPCASE(%SCAN(%cmpres(&Cent),&r,%STR( )));
			%LET RFbase&r = %UPCASE(%SCAN(%cmpres(&RFbase),&r,%STR( )));

			%IF &&N_RFband&r ne 0 and %UPCASE(&&Cent&r) ne NA %THEN %DO;
				%LET Both_RFband_Cent&r = %EVAL(&&Both_RFband_Cent&r + 1);
			%END;	

			%LET RFerr = %EVAL(&RFerr + &&Both_RFband_Cent&r + &&RFbandErr&r + &&RFmidErr&r);

			%IF &RFErr eq 0 %THEN %DO;
				/*CONTINUOUS*/
				%IF &&N_RFband&r eq 0 and &&N_RFmid&r eq 0 and %UPCASE(&&Cent&r) eq NA and %UPCASE(&&RFbase&r) eq NA %THEN %DO;
					%LET RFtype&r = CONTINUOUS;
					%IF &analysis = MultiAgeGroup %THEN %DO;
						%LET RFtypeErr&r = 1;	/*%PUT RFtypeErr&r = &&RFtypeErr&r;*/
					%END;
					%LET RFerr = %EVAL(&RFerr + &&RFtypeErr&r); /* %PUT RFerr = &RFerr;*/
				%END;

				/*BAND*/
				%IF &&N_RFband&r ne 0 and  %UPCASE(&&Cent&r) eq NA %THEN %DO;
					%LET RFtype&r = BAND;

					%IF &&N_RFmid&r ne 0 and %EVAL(&&N_RFmid&r ne %EVAL(&&N_RFband&r - 1)) %THEN %DO;
						%LET RFdimErr&r = %EVAL(&&RFdimErr&r + 1);	
					%END;

					%IF  (%EVAL(1 <= &&RFbase&r) and %EVAL(&&RFbase&r <= %EVAL(&&N_RFband&r - 1))) 	or %upcase(&&RFbase&r) = FIRST or %upcase(&&RFbase&r) = LAST  %THEN %DO;
						%IF %upcase(&&RFbase&r) = FIRST or %upcase(&&RFbase&r) = LAST %THEN %DO;  %END;
						%ELSE %DO;
							%IF %EVAL(%SYSFUNC(MOD(&&RFbase&r,1)) ne 0) %THEN %DO;
								%LET RFbaseErr&r = %EVAL(&&RFbaseErr&r + 1);	/*	%PUT RFbaseErr&r  =  &&RFbaseErr&r --------------------------;*/
							%END;
						%END;
					%END;
					%ELSE %DO;	
						%LET RFbaseErr&r = %EVAL(&&RFbaseErr&r + 1);	
					%END;

					%IF %EVAL(&&RFdimErr&r + &&RFbaseErr&r) eq 0 %THEN %DO;		
						%IF &&N_RFmid&r ne 0 and %EVAL(%SYSFUNC(anyalpha(&&RFband&r)) eq 0) %THEN %DO;
							%SortString(InString = &&RFmid&r, OutString = RFmid&r);					
						%END;	
					%END;
					%LET RFerr = %EVAL(&RFerr + &&RFdimErr&r + &&RFbaseErr&r);
				%END;
				%IF &&N_RFband&r eq 0 and  %UPCASE(&&Cent&r) eq NA and (&&N_RFmid&r ne 0 or %UPCASE(&&RFbase&r) ne NA) %THEN %DO;
					%LET RFbandNeeded&r = %EVAL(&&RFbandNeeded&r + 1);
				%END;
				%LET RFerr = %EVAL(&RFerr + &&RFbandNeeded&r);

				/*CENT*/
				%IF %UPCASE(&&Cent&r) ne NA and  &&N_RFband&r eq 0 %THEN %DO;
					%LET RFtype&r = CENT;

					%IF %EVAL(&&Cent&r < 2) or %EVAL(&&Cent&r > 100) or %DATATYP(&&Cent&r) = CHAR %THEN %DO; 
						%LET CentErr&r = %EVAL(&&CentErr&r + 1);
					%END;
					%ELSE %DO;
						%LET N_RFband&r = %EVAL(&&Cent&r +1);					***;

						%IF %EVAL(&&N_RFmid&r ne &&Cent&r) and %EVAL(&&RFmid&r.Df ne 1) %THEN %DO;
							%LET CentErr&r = %EVAL(&&CentErr&r + 1);
						%END;
						%ELSE %DO;
							%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
								%LET N_RFmid&r = &&Cent&r;		***;
							%END;
							%IF  (%EVAL(1 <= &&RFbase&r) and %EVAL(&&RFbase&r <= &&Cent&r)) or %upcase(&&RFbase&r) = FIRST or %upcase(&&RFbase&r) = LAST  %THEN %DO; 
								%IF %upcase(&&RFbase&r) = FIRST or %upcase(&&RFbase&r) = LAST %THEN %DO; %END;
								%ELSE %DO;
									%IF %EVAL(%SYSFUNC(MOD(&&RFbase&r,1)) ne 0) %THEN %DO;
										%LET RFbaseErr&r = %EVAL(&&RFbaseErr&r + 1);	/*%PUT RFbaseErr&r  =  &&RFbaseErr&r --------------------------;*/
									%END;
								%END;
							%END;
							%ELSE %DO;	
								%LET RFbaseErr&r = %EVAL(&&RFbaseErr&r + 1);	
							%END;
						%END;
					%END;


					%LET RFerr = %EVAL(&RFerr + &&CentErr&r + &&RFbaseErr&r);
				%END;
			%END;
		%END;
	%END;
%END;

%LET RFerr = %EVAL(&RFerr + &RFfmtErr + &RFbandBrktErr + &RFmidBrktErr + &N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr);
%Mend CheckRF;	

/*========================================================================================
Part 5. - Covariants
========================================================================================*/
%Macro CheckCV;
%GLOBAL CVerr N_CV CVneeded N_Class CVclassDimErr CVclassValErr CVfmtErr N_Order CVorderDimErr CVorderValErr N_Base CVbaseDimErr CVbaseValErr ;
%LET CVerr = 1;
%LET N_CV = 0;		%LET CVneeded = 0;			%LET CVfmtErr = 0;
%LET N_Class = 0; 	%LET CVclassDimErr = 0;		%LET CVclassValErr = 0;
%LET N_Order = 0;	%LET CVorderDimErr = 0;		%LET CVorderValErr = 0;
%LET N_Base = 0;	%LET CVbaseDimErr = 0;		%LET CVbaseValErr = 0;
%IF %SYMEXIST(Covars) and "&Covars" ne "&Empty" and "&Covars" ne "&Space"		%THEN %DO; Data _NULL_; call symput('N_CV', 1 + count(strip(compbl("&Covars")),' '));	run; %END;
%IF %SYMEXIST(CovClass) and "&CovClass" ne "&Empty" and "&CovClass" ne "&Space" %THEN %DO; Data _NULL_; call symput('N_Class' , 1 + count(strip(compbl("&CovClass")),' '));run; %END;
%IF %SYMEXIST(CovOrder) and "&CovOrder" ne "&Empty" and "&CovOrder" ne "&Space" %THEN %DO; Data _NULL_; call symput('N_Order', 1 + count(strip(compbl("&CovOrder")),' '));	run; %END;
%IF %SYMEXIST(CovBase) and  "&CovBase"	ne "&Empty" and  "&CovBase"	ne "&Space" %THEN %DO; Data _NULL_; call symput('N_Base' , 1 + count(strip(compbl("&CovBase")),' '));	run; %END;

%IF %EVAL(&N_CV > 0) %THEN %DO; 
	%IF %EVAL(&N_Class > 0) %THEN %DO;	
		%IF %EVAL(&N_CV ne &N_Class) %THEN %DO; %LET CVclassDimErr = 1; %END;
		%ELSE %DO r = 1 %TO &N_CV;
			%IF %UPCASE(%SCAN(&CovClass,&r)) ne 0 and %UPCASE(%SCAN(&CovClass,&r)) ne 1 %THEN %DO; %LET CVclassValErr = 1; %END;
			%ELSE %DO;
				%IF %UPCASE(%SCAN(&CovClass,&r)) eq 0 %THEN %DO;
					Libname TempLib "&InputDir";
					%LET This = %SCAN(&Covars,&r);
					%CheckVarFormat(Data = TempLib.&InputFile, Var=&This, Fmt= VFmt);
					%IF &Vfmt ne NUM %THEN %DO; 
						%LET CVfmtErr = %EVAL(&CVfmtErr + 1);
					%END;
					Libname TempLib ;
				%END;
			%END;
		%END;
	%END;
	%ELSE %DO; /*Set default values for CovClass */
		%DO r = 1 %TO &N_CV;
			Libname TempLib "&InputDir";
			%LET This = %SCAN(&Covars,&r);
			%CheckVarFormat(Data = TempLib.&InputFile, Var=&This, Fmt= VFmt);
			%IF &Vfmt ne NUM %THEN %DO; 
				%LET CVfmtErr = %EVAL(&CVfmtErr + 1);
			%END;
			Libname TempLib ;
		%END;
		%LET CovClass = %SYSFUNC(REPEAT(%STR(0 ),%EVAL(&N_CV-1))); 
		%LET CovClassDf = 1;
	%END;
																					
	%IF %EVAL(&N_Order > 0) %THEN %DO;	
		%IF %EVAL(&N_CV ne &N_Order) %THEN %DO; %LET CVorderDimErr = 1; %END; 
		%ELSE %DO p = 1 %TO &N_CV;
			%IF %UPCASE(%SCAN(&CovClass,&p)) eq 0 %THEN %DO;
				%IF %UPCASE(%SCAN(&CovOrder,&p)) ne NA %THEN %DO; %LET CVorderValErr = 1; %END;
			%END;
			%ELSE %DO;
				%IF %UPCASE(%SCAN(&CovOrder,&p)) ne I and %UPCASE(%SCAN(&CovOrder,&p)) ne F %THEN %DO; %LET CVorderValErr = 1; %END;
			%END;
		%END;
	%END;
	%ELSE %DO; /*Set default values for CovOrder */   	
		%LET CovOrder = %STR( );   						
		%DO p = 1 %TO &N_CV;   							
			%IF %UPCASE(%SCAN(&CovClass,&p)) eq 0 %THEN %DO;
				%LET CovOrder = &CovOrder.%STR(NA );
			%END;
			%ELSE %DO;
				%LET CovOrder = &CovOrder.%STR(F );
			%END;
		%END;
		%LET CovOrderDf = 1;
	%END;																		
	%IF %EVAL(&N_Base > 0) %THEN %DO;	
		%IF %EVAL(&N_CV ne &N_Base) %THEN %DO; %LET CVbaseDimErr = 1; %END; 
		%ELSE %DO q = 1 %TO &N_CV;	/*%PUT upcase_CovBase_q = %UPCASE(%SCAN(&CovBase,&q));*/

			%IF %UPCASE(%SCAN(&CovClass,&q)) eq 0 %THEN %DO;
				%IF %UPCASE(%SCAN(&CovBase,&q)) ne NA %THEN %DO; %LET CVbaseValErr = 1; %END;
			%END;
			%ELSE %DO;
				%IF %UPCASE(%SCAN(&CovBase,&q)) ne FIRST and %UPCASE(%SCAN(&CovBase,&q)) ne LAST %THEN %DO; 
					%GetTempInFile;
					%CheckValueExist(Data = &TempInFile, Var = %SCAN(&Covars,&q), Value = %SCAN(&CovBase,&q,%STR( )));
					%IF &ValueFound = 0 %THEN %DO; %LET CVbaseValErr = 1; %END;
				%END;
			%END;
		%END;
	%END;
	%ELSE %DO; /*Set default values for CovBase */
		%LET CovBase = %STR();
		%DO q = 1 %TO &N_CV;
			%IF %UPCASE(%SCAN(&CovClass,&p)) eq 0 %THEN %DO;
				%LET CovBase = &CovBase.%STR(NA );
			%END;
			%ELSE %DO;
				%LET CovBase = &CovBase.%STR(FIRST );
			%END;
		%END;
		%LET CovBaseDf = 1;
	%END;																	
%END;
%ELSE %DO;
	%IF %EVAL((&N_Class + &N_Order + &N_Base) > 0) %THEN %DO;
		%LET CVneeded = 1;
	%END;
	%ELSE %DO;
		%GLOBAL Covars;
		%LET Covars = &Space;
		%LET CovarsDf = 1;
	%END;
%END;
%LET CVerr = %EVAL(&CVneeded + &CVclassDimErr + &CVclassValErr + &CVfmtErr + &CVorderDimErr + &CVorderValErr + &CVbaseDimErr + &CVbaseValErr) ;
%Mend CheckCV;

/*========================================================================================
Part 6. -  Age group
========================================================================================*/

%Macro SortString(InString = , OutString = );
%GLOBAL &OutString;
Data _NULL_; call symput('N_String' , 1 + count(strip(compbl("&InString")),' '));	run; 
Data _NULL_;
	Length String $300;
	String = ' ';
	if _n_=1 then do;
		declare hash h(ordered:'a');
		declare hiter iter('h');
		h.definekey('Value');
		h.definedata('Value');
		h.definedone();
		call missing(Value);
	end;
	%DO _i = 1 %TO &N_String;
		Value = %SCAN(&InString,&_i,%STR( ));
		rca=h.add();
	%END;

	rc=iter.first();
	do while (rc =0);								
		String = Catx(%STR(' '),String,Value);		
		rc=iter.next();
	end;
	NewString = strip(compbl(String));
	call symput("&OutString",NewString);
	stop;
run;
%Mend SortString;

%Macro CheckDob;
%GLOBAL DobErr;
%LET DobErr = 0;
%IF &DobNameErr eq 0 and &NonExistVar eq 0 %THEN %DO;
	%IF %SYMEXIST(Dob) ne 1 or "&Dob" eq "&Empty" or "&Dob" eq "&Space" %THEN %DO;
	/*	%GLOBAL Dob;
		%LET Dob = DOB;
		%LET DobDf = 1;*/
	%END;
	%ELSE %DO;
		%IF %EVAL(%SYSFUNC(count(%cmpres(&Dob dummyvar),%STR( )))) ne 1  %THEN  %LET DobErr = %EVAL(&DobErr + 1); 
	%END;
	%IF &DobErr = 0 %THEN %DO;
		Libname TempLib "&InputDir";
		%CheckVarFormat(Data = TempLib.&InputFile, Var=&Dob, Fmt= VFmt);
		Libname TempLib ;
		%IF %SUBSTR(&Vfmt,1,1) ne D %THEN %DO;
			%LET DobErr = %EVAL(&DobErr + 1); 
		%END;
	%END;
%END;
%Mend CheckDob;

%Macro CheckAge;
/*XAge*/
%GLOBAL XAgeDf XAgeErr;
%LET XAgeDf = 0;	%LET XAgeErr = 0;
%IF %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) eq SIMPLE %THEN %DO;
	%GLOBAL XAge XAgeDf;
	%LET XAgeDf = 1;		%LET XAge = %STR( );
%END;
%ELSE %DO;
	%IF "&XAge" eq "&Empty" or "&XAge" eq "&Space" %THEN %DO; 
		%GLOBAL XAge XAgeDf;
		%LET XAgeDf = 1;		%LET XAge = 5;
	%END;
	%ELSE %DO;
		%IF %DATATYP(&XAge) = CHAR %THEN %DO; 
			%LET XAgeErr = 1;  
		%END;
		%ELSE %DO;
			%IF %EVAL(1 + %QSYSFUNC(Count(%cmpres(&XAge),%STR( )))) ne 1 %THEN %DO;
				%LET XAgeErr = 1;  
			%END;
			%ELSE %DO;
				%IF %SYSEVALF(&XAge > 10) or %SYSEVALF(&XAge < 1) %THEN %DO;
					%LET XAgeErr = 1;  
				%END;
				%IF %EVAL(%SYSFUNC(MOD(&XAge,1)) ne 0) %THEN %DO;
					%LET XAgeErr = 1;  
				%END;
			%END;
		%END;
	%END;
%END;

/*Ageband, Agemid*/
%Global AgeErr N_AgeBand AgeBandErr AgeConfDim N_AgeMid AgeMidErr;
%LET AgeErr = 1;			
%LET N_AgeBand = 0; 	%LET AgeBandErr = 0;	%LET AgeConfDim = 0;
%LET N_AgeMid = 0;		%LET AgeMidErr = 0;

%IF %SYMEXIST(AgeBand) and "&AgeBand" ne "&Empty" and "&AgeBand" ne "&Space" %THEN %DO; Data _NULL_; call symput('N_AgeBand', 1 + count(strip(compbl("&AgeBand")),' ')); run; %END;
%IF %SYMEXIST(AgeMid) and  "&AgeMid"  ne "&Empty" and "&AgeMid"  ne "&Space" %THEN %DO; Data _NULL_; call symput('N_AgeMid' , 1 + count(strip(compbl("&AgeMid")),' '));  run; %END;	

%IF %CMPRES(%SYSFUNC(compress(%UPCASE(&Analysis),,kdlu))) ne MULTIAGEGROUP %THEN %DO;
	%GLOBAL AgeBand AgeMid;
	%LET AgeBandDf = 1;		%LET AgeBand = %STR( );
	%LET AgeMidDf = 1;		%LET AgeMid = %STR( );
%END;
%ELSE %DO;
	%IF &N_AgeBand = 0 %THEN %DO;
		%LET AgebandErr = %EVAL(&AgebandErr + 1);
	%END;
	%ELSE %DO;
		%DO _k = 1 %TO &N_AgeBand;
			%LET ThisErr = 0; 
			%LET This = %SCAN(&AgeBand,&_k,%STR( )); /**vvvvvvvv can't have min max for ageband becos can't check Xage in relation to Ageband gap;*/
			%IF %DATATYP(&This) = CHAR %THEN %DO; /*  and %UPCASE(&This) ne MIN and %UPCASE(&This) ne MAX  */		
				%LET ThisErr = %EVAL(&ThisErr + 1); /*%PUT this = &this is char!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!----------------; */
			%END;
			%ELSE %DO;																		
				%IF %SYSEVALF(%SYSFUNC(mod(&This,1)) ne 0 ) %THEN %DO; 			
					%LET ThisErr = %EVAL(&ThisErr + 1); 
				%END;
				%IF %SYSEVALF(&This < 0 ) %THEN %DO; 		
					%LET ThisErr = %EVAL(&ThisErr + 1); 
				%END;
			%END;	
			%LET AgebandErr = %EVAL(&AgebandErr + &ThisErr);
		%END;

		%IF &XAgeErr eq 0 and &AgebandErr eq 0 %THEN %DO;
			%SortString(InString = &AgeBand, OutString = AgeBand);		
			%DO _k = 1 %TO &N_AgeBand;
				%DO _x = 2 %TO &N_AgeBand;
					%IF %EVAL(%SYSFUNC(MOD(%SYSEVALF(%SCAN(&AgeBand,&_x,%STR( ))-%SCAN(&AgeBand,%EVAL(&_x - 1),%STR( ))),&XAge)) ne 0) %THEN %DO; 
						%LET ThisErr = %EVAL(&ThisErr + 1);  
					%END;
				%END;
				%LET AgebandErr = %EVAL(&AgebandErr + &ThisErr);
			%END;
		%END;

	
		%IF &AgebandErr = 0 %THEN %DO; 
			%IF %EVAL(&N_AgeMid > 0) %THEN %DO;		
				%LET AgeMidExist = 1;
				%DO _c = 1 %TO &N_AgeMid;
					%LET ThisErr = 0; 
					%LET This = %SCAN(&AgeMid,&_c,%STR( )); 
					%IF %DATATYP(&This) = CHAR %THEN %DO; %LET ThisErr = 1;  %END;
					%LET AgeMidErr = %EVAL(&AgeMidErr + &ThisErr);
				%END;																							
				Data _NULL_;
					if (&N_AgeBand -1) ne &N_AgeMid then do;
						call symput("AgeConfDim",1); 
					end;
				run;	
			%END;
			%ELSE %DO;		*Set default values for AgeMid ;
				%LET N_AgeMid = 0;
				%LET AgeMidDf = 1;
			%END;
			%IF &AgeMidErr eq 0 and &AgeConfDim eq 0 and &AgeMidDf = 0 %THEN %DO;
				%SortString(InString = &AgeMid, OutString = AgeMid);
			%END;
		%END;
	%END;
%END;
%LET AgeErr = %EVAL(&XAgeErr + &AgebandErr + &AgeConfDim + &AgeMidErr) ;			
%Mend CheckAge;



