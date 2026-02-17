proc sql noprint;
	create table __DataCreated__
       (Data_Type 		char(11),
		Folder		 	char(200),		
		Data_Name		char(50),
		Last_Modified	num(8) format=datetime19.
		);

%Macro CheckAnyObs(data);
	%GLOBAL anyobs dsid;
	%let dsid=%SYSFUNC(open(&data,i));		
	%let anyobs = %SYSFUNC(ATTRN(&dsid,ANY)) ;
	%LET Dclose= %SYSFUNC(close(&dsid));	

	%IF &anyobs ne 1 %THEN %DO;
		%LET NonExistInputFile = %EVAL(&NonExistInputFile + 1);			/*%PUT CheckAnyObs NonExistInputFile = &NonExistInputFile;*/
		%LET AnyObsDataErr = %EVAL(&AnyObsDataErr + 1);
	%END;
%Mend CheckAnyObs;


%Macro GetData;
%GLOBAL AnyObsDataErr CVbaseValwarn NoCensorVal;
%LET AnyObsDataErr = 0;		%LET CVbaseValwarn = 0;		%LET NoCensorVal = 0;

%DO r = 1 %TO &N_RF;
		%GLOBAL RFminErr&r RFmaxErr&r RFobs&r RFobsErr&r  RFwarn;
		%GLOBAL AgeMinErr&r AgeMaxErr&r AgeObs&r AgeObsErr&r AgeWarn;
		%LET RFminErr&r = 0;		%LET RFmaxErr&r = 0;			%LET RFobs&r = %STR( );		%LET RFobsErr&r = 0;	%LET RFwarn = 0;
		%LET AgeMinErr&r = 0;		%LET AgeMaxErr&r = 0;			%LET AgeObs&r = %STR( );	%LET AgeObsErr&r = 0;	%LET AgeWarn = 0;
%END;

%IF &ParamError le 0 %THEN %DO; *********************;
/* To get SAS date value from datetime value */
	%LET NewParam = NewCensorDate NewStudyDate NewDob NewOutcome_Date ;	
	%LET InParam = &CensorDate &StudyDate &Dob &Outcome_Date ;			
	%LET NewOutcome_Date = %STR( );
	%LET N_InParam = %EVAL(3 + &N_Outcome); 

	%DO i = 1 %TO &N_InParam;	
		%CheckVarFormat(Data = InLib.&InputFile, Var=%SCAN(&InParam,&i,%STR( )), Fmt=Vfmt); 
		%IF %EVAL(&i lt 4) %THEN %DO;
			%IF &Vfmt eq DATETIME %THEN %DO;
				%LET %SCAN(&NewParam,&i,%STR( )) = %STR(datepart%()%SCAN(&InParam,&i,%STR( ))%STR(%));
			%END;
			%ELSE %DO;
				%LET %SCAN(&NewParam,&i,%STR( )) = %SCAN(&InParam,&i,%STR( ));
			%END; 																		
		%END;
		%ELSE %DO;
			%IF &Vfmt eq DATETIME %THEN %DO;
				%LET %SCAN(&NewParam,4,%STR( )) = &NewOutcome_Date.%STR(datepart%()%SCAN(&InParam,&i,%STR( ))%STR(%))%STR( );
			%END;
			%ELSE %DO;
				%LET %SCAN(&NewParam,4,%STR( )) = &NewOutcome_Date.%SCAN(&InParam,&i,%STR( ))%STR( );
			%END;																
		%END;
	%END;
	%GetTempInFile;

/*Data step to get Cox-ready dataset*/
	%DO r = 1 %TO &N_RF;
		%DO o = 1 %TO &N_Outcome;

			%GLOBAL RFbandr&r.o&o. N_RFbandr&r.o&o. RFmidr&r.o&o. N_RFmidr&r.o&o. RFminErrR&r.o&o. RFmaxErrR&r.o&o. ;
			%LET RFminErrR&r.o&o. = 0;	%LET RFmaxErrR&r.o&o. = 0;

			%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));
			%LET ThisNewOutDate = %SCAN(&NewOutcome_Date,&o, %STR( ));
			%LET ThisOutDate = %SCAN(&Outcome_Date,&o, %STR( ));
			%LET ThisCenVal = %SCAN(&CensorValue,&o, %STR( ));

			%CheckVarFormat(Data = InLib.&InputFile, Var=&ID, Fmt= IDFmt);
			
			Data _DateRelated_r&r.o&o. (index = (&ID));  ****	Need to delete this later;
				set &TempInFile (/*obs = 50*/ keep = &ID &CensorDate &StudyDate &Dob &ThisOutDate &ThisOutcome);*;   /******** !!! OBS OBS OBS !!!*************/
				format Date_in Date_out Date9.;

			%IF &Analysis eq MultiAgeGroup %THEN %DO; 								/*	%PUT Ageband in DateRelated = &Ageband;*/
				%LET first = %SCAN(&AgeBand,1,%STR( )); 							/*	%PUT First  in DateRelated = ___&first.___;*/
				%LET last = %SCAN(&AgeBand,&N_AgeBand,%STR( )); 					/*	%PUT Last  in DateRelated = ___&last.___;*/
				%IF %UPCASE(&first) ne MIN %THEN %DO;
					Date_in = Max("&StartDate"d, intnx('year',&NewStudyDate,&LowFu,'sameday'), intnx('year',&NewDob,&first,'sameday')); /*intnx('year',&NewDob,&LowAge,'sameday') ,*/ 
				%END;
				%IF %UPCASE(&last) ne MAX %THEN %DO;		/*%PUT ThisOutDate = &ThisNewOutDate;*/
					Date_out = Min("&EndDate"d,  intnx('year',&NewStudyDate,%EVAL(&HighFu),'sameday')-1, &NewCensorDate, &ThisNewOutDate, intnx('year',&NewDob,&last,'sameday')-1); /*intnx('year',&NewDob,&HighAge+1,'sameday')-1,*/ 
				%END;
				%LET first = ;
				%LET last = ;
			%END;
			%ELSE %DO;		/*%PUT ThisOutDate = &ThisNewOutDate;*/
				Date_in = Max("&StartDate"d, intnx('year',&NewStudyDate,&LowFu,'sameday'),  intnx('year',&NewDob,&LowAge,'sameday'));
				Date_out = Min("&EndDate"d,  intnx('year',&NewStudyDate,%EVAL(&HighFu),'sameday')-1,&NewCensorDate, &ThisNewOutDate, intnx('year',&NewDob,&HighAge+1,'sameday')-1);
			%END;

				Age_in = yrdif(&NewDob, Date_in, 'ACT/ACT');
				Age_out = yrdif(&NewDob, Date_out, 'ACT/ACT');

				%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;
					Age_in_d = datdif(&NewDob, Date_in, 'ACT/ACT');
					Age_out_d = datdif(&NewDob, Date_out, 'ACT/ACT');
				%END;

				if Date_in <= Date_out then output;
