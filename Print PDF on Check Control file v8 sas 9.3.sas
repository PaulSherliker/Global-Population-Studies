goptions reset=all;
options orientation = PORTRAIT nodate nocenter nonumber formdlim = " " TOPMARGIN=1cm BOTTOMMARGIN= 1cm LEFTMARGIN= 1cm RIGHTMARGIN=0.5cm;
ods escapechar="^";
%*let line= %STR(________________________________________________________________________________________________________);

%Macro ErrorFormat;
proc format;
Value $Msg
	"AnaBlank"  = "^S={font_weight=BOLD}Analysis ^S={FONTWEIGHT=MEDIUM} is missing."
	"InDBlank"  = "^S={font_weight=BOLD}InputDir ^S={FONTWEIGHT=MEDIUM} is missing."
	"InFBlank"  = "^S={font_weight=BOLD}InputFile ^S={FONTWEIGHT=MEDIUM} is missing."
	"OutBlank"  = "^S={font_weight=BOLD}Outcome ^S={FONTWEIGHT=MEDIUM} is missing."
	"RF_Blank"  = "^S={font_weight=BOLD}RF	^S={FONTWEIGHT=MEDIUM} is missing."
	"RFband_Blank"	= "^S={font_weight=BOLD}RFband ^S={FONTWEIGHT=MEDIUM} is missing."
	"RFmid_Blank"	= "^S={font_weight=BOLD}RFmid ^S={FONTWEIGHT=MEDIUM} is missing."
	"Cent_Blank"	= "^S={font_weight=BOLD}Cent ^S={FONTWEIGHT=MEDIUM} is missing."
	"RFbase_Blank"	= "^S={font_weight=BOLD}RFbase	^S={FONTWEIGHT=MEDIUM} is missing."
	"TUnit_Blank"	= "^S={font_weight=BOLD}TimeUnit	^S={FONTWEIGHT=MEDIUM} is missing."
	"TVar_Blank"	= "^S={font_weight=BOLD}TimeVar	^S={FONTWEIGHT=MEDIUM} is missing."
%IF &NonExistInputDir ne 0 and &NonExistOutputDir ne 0 %THEN %DO; 
	"NonExistInputDir" = "Both ^S={FONTWEIGHT=BOLD}  InputDir ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD} OutputDir ^S={FONTWEIGHT=MEDIUM}
							directory do not exist. This file is stored in ^S={Color=RED}  %_grabpath_\ ^S={Color=RED}."	
%END;
%ELSE %DO; 
	"NonExistInputDir" = "Directory does not exist."	
%END;
%IF &AnyObsDataErr = 0 %THEN %DO;
	"NonExistInputFile" = "SAS dataset does not exist in the ^S={FONTWEIGHT=BOLD}  InputDir ^S={FONTWEIGHT=MEDIUM} folder. Or no observation in dataset."	
%END;
%ELSE %DO;
	"NonExistInputFile" = "No observation in analysis dataset based on your parameters."	
%END;
	"NonExistOutputDir" = "	Note: Directory specified in ^S={FONTWEIGHT=BOLD} OutputDir ^S={FONTWEIGHT=MEDIUM} does not exist.	&InputDir\Output &_date 
							will be used."	
	"IDNameErr" = "Invalid SAS variable name."
	"OutcomeNameErr" = "Invalid SAS variable name."
	"RFNameErr" = "Invalid SAS variable name."
	"CovarsNameErr" = "Invalid SAS variable name."
	"StrataNameErr" = "Invalid SAS variable name."
	"DobNameErr" = "Invalid SAS variable name."
	"CensorDateNameErr" = "Invalid SAS variable name."
	"StudyDateNameErr" = "Invalid SAS variable name."
	"DataNameLenErr" = "The following combination of ^S={FONTWEIGHT=BOLD} Outcome, RF ^S={FONTWEIGHT=MEDIUM} are longer than 27 characters for naming the permanent analysis dataset: &DataNameLenErrV"
	"NonExistVar" = "The following variables are missing: ^S={FONTWEIGHT=BOLD} &NonExistVarname ^S={FONTWEIGHT=MEDIUM}."	
	"IDeqOutcome" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Outcome^S={FONTWEIGHT=MEDIUM}."
	"IDeqRF" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  RF^S={FONTWEIGHT=MEDIUM}."
	"IDeqCovars" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."
	"IDeqStrata" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Strata^S={FONTWEIGHT=MEDIUM}."
	"IDeqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob ^S={FONTWEIGHT=MEDIUM}."
	"IDeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate ^S={FONTWEIGHT=MEDIUM}."
	"IDeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate ^S={FONTWEIGHT=MEDIUM}."
	"IDeqOutcome_Date" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  ID ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM}."

	"Outcome_DateeqRF" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  RF^S={FONTWEIGHT=MEDIUM}."
	"Outcome_DateeqCovars" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."
	"Outcome_DateeqStrata" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Strata^S={FONTWEIGHT=MEDIUM}."
	"Outcome_DateeqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob^S={FONTWEIGHT=MEDIUM}."
	"Outcome_DateeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"Outcome_DateeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  'Outcome'_Date ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"OutcomeeqRF" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  RF^S={FONTWEIGHT=MEDIUM}."
	"OutcomeeqCovars" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."
	"OutcomeeqStrata" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Strata^S={FONTWEIGHT=MEDIUM}."
	"OutcomeeqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob^S={FONTWEIGHT=MEDIUM}."
	"OutcomeeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"OutcomeeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Outcome ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"RFeqStrata" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Strata^S={FONTWEIGHT=MEDIUM}."
	"RFeqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob^S={FONTWEIGHT=MEDIUM}."
	"RFeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"RFeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"CovarseqStrata" = "Same variable found in both ^S={FONTWEIGHT=BOLD}  Covars ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Strata^S={FONTWEIGHT=MEDIUM}."
	"CovarseqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Covars ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob^S={FONTWEIGHT=MEDIUM}."
	"CovarseqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Covars ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"CovarseqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Covars ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"StrataeqDob" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Strata ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  Dob^S={FONTWEIGHT=MEDIUM}."
	"StrataeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Strata ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"StrataeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Strata ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"DobeqCensorDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Dob ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	"DobeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  Dob ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  StudyDate^S={FONTWEIGHT=MEDIUM}."

	"CensorDateeqStudyDate" = "(Or) Same variable found in both ^S={FONTWEIGHT=BOLD}  StudyDate ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD}  CensorDate^S={FONTWEIGHT=MEDIUM}."
	/*Part 1*/
	"IDErr" = "More than one variable specified. Or variable specified is in SAS date/ date time value. Or values of this variable are not unique."
	"ProjectErr" = "The first character must be a letter (A, B, C, . . ., Z) or underscore (_). No space can be included."
	"RunTypeErr" = "Invalid value specified. Only ^S={FONTWEIGHT=BOLD}  RUN, DATA, CHECK ^S={FONTWEIGHT=MEDIUM}. ^S={FONTWEIGHT=BOLD}  CHECK ^S={FONTWEIGHT=MEDIUM} performed."	
	"AnalysisTypeErr" = "Invalid value specified. Only ^S={FONTWEIGHT=BOLD}  Simple ^S={FONTWEIGHT=MEDIUM}, ^S={FONTWEIGHT=BOLD}  Age-Stratified ^S={FONTWEIGHT=MEDIUM}, 
						^S={FONTWEIGHT=BOLD}  Multi-age group ^S={FONTWEIGHT=MEDIUM}."	
	/*Part 2*/
	"LowFUErr" = "Character value or more than 1 value found. Or non-integer value found. Or value is negative number. Or ^S={FONTWEIGHT=BOLD}    LowFU ^S={FONTWEIGHT=MEDIUM} 
					is greater than or equal to  ^S={FONTWEIGHT=BOLD} HighFU ^S={FONTWEIGHT=MEDIUM}."
	"HighFUErr" = "Character value or more than 1 value found. Or value is negative number. Or non-integer value found."
	"StartDateErr" = "<date> is not in ddmmmyyyy format or not a valid date or more than 1 value found. Or ^S={FONTWEIGHT=BOLD}    StartDate ^S={FONTWEIGHT=MEDIUM}is greater 
					than or equal to ^S={FONTWEIGHT=BOLD} EndDate ^S={FONTWEIGHT=MEDIUM}."
	"EndDateErr" = "<date> is not in ddmmmyyyy format or not a valid date or more than 1 value found."
	"LowAgeErr" = "Character value or more than 1 value found. Or value is negative number. Or ^S={FONTWEIGHT=BOLD}    LowAge ^S={FONTWEIGHT=MEDIUM} is greater than or equal 
					to ^S={FONTWEIGHT=BOLD} HighAge ^S={FONTWEIGHT=MEDIUM}. Or non-integer value found."
	"HighAgeErr" = "Character value or more than 1 value found. Or value is negative number. Or non-integer value found."
	/*Part 3*/
	"TUnitErr" = "Invalid value specified. Only ^S={FONTWEIGHT=BOLD}  Day ^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD}  Week ^S={FONTWEIGHT=MEDIUM} or 
						^S={FONTWEIGHT=BOLD}  Month ^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD}  Year ^S={FONTWEIGHT=MEDIUM}."	
	"TVarErr" = "Invalid value specified. Only ^S={FONTWEIGHT=BOLD}  Time_in Time_out ^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD}  Tottime ^S={FONTWEIGHT=MEDIUM}."	
	"OutcomeErr" = "^S={FONTWEIGHT=BOLD}Outcome ^S={FONTWEIGHT=MEDIUM} not numeric or 'Outcome'_date variable not SAS date/date time value."	
	"CensorDimErr" = "Number of elements does not agree with ^S={FONTWEIGHT=BOLD}  Outcome^S={FONTWEIGHT=MEDIUM}."	
