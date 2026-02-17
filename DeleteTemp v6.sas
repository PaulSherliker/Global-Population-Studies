%Macro DeleteTemp;
filename mv "%sysfunc(Getoption(WORK))\global_log00000000000000.txt";
proc printto log=mv NEW; run;

%PUT _GLOBAL_;

proc printto log=log; run;

data _macrovars_ (drop = word1);
  infile mv;
  input word1 $ @;
  if word1='GLOBAL' then
     do;
        input vname:$32. ;
		if substr(vname,1,3) ne 'SYS' and substr(vname,1,2) ne '__' then output;
     end;
run;

proc sort; by vname; run;

data _deletemv_; ****	Need to delete this later;
	length vname $32;
	if _n_=1 then do;
		declare hash dr(dataset:'_keepmv_');
		dr.definekey("vname");
		dr.definedata("vname");
		dr.definedone();
		call missing(vname);
	end;
	set _macrovars_;
	rc=dr.find(key: vname);
	if rc ne 0 then output;
	drop rc;
run;

%IF &__Cnt_Param__ eq 36 %THEN %DO;
	proc datasets library = work  NODETAILS NOLIST;
		delete _AllKeepVar_ _ErrorData_ _InParam_ _InParamError_ _KeepVarContents_ _NoDupKeepVar_ _NonExistVar_ _OrigAllVar_ _pctile_ 
				_KeepVarNoRF_ _NoDupKeepVarNoRF_
				_VarNameList_ _TempError_ _TempInFile_ _DateRelated_ _OtherData_ _RFData_ _macrovars_  _keepmv_ _paramv_ _existedmv_
				_AgeData_ QSEPLUM FAR Parm0 QSE
				_ConvergenceStatus_ _FitStatistics_ _GlobalTests_ _NewCov_ _NObs_ __DataCreated__
				__Macro_Names__ _ReservedMacro_ _SameMacro_
				_ReserveMV_ _MatchMV_
				_ReserveVar_ _MatchVar_
				_existData_ _ReserveData_ _MatchData_
	%DO r = 1 %TO &N_RF;
		%DO o = 1 %TO &N_Outcome;
				_Classr&r.o&o._ _COVr&r.o&o._ _CSr&r.o&o._ _CSV_Datar&r.o&o._ _CSVheadr&r.o&o._ _NewClassr&r.o&o._ _Type3r&r.o&o._ 
		%END;
	%END;
	;
	run; quit;

	proc catalog cat=work.formats;
	   delete Msg.formatc;
	run;

	proc catalog cat = work.sasmacr;
	delete 	ANYMATCHVAR.Macro CHECKAGE.Macro CHECKBRACKETS.Macro CHECKCV.Macro CHECKINPARAM.Macro CHECKPART1.Macro CHECKPART2.Macro CHECKPART3.Macro 
			CHECKRF.Macro CHECKVALUEEXIST.Macro CHECKVAREXIST.Macro CHECKVARFORMAT.Macro CHECKVARNAME.Macro DELQUOTES.Macro DIREXIST.Macro ERRORDATA.Macro 
			FILEEXIST.Macro GETTEMPINFILE.Macro INPARAMDATA.Macro CheckDob.Macro PRINTPDF.Macro REQUIREDFILLED.Macro SORTSTRING.Macro 
			CombineParamError.Macro DefaultMid.Macro AnyError.Macro GetData.Macro CheckStudyDate.Macro CheckCensorDate.Macro 
			PHREG.Macro RunPhreg.Macro PrintPhreg.Macro CheckAnyObs.Macro ErrorFormat.Macro CheckID.Macro calculate_new_CI_tphreg.Macro
			CheckVarEqual.Macro RunFar.Macro DataNameLen.Macro CSV.Macro CheckRFequal.Macro CheckQuote.Macro CheckMinMax.Macro CheckTimeVar.Macro qsterr.Macro
			SetLog.Macro  
	;
	run; quit;
%END;
%ELSE %DO;
	proc datasets library = work  NODETAILS NOLIST;
		delete _existData_ _existedmv_ _keepmv_ _macrovars_ _MatchData_ _MatchMV_ _paramv_ _ReserveData_ _ReservedMacro_ 
				_ReserveMV_ _ReserveVar_ _SameMacro_ __Macro_Names__	;
	run; quit;
%END;

data _NULL_;
set _deletemv_;
	call execute('%symdel '||trim(left(vname))||';');
run;

data _NULL_;
rc = fdelete('mv');
run;
filename mv clear;

proc datasets library = work  NODETAILS NOLIST;
	delete  _deletemv_ _macrovars_;
run; quit;

%IF (%sysfunc(libref(InLib))) = 0 %THEN %DO;
	libname InLib;
%END;
%Mend DeleteTemp;
%DeleteTemp;

proc catalog cat = work.sasmacr;
delete 	DELETETEMP.Macro;
run; quit;

/*
proc catalog cat=work.formats;
   contents out = outsasmacro;
run;

proc sql; select distinct NAME into: SASMacroName separated by ' ' from outsasmacro;

%Put &SASMacroName;
%SYMDEL SASMacroName;

proc datasets library = work;
	delete outsasmacro;
run; quit;

%PUT _ALL_;
*/