/**			put "***************************************!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!";*/ 
			run;

			%CheckAnyObs(_DateRelated_r&r.o&o.);
			%IF &anyobs ne 1 %THEN %DO;		%GOTO Exit;		%END;

			/*** GET RFband Min Max value ****/

			data _RFdata_r&r.o&o. (index = (&ID)); ****	Need to delete this later;
				%IF &IDFmt eq NUM %THEN %DO; length &ID 8; %END;
				%IF &IDFmt eq CHAR %THEN %DO; length &ID $20; %END;
				if _n_=1 then do;
					declare hash dr(dataset:"_DateRelated_r&r.o&o.");
					dr.definekey("&ID");
					dr.definedata("&ID");
					dr.definedone();
					call missing(&ID);
				end;
				set &TempInFile (keep = &ID &&RF&r);
				rc=dr.find(key: &ID);
				if rc=0 then output;
				drop rc;
			run;

			%CheckAnyObs(_RFdata_r&r.o&o.);
			%IF &anyobs ne 1 %THEN %DO;		%GOTO Exit;		%END;

*************;
			%IF %UPCASE(&&RFType&r) eq CENT %THEN %DO;
				%LET div = %SYSEVALF(100/&&Cent&r/2);
				%LET _pct = %STR(0 );
				%DO _x_ = 1 %TO %EVAL(&&Cent&r *2);
					%LET _pct = &_pct.%STR( )%SYSEVALF(&_x_*&div);
				%END;														/*	%PUT _pct= &_pct;			*/						
				%LET _p_band = %STR(_0, );
				%DO _y_ = 1 %TO %EVAL(&&Cent&r);
					%LET _p_band = &_p_band.%STR( _)%SYSEVALF(&_y_*2)%STR(,);		
				%END;																	
				%LET _p_band = %SUBSTR(&_p_band,1,%EVAL(%LENGTH(&_p_band)-1));		/*	%PUT _p_band = &_p_band;*/

				%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;	
					%LET _p_mid = %STR(a);
					%DO _z_ = 1 %TO %EVAL(&&Cent&r *2) %BY 2;
						%LET _p_mid = &_p_mid.%STR( _)&_z_%STR(,);				
					%END;																		
					%LET _p_mid = %SUBSTR(&_p_mid.,2,%EVAL(%LENGTH(&_p_mid.)-2));		/*	%PUT _p_mid = &_p_mid.;*/
				%END;

				proc capability data = _RFdata_r&r.o&o. (keep = &&RF&r) NOPRINT;
				    var &&RF&r;
					output out = _pctile_r&r.o&o. pctlpts= &_pct. PCTLPRE= _ ;
				run;

				proc transpose data = _pctile_r&r.o&o. out = _pctile_r&r.o&o. ; run;
				Data _pctile_r&r.o&o. ; set _pctile_r&r.o&o. ; Order = _N_-1; run;
				proc sort data = _pctile_r&r.o&o. ; by COL1; run;

				proc sql ;
				create table __tb_r&r.o&o.  as select distinct * from _pctile_r&r.o&o. where mod(Order,2) = 0 order by Order;
				%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
					create table __tm_r&r.o&o.  as select distinct * from _pctile_r&r.o&o. where mod(Order,2) = 1 order by Order;
				%END;

				proc transpose data = __tb_r&r.o&o.  out = __tb2_r&r.o&o.  prefix = _; id Order;  run;
				%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
					proc transpose data = __tm_r&r.o&o.  out = __tm2_r&r.o&o.  prefix = _; id Order; run;
				%END;

				Data _NULL_;
				length new_band $10000;
				set __tb2_r&r.o&o. ;
				call catx(" ",new_band,&_p_band);
				call symput("RFbandr&r.o&o.",new_band);
				run;

				%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
					Data _NULL_;
					length new_mid $10000;
					set __tm2_r&r.o&o. ;
					call catx(" ",new_mid,&_p_mid);
					call symput("RFmidr&r.o&o.",new_mid);
					run;
				%END;
				%ELSE %DO;
					%LET RFmidr&r.o&o. = &&RFmid&r;
				%END;

/*%PUT RFbandr&r.o&o.  = &&RFbandr&r.o&o. ;
%PUT RFmidr&r.o&o.   = &&RFmidr&r.o&o.  ;*/

				/* add 0.000001 to maximum value */
				proc sql noprint; select  count(*) into:N4max  from _pctile_r&r.o&o. where mod(monotonic(),2) = 1; quit;
				%LET MinValue = %SCAN(&&RFbandr&r.o&o.,1,%STR( ));		/*%PUT MinValue = &MinValue;*/
				%LET MaxValue = %SCAN(&&RFbandr&r.o&o.,&N4max,%STR( ));	/*%PUT MaxValue = &MaxValue;	*/
				%CheckMinMax(Data = work._RFdata_r&r.o&o., Var = &&RF&r);	/*	%PUT Minimum = &Minimum	Maximum = &Maximum   plus1 =%SYSEVALF(&Maximum + 0.000001);		*/
				%LET RFbandr&r.o&o. = &Minimum%STR( )%SUBSTR(&&RFbandr&r.o&o.,%EVAL(%LENGTH(&MinValue)+1),%EVAL(%LENGTH(&&RFbandr&r.o&o.)-(%LENGTH(&MaxValue)+%LENGTH(&MinValue)+1)))%STR( )%SYSEVALF(&Maximum + 0.000001);/*%PUT RFbandr&r.o&o. = &&RFbandr&r.o&o.;*/

				%LET N_RFbandr&r.o&o. = %EVAL(&&Cent&r +1);					***;
				%LET N_RFmidr&r.o&o. = &&Cent&r;		***;

			%END;

			%IF %UPCASE(&&RFType&r) eq BAND %THEN %DO;
