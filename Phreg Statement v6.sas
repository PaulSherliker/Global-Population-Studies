%AnyError; 	/*%PUT ParamError = &ParamError;*/

%Macro Phreg;
%IF &ParamError le 0 %THEN %DO; 

	%GLOBAL LibStmt separator  Nb_start Nb_end  ;**-------------------------------***;
	%LET separator = %STR(/&Empty.*----------------------------------------------------------------------------------------------------------*&Empty./);
/*	%LET LibStmt = %STR(Libname OutLib )'&OutputDir'%STR(;);*/
	%LET Nb_start = %STR(/&Empty.*    ); 
	%LET Nb_end = %STR(*&Empty./); 

	%DO r = 1 %TO &N_RF;
		%DO o = 1 %TO &N_Outcome;

			%GLOBAL PStmtr&r.o&o. CStmtr&r.o&o. MStmtr&r.o&o.  SStmtr&r.o&o. OStmtr&r.o&o. Rstmt;

			/***; %PUT &Nb_start;*/
			%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));			/***; %PUT Outcome = &ThisOutcome;*/
			%LET ThisRF = %SYSFUNC(strip(%UPCASE(&&RF&r)));			/***; %PUT RF = &ThisRF;*/
			%LET ThisRFType = &&RFType&r;							
			/***; %PUT &Nb_end;*/
	 %PUT ;
			*** Proc statement;
			%LET PStmtr&r.o&o. = %STR(Proc PHREG Data = Data_&ThisRF._&ThisOutcome. outest = _Covr&r.o&o._ COVOUT MULTIPASS ;);

			/***; %PUT &&PStmtr&r.o&o.;*/

			*** Class statement;
			%LET TempClass = %STR( );

			%IF "&ALY" eq "MUL" %THEN %DO;
				%LET age_b = %SYSFUNC(strip(%UPCASE(%SCAN(&&Agemidr&r.o&o.,1, %STR( )))));	
			%END;

			%IF %UPCASE(&ThisRFType) ne CONTINUOUS %THEN %DO;
				%IF "&ALY" ne "MUL" %THEN %DO;	/*	*/
					%LET TempClass = &TempClass.&ThisRF.Grp%STR( %(order = INTERNAL )%STR( ref = ) ;
				%END;							/*	*/
				%IF %UPCASE(&&RFbase&r) eq FIRST %THEN %DO; 
					%IF "&ALY" eq "MUL" %THEN %DO;
						%LET rf_b = %SYSFUNC(strip(%UPCASE(%SCAN(&&RFmidr&r.o&o.,1, %STR( )))));	
						/* %LET TempClass = &TempClass.%STR( FIRST );  */
					%END;
					%ELSE %DO;
						%LET TempClass = &TempClass.&&RFbase&r..%STR( ); 
					%END;
				%END;
				%ELSE %IF %UPCASE(&&RFbase&r) eq  LAST %THEN %DO; 
					%IF "&ALY" eq "MUL" %THEN %DO;
						%LET rf_b = %SYSFUNC(strip(%UPCASE(%SCAN(&&RFmidr&r.o&o.,&&N_RFmidr&r.o&o., %STR( )))));	
						/* %LET TempClass = &TempClass.%STR( LAST ); */
					%END;
					%ELSE %DO;
						%LET TempClass = &TempClass.&&RFbase&r..%STR( ); 
					%END;
				%END;
				%ELSE %DO; 
					%IF "&ALY" eq "MUL" %THEN %DO;
						%LET rf_b = %SYSFUNC(strip(%UPCASE(%SCAN(&&RFmidr&r.o&o.,&&RFbase&r.., %STR( )))));	
						/* %LET TempClass = &TempClass.%STR(%')&rf_b.STR( ))%STR(%' ); */
					%END;
					%ELSE %DO;
						%LET TempClass = &TempClass.%STR(%')%SCAN(&&RFmidr&r.o&o.,&&RFbase&r..,%STR( ))%STR(%' );
					%END;
				%END;
				%IF "&ALY" eq "MUL" %THEN %DO;
					Data _NULL_;
						format cross_b $13.;
						cross_b = 'a'||put(&age_b,4.1-R)||" rf"||put(&rf_b,5.-R);	
						call symput("cross_b",cross_b);
					run;
				%END;
				%IF "&ALY" ne "MUL" %THEN %DO;	/*	*/
					%LET TempClass = &TempClass.%STR(%)) ;
				%END;							/*	*/
			%END;

			%LET CVlist = %STR( );
			%DO c = 1 %TO &N_CV; 
				%LET ThisCV = %SYSFUNC(strip(%UPCASE(%SCAN(&Covars,&c, %STR( )))));	
				%IF &ThisRF ne &ThisCV %THEN %DO;												
					%LET CVlist = &CVlist.%STR(&ThisCV );
					%IF %SCAN(&CovClass,&c, %STR( )) eq 1 %THEN %DO; 					
						%LET ThisOrder = %UPCASE(%SCAN(&CovOrder,&c, %STR( )));
						%IF "&ThisOrder" eq "F"	%THEN %DO;
							%LET UseOrder = FORMATTED;
						%END;
						%IF "&ThisOrder" eq "I"	%THEN %DO;
							%LET UseOrder = INTERNAL;
						%END;
						%LET TempClass = &TempClass.%STR( )%SCAN(&Covars,&c,%STR( ))%STR( %(order = )&UseOrder%STR( ref = ) ;
						%IF %UPCASE(%SCAN(&CovBase,&c)) eq FIRST or %UPCASE(%SCAN(&CovBase,&c)) eq  LAST %THEN %DO; 
							%LET TempClass = &TempClass.%SCAN(&CovBase,&c,%STR( ))%STR( ); 
						%END;
						%ELSE %DO; 
							%LET TempClass = &TempClass.%STR(%')%SCAN(&CovBase,&c,%STR( ))%STR(%' );
						%END;
						%LET TempClass = &TempClass.%STR(%) ) ;
					%END;
				%END;
			%END;																	
			%IF "&ALY" eq "MUL" %THEN %DO;
				%LET TempClass = &TempClass.%STR( CrossGrp %( ref = %"&cross_b%" %) AgeBand %( ref = FIRST %) );
			%END;

			%IF "&TempClass" ne " " %THEN %DO;
				%LET CStmtr&r.o&o. = %STR(    Class)&TempClass.%STR(;);
			%END;
			%ELSE %DO;
				%LET CStmtr&r.o&o. = %STR( );
			%END;
			/***; %PUT &&CStmtr&r.o&o.;*/

			*** ID statement;
	/*		%LET IDstmt = %STR(ID &ID);					***; %PUT ID = &ID;
	*/
			*** Model statement;
			%LET MStmt = %STR(    Model );
			%IF "&ALY" ne "MUL" %THEN %DO;
				%IF %UPCASE(&ThisRFType) eq CONTINUOUS %THEN %DO;
					%IF %UPCASE(&TimeVar) eq TIME_IN TIME_OUT %THEN %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_d Time_out_d%) * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_w Time_out_w%) * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_m Time_out_m%) * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_y Time_out_y%) * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
					%END;
					%ELSE %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_d * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_w * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_m * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( Tottime_y * Censor %(0%) = &ThisRF &CVlist / RL COVB);
						%END;
					%END;
				%END;
				%ELSE %DO;
					%IF %UPCASE(&TimeVar) eq TIME_IN TIME_OUT %THEN %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_d Time_out_d%) * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_w Time_out_w%) * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_m Time_out_m%) * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_y Time_out_y%) * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
					%END;
					%ELSE %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_d * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_w * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_m * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( Tottime_y * Censor %(0%) = &ThisRF.Grp &CVlist / RL COVB);
						%END;
					%END;
				%END;
			%END;
			%ELSE %DO;
					%IF %UPCASE(&TimeVar) eq TIME_IN TIME_OUT %THEN %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_d Time_out_d%) * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_w Time_out_w%) * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_m Time_out_m%) * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( %(Time_in_y Time_out_y%) * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
					%END;
					%ELSE %DO;
						%IF %UPCASE(&TimeUnit) eq DAY %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_d * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_w * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
							%LET MStmt = &MStmt.%STR( Tottime_m * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
						%ELSE %DO;
							%LET MStmt = &MStmt.%STR( Tottime_y * Censor %(0%) = &CVlist CrossGrp  Nuis(AgeBand)/ RL COVB);
						%END;
					%END;
			%END;
			%LET MStmtr&r.o&o. = &MStmt.%STR(;);
			/***; %PUT 	&&MStmtr&r.o&o.;*/

			*** Strata statement;
			%IF ("&ALY" eq "SIM" or "&ALY" eq "MUL") and  "&Strata" eq "&Space" %THEN %DO; 	%END;
			%ELSE %DO;			
				%LET SStmt = %STR(    Strata );								
				%IF "&Strata" ne "&Space" %THEN %DO;
					%LET SStmt = &SStmt.%STR(&Strata );
				%END;
				%IF "&ALY" eq "AGE" %THEN %DO;
					%LET SStmt = &SStmt.%STR(XAgeGrp );
				%END;
				%LET SStmtr&r.o&o. = &SStmt.%STR(;);
			%END;
			/***; %PUT 	&&SStmtr&r.o&o.; */

			*** Hazard Ratio statement;
			%GLOBAL N_HStmtr&r.o&o.;
			%LET N_CVlist = %EVAL(%QSYSFUNC(Count(%cmpres(&CVlist dummyvar),%STR( ))));		
/*			%LET N_HStmtr&r.o&o. = %EVAL(&N_CVlist + 1);*/
			%LET N_HStmtr&r.o&o. = %EVAL(1);
			%GLOBAL HStmtr&r.o&o.n1;
			%IF "&ALY" ne "MUL" %THEN %DO;
				%IF %UPCASE(&ThisRFType) eq CONTINUOUS %THEN %DO;		
					%LET HStmtr&r.o&o.n1 = %STR(    HazardRatio %')&ThisRF%STR(%' &ThisRF. / cl=Wald;);
				%END;
				%ELSE %DO;													
					%LET HStmtr&r.o&o.n1 = %STR(    HazardRatio %')&ThisRF.Grp%STR(%' &ThisRF.Grp / cl=Wald;);
				%END;																							
			%END;
			%ELSE %DO;
					%LET HStmtr&r.o&o.n1 = %STR(    HazardRatio %')CrossGrp%STR(%' CrossGrp / cl=Wald;);
			%END;
/*				
			%DO hr = 2 %TO &&N_HStmtr&r.o&o.; 
				%GLOBAL HStmtr&r.o&o.n&hr;
				%LET ThisCV = %SYSFUNC(strip(%UPCASE(%SCAN(&CVlist,%EVAL(&hr-1), %STR( )))));	
				%LET HStmtr&r.o&o.n&hr = %STR(    HazardRatio %')&ThisCV%STR(%' &ThisCV/ cl=Wald;);
			%END;
*/
			*** ODS output statement;
			%LET OStmtr&r.o&o. = %STR(    ODS Output NObs = _Nobs_ ConvergenceStatus = _ConvergenceStatus_
													FitStatistics = _FitStatistics_ GlobalTests = _GlobalTests_ /*CensoredSummary = _CSr&r.o&o._ */
													Type3 = _Type3r&r.o&o._ ClassLevelInfo = _Classr&r.o&o._
													HazardRatios = HR_&ThisRF._&ThisOutcome. ParameterEstimates = PE_&ThisRF._&ThisOutcome.
													;
									);

			*** Run statment;
			%LET Rstmt = %STR(Run;);
			/***; %PUT 	&Rstmt; */

			*** Note;
			%GLOBAL N_NBr&r.o&o.;
			%IF %UPCASE(&ThisRFType) eq CONTINUOUS and "&ALY" eq "SIM" %THEN %DO;
				%LET N_NBr&r.o&o. = 0;
			%END;
			%ELSE %DO;
				%GLOBAL Nbr&r.o&o.n0;
				%LET Nbr&r.o&o.n0 = %STR(/&Empty.*  N.B.); 

				%IF %UPCASE(&ThisRFType) ne CONTINUOUS %THEN %DO;
					%DO i = 1 %TO %EVAL(&&N_RFmidr&r.o&o.);		
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET M = %SCAN(&&RFmidr&r.o&o.,&i,%STR( ));
						%LET L = %SCAN(&&RFbandr&r.o&o.,&i,%STR( ));
						%LET U = %SCAN(&&RFbandr&r.o&o.,%EVAL(&i+1),%STR( ));
						%IF &i = 1 %THEN %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        &ThisRF.Grp = &M when &L <= &ThisRF < &U);
						%END;
						%ELSE %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(                    = &M when &L <= &ThisRF < &U);
						%END;
					%END;
					%IF &&RFminErrR&r.o&o. gt 0 %THEN %DO;
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        ***Some values found in the specified RFband are less than or equal to the minimum of &ThisRF..);
					%END;
					%IF &&RFmaxErrR&r.o&o. gt 0 %THEN %DO;
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        ***Some values found in the specified RFband are greater than or equal to the maximum of &ThisRF..);
					%END;
				%END;
				%IF "&ALY" eq "MUL" %THEN %DO;
					%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
					%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
					%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        CrossGrp = &ThisRF.Grp * AgeBand;);
					%DO k = 1 %TO %EVAL(&&N_Agemidr&r.o&o.);	
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET M = %SCAN(&&Agemidr&r.o&o.,&k,%STR( ));
						%LET L = %SCAN(&&AgeBandr&r.o&o.,&k,%STR( ));
						%LET U = %SCAN(&&AgeBandr&r.o&o.,%EVAL(&k+1),%STR( ));
						%IF &k = 1 %THEN %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        AgeBand = &M when &L <= Age < &U);
						%END;
						%ELSE %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(               = &M when &L <= Age < &U);
						%END;
					%END;
					%IF &&AgeMinErrR&r.o&o. lt 0 %THEN %DO;
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        ***Some values found in the specified AgeBand are less than or equal to the minimum of Age.);
					%END;
					%IF &&AgeMaxErrR&r.o&o. lt 0 %THEN %DO;
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        ***Some values found in the specified AgeBand are greater than or equal to the maximum of Age.);
					%END;
				%END;
				%IF "&ALY" ne "SIM" %THEN %DO;
					%DO j = 1 %TO %EVAL(&N5A -1);			
						%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
						%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
						%LET M = %SYSEVALF( (%SCAN(&Band5A,&j,%STR( ))+ %SCAN(&Band5A,%EVAL(&j+1),%STR( )))/2 );
						%LET L = %SCAN(&Band5A,&j,%STR( ));
						%LET U = %SCAN(&Band5A.,%EVAL(&j+1),%STR( ));
						%IF &j = 1 %THEN %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(        XAgeGrp = &M when &L <= Age < &U);
						%END;
						%ELSE %DO;
							%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(                 = &M when &L <= Age < &U);
						%END;
					%END;
				%END;
				%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
				%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
				%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(*&Empty./); 
			%END;
		%END;
	%END;