%IF &NoCensorVal eq 0 %THEN %DO;
	"CensorValErr" = "Value not found in ^S={FONTWEIGHT=BOLD} Outcome ^S={FONTWEIGHT=MEDIUM} variable. Or invalid ^S={FONTWEIGHT=BOLD} WhereStmt ^S={FONTWEIGHT=MEDIUM}. Or formats need to be loaded before running the system."	
%END;
%ELSE %DO;
	"CensorValErr" = "Value not found in ^S={FONTWEIGHT=BOLD} Outcome ^S={FONTWEIGHT=MEDIUM} variable after generating the dataset(s) based on your parameters. Or invalid ^S={FONTWEIGHT=BOLD} WhereStmt ^S={FONTWEIGHT=MEDIUM}."	
%END;
	"CensorDateErr" = "More than 1 variable specified, or variable is not SAS data/date time value."	
	"StudyDateErr" = "More than 1 variable specified, or variable is not SAS data/date time value."	
	"RFequalErr" = "Some ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM} variables are the same. Please rename."
	"WhereErr" = "Unmatched parenthese."
	/*Part 4*/
	"RFfmtErr" = "Some variables are not numeric format."
	"RFbandBrktErr" = "Not all square brackets are paired or unnecessary brackets found."
	"RFmidBrktErr" = "Not all square brackets are paired or unnecessary brackets found."
	"N_RFbandErr" = "Dimensions of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM}  are not the same."
	"N_RFmidErr" = "Dimensions of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM} are not the same."
	"N_CentErr" = "Dimensions of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD} Cent ^S={FONTWEIGHT=MEDIUM}  are not the same."
	"N_RFbaseErr" = "Dimensions of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM} and ^S={FONTWEIGHT=BOLD} RFbase ^S={FONTWEIGHT=MEDIUM}  are not the same."
%IF &N_RF > 0 and %EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr) eq 0  %THEN  %DO;
 	%DO r = 1 %TO &N_RF;
	"Both_RFband_Cent&r" = "If ^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM} is filled, ^S={FONTWEIGHT=BOLD} Cent ^S={FONTWEIGHT=MEDIUM} should 
							be NA. If ^S={FONTWEIGHT=BOLD} Cent ^S={FONTWEIGHT=MEDIUM} is filled, ^S={FONTWEIGHT=BOLD} RFband 
							^S={FONTWEIGHT=MEDIUM} should be [ ]."
	"RFbandNeeded&r" = "If ^S={FONTWEIGHT=BOLD}RFbase ^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM} is filled,
						 ^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM} should be filled."	
	"CentErr&r" = "Value should be either NA or between 2 and 100. Or    ^S={FONTWEIGHT=BOLD} Cent ^S={FONTWEIGHT=MEDIUM} do not match the number of ^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM}."	
	"RFbaseErr&r" = "For categorical risk factor, value should be one of the followings: FIRST; LAST; between 1 and number of elements in 
				^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM}; between 1 and ^S={FONTWEIGHT=BOLD} Cent ^S={FONTWEIGHT=MEDIUM}. Or the value is not an integer. 
				For continuous risk factor, value should be NA."	
	"RFdimErr&r" = "Number of elements of ^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM} is not number of elements of ^S={FONTWEIGHT=BOLD} 
				RFband ^S={FONTWEIGHT=MEDIUM} minus 1."
	"RFbandErr&r"	= 	"^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM} have less than 2 groups or character value other than Min or Max was found."	
	"RFmidErr&r"	= 	"Character value found in ^S={FONTWEIGHT=BOLD} RFmid ^S={FONTWEIGHT=MEDIUM}."	
	"RFtypeErr&r" = "Risk factor can not be continuous when running Multi-Age Group analysis."