/*				proc sql noprint; select min(&&RF&r), max(&&RF&r) into: Min, :Max from _RFdata_r&r.o&o.; quit;*/
				%CheckMinMax(Data = work._RFdata_r&r.o&o., Var = &&RF&r);
				%LET Min = &Minimum;
				%LET Max = &Maximum;

				%LET Max = %SYSEVALF(&Max + 0.000001);			/*%PUT Min = &Min Max = &Max;*/
						
				%LET TempRF = &&RFband&r;		

				%IF %EVAL(%INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MIN )) ne 0) eq 1  %THEN %DO;		
					%LET TempRF = %SYSFUNC(tranwrd(%STR( )%UPCASE(&TempRF)%STR( ),%STR( MIN ),%STR( )&MIN%STR( )));			
				%END;
				%IF %EVAL(%INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MAX )) ne 0) eq 1 %THEN %DO;		
					%LET TempRF = %SYSFUNC(tranwrd(%STR( )%UPCASE(&TempRF)%STR( ),%STR( MAX ),%STR( )&MAX%STR( )));			
				%END;

				%SortString(InString = &TempRF, OutString = SortRF);	
				%LET N_SortRF = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&SortRF),%STR( ))));

				data _NULL_;
					length New_RF New_mid$500;
					LeMin = 0; 
					GeMax = 0; 
					tempRF = symget("SortRF");		
					tempMid = symget("RFmid&r");		
					tempMin = symget("Min");
					tempMax = symget("Max");
					count = count(COMPBL(tempRF),' ');
					New_RF = ' ';
					New_mid = ' ';

					array RF(&N_SortRF) _TEMPORARY_ (&SortRF);
			/*		%PUT Index Min : %INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MIN )); */
			/*		%PUT Index Max : %INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MAX )); */
					do i = 1 to count;
						%IF %EVAL(%INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MIN ))  gt 0 ) eq 1 %THEN %DO;		
							if RF(i) lt tempMin then do;	LeMin = LeMin + 1; 		end;		/*	put i = 	LeMin = ;*/
						%END;
						%IF %EVAL(%INDEX(%STR( )%UPCASE(&&RFband&r)%STR( ),%STR( MAX )) gt 0 ) eq 1 %THEN %DO;		
							if RF(i) gt tempMax then do;	GeMax = GeMax + 1; 		end;		/*	put i = 	GeMax = ;*/
						%END;
					end;
					do j = 1 + LeMin to count - GeMax ;
						New_RF = CATX(' ', New_RF, scan(tempRF,j,' '));						/*	put j = 	New_RF = ;*/
					end;

					do k = 1 + LeMin to count - GeMax -1 ;
						New_mid = CATX(' ', New_mid, scan(tempMid,k,' '));					/*	put k = 	New_mid = ;*/
					end;

					call symputx ("RFminErrR&r.o&o." , LeMin) ;                                                 
					call symputx ("RFmaxErrR&r.o&o." , GeMax) ;                                                 
					call symputx ("RFbandr&r.o&o." , New_RF) ;                                                 
					call symputx ("RFmidr&r.o&o." , New_mid) ;                                                 
				run;

				%LET N_RFbandr&r.o&o. =%EVAL(%QSYSFUNC(Count(%cmpres(&&RFbandr&r.o&o. dummyvar),%STR( ))));				
				%LET N_RFmidr&r.o&o. =%EVAL(&&N_RFbandr&r.o&o. - 1);				

				%LET RFwarn = %EVAL(&RFwarn + &&RFminErr&r + &&RFmaxErr&r);
				%LET RFminErr&r = %EVAL(&&RFminErr&r + &&RFminErrR&r.o&o.);
				%LET RFmaxErr&r = %EVAL(&&RFmaxErr&r + &&RFmaxErrR&r.o&o.);

				%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
					%DefaultMid(Data = _RFdata_r&r.o&o., Var = &&RF&r, N_Var = &&N_RFbandr&r.o&o., InString = &&RFbandr&r.o&o., OutString = thisOutString); /* %PUT thisOutString = &thisOutString;*/
					%Let RFmidr&r.o&o. = &thisOutString;
					%LET N_RFmidr&r.o&o. = %EVAL(%SYSFUNC(count(%cmpres(&&RFmidr&r.o&o. dummyvar),%STR( ))));	/*%PUT N_RFbandr&r.o&o. = &&N_RFbandr&r.o&o. RFbandr&r.o&o.  = &&RFbandr&r.o&o. RFmidr&r.o&o. = &&RFmidr&r.o&o.;	****;		*/
				%END;
			%END;

*!!**!!!**;	%IF %UPCASE(&&RFType&r) ne CONTINUOUS %THEN %DO;
				%IF %EVAL(&&N_RFmidr&r.o&o. gt 0) %THEN %DO;
				data _RFdata_r&r.o&o.(index = (&ID)); 
					set _RFdata_r&r.o&o.;

					array RFBand(&&N_RFbandr&r.o&o.) _TEMPORARY_ (&&RFbandr&r.o&o.);
					array RFMid(&&N_RFmidr&r.o&o.) _TEMPORARY_ (&&RFmidr&r.o&o.);	
					do I_RF = 1 to &&N_RFmidr&r.o&o.;
						if RFband(I_RF) le &&RF&r lt RFband(I_RF + 1) then &&RF&r..Grp = RFmid(I_RF); 
						/* 	Missing value of &&RF&r will fall under the lowest group, it'll be remove from the dataset at the last
							step "Data_&&RF&r.._&ThisOutcome" using "if &&RF&r ne . then output"
							instead of &&RF&r..Grp. This is because of the use of index of _DateRelated_r&r.o&o. to merge all the datasets.
							Using _DateRelated_r&r.o&o. as the base to index and all other store in memory using hash tables because
							_DateRelated_r&r.o&o. generally holds most of the output variables. */
					end;
					output;
					drop I_RF;
				run;
				%END;

				%CheckAnyObs(_RFdata_r&r.o&o.);		
		
				%LET TempRFobs = %STR();		
				%DO I_RF = 1 %TO %EVAL(&&N_RFbandr&r.o&o. - 1);
					%IF %EVAL(&&RFmid&r.Df eq 1) %THEN %DO;
						%LET ValueFound = 0;
						%DO J_RF = 1 %TO &&N_RFmidr&r.o&o.;  
							/*	%PUT i = &I_RF j = &J_RF 
												%SCAN(&&RFbandr&r.o&o.,&I_RF, %STR( ))		 	%SCAN(&&RFmidr&r.o&o.,&J_RF, %STR( )) 
																							%SCAN(&&RFbandr&r.o&o.,%EVAL(&I_RF+1), %STR( ));*/
							%IF 	%SYSEVALF(	%SCAN(&&RFbandr&r.o&o.,&I_RF, %STR( )) le 		%SCAN(&&RFmidr&r.o&o.,&J_RF, %STR( ))				) 
								and %SYSEVALF(  %SCAN(&&RFmidr&r.o&o.,&J_RF, %STR( )) lt 	%SCAN(&&RFbandr&r.o&o.,%EVAL(&I_RF+1), %STR( ))			) 
							%THEN %DO; 
									%LET ValueFound = %EVAL(&ValueFound + 1); 
							%END;
							%ELSE %DO;
									%LET ValueFound = %EVAL(&ValueFound + 0); 
							%END;							
						%END;
					%END;
					%ELSE %DO;
						%IF &anyobs eq 1 %THEN %DO;		
							%CheckValueExist(Data = _RFdata_r&r.o&o., Var = &&RF&r..Grp, Value = %SCAN(&&RFmidr&r.o&o.,&I_RF, %STR( )));	/*	%PUT %STR(ok CheckValueExist) Value = %SCAN(&&RFmidr&r.o&o.,&I_RF, %STR( )) ValueFound = &ValueFound;*/
						%END;
					%END;
					%IF &ValueFound = 0 %THEN %DO;		/*	%PUT %STR(IF ValueFound = 0);*/
						%LET RFobsErr&r = %EVAL(&&RFobsErr&r + 1);		/*	%PUT RFobsErr&r = &&RFobsErr&r;*/
						%LET RFerr = %EVAL(&RFerr + 1000);				/*		%PUT RFerr = &RFerr;*/
						%LET TempRFobs = &TempRFobs.%STR(, )%SCAN(&&RFbandr&r.o&o.,&I_RF, %STR( ))%STR(-)%SCAN(&&RFbandr&r.o&o.,%EVAL(&I_RF+1), %STR( )); 
					%END;
				%END;
				%IF %EVAL(&&RFobsErr&r > 0) %THEN %DO;
					%LET RFobs&r = &&RFobs&r..%STR(For outcome: )&ThisOutcome.%STR( there is no observation in catagory: )%QSUBSTR(&TempRFobs,3);	/*%PUT RFobs&r = &&RFobs&r;*/
				%END;
			%END;	/*	%PUT %STR(End of _RFdata_2);*/
			%IF &anyobs ne 1 %THEN %DO;		%GOTO Exit;		%END;
			%IF %EVAL(&&RFobsErr&r > 0) %THEN %DO;	%GOTO Exit; %END;

