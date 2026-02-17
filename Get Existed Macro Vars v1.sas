Data _paramv_;
input vname:$32.;
cards;
AGEBAND
AGEMID
ANALYSIS
CENSORDATE
CENSORVALUE
CENT
COVARS
COVBASE
COVCLASS
COVORDER
DOB
ENDDATE
HIGHAGE
HIGHFU
ID
INPUTDIR
INPUTFILE
LOWAGE
LOWFU
OUTCOME
OUTPUTDIR
PROJDESC
PROJECT
RF
RFBAND
RFBASE
RFMID
RUNDESC
RUNTYPE
STARTDATE
STRATA
STUDYDATE
TIMEUNIT
TIMEVAR
WHERESTMT
XAGE
;
run;

/****** Now in the beginning of "Run Cox Analysis System.sas" *******
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
		if substr(vname,1,3) ne 'SYS' and substr(vname,1,3) ne '___' then output;
     end;
run;

proc sort; by vname; run;

data _NULL_;
rc = fdelete('mv');
run;
filename mv clear;
*************************************************************************/

data _keepmv_; ****	Need to delete this later;
	length vname $32;
	if _n_=1 then do;
		declare hash dr(dataset:'_paramv_');
		dr.definekey("vname");
		dr.definedata("vname");
		dr.definedone();
		call missing(vname);
	end;
	set _existedmv_;
	rc=dr.find(key: vname);
	if rc ne 0 then output;
	drop rc;
run;

/* Reserved Global Macro Names without &i &O &r, exclude those in _paramv_, ___start___ , __path__ */
Data _ReserveMV_;
RowNum = _N_;
input rmvName:$30.;
cards;
Nbr

HStmt

AgeBand
AgeMaxErr
AgeMid
AgeMinErr
CStmt 
Farfail
FarUsed
MStmt 
N_AgeBand
N_AgeMid
N_HStmt
N_NB
N_RFband 
N_RFmid 
NObsR 
NObsU
OStmt 
PhErr 
PStmt 
RFband 
RFmaxErr
RFmid 
RFminErr
SStmt 
Status


Cent
RF
RFband
RFbase
RFmid

AgeMaxErr
AgeMinErr
AgeObsErr
AgeObs
Both_RFband_Cent
Cent
CentErr
F
KeepVarName
KeepVarType
Msg
N_RFband
N_RFmid
RF
RFband
RFbandErr
RFbandNeeded 
RFbase 
RFmaxErr 
RFmid 
RFminErr 
RFmidErr
RFobs 
RFobsErr  
RFtype
RFtypeErr
RFbaseErr 
RFdimErr 
vfmt