%IF &RFwarn ne 0 and &AnyObsDataErr eq 0 and &NoCensorVal eq 0 %THEN %DO;
	"RFminErr&r"	= "Some values found in ^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM} are less than the minimum of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM}.
						  ^S={FONTWEIGHT=BOLD} RFBand, RFMid ^S={FONTWEIGHT=MEDIUM} have been adjusted. Please see the following SAS Codes."	
	"RFmaxErr&r"	= "Some values found in ^S={FONTWEIGHT=BOLD} RFband ^S={FONTWEIGHT=MEDIUM} are greater than the maximum of ^S={FONTWEIGHT=BOLD} RF ^S={FONTWEIGHT=MEDIUM}.
						^S={FONTWEIGHT=BOLD} RFBand, RFMid ^S={FONTWEIGHT=MEDIUM} have been adjusted. Please see the following SAS Codes."		
%END;
	"RFobsErr&r"	= "&&RFobs&r"		
	%END;
%END;
	/*Part 5*/
	"CVneeded" = "^S={FONTWEIGHT=BOLD}Covars ^S={FONTWEIGHT=MEDIUM} is blank but ^S={FONTWEIGHT=BOLD} CovClass 
					^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD} CovOrder ^S={FONTWEIGHT=MEDIUM} or ^S={FONTWEIGHT=BOLD} CovBase 
					^S={FONTWEIGHT=MEDIUM} is filled."	
	"CVfmtErr" = "For categoical covariates, ^S={FONTWEIGHT=BOLD} CovClass ^S={FONTWEIGHT=MEDIUM} must be 1."
	"CVclassDimErr" = "Number of elements does not agree with ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."	
	"CVclassValErr" = "Invalid value specified. Only 0 or 1 is valid."	
	"CVorderDimErr" = "Number of elements does not agree with ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."	
	"CVorderValErr" = "Invalid value specified. For class covariate, only I or F allowed. For continuous covariates, only NA allowed."	
	"CVbaseDimErr" = "Number of elements does not agree with ^S={FONTWEIGHT=BOLD}  Covars^S={FONTWEIGHT=MEDIUM}."	
%IF &CVbaseValwarn ne 0 and &AnyObsDataErr eq 0 and &NoCensorVal eq 0 %THEN %DO;
	"CVbaseValErr" = "Some value(s) do(es) not exist in the covariate variable after generating the dataset(s)
							based on your parameters.   ^S={FONTWEIGHT=BOLD}   FIRST ^S={FONTWEIGHT=MEDIUM} is used instead."	
%END;
%ELSE %DO;
	"CVbaseValErr" = "Invalid value specified. Value must exist in the variable for class covariates.  NA must be specified for continuous covariates."	
%END;
	/*Part 6*/
	"DobErr" = "More than one variable specified. Or variable specified is not SAS date/ date time value."	
	"XAgeErr" = "More than one value specified. Or non-numeric value specified. Or value is not integer between 1 and 10."	
	"AgebandErr" = "^S={FONTWEIGHT=BOLD}AgeBand^S={FONTWEIGHT=MEDIUM} is required for ^S={FONTWEIGHT=BOLD}       Multi-age group ^S={FONTWEIGHT=MEDIUM} analysis.
					  Or non-integer value found.  Or Character value found. Or difference between consecutive values are not multiples of XAge.
						Or negative number found"	
	"AgeConfDim" = "Number of elements does not agree with ^S={FONTWEIGHT=BOLD}  AgeBand^S={FONTWEIGHT=MEDIUM}."	
	"AgeMidErr" = "Some values are character values."	
%IF &N_RF > 0 and %EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr) eq 0  %THEN  %DO;
 	%DO r = 1 %TO &N_RF;
	"AgeObsErr&r"	= "&&AgeObs&r"		
	%END;
%END;
	;
run;
quit;
%Mend ErrorFormat;
%ErrorFormat;