/*	%PUT RFbandr&r.o&o. = &&RFbandr&r.o&o. 		RFmidr&r.o&o. = &&RFmidr&r.o&o.;*/
/*	%PUT N_RFbandr&r.o&o. = &&N_RFbandr&r.o&o. 		N_RFmidr&r.o&o. = &&N_RFmidr&r.o&o.;*/
/*	%PUT RFminErr&r = &&RFminErr&r 		RFmaxErr&r = &&RFmaxErr&r ;*/
/*	%PUT RFwarn = &RFwarn;*/
/*	%PUT RFobsErr&r = &&RFobsErr&r RFobs&r = &&RFobs&r;*/
/*	%PUT RFmid&r.Df = &&RFmid&r.Df;*/
/*	%PUT ;*/
			%GLOBAL AgeBandr&r.o&o. N_AgeBandr&r.o&o. AgeMidr&r.o&o. N_AgeMidr&r.o&o. AgeMinErrR&r.o&o. AgeMaxErrR&r.o&o. ;
			%LET AgeMinErrR&r.o&o. = 0;	%LET AgeMaxErrR&r.o&o. = 0;

			/*** GET Ageband Min Max value ****/
			%IF &Analysis eq MultiAgeGroup %THEN %DO;

/*				proc sql noprint; select min(Age_in), max(Age_out) into: Min, :Max from _DateRelated_r&r.o&o.; quit;*/
				%CheckMinMax(Data = work._DateRelated_r&r.o&o., Var = Age_in);
				%LET Min = &Minimum;
				%CheckMinMax(Data = work._DateRelated_r&r.o&o., Var = Age_out);
				%Let Max = &Maximum;

				%LET Max = %SYSEVALF(&Max + 0.000001);		/*	%PUT Min = &Min Max = &Max;*/
						
				%LET TempAge = &AgeBand;

				%IF %EVAL(%INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MIN )) ne 0) eq 1  %THEN %DO;		
					%LET TempAge = %SYSFUNC(tranwrd(%STR( )%UPCASE(&TempAge)%STR( ),%STR( MIN ),%STR( )&MIN%STR( )));			
				%END;
				%IF %EVAL(%INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MAX )) ne 0) eq 1 %THEN %DO;		
					%LET TempAge = %SYSFUNC(tranwrd(%STR( )%UPCASE(&TempAge)%STR( ),%STR( MAX ),%STR( )&MAX%STR( )));			
				%END;

				%SortString(InString = &TempAge, OutString = SortAge);
				%LET N_SortAge = %EVAL(1 + %QSYSFUNC(Count(%cmpres(&SortAge),%STR( ))));

				data _NULL_;
					length New_Age New_mid$500;
					LeMin = 0; 
					GeMax = 0; 
					TempAge = symget("SortAge");	/* put TempAge =;*/
					tempMid = symget("AgeMid");		/* put tempMid =;*/
					tempMin = symget("Min");		/* put tempMin =;*/
					tempMax = symget("Max");		/* put tempMax =;*/
					count = count(COMPBL(TempAge),' ');
					New_Age = ' ';
					New_mid = ' ';

					array Age(&N_SortAge) _TEMPORARY_ (&SortAge);
		/*			%PUT Index Min : %INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MIN ));*/
		/*			%PUT Index Max : %INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MAX ));*/
					do i = 1 to count;
				%IF %EVAL(%INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MIN ))  gt 0 ) eq 1 %THEN %DO;		
						if Age(i) lt tempMin then do;	LeMin = LeMin + 1; 		end;		/*	put i = 	LeMin = ;*/
				%END;
				%IF %EVAL(%INDEX(%STR( )%UPCASE(&AgeBand)%STR( ),%STR( MAX )) gt 0 ) eq 1 %THEN %DO;		
						if Age(i) gt tempMax then do;	GeMax = GeMax + 1; 		end;		/*	put i = 	GeMax = ;*/
				%END;
					end;
					do j = 1 + LeMin to count - GeMax ;
						New_Age = CATX(' ', New_Age, scan(TempAge,j,' '));					/*	put j = 	New_Age = ;*/
					end;

					do k = 1 + LeMin to count - GeMax -1 ;
						New_mid = CATX(' ', New_mid, scan(tempMid,k,' '));					/*	put k = 	New_mid = ;*/
					end;

					call symputx ("AgeMinErrR&r.o&o." , LeMin) ;                                                 
					call symputx ("AgeMaxErrR&r.o&o." , GeMax) ;                                                 
					call symputx ("AgeBandr&r.o&o." , New_Age) ;                                                 
					call symputx ("AgeMidr&r.o&o." , New_mid) ;                                                 
				run;

				%LET N_Agebandr&r.o&o. = %EVAL(%QSYSFUNC(Count(%cmpres(&&Agebandr&r.o&o. dummyvar),%STR( ))));				
				%LET N_Agemidr&r.o&o.  = %EVAL(&&N_Agebandr&r.o&o. - 1);		

