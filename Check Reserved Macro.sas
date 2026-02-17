%GLOBAL SameMacroWarn;

/****** Now in the beginning of "Run Cox Analysis System.sas" *******
proc catalog catalog=work.sasmacr;
   contents out = __Macro_Names__;
run;
*************************************************************************/


Data _ReservedMacro_;
input RName:$32.;
cards;
AnyError
AnyMatchVar
calculate_new_CI_tphreg
CheckAge
CheckAnyObs
CheckBrackets
CheckCensorDate
CheckCV
CheckDob
CheckID
CheckInParam
CheckMinMax
CheckPart1
CheckPart2
CheckPart3
CheckQuote
CheckRF
CheckRFequal
CheckStudyDate
CheckTimeVar
CheckValueExist
CheckVarEqual
CheckVarExist
CheckVarFormat
CheckVarName
CombineParamError
CSV
DataNameLen
DefaultMid
DeleteTemp
DelQuotes
DelWorkData
DirExist
ErrorData
ErrorFormat
FileExist
GetData
GetTempInFile
InParamData
Phreg
PrintPDF
PrintPhreg
qsterr
RequiredFilled
RunCoxSystem
RunFAR
RunPhreg
SetLog
SortString
run;

proc sql noprint;
	Create table _SameMacro_ as
	select distinct RName
	from _ReservedMacro_ a, (select NAME from __Macro_Names__ where type = 'MACRO') b
	where upper(a.RName) = upper(b.NAME)
	;

	select RName into : SameMacroWarn separated by ', ' from _SameMacro_;

quit;