%Macro ErrorData;
Data _NULL_;
	format Key Value best12.;
	length Parameter $30. Msg $30;
	if _n_=1 then do;
		declare hash h(ordered:'a');	
		h.definekey('Key');
		h.definedata('Key','Parameter','Value','Msg');
		h.definedone();
		call missing(Key,Parameter,Value,Msg);
	end;
	Key = 1;
	Parameter = "Project";		Value =  &ProjectErr; 		Msg = "ProjectErr";		rca=h.add();	Key = Key + 1;	
	Parameter = "RunType";		Value =  &RunTypeErr; 		Msg = "RunTypeErr";		rca=h.add();	Key = Key + 1;	
	Parameter = "Analysis";		Value =  &AnalysisTypeErr; 	Msg = "AnalysisTypeErr";rca=h.add();	Key = Key + 1;	
	Parameter = "TimeUnit";		Value =  &TUnitErr; 		Msg = "TUnitErr";		rca=h.add();	Key = Key + 1;	
	Parameter = "TimeVar";		Value =  &TVarErr; 			Msg = "TVarErr";		rca=h.add();	Key = Key + 1;	
	%IF &ReqUnfilled = 1 %THEN %DO;
		Parameter = "Analysis";		Value =  &AnaBlank;		Msg = "AnaBlank";	rca=h.add();	Key = Key + 1;	
		Parameter = "InputDir";		Value =  &InDBlank; 	Msg = "InDBlank";	rca=h.add();	Key = Key + 1;	
		Parameter = "InputFile";	Value =  &InFBlank; 	Msg = "InFBlank";	rca=h.add();	Key = Key + 1;	
		Parameter = "Outcome";		Value =  &OutBlank; 	Msg = "OutBlank";	rca=h.add();	Key = Key + 1;	
		Parameter = "RF";			Value =  &RF_Blank; 	Msg = "RF_Blank";	rca=h.add();	Key = Key + 1;	
		Parameter = "RFband";		Value =  &RFband_Blank; Msg = "RFband_Blank";	rca=h.add();	Key = Key + 1;	
		Parameter = "RFmid";		Value =  &RFmid_Blank; 	Msg = "RFmid_Blank";	rca=h.add();	Key = Key + 1;	
		Parameter = "Cent";			Value =  &Cent_Blank; 	Msg = "Cent_Blank";		rca=h.add();	Key = Key + 1;	
		Parameter = "RFbase";		Value =  &RFbase_Blank; Msg = "RFbase_Blank";	rca=h.add();	Key = Key + 1;	
		Parameter = "TimeUnit";		Value =  &TUnit_Blank; 	Msg = "TUnit_Blank";	rca=h.add();	Key = Key + 1;	
		Parameter = "TimeVar";		Value =  &TVar_Blank;	Msg = "TVar_Blank";		rca=h.add();	Key = Key + 1;	
	%END;
	/*Part 1*/
	%IF &NonExistInputDir  ne 0 %THEN %DO;
		%IF &NonExistOutputDir ne 0 %THEN %DO; 
			Parameter = "InputDir";		Value =  &NonExistInputDir; 	Msg = "NonExistInputDir";	rca=h.add();	Key = Key + 1;	
			Parameter = "OutputDir";	Value =  &NonExistInputDir; 	Msg = "NonExistInputDir";	rca=h.add();	Key = Key + 1;	
		%END;
		%ELSE %DO; 
			Parameter = "InputDir";		Value =  &NonExistInputDir; 	Msg = "NonExistInputDir";	rca=h.add();	Key = Key + 1;	
		%END;
	%END;
	%IF &ReqUnfilled eq 0 and &NonExistInputDir  eq 0 %THEN %DO;
		%IF &NonExistOutputDir ne 0 %THEN %DO; 
			Parameter = "OutputDir";	Value =  &NonExistOutputDir;	Msg = "NonExistOutputDir";	rca=h.add();	Key = Key + 1;	
		%END;
		%IF &NonExistInputFile ne 0 %THEN %DO; 
			Parameter = "InputFile";	Value =  &NonExistInputFile; 	Msg = "NonExistInputFile";	rca=h.add();	Key = Key + 1;	
		%END;
		%ELSE %DO;
			%IF %EVAL	(&IDNameErr + &OutcomeNameErr + &CensorDateNameErr + &StudyDateNameErr + &RFNameErr + &CovarsNameErr + &StrataNameErr + &DobNameErr
						+ &Part1Err + &TimeErr) ne 0 %THEN %DO;
				Parameter = "ID";			Value =  &IDNameErr; 		Msg = "IDNameErr";			rca=h.add();	Key = Key + 1;	
				Parameter = "Outcome";		Value =  &OutcomeNameErr; 	Msg = "OutcomeNameErr";		rca=h.add();	Key = Key + 1;	
				Parameter = "CensorDate";	Value =  &CensorDateNameErr;Msg = "CensorDateNameErr";	rca=h.add();	Key = Key + 1;	
				Parameter = "StudyDate";	Value =  &StudyDateNameErr; Msg = "StudyDateNameErr";	rca=h.add();	Key = Key + 1;	
				Parameter = "RF";			Value =  &RFNameErr; 		Msg = "RFNameErr";			rca=h.add();	Key = Key + 1;	
				Parameter = "Covars";		Value =  &CovarsNameErr; 	Msg = "CovarsNameErr";		rca=h.add();	Key = Key + 1;	
				Parameter = "Strata";		Value =  &StrataNameErr; 	Msg = "StrataNameErr";		rca=h.add();	Key = Key + 1;	
				Parameter = "Dob";			Value =  &DobNameErr; 		Msg = "DobNameErr";			rca=h.add();	Key = Key + 1;	
			%END;
			%ELSE %DO;
				%IF %EVAL(&DataNameLenErr ne 0) %THEN %DO;
					Parameter = "Outcome";	Value =  &DataNameLenErr; 		Msg = "DataNameLenErr";		rca=h.add();	Key = Key + 1;	
					Parameter = "RF";		Value =  &DataNameLenErr; 		Msg = "DataNameLenErr";		rca=h.add();	Key = Key + 1;	
				%END;
				%ELSE %DO;
					%IF %EVAL(&WhereErr ne 0) %THEN %DO;
						Parameter = "WhereStmt";	Value =  &WhereErr; 			Msg = "WhereErr";	rca=h.add();	Key = Key + 1;	
					%END;
					%ELSE %DO;
						%IF &NonExistVar ne 0 %THEN %DO;
							Parameter = "InputFile";	Value =  &NonExistVar; 			Msg = "NonExistVar";	rca=h.add();	Key = Key + 1;	
						%END;
						%ELSE %DO;
							%IF &MatchVarErr ne 0 or &CensorDateErr ne 0 or &StudyDateErr ne 0 or &IDerr ne 0 or &DobErr ne 0 or &RFequalErr ne 0 %THEN %DO;
								Parameter = "CensorDate";	Value =  &CensorDateErr; 	Msg = "CensorDateErr";		rca=h.add();	Key = Key + 1;	
								Parameter = "StudyDate";	Value =  &StudyDateErr; 	Msg = "StudyDateErr";		rca=h.add();	Key = Key + 1;	
								Parameter = "Dob";			Value =  &DobErr; 			Msg = "DobErr";				rca=h.add();	Key = Key + 1;	
								Parameter = "ID";			Value =  &IDErr; 			Msg = "IDErr";				rca=h.add();	Key = Key + 1;	

								Parameter = "ID";			Value =  &IDeqOutcome; 		Msg = "IDeqOutcome";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &IDeqOutcome; 		Msg = "IDeqOutcome";	rca=h.add();	Key = Key + 1;	 
								Parameter = "ID";			Value =  &IDeqRF; 			Msg = "IDeqRF";			rca=h.add();	Key = Key + 1;	
								Parameter = "RF";			Value =  &IDeqRF; 			Msg = "IDeqRF";			rca=h.add();	Key = Key + 1;	
								Parameter = "ID";			Value =  &IDeqCovars; 		Msg = "IDeqCovars";		rca=h.add();	Key = Key + 1;	
								Parameter = "Covars";		Value =  &IDeqCovars; 		Msg = "IDeqCovars";		rca=h.add();	Key = Key + 1;	
								Parameter = "ID";			Value =  &IDeqStrata; 		Msg = "IDeqStrata";		rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &IDeqStrata; 		Msg = "IDeqStrata";		rca=h.add();	Key = Key + 1;	 
								Parameter = "ID";			Value =  &IDeqDob; 			Msg = "IDeqDob";		rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &IDeqDob; 			Msg = "IDeqDob";		rca=h.add();	Key = Key + 1;	 
								Parameter = "ID";			Value =  &IDeqCensorDate; 	Msg = "IDeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "CensorDate";	Value =  &IDeqCensorDate; 	Msg = "IDeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "ID";			Value =  &IDeqStudyDate; 	Msg = "IDeqStudyDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "StudyDate";	Value =  &IDeqStudyDate; 	Msg = "IDeqStudyDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "ID";			Value =  &IDeqOutcome_Date; Msg = "IDeqOutcome_Date";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &IDeqOutcome_Date; Msg = "IDeqOutcome_Date";	rca=h.add();	Key = Key + 1;	 

								Parameter = "Outcome";		Value =  &Outcome_DateeqRF; 		Msg = "Outcome_DateeqRF";	rca=h.add();	Key = Key + 1;	 
								Parameter = "RF";			Value =  &Outcome_DateeqRF; 		Msg = "Outcome_DateeqRF";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &Outcome_DateeqCovars; 	Msg = "Outcome_DateeqCovars";rca=h.add();	Key = Key + 1;	 
								Parameter = "Covars";		Value =  &Outcome_DateeqCovars; 	Msg = "Outcome_DateeqCovars";rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &Outcome_DateeqStrata; 	Msg = "Outcome_DateeqStrata";rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &Outcome_DateeqStrata; 	Msg = "Outcome_DateeqStrata";rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &Outcome_DateeqDob; 		Msg = "Outcome_DateeqDob";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &Outcome_DateeqDob; 		Msg = "Outcome_DateeqDob";	rca=h.add();	Key = Key + 1;	
			 					Parameter = "Outcome";		Value =  &Outcome_DateeqCensorDate; Msg = "Outcome_DateeqCensorDate";rca=h.add();	Key = Key + 1;	
								Parameter = "CensorDate";	Value =  &Outcome_DateeqCensorDate; Msg = "Outcome_DateeqCensorDate";rca=h.add();	Key = Key + 1;	
								Parameter = "Outcome";		Value =  &Outcome_DateeqStudyDate; 	Msg = "Outcome_DateeqStudyDate";	rca=h.add();	Key = Key + 1;	
								Parameter = "StudyDate";	Value =  &Outcome_DateeqStudyDate; 	Msg = "Outcome_DateeqStudyDate";	rca=h.add();	Key = Key + 1;	

								Parameter = "Outcome";		Value =  &OutcomeeqRF; 		Msg = "OutcomeeqRF";	rca=h.add();	Key = Key + 1;	 
								Parameter = "RF";			Value =  &OutcomeeqRF; 		Msg = "OutcomeeqRF";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &OutcomeeqCovars; 	Msg = "OutcomeeqCovars";rca=h.add();	Key = Key + 1;	 
								Parameter = "Covars";		Value =  &OutcomeeqCovars; 	Msg = "OutcomeeqCovars";rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &OutcomeeqStrata; 	Msg = "OutcomeeqStrata";rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &OutcomeeqStrata; 	Msg = "OutcomeeqStrata";rca=h.add();	Key = Key + 1;	 
								Parameter = "Outcome";		Value =  &OutcomeeqDob; 	Msg = "OutcomeeqDob";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &OutcomeeqDob; 	Msg = "OutcomeeqDob";	rca=h.add();	Key = Key + 1;	
			 					Parameter = "Outcome";		Value =  &OutcomeeqCensorDate; 	Msg = "OutcomeeqCensorDate";rca=h.add();	Key = Key + 1;	
								Parameter = "CensorDate";	Value =  &OutcomeeqCensorDate; 	Msg = "OutcomeeqCensorDate";rca=h.add();	Key = Key + 1;	
								Parameter = "Outcome";		Value =  &OutcomeeqStudyDate; 	Msg = "OutcomeeqStudyDate";	rca=h.add();	Key = Key + 1;	
								Parameter = "StudyDate";	Value =  &OutcomeeqStudyDate; 	Msg = "OutcomeeqStudyDate";	rca=h.add();	Key = Key + 1;	

								Parameter = "RF";			Value =  &RFeqStrata; 		Msg = "RFeqStrata";		rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &RFeqStrata; 		Msg = "RFeqStrata";		rca=h.add();	Key = Key + 1;	 
								Parameter = "RF";			Value =  &RFeqDob; 			Msg = "RFeqDob";		rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &RFeqDob; 			Msg = "RFeqDob";		rca=h.add();	Key = Key + 1;	 
								Parameter = "RF";			Value =  &RFeqCensorDate; 	Msg = "RFeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "CensorDate";	Value =  &RFeqCensorDate; 	Msg = "RFeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "RF";			Value =  &RFeqStudyDate; 	Msg = "RFeqStudyDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "StudyDate";	Value =  &RFeqStudyDate; 	Msg = "RFeqStudyDate";	rca=h.add();	Key = Key + 1;	
		 
								Parameter = "Covars";		Value =  &CovarseqStrata; 	Msg = "CovarseqStrata";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &CovarseqStrata; 	Msg = "CovarseqStrata";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Covars";		Value =  &CovarseqDob; 		Msg = "CovarseqDob";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &CovarseqDob; 		Msg = "CovarseqDob";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Covars";		Value =  &CovarseqCensorDate; 	Msg = "CovarseqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "CensorDate";	Value =  &CovarseqCensorDate; 	Msg = "CovarseqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Covars";		Value =  &CovarseqStudyDate; 	Msg = "CovarseqStudyDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "StudyDate";	Value =  &CovarseqStudyDate; 	Msg = "CovarseqStudyDate";	rca=h.add();	Key = Key + 1;	 

								Parameter = "Strata";		Value =  &StrataeqDob; 		Msg = "StrataeqDob";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Dob";			Value =  &StrataeqDob; 		Msg = "StrataeqDob";	rca=h.add();	Key = Key + 1;	
			 					Parameter = "Strata";		Value =  &StrataeqCensorDate; 	Msg = "StrataeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "CensorDate";	Value =  &StrataeqCensorDate; 	Msg = "StrataeqCensorDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "Strata";		Value =  &StrataeqStudyDate; 	Msg = "StrataeqStudyDate";	rca=h.add();	Key = Key + 1;	 
								Parameter = "StudyDate";	Value =  &StrataeqStudyDate; 	Msg = "StrataeqStudyDate";	rca=h.add();	Key = Key + 1;	
		 
								Parameter = "Dob";			Value =  &DobeqCensorDate; 		Msg = "DobeqCensorDate";	rca=h.add();	Key = Key + 1;	
								Parameter = "CensorDate";	Value =  &DobeqCensorDate; 		Msg = "DobeqCensorDate";	rca=h.add();	Key = Key + 1;	
								Parameter = "Dob";			Value =  &DobeqStudyDate; 		Msg = "DobeqStudyDate";		rca=h.add();	Key = Key + 1;	
								Parameter = "StudyDate";	Value =  &DobeqStudyDate; 		Msg = "DobeqStudyDate";		rca=h.add();	Key = Key + 1;	

								Parameter = "CensorDate";	Value =  &CensorDateeqStudyDate; Msg = "CensorDateeqStudyDate";	rca=h.add();	Key = Key + 1;	
								Parameter = "StudyDate";	Value =  &CensorDateeqStudyDate; Msg = "CensorDateeqStudyDate";	rca=h.add();	Key = Key + 1;
			
								Parameter = "RF";			Value =  &RFequalErr; 			Msg = "RFequalErr";	rca=h.add();	Key = Key + 1;	
							%END;
							%ELSE %DO;
								/*Part 2*/
								%LET String = LowFU HighFU StartDate EndDate LowAge HighAge;
								%DO a = 1 %TO 6;
									%LET This = %SCAN(&String,&a,%STR( )); 
									%IF  &&&This.Err ne 0 %THEN %DO;  
										Parameter = "&This";	Value =  &&&This.Err; 		Msg = "&This.Err";		rca=h.add();	Key = Key + 1;	
									%END;
								%END;
								/*Part 3*/
								%IF &Part3Err ne 0 or &NoCensorVal ne 0 %THEN %DO;
									Parameter = "Outcome";		Value =  &OutcomeErr; 		Msg = "OutcomeErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "CensorValue";	Value =  &CensorDimErr; 	Msg = "CensorDimErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CensorValue";	Value =  &CensorValErr; 	Msg = "CensorValErr";	rca=h.add();	Key = Key + 1;	
								%END;
								/*Part 4*/
								%IF &RFerr ne 0 or &RFwarn ne 0 %THEN %DO;
									Parameter = "RF";		Value =  &RFfmtErr; 		Msg = "RFfmtErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "RFband";	Value =  &RFbandBrktErr; 	Msg = "RFbandBrktErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "RFmid";	Value =  &RFmidBrktErr; 	Msg = "RFmidBrktErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "RF";		Value =  &N_RFbandErr; 		Msg = "N_RFbandErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "RFband";	Value =  &N_RFbandErr; 		Msg = "N_RFbandErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "RF";		Value =  &N_RFmidErr; 		Msg = "N_RFmidErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "RFmid";	Value =  &N_RFmidErr; 		Msg = "N_RFmidErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "RF";		Value =  &N_CentErr; 		Msg = "N_CentErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "Cent";		Value =  &N_CentErr; 		Msg = "N_CentErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "RF";		Value =  &N_RFbaseErr; 		Msg = "N_RFbaseErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "RFbase";	Value =  &N_RFbaseErr; 		Msg = "N_RFbaseErr";	rca=h.add();	Key = Key + 1;	
									%IF &N_RF > 0 and 
									%EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr + &RFbandBrktErr + &RFmidBrktErr + &RFfmtErr) eq 0  %THEN  %DO;
									 	%DO r = 1 %TO &N_RF;
											Parameter = "RFband&r";	Value =  &&RFbandErr&r; 		Msg = "RFbandErr&r";	rca=h.add();	Key = Key + 1;	
											Parameter = "RFband&r";	Value =  &&RFdimErr&r; 			Msg = "RFdimErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFmid&r";	Value =  &&RFdimErr&r; 			Msg = "RFdimErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFmid&r";	Value =  &&RFmidErr&r; 			Msg = "RFmidErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFbase&r";	Value =  &&RFbaseErr&r; 		Msg = "RFbaseErr&r";	rca=h.add();	Key = Key + 1;	
											Parameter = "Cent&r";	Value =  &&CentErr&r; 			Msg = "CentErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFband&r";	Value =  &&RFbandNeeded&r; 		Msg = "RFbandNeeded&r";	rca=h.add();	Key = Key + 1;	
											Parameter = "RFmid&r";	Value =  &&RFbandNeeded&r; 		Msg = "RFbandNeeded&r";	rca=h.add();	Key = Key + 1;	
											Parameter = "RFbase&r";	Value =  &&RFbandNeeded&r; 		Msg = "RFbandNeeded&r";	rca=h.add();	Key = Key + 1;	
											Parameter = "RFband&r";	Value =  &&Both_RFband_Cent&r; 	Msg = "Both_RFband_Cent&r";rca=h.add();	Key = Key + 1;	
											Parameter = "Cent&r";	Value =  &&Both_RFband_Cent&r; 	Msg = "Both_RFband_Cent&r";rca=h.add();	Key = Key + 1;	
											Parameter = "RFtype&r";	Value =  &&RFtypeErr&r; 		Msg = "RFtypeErr&r";	rca=h.add();	Key = Key + 1;	
											%IF &RFwarn ne 0 and &AnyObsDataErr eq 0 and &NoCensorVal eq 0 %THEN %DO;
											Parameter = "RFband&r";	Value =  &&RFminErr&r; 			Msg = "RFminErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFband&r";	Value =  &&RFmaxErr&r; 			Msg = "RFmaxErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFmid&r";	Value =  &&RFminErr&r; 			Msg = "RFminErr&r";		rca=h.add();	Key = Key + 1;	
											Parameter = "RFmid&r";	Value =  &&RFmaxErr&r; 			Msg = "RFmaxErr&r";		rca=h.add();	Key = Key + 1;	
											%END;
											Parameter = "RFband&r";	Value =  &&RFobsErr&r; 			Msg = "RFobsErr&r";		rca=h.add();	Key = Key + 1;	
										%END;
									%END;
								%END;
								/*Part 5*/
								%IF &CVerr ne 0 %THEN %DO;
									Parameter = "Covars";		Value =  &CVneeded; 		Msg = "CVneeded";		rca=h.add();	Key = Key + 1;	
									Parameter = "Covars";		Value =  &CVfmtErr; 		Msg = "CVfmtErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "CovClass";		Value =  &CVfmtErr; 		Msg = "CVfmtErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "CovClass";		Value =  &CVclassDimErr; 	Msg = "CVclassDimErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CovClass";		Value =  &CVclassValErr; 	Msg = "CVclassValErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CovOrder";		Value =  &CVorderDimErr; 	Msg = "CVorderDimErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CovOrder";		Value =  &CVorderValErr; 	Msg = "CVorderValErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CovBase";		Value =  &CVbaseDimErr; 	Msg = "CVbaseDimErr";	rca=h.add();	Key = Key + 1;	
									Parameter = "CovBase";		Value =  &CVbaseValErr; 	Msg = "CVbaseValErr";	rca=h.add();	Key = Key + 1;	
								%END;
								/*Part 6*/
								%IF &AgeErr ne 0 %THEN %DO;
									Parameter = "XAge";			Value =  &XAgeErr; 			Msg = "XAgeErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "AgeBand";		Value =  &AgebandErr; 		Msg = "AgebandErr";		rca=h.add();	Key = Key + 1;	
									%IF &N_RF > 0 and 
									%EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr + &RFbandBrktErr + &RFmidBrktErr + &RFfmtErr) eq 0  %THEN  %DO;
									 	%DO r = 1 %TO &N_RF;
										Parameter = "AgeBand";		Value =  &&AgeObsErr&r; 	Msg = "AgeObsErr&r";	rca=h.add();	Key = Key + 1;	
										%END;
									%END;
									Parameter = "AgeMid";		Value =  &AgeConfDim; 		Msg = "AgeConfDim";		rca=h.add();	Key = Key + 1;	
									Parameter = "AgeMid";		Value =  &AgeMidErr; 		Msg = "AgeMidErr";		rca=h.add();	Key = Key + 1;	
		/*							Parameter = "AgeBand";		Value =  &AgeMinErr; 		Msg = "AgeMinErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "AgeBand";		Value =  &AgeMaxErr; 		Msg = "AgeMaxErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "AgeMid";		Value =  &AgeMinErr; 		Msg = "AgeMinErr";		rca=h.add();	Key = Key + 1;	
									Parameter = "AgeMid";		Value =  &AgeMaxErr; 		Msg = "AgeMaxErr";		rca=h.add();	Key = Key + 1;	
		*/						%END;
							%END;
						%END;
					%END;
				%END;
			%END;
		%END;
	%END;
	rco = h.output(dataset: 'work._ErrorData_');
	stop;