/*	%PUT Agebandr&r.o&o. = &&Agebandr&r.o&o. 		Agemidr&r.o&o. = &&Agemidr&r.o&o.;*/
/*	%PUT N_Agebandr&r.o&o. = &&N_Agebandr&r.o&o. 	N_Agemidr&r.o&o. = &&N_Agemidr&r.o&o.;*/

				%LET AgeWarn = %EVAL(&AgeWarn + &&AgeMinErr&r + &&AgeMaxErr&r);
				%LET AgeMinErr&r. = %EVAL(&&AgeMinErr&r + &&AgeMinErrR&r.o&o.);
				%LET AgeMaxErr&r. = %EVAL(&&AgeMaxErr&r + &&AgeMaxErrR&r.o&o.);

				%IF %EVAL(&&AgeMidDf eq 1) %THEN %DO; ****check if this exist;

					%DefaultMid(Data = _DateRelated_r&r.o&o., Var = Age_in, N_Var = &&N_AgeBandr&r.o&o., InString = &&AgeBandr&r.o&o., OutString = In_Mid);	/*%PUT In_Mid = &In_Mid;*/
					%DefaultMid(Data = _DateRelated_r&r.o&o., Var = Age_out, N_Var = &&N_AgeBandr&r.o&o., InString = &&AgeBandr&r.o&o., OutString = Out_Mid); /*%PUT Out_Mid = &Out_Mid;*/

					%LET AgeMidr&r.o&o. = %STR();
					%LET N_In_Mid =%EVAL(%QSYSFUNC(Count(%cmpres(&In_Mid dummyvar),%STR( ))));			/*	%PUT N_In_Mid = &N_In_Mid;*/
					%DO _m_ = 1 %TO %EVAL(&N_In_Mid);
/*						%LET x = %SYSEVALF(0.5*%SCAN(&In_Mid,&_m_,%STR( ))) + %SYSEVALF(0.5*%SCAN(&Out_Mid,&_m_,%STR( )));		*/
/*					Start: Change from median to midpoint of AgeBand */
						%LET x = %SYSEVALF(0.5*%SCAN(&&AgeBandr&r.o&o.,&_m_,%STR( ))) + %SYSEVALF(0.5*%SCAN(&&AgeBandr&r.o&o.,%EVAL(&_m_+1),%STR( )));
/*					End: Change from median to midpoint of AgeBand */
						%LET x = %SYSFUNC(round(&x,.1));
						%LET AgeMidr&r.o&o. = &&AgeMidr&r.o&o.%STR( )&x;
					%END;
					%LET N_Agemidr&r.o&o. = %EVAL(%SYSFUNC(count(%cmpres(&&Agemidr&r.o&o. dummyvar),%STR( ))));	

				%END;

				%IF %EVAL(&&N_Agemidr&r.o&o. gt 0) %THEN %DO;
				data _Agedata_r&r.o&o. (index = (&ID)); 
					set _DateRelated_r&r.o&o. (Keep = &ID &Dob Date_in Date_out);

					array AgeB(&&N_Agebandr&r.o&o.) _TEMPORARY_ (&&Agebandr&r.o&o.);
					array AgeM(&&N_Agemidr&r.o&o.) _TEMPORARY_ (&&Agemidr&r.o&o.);	
					do A = 1 to &&N_Agemidr&r.o&o.;
/*						if AgeB(A) <= yrdif(&NewDob, Date_out, 'ACT/ACT') and yrdif(&NewDob, Date_in, 'ACT/ACT') < AgeB(A+1) then do;	*/
/* 						Start : Change to base on date rather than yrdif */
						if intnx('year', &NewDob, AgeB(A),'sameday') <= Date_out and Date_in < intnx('year', &NewDob, AgeB(A+1),'sameday') then do;
/* 						End : Change to base on date rather than yrdif */
							AgeBand = AgeM(A);
							output;
						end;
						else do;
							AgeBand = .;
							output;
						end;
					end;
					drop A;
				run;
				%END;
		
				%LET TempAgeobs = %STR();		
				%DO J_A = 1 %TO %EVAL(&&N_Agebandr&r.o&o. - 1);
					%IF %EVAL(&&AgeMidDf eq 1) %THEN %DO;
						%LET ValueFound = 0;
						%DO K_A = 1 %TO &&N_Agemidr&r.o&o.;  
										/*%PUT i = &J_A j = &K_A
													%SCAN(&&Agebandr&r.o&o.,&J_A, %STR( )) 				%SCAN(&&Agemidr&r.o&o.,&K_A, %STR( ))
																										%SCAN(&&Agebandr&r.o&o.,%EVAL(&J_A+1), %STR( )); */
							%IF 	%SYSEVALF( 		%SCAN(&&Agebandr&r.o&o.,&J_A, %STR( )) 		le 		%SCAN(&&Agemidr&r.o&o.,&K_A, %STR( ))				) 
								and %SYSEVALF(  	%SCAN(&&Agemidr&r.o&o.,&K_A, %STR( )) 		lt 		%SCAN(&&Agebandr&r.o&o.,%EVAL(&J_A+1), %STR( ))		) 
							%THEN %DO; %LET ValueFound = %EVAL(&ValueFound + 1); %END;
							%ELSE %DO; %LET ValueFound = %EVAL(&ValueFound + 0); %END;							
						%END;
					%END;
					%ELSE %DO;
						%CheckValueExist(Data = _Agedata_r&r.o&o. , Var = AgeBand, Value = %SCAN(&&Agemidr&r.o&o.,&J_A, %STR( )));		/*%PUT %STR(ok CheckValueExist) Value = %SCAN(&&Agemidr&r.o&o.,&J_A, %STR( )) ValueFound = &ValueFound;*/
					%END;
					%IF &ValueFound = 0 %THEN %DO;			/*%PUT %STR(IF ValueFound = 0);*/
						%LET AgeObsErr&r = %EVAL(&&AgeObsErr&r + 1);		/*	%PUT AgeObsErr&r = &&AgeObsErr&r;*/
						%LET AgeErr = %EVAL(&AgeErr + 1000);				/*		%PUT AgeErr = &AgeErr;*/
						%LET TempAgeObs = &TempAgeObs.%STR(, )%SCAN(&&Agebandr&r.o&o.,&J_A, %STR( ))%STR(-)%SCAN(&&Agebandr&r.o&o.,%EVAL(&J_A+1), %STR( )); 
					%END;
				%END;
				%IF %EVAL(&&AgeObsErr&r > 0) %THEN %DO;
					%LET AgeObs&r = &&AgeObs&r..%STR(For outcome: )&ThisOutcome.%STR( there is no observation in age catagory: )%QSUBSTR(&TempAgeobs,3);	/*%PUT AgeObs&r = &&AgeObs&r;*/
				%END;