%END;
%Mend Phreg;

%Phreg;

%Macro RunPhreg;
%IF &ParamError le 0 and %UPCASE(&RunType) eq DATA %THEN %DO; *********************;
	data _NULL_;
		*** Assign Library;
		call execute("&LibStmt");
	run;
%END;
%DO r = 1 %TO &N_RF;
	%DO o = 1 %TO &N_Outcome;
		%GLOBAL PhErrr&r.o&o. Statusr&r.o&o.;
		%LET PhErrr&r.o&o. = 0;
		%IF %UPCASE(&RunType) ne RUN %THEN %DO; *********************;
			%LET Statusr&r.o&o. = 0;
		%END;
	%END;
%END;

%IF &ParamError le 0 and %UPCASE(&RunType) eq RUN %THEN %DO; *********************;
	%DO r = 1 %TO &N_RF;
		%DO o = 1 %TO &N_Outcome;
			%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));			/***; %PUT Outcome = &ThisOutcome;*/
			%LET ThisRF = %SYSFUNC(strip(%UPCASE(&&RF&r)));			/***; %PUT RF = &ThisRF;*/
			%LET ThisCenVal = %SCAN(&CensorValue,&o, %STR( ));
			%LET ThisRFType = &&RFType&r;							

			data _NULL_;
				*** Assign Library;
				call execute("&LibStmt");
				*** Proc statement;
				call execute("&&PStmtr&r.o&o.");
				*** Class statement;
				%IF "&&CStmtr&r.o&o." ne " " %THEN %DO;
					call execute("&&CStmtr&r.o&o.");
				%END;
				*** Model statement;
				call execute("&&MStmtr&r.o&o.");
				*** Strata statement;
				%IF ("&ALY" eq "SIM" or "&ALY" eq "MUL") and  "&Strata" eq "&Space" %THEN %DO; %END;
				%ELSE %DO;
					call execute("&&SStmtr&r.o&o."); 
				%END;
				*** Hazard Ratio statement;					
				%DO hr = 1 %TO &&N_HStmtr&r.o&o.;	
					call execute("&&HStmtr&r.o&o.n&hr");
				%END;											
				*** ODS output statement;
				call execute("&&OStmtr&r.o&o.");
				*** Run statment;
				call execute("&Rstmt"); 
			run;
			
		/*	%PUT  SYSERR = &SYSERR;*/

			%LET PhErrr&r.o&o. = &SYSERR;

			%IF &SYSERR = 0 %THEN %DO;
				proc sql noprint; select Status into: Statusr&r.o&o. from _ConvergenceStatus_;
				%IF &&Statusr&r.o&o. eq 0 %THEN %DO;
					%GLOBAL NObsRr&r.o&o. NObsUr&r.o&o.;
					proc sql noprint; select NObsRead, NObsUsed into :NObsRr&r.o&o., :NObsUr&r.o&o. from _NObs_;

					proc sql noprint stimer;
					create table Fit_&ThisRF._&ThisOutcome as
					select g.Test, f.Criterion, f.WithoutCovariates, f.WithCovariates, g.ChiSq, g.DF, g.ProbChiSq
					from (select * from _FitStatistics_ where monotonic() = 1 ) as f,
						 (select * from _GlobalTests_ where monotonic() = 1 ) as g
					;quit;

					proc sql noprint stimer;
					create table _CSr&r.o&o._ as
					select distinct 
						%IF %UPCASE(&ThisRFType) ne CONTINUOUS %THEN %DO; 
							"&ThisRF.Grp" as RF, 
							Compress(put(&ThisRF.Grp, best.)) as RF_Level, 
						%END;
						%ELSE %DO;
							"&ThisRF." as RF, 
							" " as RF_Level, 
						%END;
						%IF &ALY eq MUL %THEN %DO;
							AgeBand, CrossGrp,
						%END;
						Sum(case when Censor ne &ThisCenVal then 1 else 0 end) as NEvents, Count(*) as NObs, 
						Sum(case when Censor ne &ThisCenVal then 1 else 0 end)/Count(*) as Pct_Events format = percentn8.2,
						Sum(Tottime) as PYears
					from Data_&ThisRF._&ThisOutcome.
					group by 	RF, RF_Level	%IF &ALY eq MUL %THEN %DO;	,AgeBand, CrossGrp	%END;
					order by 	RF, RF_Level	%IF &ALY eq MUL %THEN %DO;	,CrossGrp %END;
					;																					


					%IF %sysfunc(exist(Fit_&ThisRF._&ThisOutcome)) %THEN %DO;
						data _fileCreateInfo_;
							dsid=open("Fit_&ThisRF._&ThisOutcome");
							FileTime = ATTRN(dsid, "MODTE");
							FileObs = ATTRN(dsid,"NLOBS"); 
							rc=close(dsid);
						run;

						proc sql noprint;
							insert into __DataCreated__
							select "SAS Dataset", "Work","Fit_&ThisRF._&ThisOutcome", FileTime
							from _fileCreateInfo_
							where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

						%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
							proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
						%END;
					%END;


					%IF %sysfunc(exist(HR_&ThisRF._&ThisOutcome.)) %THEN %DO;
						data _fileCreateInfo_;
							dsid=open("HR_&ThisRF._&ThisOutcome.");
							FileTime = ATTRN(dsid, "MODTE");
							FileObs = ATTRN(dsid,"NLOBS"); 
							rc=close(dsid);
						run;

						proc sql noprint;
							insert into __DataCreated__
							select "SAS Dataset", "Work","HR_&ThisRF._&ThisOutcome.", FileTime
							from _fileCreateInfo_
							where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

						%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
							proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
						%END;
					%END;

					%IF %sysfunc(exist(PE_&ThisRF._&ThisOutcome.)) %THEN %DO;
						data _fileCreateInfo_;
							dsid=open("PE_&ThisRF._&ThisOutcome.");
							FileTime = ATTRN(dsid, "MODTE");
							FileObs = ATTRN(dsid,"NLOBS"); 
							rc=close(dsid);
						run;

						proc sql noprint;
							insert into __DataCreated__
							select "SAS Dataset", "Work","PE_&ThisRF._&ThisOutcome.", FileTime
							from _fileCreateInfo_
							where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

						%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
							proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
						%END;
					%END;


				%END;
			%END;
			%ELSE %DO;
				%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(S={color=red FONTWEIGHT=BOLD} !!! Warning !!! The specified model did not converge.); 
				%LET N_NBr&r.o&o. = %EVAL(&&N_NBr&r.o&o. + 1);
				%GLOBAL Nbr&r.o&o.n&&N_NBr&r.o&o.;
				%LET Nbr&r.o&o.n&&N_NBr&r.o&o. = %STR(*&Empty./); 
			%END;
		%END;
	%END;
%END;
%Mend RunPhreg;

%RunPhreg;




/*--------------------------------------------------------------*/