run;

Data _ErrorData_;
	set _ErrorData_;
	Message = put(Msg,$Msg.); 
	label Message = 'Error Message'; 
	if Value ne 0 then output;
run;

%Mend ErrorData;
%ErrorData;


%Macro InParamData;
%IF &N_RF = 0 or (%EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr + &RFbandBrktErr + &RFmidBrktErr + &RFfmtErr) >0) %THEN  %DO;
	%LET InParam = %NRSTR(&RunType &Analysis &Project &ProjDesc &RunDesc &InputDir &InputFile &OutputDir &ID
						&LowFU &HighFU &StartDate &EndDate &LowAge &HighAge &WhereStmt &Outcome &CensorValue &CensorDate &StudyDate &TimeUnit &TimeVar
						&RF  &RFband &RFmid &Cent &RFbase
						&Covars &CovClass &CovOrder &CovBase &Strata &Dob &XAge &AgeBand &AgeMid);
	Data _NULL_; call symput('N_InParam' , 1 + count(strip(compbl("&InParam")),' '));	run; 
%END;
%ELSE %DO;
	%LET InParam = %NRSTR(&RunType &Analysis &Project &ProjDesc &RunDesc &InputDir &InputFile &OutputDir &ID
						&LowFU &HighFU &StartDate &EndDate &LowAge &HighAge &WhereStmt &Outcome &CensorValue &CensorDate &StudyDate &TimeUnit &TimeVar
						&Covars &CovClass &CovOrder &CovBase &Strata &Dob &XAge &AgeBand &AgeMid);
	Data _NULL_; call symput('N_InParam' , 1 + count(strip(compbl("&InParam")),' '));	run; 