/*		%PUT Agebandr&r.o&o. = &&Agebandr&r.o&o. 		Agemidr&r.o&o. = &&Agemidr&r.o&o.;*/
/*		%PUT N_Agebandr&r.o&o. = &&N_Agebandr&r.o&o. 	N_Agemidr&r.o&o. = &&N_Agemidr&r.o&o.;*/
/*		%PUT AgeMinErr&r = &&AgeMinErr&r 		AgeMaxErr&r = &&AgeMaxErr&r ;*/
/*		%PUT AgeWarn = &AgeWarn;*/
/*		%PUT AgeObsErr&r = &&AgeObsErr&r AgeObs&r = &&AgeObs&r;*/
/*		%PUT AgeMidDf = &&AgeMidDf;*/
/*		%PUT ;*/
			%END;
			%IF %EVAL(&&AgeObsErr&r > 0) %THEN %DO;		%GOTO Exit; 		%END;
*****!!!!!!!!!!!!!!!<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<********;

			/*** GET Covars and Strata ****/
			data _OtherData_r&r.o&o. (index = (&ID)); ****	Need to delete this later;
				%IF &IDFmt eq NUM %THEN %DO; length &ID 8; %END;
				%IF &IDFmt eq CHAR %THEN %DO; length &ID $20; %END;
				if _n_=1 then do;
					declare hash dr(dataset:"_DateRelated_r&r.o&o.");
					dr.definekey("&ID");
					dr.definedata("&ID");
					dr.definedone();
					call missing(&ID);
				end;
				set &TempInFile (keep = &ID &Strata &Covars);
				rc=dr.find(key: &ID);
				if rc=0 then output;
				drop rc;
			run;

			%CheckAnyObs(_OtherData_r&r.o&o. );
			%IF &anyobs ne 1 %THEN %DO;		%GOTO Exit;		%END;
			
			/*** Check if CovBase still exist in Covars ***/
			%IF %EVAL(&N_Base > 0) %THEN %DO;	
				%DO q = 1 %TO &N_CV;	/*%PUT upcase_CovBase_q = %UPCASE(%SCAN(&CovBase,&q));*/
					%IF %UPCASE(%SCAN(&CovBase,&q)) ne FIRST and %UPCASE(%SCAN(&CovBase,&q)) ne LAST and %UPCASE(%SCAN(&CovBase,&q)) ne NA %THEN %DO; 
						%CheckValueExist(Data = _OtherData_r&r.o&o. , Var = %SCAN(&Covars,&q,%STR( )), Value = %SCAN(&CovBase,&q,%STR( ))); /* %PUT %SCAN(&Covars,&q) %SCAN(&CovBase,&q);*/
						%IF &ValueFound = 0 %THEN %DO; 
							%LET CVbaseValwarn = %EVAL(&CVbaseValwarn - 1); 
/**/						%LET CovBase = %SYSFUNC(tranwrd(%STR( )&CovBase%STR( ),%STR( )%SCAN(&CovBase,&q,%STR( ))%STR( ),%STR( FIRST )));  /*  %PUT CovBase = &CovBase;*/
						%END;  					
					%END;
				%END;
			%END;

			%GLOBAL N5A Band5A;
			%IF &Analysis ne Simple %THEN %DO;
				%LET Band5A=;
				%IF &Analysis ne MultiAgeGroup %THEN %DO;
					%LET N5A = %SYSFUNC(Ceil(%SYSEVALF((&HighAge+1-&LowAge)/&XAge +1))); 		********************; /* %PUT N5A = &N5A;*/
					%LET begin = &LowAge;													*****; /* %PUT begin = &begin;*/
					%LET end = %SYSEVALF(&HighAge+1);													*****; /* %PUT end = &end;*/
				%END;
				%ELSE %DO;
					%LET N5A = %SYSEVALF((%SCAN(&&AgeBandr&r.o&o.,&&N_AgeBandr&r.o&o.,%STR( )) - %SCAN(&&AgeBandr&r.o&o.,1,%STR( )))/&XAge+1);*****; /* %PUT N5A = &N5A;*/
					%LET begin = %SCAN(&&AgeBandr&r.o&o.,1,%STR( ));						*****; /* %PUT begin = &begin;*/
					%LET end = %SCAN(&&AgeBandr&r.o&o.,&&N_AgeBandr&r.o&o.,%STR( ));		*****;/*  %PUT end = &end;*/
				%END;
				%DO A = 1 %TO &N5A;
					%IF &A < &N5A %THEN %DO;
						%LET Band5A = &Band5A.%STR( )%EVAL(&begin + (&A - 1) * &XAge);		
					%END;
					%ELSE %DO;
						%LET Band5A = &Band5A.%STR( )%EVAL(&end.);												/*%PUT Band5A= &Band5A;*/
					%END;
				%END;
			%END;

