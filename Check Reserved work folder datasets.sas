/* Reserved work folder datasets */

/****** Now in the beginning of "Run Cox Analysis System.sas" *******
ods output members = _existData_;
ods listing close;
proc datasets library = work  ;
run;quit;
ods listing;
*************************************************************************/

Data _existData_;
	set _existData_;
	if Memtype = 'DATA';
	name = upcase(name);
	keep name;
run;

Data _ReserveData_;
RowNum = _N_;
input rmvName:$30.;
cards;
CSV_
FAR_
Fit_
HR_
PE_
Data_

__tb_r
__tb2_r
__tm_r
__tm2_r
_Agedata_r
_DateRelated_r
_OtherData_r
_pctile_r
_RFdata_r

_Class
_Cov
_CS
_CSV_Data
_CSVhead
_NewClass
_Type3


__DataCreated__
__Macro_Names__
__Parameter_Exist__
_AgeData_
_AllKeepVar_
_AllMedian_
_CheckValueExist_
_ConvergenceStatus_
_DateRelated_
_deletemv_
_ErrorData_
_existedmv_
_existData_
_fileCreateInfo_
_FitStatistics_
_Function_
_GlobalTests_
_InParam_
_InParamError_
_keepmv_
_KeepVarContents_
_KeepVarNoRF_
_lookup_
_macrovars_
_MatchMV_
_MatchVar_
_MatchData_
_median_
_min_max_
_NewCov_
_NObs_
_NoDupKeepVar_
_NoDupKeepVarNoRF_
_NonExistVar_
_OrigAllVar_
_OtherData_
_paramv_
_pctile_
_ReservedMacro_
_ReserveMV_
_ReserveVar_
_ReserveData_
_RFData_
_SameMacro_
_TempError_
_TempInFile_
_VarNameList_
FAR
Parm0
QSE
QSEPLUM
;
run;


proc sql;
	create table _MatchData_ as 
	select a.RowNum, a.rmvName, b.name,
			case when a.RowNum <=6 then "/\b"||compress(upcase(a.rmvName))||"\S{0,}"||"\b/"
				 when a.RowNum >=7 and a.RowNum <=15 then "/\b"||compress(upcase(a.rmvName))||"\d{1,4}O\d{1,4}"||"\b/"
				 when a.RowNum >=16 and a.RowNum <=22 then "/\b"||compress(upcase(a.rmvName))||"R\d{1,4}O\d{1,4}_"||"\b/"
				 else "/\b"||compress(upcase(a.rmvName))||"\b/"
			end as Pattern,
			prxmatch(calculated Pattern,upcase(b.name)) as Match
	from _ReserveData_ a, _ExistData_ b
	having calculated Match > 0
	;

%GLOBAL SameDataWarn SameDataWarn_c;

proc sql noprint;
	select distinct name into: SameDataWarn_c separated by ', ' from _MatchData_;
	select distinct name into: SameDataWarn separated by ' ' from _MatchData_;
quit;

%MACRO DelWorkData;
%IF %SYMEXIST(SameDataWarn) = 1 and "&SameDataWarn" ne "&Empty" and "&SameDataWarn" ne "&Space" %THEN %DO; 
proc datasets library = work  NODETAILS NOLIST;
	delete &SameDataWarn;
run; quit;
%END;
%Mend DelWorkData;
%DelWorkData;

proc catalog cat = work.sasmacr;
delete  DelWorkData.Macro;
run; quit;