%END;

Data _NULL_;
	format Key best12.;
	length Parameter $12. Value $300;
	if _n_=1 then do;
		declare hash h(ordered:'a');	
		h.definekey('Key');
		h.definedata('Key','Parameter','Value');
		h.definedone();
		call missing(Key,Parameter,Value);
	end;
	%IF &N_RF = 0 or (%EVAL(&N_RFbandErr + &N_RFmidErr + &N_CentErr + &N_RFbaseErr + &RFbandBrktErr + &RFmidBrktErr + &RFfmtErr) >0) %THEN  %DO;
		%DO _i = 1 %TO &N_InParam;
			%LET This = %qsubstr(%qSCAN(&InParam,&_i,%STR( )),2)Df;					
			Key = &_i.;
			Parameter = "%qsubstr(%qSCAN(&InParam,&_i,%STR( )),2)";
			%IF %SUBSTR(&&&This,1) = 1 %THEN %DO;
				Value = "^S={BACKGROUNDCOLOR=very light grey} %CMPRES(%SCAN(&InParam,&_i,%STR( )))";
			%END;
			%ELSE %DO;
				Value = "%BQUOTE(%CMPRES(%qSCAN(&InParam,&_i,%STR( ))))";
			%END;
			rca=h.add();
		%END;
	%END;
	%ELSE %DO;
		%DO _i = 1 %TO 22;
			%LET This = %qsubstr(%qSCAN(&InParam,&_i,%STR( )),2)Df;
			Key = &_i.;
			Parameter = "%qsubstr(%qSCAN(&InParam,&_i,%STR( )),2)";
			%IF %SUBSTR(&&&This,1) = 1 %THEN %DO;
				Value = "^S={BACKGROUNDCOLOR=very light grey}%CMPRES(%SCAN(&InParam,&_i,%STR( )))";
			%END;
			%ELSE %DO;
				Value = "%BQUOTE(%CMPRES(%qSCAN(&InParam,&_i,%STR( ))))";
			%END;
			rca=h.add();
		%END;
	 	%DO _j = 1 %TO &N_RF;
			Key = %EVAL(6*(&_j.-1)+1 +22);
			Parameter = "RF&_j";
			Value = "^S={BORDERTOPCOLOR=Gray }%CMPRES(&&RF&_j)";
			rca=h.add();
			Key = %EVAL(6*(&_j.-1)+2 +22);
			Parameter = "RFtype&_j";
			Value = "%CMPRES(&&RFtype&_j)";
			rca=h.add();
			Key = %EVAL(6*(&_j.-1)+3 +22);
			Parameter = "RFband&_j";
			Value = "%CMPRES(&&RFband&_j)";
			rca=h.add();
			Key = %EVAL(6*(&_j.-1)+4 +22);
			Parameter = "RFmid&_j";
			%IF &&RFmid&_j.Df = 1 %THEN %DO;
				Value = "^S={BACKGROUNDCOLOR=very light grey}%CMPRES(&&RFmid&_j)";
			%END;
			%ELSE %DO;
				Value = "%CMPRES(&&RFmid&_j)";
			%END;
			rca=h.add();
			Key = %EVAL(6*(&_j.-1)+5 +22);
			Parameter = "Cent&_j";
			Value = "%CMPRES(&&Cent&_j)";
			rca=h.add();
			Key = %EVAL(6*(&_j.-1)+6 +22);
			Parameter = "RFbase&_j";
			Value = "^S={BORDERBOTTOMCOLOR=Gray }%CMPRES(&&RFbase&_j)";
			rca=h.add();
		%END;
		%DO _k = 21 %TO &N_InParam;
			%LET This = %qsubstr(%qSCAN(&InParam,&_k,%STR( )),2)Df;
			Key = %EVAL(&_k. + 22 +  &N_RF*6);
			Parameter = "%qsubstr(%qSCAN(&InParam,&_k,%STR( )),2)";
			%IF %SUBSTR(&&&This,1) = 1 %THEN %DO;
				Value = "^S={BACKGROUNDCOLOR=very light grey}%CMPRES(%SCAN(&InParam,&_k,%STR( )))";
			%END;
			%ELSE %DO;
				Value = "%CMPRES(%SCAN(&InParam,&_k,%STR( )))";
			%END;
			rca=h.add();
		%END;
	%END;
	rco = h.output(dataset: 'work._InParam_');
	stop;