___duration___ 
___end___ 
__Cnt_Param__
_50
_date
_datetime
_ddmmmyyyy 
_starttime
_time
AgeBandDf 
AgeBandErr 
AgeConfDim 
AgeErr 
AgeMidDf
AgeMidErr
AgeWarn
All4InClause
AllClass
ALY 
AnaBlank 
AnalysisDf 
AnalysisTypeErr
anyobs 
AnyObsDataErr 
Band5A
BaseClass
BaseValue
CensorDateDf 
CensorDateeqStudyDate
CensorDateErr
CensorDateNameErr
CensorDimErr 
CensorValErr
CensorValueDf 
Cent_Blank 
CentDf 
CovarsDf 
CovarseqCensorDate
CovarseqDob
CovarseqStrata
CovarseqStudyDate
CovarsNameErr
CovBaseDf 
CovClassDf 
CovOrderDf 
cross_b
CVbaseDimErr 
CVbaseValErr 
CVbaseValwarn 
CVclassDimErr 
CVclassValErr 
CVerr 
CVfmtErr 
CVneeded 
CVorderDimErr 
CVorderValErr 
DataNameLenErr 
DataNameLenErrV
DeDouble
DeSingle
dim
DobDf 
DobeqCensorDate
DobeqStudyDate
DobErr
DobNameErr
dsid
Empty 
EndDateDf 
EndDateErr 
HighAgeDf 
HighAgeErr
HighFUDf 
HighFUErr 
IDDf
IDeqCensorDate
IDeqCovars
IDeqDob
IDeqOutcome
IDeqOutcome_Date
IDeqRF
IDeqStrata
IDeqStudyDate
IDerr
IDFmt
IDNameErr
In_Mid
InDBlank 
InFBlank 
InParam
InputDirDf 
InputFileDf 
KeepVar
KeepVarNoRF
LibStmt
LowAgeDf 
LowAgeErr 
LowFUDf 
LowFUErr 
MatchVarErr
Max
Maximum
Min
Minimum 
N_AgeBand 
N_AgeMid 
N_Base 
N_Censor 
N_Cent 
N_CentErr 
N_Class 
N_CV 
N_f
N_InParam
N_Msg
N_Order 
N_Outcome 
N_RF 
N_RFband 
N_RFbandErr 
N_RFbase
N_RFbaseErr
N_RFmid 
N_RFmidErr 
N4max
N5A 
Nb_end  
Nb_start 
NoCensorVal
NonBaseClass
NonExistInputDir
NonExistInputFile
NonExistOutputDir
NonExistVar
NonExistVarname
Out_Mid
OutBlank  
Outcome_Date
Outcome_DateeqCensorDate
Outcome_DateeqCovars
Outcome_DateeqDob
Outcome_DateeqRF
Outcome_DateeqStrata
Outcome_DateeqStudyDate
OutcomeDf 
OutcomeeqCensorDate
OutcomeeqCovars
OutcomeeqDob
OutcomeeqRF
OutcomeeqStrata
OutcomeeqStudyDate
OutcomeErr 
OutcomeNameErr
OutputDir   
ParamError
Part1Err 
Part2Err
Part3Err 
ProjDescDf 
ProjectDf 
ProjectErr 
ReqUnfilled  
RF_Blank 
RFband_Blank 
RFbandBrktErr 
RFbandDf 
RFbase_Blank 
RFbaseDf
RFDf 
RFeqCensorDate
RFeqDob
RFeqStrata
RFeqStudyDate
RFequalErr
RFerr
RFfmtErr
RFmid_Blank 
RFmidBrktErr 
RFmidDf 
RFNameErr
RFwarn
Rstmt
RunDescDf 
RunTypeDf 
RunTypeErr 
SameMacroWarn
SameMVWarn
SameVarWarn
SameDataWarn
SameDataWarn_c
separator 
SortAge
SortRF
Space 
StartDateDf 
StartDateErr 
StrataDf 
StrataeqCensorDate
StrataeqDob
StrataeqStudyDate
StrataNameErr
StudyDateDf 
StudyDateErr
StudyDateNameErr
TempInFile
thisOutString
TimeErr 
TimeUnitDf  
TimeVarDf
TUnit_Blank 
TUnitErr 
TVar_Blank
TVarErr
UndScore
ValueFound
VFmt
WhereErr
WhereStmtDf 
XAgeDf 
XAgeErr
;
run;


proc sql;
	create table _MatchMV_ as 
	select a.RowNum, a.rmvName, b.vname,
			case when a.RowNum = 1 then "/\b"||compress(upcase(a.rmvName))||"\d{1,4}O\d{1,4}N\d{1,4}"||"\b/"
				 when a.RowNum = 2 then "/\b"||compress(upcase(a.rmvName))||"R\d{1,4}O\d{1,4}N1"||"\b/"
				 when a.RowNum >=3 and a.RowNum <= 27 then "/\b"||compress(upcase(a.rmvName))||"R\d{1,4}O\d{1,4}"||"\b/"
				 when a.RowNum >=28 and a.RowNum <=32 then "/\b"||compress(upcase(a.rmvName))||"\d{1,4}DF"||"\b/"
				 when a.RowNum >=33 and a.RowNum <=61 then "/\b"||compress(upcase(a.rmvName))||"\d{1,4}"||"\b/"
				 else "/\b"||compress(upcase(a.rmvName))||"\b/"
			end as Pattern,
			prxmatch(calculated Pattern,upcase(b.vname)) as Match
	from _ReserveMV_ a, _keepmv_ b
	having calculated Match > 0
	;

%GLOBAL SameMVWarn;

proc sql noprint;
	select distinct vname into: SameMVWarn separated by ', ' from _MatchMV_;
quit;

/*Reserved dataset variables 
supposed to be in "Check Control File Macros" under  %CheckVarExist*/
Data _ReserveVar_;
input Varname:$32.;
cards;
Age_in
Age_in_d 
Age_out
Age_out_d
AgeBand
CrossGrp
Date_in
Date_out
Estimate
FIRST
HazardRatio
HR
HRLowerCL
HRUpperCL
Key
LAST
LowerCL
Message
NEvents
NObs
Nuis
Parameter
PYears
QLowerCL 
QStdErr 
QUpperCL 
REGTIM
RF
StdErr
Time_In
Time_In_d
Time_In_m 
Time_In_w 
Time_In_y 
Time_Out
Time_Out_d
Time_Out_m
Time_Out_w
Time_Out_y
Tottime
Tottime_d
Tottime_m 
Tottime_w 
Tottime_y 
UpperCL
Value
var
XAgeGrp
;
run;