%IF %UPCASE(&RunType) ne CHECK %THEN %DO;
			/*** get veriable format  for length statment ****/

			%IF %UPCASE(&&RFType&r) ne CONTINUOUS %THEN %DO;
				%LET listvar= &&RF&r..Grp &&RF&r &Covars &Strata;
				Data _NULL_;
					set _RFdata_r&r.o&o. (obs = 1 keep = &&RF&r..Grp);
					call symput ("vfmt1",vformat(&&RF&r..Grp));
				run;
			%END;
			%ELSE %DO;
				%LET listvar= &&RF&r &Covars &Strata;
				Data _NULL_;
					set _RFdata_r&r.o&o. (obs = 1 keep = &&RF&r);
					call symput ("vfmt1",vformat(&&RF&r));
				run;
			%END;

			%LET cnt = %EVAL(%SYSFUNC(count(%cmpres(&listvar dummyvar),%STR( ))));
			%DO c = 2 %TO &cnt;
				Data _NULL_;
					set &TempInFile (obs = 1 keep = %SCAN(&listvar,&c));
					call symput ("vfmt&c",vformat(%SCAN(&listvar,&c)));
				run;
			%END;

			/*** merge all together ****/
			Data Data_&&RF&r.._&ThisOutcome (drop=rc);
				declare hash Other (dataset:"_OtherData_r&r.o&o. "); 
					rc = Other.DefineKey ("&ID");
					rc = Other.DefineData (ALL: 'YES');
					rc = Other.DefineDone ();
				declare hash RF (dataset:"_RFdata_r&r.o&o.");
					rc = RF.DefineKey ("&ID");
					rc = RF.DefineData (ALL: 'YES');
					rc = RF.DefineDone ();
	/*Col17*/	do until (eof) ;
					set _DateRelated_r&r.o&o. end = eof;
					format %DO c = 1 %TO &cnt; %SCAN(&listvar,&c) &&vfmt&c	%END;;
					rc= RF.find (); 
					rc= Other.find ();
					Censor = 0;
				%IF &Analysis eq Simple %THEN %DO;
				/* Date_out in data step of _DateRelated_r&r.o&o. has already minus 1 day from HighFU and HighAge, that's why it's <= Date_Out */
	/*own*/			if Date_in <= &ThisNewOutDate and &ThisNewOutDate <= Date_out and &ThisOutcome ne &ThisCenVal then Censor = 1; /*%PUT &ThisOutcome = &ThisCenVal;*/
					Tottime = yrdif(Date_in, Date_out, 'ACT/ACT');
					Time_In = round(yrdif(&NewStudyDate, Date_in, 'ACT/ACT'),.0001);
					Time_Out = yrdif(&NewStudyDate,  Date_out, 'ACT/ACT');		

					%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;
						Tottime_d = datdif(Date_in, Date_out, 'ACT/ACT');
						Time_In_d = datdif(&NewStudyDate, Date_in, 'ACT/ACT');
						Time_Out_d = datdif(&NewStudyDate, Date_out, 'ACT/ACT');
					%END;
/*			rounding is now done below because of adding the extra 0.9 day */ 
					%IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
						Tottime_w = Tottime_d/7;
/***/					Time_In_w = floor(Time_In_d/7);
						Time_Out_w = Time_Out_d/7;
					%END;

					%IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
/**!!!!!*/				Tottime_m = Tottime*12;
/**!!!!!*/				Time_In_m = floor(Time_In*12 + (.95/365.25)*12);
/**!!!!!*/				Time_Out_m = Time_Out*12;
					%END;

						Time_Out = round(Time_Out + .95/365.25,.0001);		Tottime = round(Tottime + .95/365.25,.0001);				
						%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;	Time_Out_d = Time_Out_d + .95;		Tottime_d = Tottime_d + .95;		%END;
						%IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;	
/***/						Time_Out_w = floor(Time_Out_w + (.95/365.25)/7);		
/***/						Tottime_w = floor(Tottime_w + (.95/365.25)/7);	
							if Tottime_w = 0 then Tottime_w = .1; 
							if Time_In_w = Time_Out_w then Time_Out_w = Time_Out_w + .1;
						%END;			
						%IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO; 	
/**!!!*/					Time_Out_m = floor(Time_Out*12 + (.95/365.25)*12);		
/*!!!**/					Tottime_m= floor(Tottime*12 + (.95/365.25)*12);	
							if Tottime_m = 0 then Tottime_m = 0.01; 
							if Time_In_m = Time_Out_m then Time_Out_m = Time_Out_m + .01;
						%END;			