run; quit;

proc datasets library=work  nolist NODETAILS;
   modify _InParam_;
   label Value='Value. Default values in grey';
run; quit;
%Mend InParamData;
%InParamData;

%Macro CombineParamError;
Data _TempError_; set _ErrorData_; run;

%LET dsid=%SYSFUNC(open(work._ErrorData_)); 		
%LET pw=%SYSFUNC(attrn(&dsid,ANY)); 				
%IF &pw eq 1 %THEN %DO;
	proc sort data =  _TempError_ (Keep = Message Parameter Key) out = _TempError_;
		by parameter;
	run;

	proc transpose data = _TempError_ out = _TempError_ ;
		ID Key;
		by Parameter;
		var Message;
	run;

	proc contents data = _TempError_ short varnum out = _VarNameList_ noprint; run;
	proc sql noprint; select count(*) into:N_Msg from work._ErrorData_;								

	proc sql noprint; select NAME into:Msg1 -:Msg%sysfunc(COMPBL(&N_Msg)) from _VarNameList_ where substr(NAME,1,1) = '_' and NAME not in ('_LABEL_','_NAME_');

	Data _TempError_;
		Format Message $1000.;
		Set _TempError_;
		%IF &N_Msg > 1 %THEN %DO;
			Message = Catx("&Space" %DO i = 1 %TO %EVAL(&N_Msg-1); ,&&Msg&i %END; ,&&Msg&i); 
		%END;
		%ELSE %DO;
			Message = &Msg1; 
		%END;
	run;

	proc sql noprint;
	create table _InParamError_ as
	select distinct
		a.Key, a.Parameter, a.Value label = 'Value. Default values in grey',
		b.Message label =  %IF &ParamError gt 0 %THEN %DO; "Error Message" %END; %ELSE %DO; "Warnings" %END;
	from _InParam_ a left join _TempError_ b
	on a.Parameter = b.Parameter
	order by a.Key
	;quit;

%END;
%LET Dclose= %SYSFUNC(close(&dsid));	
%Mend CombineParamError;

%CombineParamError;












































%Macro PrintPDF;
%IF %SYMEXIST(ProjDesc) = 0 or "&ProjDesc" eq "&Empty" or "&ProjDesc" eq "&Space" %THEN %DO; 
	title "Cox Analysis System";
%END;
%ELSE %DO;
	title "Cox Analysis System for <&ProjDesc> Project";
%END;
%IF %SYMEXIST(RunDesc)and  "&RunDesc"	ne "&Empty" and "&RunDesc"	ne "&Space" %THEN %DO;
	title2 "&RunDesc";
%END;

%IF %SYMEXIST(Project) = 0%THEN %DO; %LET Project = %STR();	%END;
%IF &NonExistInputDir ne 0 and &NonExistOutputDir ne 0 %THEN %DO; 
	ODS RESULTS ON; 
%END;
%ELSE %IF &NonExistOutputDir ne 0 and &OutputDirDf eq 1 %THEN %DO; 
	ODS RESULTS ON; 
%END;
%ELSE %DO; 
	ODS RESULTS OFF; 
%END;
/*	footnote "^S={BACKGROUNDCOLOR=very light grey}Note: Parameter values in grey background are default values";*/
	%IF &ProjectErr eq 0 %THEN %DO;
		footnote1 h=7pt j=l "Control File->  %sysget(SAS_EXECFILEPATH)" ;
		footnote2 h=7pt j=l "This PDF File-> %CMPRES(&OutputDir.\&Project &_datetime.).pdf" j=r "Page ^{thispage} of ^{lastpage}";
		ods pdf notoc file = "&OutputDir.\&Project &_datetime..pdf"
	%END;
	%ELSE %DO;
		footnote1 h=7pt j=l "Control File->  %sysget(SAS_EXECFILEPATH)" ;
		footnote2 h=7pt j=l "This PDF File-> %CMPRES(&OutputDir.\&_datetime.).pdf" j=r "Page ^{thispage} of ^{lastpage}";
		ods pdf notoc file = "&OutputDir.\&_datetime..pdf"
	%END;
/*style = sasdocprinter Journal5*/
	style = Journal
	startpage=never
	%IF %SYMEXIST(RunDesc) %THEN %DO;
		title = "&RunDesc"
	%END;
	%IF %SYMEXIST(ProjDesc) %THEN %DO;
		subject = "&ProjDesc";
	%END;

	%LET dsid=%SYSFUNC(open(work._ErrorData_)); 
	%LET pw=%SYSFUNC(attrn(&dsid,ANY)); 
	%IF &pw %THEN %DO;
		ods pdf text = ' ';	
		proc print data = work._InParamError_ noobs label ; Var Parameter Value Message; run;
	%END;
	%ELSE %DO;
		ods pdf text = ' ';	
		proc print data = work._InParam_ noobs label; Var Parameter Value; run;
	%END;

	/*Reserved names warnings*/
	%IF %SYMEXIST(SameMacroWarn) = 1 and "&SameMacroWarn" ne "&Empty" and "&SameMacroWarn" ne "&Space" %THEN %DO; 
		ods pdf text = ' ';	
		ods pdf text = "^S={color=red}Warnings!!! Name(s) of the following macro(s) are reserved for the system and were deleted during this run:";	
		ods pdf text = "^S={color=red}		&SameMacroWarn.";	
	ods pdf text = ' ';	
	%END;
	%IF %SYMEXIST(SameMVWarn) = 1 and "&SameMVWarn" ne "&Empty" and "&SameMVWarn" ne "&Space" %THEN %DO; 
		ods pdf text = ' ';	
		ods pdf text = "^S={color=red}Warnings!!! Name(s) of the following macro variable(s) are reserved for the system and were deleted during this run:";	
		ods pdf text = "^S={color=red}		&SameMVWarn.";	
		ods pdf text = ' ';	
	%END;
	%IF %SYMEXIST(SameVarWarn) = 1 and "&SameVarWarn" ne "&Empty" and "&SameVarWarn" ne "&Space" %THEN %DO; 
		ods pdf text = ' ';	
		ods pdf text = "^S={color=red}Warnings!!! Name(s) of the following variable(s) in the input dataset are reserved for the system:";	
		ods pdf text = "^S={color=red}		&SameVarWarn.";	
		ods pdf text = ' ';	
	%END;
	%IF %SYMEXIST(SameDataWarn) = 1 and "&SameDataWarn" ne "&Empty" and "&SameDataWarn" ne "&Space" %THEN %DO; 
		ods pdf text = ' ';	
		ods pdf text = "^S={color=red}Warnings!!! Name(s) of the following dataset(s) are reserved for the system and were deleted/replaced during this run:";	
		ods pdf text = "^S={color=red}		&SameDataWarn_c.";	
		ods pdf text = ' ';	
	%END;

ods pdf style = Journal;	/*style = sasdocprinter Journal5dec;*/

	%IF &ParamError le 0 %THEN %DO; *********************;
		%PrintPhreg;
	%END;
	%LET Dclose= %SYSFUNC(close(&dsid));	

ods pdf style = Journal; /*	style = sasdocprinter Journal5;*/
	%IF %sysfunc(exist(__DataCreated__)) %THEN %DO;
		data _fileCreateInfo_;
			DC_id = open("__DataCreated__");
			if DC_id > 0 then do;
				call symputx('DC_Time', ATTRN(DC_id, "MODTE"));
				call symputx('DC_Obs', ATTRN(DC_id,"NLOBS")) ;
			end;
			else do;
				call symputx('DC_Time', 0);
				call symputx('DC_Obs', 0); 
			end;
			rc=close(DC_id);
		run;

		%IF &DC_Time > 0 and &DC_Obs > 0 %THEN %DO;
			ods pdf text = ' ';	
			ods pdf text =  'The following datasets/files were created:';	
			proc sort data = work.__DataCreated__ ; by Folder Data_Name; run;
			proc print data = work.__DataCreated__ noobs label; var Data_Type 	Data_Name		Last_Modified	Folder; run;
			ods pdf text = ' ';	
			Title2;
		%END;

		%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
			proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
		%END;
	%END;

ods pdf close;
%Mend PrintPDF;

ods listing close;
%PrintPDF;
ods listing;
title; footnote;