/***/					%IF %UPCASE(&TimeUnit) eq YEAR %THEN %DO; 	
/**!!!!*/					Time_In_y = floor(Time_In + (.95/365.25));		
/***/						Time_Out_y = floor(Time_Out + (.95/365.25) );		
/***/						Tottime_y= floor(Tottime + (.95/365.25));	
/***/						if Tottime_y = 0 then Tottime_y = 0.001; 
/***/						if Time_In_y = Time_Out_y then Time_Out_y = Time_Out_y + .001;
/***/					%END;			
					%IF %UPCASE(&&RFType&r) ne CONTINUOUS %THEN %DO;
						if &&RF&r eq . or &&RF&r..Grp eq . then do; end; 
					%END;
					%ELSE %DO;
						if &&RF&r eq . then do; end; 
					%END;
						else do; output; end;
				%END;
				%ELSE %DO;
					%IF &Analysis eq MultiAgeGroup %THEN %DO;
						array Age_Band(&&N_AgeBandr&r.o&o.) _TEMPORARY_ (&&AgeBandr&r.o&o.);			/*%PUT ageband = &&AgeBandr&r.o&o.;*/
						array AgeMid(&&N_AgeMidr&r.o&o.) _TEMPORARY_ (&&AgeMidr&r.o&o.); 			/*%PUT agemid = &&AgeMidr&r.o&o.;*/
		/*Col25*/		do I_A = 1 to &&N_AgeMidr&r.o&o.;

			/*Col29*/	/**/if intnx('year',&NewDob,Age_Band(I_A),'sameday')  <= Date_out and Date_in < intnx('year',&NewDob,Age_Band(I_A+1),'sameday') then do;
								AgeBand = AgeMid(I_A);
					%END;
								array Band5A(&N5A) _TEMPORARY_ (&Band5A);		/*%PUT Band5A = &Band5A;*/
				/*Col33*/		do B = 1 to &N5A-1;
									%IF &Analysis eq MultiAgeGroup %THEN %DO;

					/*Col41*/			if Age_Band(I_A) <= (Band5A(B) + Band5A(B+1))/2 <= Age_Band(I_A+1)/**/
										and intnx('year',&NewDob,Band5A(B),'sameday') <= Date_out and Date_in < intnx('year',&NewDob,Band5A(B+1),'sameday') then do; 
									%END;
									%ELSE %DO;
					/*Col41*/			if intnx('year',&NewDob,Band5A(B),'sameday') <= Date_out and Date_in < intnx('year',&NewDob,Band5A(B+1),'sameday') then do; 
									%END;
											XAgeGrp = (Band5A(B) + Band5A(B+1))/2;
											%IF &Analysis eq MultiAgeGroup %THEN %DO;
												Nuis = XAgeGrp - AgeBand;
												format CrossGrp $13.;
												%IF %UPCASE(&&RFType&r) ne CONTINUOUS %THEN %DO;******************** ;
													CrossGrp = 'a'||put(AgeBand,4.1-R)||" rf"||put(&&RF&r..Grp,5.-R);	
												%END;
											%END;
											Age_in = yrdif(&NewDob,Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),'ACT/ACT');
											Age_out = yrdif(&NewDob,Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')),'ACT/ACT')-.05/365.25;

											%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;
												Age_In_d = datdif(&NewDob,Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),'ACT/ACT');
												Age_Out_d = datdif(&NewDob,Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')),'ACT/ACT')-.05;
											%END;

											/* It's &ThisNewOutDate <= Age_out but not < because 1 day from the end of the period has been taken out in the calculation of Age_out */
											if Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')) <= &ThisNewOutDate <= Min(Date_out,intnx('year',&NewDob,Band5A(B+1),'same')-1) and &ThisOutcome ne &ThisCenVal then Censor = 1;

											Time_In = round(yrdif(&NewStudyDate, Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),'ACT/ACT'),.0001);
											Time_Out = round(yrdif(&NewStudyDate, Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')), 'ACT/ACT')-.05/365.25,.0001);		
											Tottime = round(yrdif(Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')),'ACT/ACT')-.05/365.25,.0001);			

											%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;
												Time_In_d = datdif(&NewStudyDate, Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),'ACT/ACT');
												Time_Out_d = datdif(&NewStudyDate, Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')), 'ACT/ACT')-.05;
												Tottime_d = datdif(Max(Date_in,intnx('year',&NewDob,Band5A(B),'same')),Min(Date_out+1,intnx('year',&NewDob,Band5A(B+1),'same')),'ACT/ACT')-.05;		
												if Time_In_d = Time_Out_d then Time_Out_d = 0.1;	
												if Tottime_d = 0 then Tottime_d = 0.1;	
											%END;

											%IF %UPCASE(&TimeUnit) eq MONTH %THEN %DO;
/*!!!**/										Time_In_m = floor(Time_In*12 + (.95/365.25)*12);
/*!!!**/										Time_Out_m = floor(Time_Out*12 + (.95/365.25)*12);
/*!!!**/										Tottime_m = floor(Tottime*12 + (.95/365.25)*12);
												if Time_In_m = Time_Out_m then Time_Out_m = Time_Out_m + 0.01;
												if Tottime_m = 0 then Tottime_m = 0.01;
											%END;

											%IF %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
/***/											Time_In_w = floor(Time_In_d/7);
/***/											Time_Out_w = floor(Time_Out_d/7);
/***/											Tottime_w = floor(Tottime_d/7);
												if Time_In_w = Time_Out_w then Time_Out_w = Time_Out_w + 0.1;
												if Tottime_w = 0 then Tottime_w = 0.1;
											%END;
/***/										%IF %UPCASE(&TimeUnit) eq YEAR %THEN %DO; 	
/*!!!**/										Time_In_y = floor(Time_In + (.95/365.25));		
/*!!!**/										Time_Out_y = floor(Time_Out + (.95/365.25));		
/*!!!**/										Tottime_y= floor(Tottime + (.95/365.25));	
/***/											if Tottime_y = 0 then Tottime_y = 0.001; 
/***/											if Time_In_y = Time_Out_y then Time_Out_y = Time_Out_y + .001;
/***/										%END;			

											%IF %UPCASE(&&RFType&r) ne CONTINUOUS %THEN %DO;
												if &&RF&r eq . or &&RF&r..Grp eq . then do; end; 
											%END;
											%ELSE %DO;
												if &&RF&r eq . then do; end; 
											%END;
												else do; output; end;
					/*Col41*/			end;
				/*Col33*/		end;
					%IF &Analysis eq MultiAgeGroup %THEN %DO;
			/*Col29*/		end;
		/*Col25*/		end; 
						drop I_A;
					%END;
					drop B ;
				%END;
	/*Col17*/	end;
				stop; 
				%IF %UPCASE(&TimeUnit) eq MONTH or %UPCASE(&TimeUnit) eq WEEK %THEN %DO;
					drop Tottime_d  Time_In_d  Time_Out_d;
				%END;
				%IF %UPCASE(&TimeUnit) ne YEAR %THEN %DO;
					drop Age_In_d Age_Out_d;
				%END;
			run;

			/*** Check if CensorValue still exist in Outcome ***/			
			%CheckValueExist(Data = Data_&&RF&r.._&ThisOutcome, Var = Censor, Value = &ThisCenVal);	/*%PUT ThisCenVal = &ThisCenVal;*/
			%IF &ValueFound = 0 %THEN %DO;	
				%LET CensorValErr = %EVAL(&CensorValErr + 1);				/*	%PUT CensorValErr = &CensorValErr;*/
				%LET NoCensorVal = %EVAL(&NoCensorVal + &CensorValErr ); 		/*		%PUT NoCensorVal = &NoCensorVal;*/
				%GOTO Exit;
			%END;

			%IF %sysfunc(exist(Data_&&RF&r.._&ThisOutcome)) %THEN %DO;
				data _fileCreateInfo_;
					dsid=open("Data_&&RF&r.._&ThisOutcome");
					FileTime = ATTRN(dsid, "MODTE");
					FileObs = ATTRN(dsid,"NLOBS"); 
					rc=close(dsid);
				run;

				proc sql noprint;
					insert into __DataCreated__
					select "SAS Dataset", "Work","Data_&&RF&r.._&ThisOutcome", FileTime
					from _fileCreateInfo_
					where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

				%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
					proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
				%END;
			%END;

%END;	/*%IF %UPCASE(&RunType) ne CHECK*/
			%GOTO Exit;
%Exit:
			%IF %SYSFUNC(exist(_DateRelated_r&r.o&o.)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  _DateRelated_r&r.o&o. ; run; quit; %END;
			%IF %SYSFUNC(exist(_RFdata_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  _RFdata_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(_pctile_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  _pctile_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(__tb_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  __tb_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(__tm_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  __tm_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(__tb2_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  __tb2_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(__tm2_r&r.o&o.		)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  __tm2_r&r.o&o.		 ; run; quit; %END;
			%IF %SYSFUNC(exist(_Agedata_r&r.o&o.	)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  _Agedata_r&r.o&o.	 ; run; quit; %END;
			%IF %SYSFUNC(exist(_OtherData_r&r.o&o.	)) 	%THEN %DO; proc datasets library = work  NODETAILS NOLIST; delete  _OtherData_r&r.o&o.	 ; run; quit; %END;
		%END;
	%END; 
%END;
%Mend GetData;


%GetData;
