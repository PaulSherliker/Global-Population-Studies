%macro qsterr(covmat=CovarianceMatrix);
/* 
   Floating absolute risks:
   "Heuristic method" of Easton et al
   Stats in Medicine 10 1025-1035 1991 and iterative
   algorithm from Plummer - Statist.Med 2004 23 93-104
   
   Programmed by Alison Offer on a quiet morning in Spring

    &covmat - name of covariance matrix (other rows and columns are
    ignored).
   
*/
 proc IML;

      use &covmat;
      read next %eval(&dim-1) var {&NonBaseClass}  into B;
 /*     print "Initial covariance matrix";*/
 /*     print B;*/
      close &covmat;
    
 /* we need to form the transformed covariance matix
    Let column 0 and row 0 be the row for baseline variable.
    A00 = 1/(s-1)(s-2) sum_i,j<>i B(I,J)
 */ 
      A00 = (sum(B) - sum(diag(B)) ) / ((&dim-1)*(&dim-2)) ;
/*	  print A00;  */
 /*
     A0i = A00 - 1/(s-2) * sum_j<>i Bij
     vector contains the elements A[0,i] = A[i,0]
 */
      vector = J(1,&dim-1,A00) - (B[+,]-vecdiag(B)`)/(&dim-2);
/*	  print vector;   */
 /* 
    now create &dim-1 x &dim-1 matrices - C has &dim-1 
    rows containing vector, D is a square matrix containing A00
 */
      C = vector;
      D = J(&dim-1,&dim-1,A00);
/*	  print C;*/
/*	  print D;*/
      do i = 1 to &dim-2;
         C = C//vector;
      end;  
 /* 
       Remaining terms of A are given by Aij = Bij + A0i + A0j - A00
 */
      A = B + C + C` - D;
    
 /* Build up final matix A by adding vector and A00 */

      A = (A//vector) || (vector`//A00);
    
/*      print "Adjusted Covariance Matrix";*/
/*      print A;*/
      names = {&NonBaseClass &BaseClass};
/*      print names;*/
      Variable = names`;
      create FAR from A [c=names r=Variable]   ;
      append from A [r=Variable];
 /* 
    now calculate and output new standard errors - these are square
    roots of diagonal terms
 */
      STERR = vecdiag((diag(A))##(0.5));
      create QSE from STERR [c='QStdErr' r=Variable]   ;
      append from STERR [r=Variable];
  quit;

/* 
  Now to extend beyond this to the 'improved' estimates (Plummer)  
  Statist.Med 2004 23 93-104
  Using the method outlined in Appendix A - Algorithm uses data covariance matrix 
  Omegahat augmented with an extra row and column
  Initial values:
  Omegahat(00) = sum_j sum_k<>j Omegahat / (dim-1)(dim-2)
  Omegahat(0i) = Omegahat(i0) = sum_j<>i Omegahat(ij)/(dim-2)
  where the sums are from 1-(dim-1)
  
  Omegahat (Plummers notation) is equivalent to matrix B above
  so initial Omegahat(00) = A00 and Omegahat(0i) = A00-Aij
  
  Lambda (as defined by Plummer) is the vector of the floated 
  variances - ie the diagonal elements of A
  
  Algorithm procedes as:
	    S = sum(i=0,dim-1) (1/lambda_i)
	    w_i = (1/lambda_i) / S
	    
	    Omegahat(00) = 1/S + sum_j sum_k w_j Omegahat(j,k) w_k
	    Omegahat(0i) = sum_j w_j Omegahat(j,i) i=1,...m
	    
	    lambda_0  = Omegahat(00)
	    lambda_i =  Omegahat(00) - 2*Omegahat(0i) + Omegahat(ii) i=1,m
  Note that Omega(i,j) i<>0, j<>0 do not change	      
  */

  proc IML;
/* 
  The covariance matrix is in SAS dataset &COVMAT and the first
  (&dim-1) rows and columns correspond to the elements for the
  (&dim-1) dummy variables.
*/
      use &covmat;
      read next %eval(&dim-1) var {&NonBaseClass}  into Omegahat;
/*      print "Initial covariance matrix";*/
 /*     print Omegahat;*/
      close &covmat;
/* 
    Omegahat is (dim-1)*(dim-1) matrix and is fixed  
    now get the floated variances - diagonal elements of FAR covar matrix
*/ 
      use FAR;
      read all var {&NonBaseClass &BaseClass}  into A;
      lambda = VECDIAG(A);
 /*     print lambda;*/
      close FAR;
      newlamb = lambda;
      
/* Now define convergence criteria and begin iterations */

      itermax = 500;
      eps = 1e-7;
      criterium = 0;
      do iter = 1 to itermax while(criterium=0);
/*
	    S = sum(i=0,dim-1) (1/lambda_i) - note this sum includes baseline term;
*/
          invlambda = lambda##(-1);
          S = sum(invlambda);
/*
	    w_i = (1/lambda_i) / S    i=1...dim-1;
*/
	  W = invlambda[1:&dim-1]#(1./S); 
/*
       Omegahat(00) = 1/S + sum_j sum_k w_j Omegahat(j,k) w_k  j,k=1...dim-1
            on RHS only want (dim-1)*(dim-1) dimensioned matrix;
*/
          Om00 = 1./S + W`*Omegahat*W;
/*
	    Omegahat(0i) = sum_j w_j Omegahat(j,i) i=1,...m;
*/
          vector = Omegahat*W;
/*
	    lambda_0  = Omegahat(00);
	    lambda_i =  Omegahat(00) - 2*Omegahat(0i) + Omegahat(ii) i=1,dim-1;
*/
 	  newlamb[&dim] = Om00;
	  newlamb[1:&dim-1] = J(&dim-1,1,Om00) - 2#vector + vecdiag(Omegahat);
/*
     convergence criterium
*/
          delta = lambda - newlamb;
	  criterium = (delta` * delta < eps*eps);									

	  lambda = newlamb;
      end;

      if  (^ criterium) then do; 
	  	call symputx("Farfailr&r.o&o.",'1');
		print "*** WARNING *** Plummers method failed to converge  ";
	  	print "                Reverting to FAR ";
      	lambda = VECDIAG(A);
      end;
	  else do;
	  	call symputx("Farfailr&r.o&o.",'0');
	  end;
      
/*      print "Quasi Variances after Plum";*/
 /*     print lambda;       */
/* 
      output new Standard Errors
*/
      STERR = lambda##0.5;
      Variable = {&NonBaseClass &BaseClass}`;
      create QSEPLUM from STERR [c='QStdErr' r=Variable]   ;
      append from STERR [r=Variable];
  quit;	  
/*%PUT Farfail = &Farfail ££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££££;*/
%mend qsterr;

%macro calculate_new_CI_tphreg(binvar=, Parm=Parmest, out=_results);
/* 
     macro called after qsterr to calculate new confidence 
     interval - QSEPLUM is a data set generated by macro qsterr
     This version for output from TPHREG

     Programmed by Alison Offer 2006
  
     binvar = variable name
     baseline = index of baseline (reference) level
     Parm = name of Variable estimate ods file
     out = file for writing results 

*/
          
  data Parm0;
  	 Parameter = "&binvar";
	 ClassVal0 = "&BaseValue";
     Variable  = upcase("&BaseClass");
     Estimate  = 0.0;
     StdErr  = 0.0;
  run;

  data &Parm;
    set &Parm;
	if upcase(Parameter)=upcase("&binvar") then 
	%IF "&ALY" ne "MUL" %THEN %DO;
        Variable=upcase(translate(strip(Parameter)||strip(ClassVal0),'_',' ','D','.'));
	%END;
	%ELSE %DO;
        Variable=upcase(translate(strip(Parameter)||strip(ClassVal0),'_',' ','_','.'));
	%END;
  run;

  data &Parm;
    set &Parm Parm0;
  run;

  proc sort data=&Parm; by Variable; quit;
  proc sort data=QSEPLUM; by Variable; quit;
/* 
   Now merge QSE and Variable Estimate files and calculate new 95% CI
*/
  data &out;
     merge &Parm(in=in_par keep= Parameter ClassVal0 Variable Estimate StdErr ChiSq ProbChiSq) 
           QSEPLUM(in=in_qse);
     by Variable;
/* 
   Now calculate Exp(estimate) and new 95% CI
*/
     if (in_qse and in_par) then do;
	    HR = exp(Estimate);
        QLowerCL = exp(Estimate - 1.96 * QStdErr);
        QUpperCL = exp(Estimate + 1.96 * QStdErr);
     end;
     else delete;

     P_value  = 2.0 * (1.0 - probnorm(abs(Estimate/QStdErr)));          
/*
   Need to extract the number from the end of the variable
   name (&binvar.nn) for resorting 
*/  
/****** 
     group = 1*tranwrd(Variable,"&binvar","");
******/
	 rename ClassVal0 = Group;
	run;
   
  proc sort data=&out; by group; quit;      
%mend calculate_new_CI_tphreg;

%Macro RunFAR;
%IF &ParamError le 0 and %UPCASE(&RunType) eq RUN %THEN %DO;
	%DO r = 1 %TO &N_RF;
		%DO o = 1 %TO &N_Outcome;
			%IF &&Statusr&r.o&o. eq 0 and &&PhErrr&r.o&o. eq 0 %THEN %DO;
				%GLOBAL FarUsedr&r.o&o.;		
				%IF %UPCASE(&&RFType&r) eq CONTINUOUS %THEN %DO;
					%LET FarUsedr&r.o&o. = 0;
				%END;
				%ELSE %DO;
					%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));			***; ODS PDF TEXT = "Outcome = &ThisOutcome";
					%LET ThisRF = %SYSFUNC(strip(%UPCASE(&&RF&r)));			/***; %PUT RF = &ThisRF;*/

					Data _NewClassr&r.o&o._;
						do until (eof) ;
							set _Classr&r.o&o._ (rename = (Class = OldClass)) end = eof;
							if ANYALNUM(OldClass) = 1 then do; Class = OldClass; retain Class;   end;
							SumX =sum(of X:);
							%IF "&ALY" ne "MUL" %THEN %DO;
								if Class = "&ThisRF.Grp" then do;
									ClassLevel = translate(strip(Class)||strip(Value),'_',' ','D','.');
									output;
								end;
							%END;
							%ELSE %DO;
								if Class = "CrossGrp" then do; 
									ClassLevel = translate(strip(Class)||strip(Value),'_',' ','_','.');
									output;
								end;
							%END;
						end;
						drop OldClass ;
					run;

					proc sql noprint;
					select count(*) into:dim from _NewClassr&r.o&o._;
					select strip(Value) into:BaseValue from _NewClassr&r.o&o._ where  SumX = 0;
					select ClassLevel into: AllClass separated by ' ' from _NewClassr&r.o&o._ ;
					select QUOTE(strip(ClassLevel)) into: All4InClause separated by ", " from _NewClassr&r.o&o._ ;
					select ClassLevel into: BaseClass separated by ' ' from _NewClassr&r.o&o._ where SumX = 0;
					select ClassLevel into: NonBaseClass separated by ' ' from _NewClassr&r.o&o._ where SumX = 1;

					%GLOBAL Farfailr&r.o&o.;
					%IF &dim lt 3 %THEN %DO;
						%LET FarUsedr&r.o&o. = 0;
						/*proc datasets library = work  NODETAILS NOLIST;	delete _NewClass_;	run; quit;*/
					%END;
					%ELSE %DO;
						%LET FarUsedr&r.o&o. = 1;
						Data _NewCov_;
							set _Covr&r.o&o._;
							if _NAME_ in (&All4InClause);		/*	%PUT All4InClause = &All4InClause;*/
						run;

						%qsterr(covmat=_NewCov_);
						%IF "&ALY" ne "MUL" %THEN %DO;
							%calculate_new_CI_tphreg(binvar=&ThisRF.Grp, Parm=PE_&ThisRF._&ThisOutcome., out=FAR_&ThisRF._&ThisOutcome.);
						%END;
						%ELSE %DO;
							%calculate_new_CI_tphreg(binvar=CrossGrp, Parm=PE_&ThisRF._&ThisOutcome., out=FAR_&ThisRF._&ThisOutcome.);
						%END;

						%IF %sysfunc(exist(FAR_&ThisRF._&ThisOutcome.)) %THEN %DO;
							data _fileCreateInfo_;
								dsid=open("FAR_&ThisRF._&ThisOutcome.");
								FileTime = ATTRN(dsid, "MODTE");
								FileObs = ATTRN(dsid,"NLOBS"); 
								rc=close(dsid);
							run;

							proc sql noprint;
								insert into __DataCreated__
								select "SAS Dataset", "Work","FAR_&ThisRF._&ThisOutcome.", FileTime
								from _fileCreateInfo_
								where FileObs > 0 and dsid > 0 and FileTime > &_starttime;

							%IF %sysfunc(exist(_fileCreateInfo_)) %THEN %DO;
								proc datasets library = work  NODETAILS NOLIST; delete  _fileCreateInfo_ ; run;
							%END;
						%END;

					/*	proc datasets library = work  NODETAILS NOLIST;	delete _NewClass_ _NewCov_ Far QSE Parm0;	run; quit;*/
					%END;
				%END;
			%END;
		%END;
	%END;
%END;
%MEND RunFAR;

%RunFAR;
























%Macro PrintPhreg;
ods escapechar="^";

ODS PDF TEXT = "     ";
ODS PDF TEXT = "&separator";

%DO r = 1 %TO &N_RF;
	%DO o = 1 %TO &N_Outcome;
		ODS PDF TEXT = "&Nb_start";
		%LET ThisOutcome = %SCAN(&Outcome,&o, %STR( ));			***; ODS PDF TEXT = "Outcome = &ThisOutcome";
		%LET ThisRF = %SYSFUNC(strip(%UPCASE(&&RF&r)));			***; ODS PDF TEXT = "Risk Factor = &ThisRF";
		ODS PDF TEXT = "&Nb_end";
		ODS PDF TEXT = "   ";
		ODS PDF TEXT = "&LibStmt";
		ODS PDF TEXT = "   ";

		*** Proc statement;
		ODS PDF TEXT = "&&PStmtr&r.o&o.";

		*** Class statement;
		%IF "&&CStmtr&r.o&o." ne " " %THEN %DO;
			ODS PDF TEXT = "^S={leftmargin=15}&&CStmtr&r.o&o.";
		%END;

		*** Model statement;
		ODS PDF TEXT = "^S={leftmargin=15}&&MStmtr&r.o&o.";

		*** Strata statement;
		%IF ("&ALY" eq "SIM" or "&ALY" eq "MUL") and  "&Strata" eq "&Space" %THEN %DO; %END;
		%ELSE %DO;
			ODS PDF TEXT = "^S={leftmargin=15}&&SStmtr&r.o&o."; 
		%END;

		*** Hazard Ratio statement;					
		%DO hr = 1 %TO &&N_HStmtr&r.o&o.;
			ODS PDF TEXT = "^S={leftmargin=15}&&&&HStmtr&r.o&o.n&hr"; 
		%END;
		*** Run statment;
		ODS PDF TEXT = "&Rstmt"; 

		*** Note;
		%IF &&N_NBr&r.o&o. ne 0 %THEN %DO;
			%DO n = 0 %TO &&N_NBr&r.o&o.;
				%IF &n = 0 or &n = &&N_NBr&r.o&o. %THEN %DO;
					ODS PDF TEXT = "&&Nbr&r.o&o.n&n.";
				%END;
				%ELSE %IF &n = 1 %THEN %DO;
					%IF %SYMEXIST(WhereStmt) ne 0 and %LENGTH(&WhereStmt) gt 0    %THEN %DO; ***;
						ODS PDF TEXT = "^S={leftmargin=28}       Where = %BQUOTE(&WhereStmt)";
					%END;

					ODS PDF TEXT = "^S={leftmargin=15}&&Nbr&r.o&o.n&n.";
				%END;
				%ELSE %DO;
					ODS PDF TEXT = "^S={leftmargin=30}&&Nbr&r.o&o.n&n.";
				%END;
			%END;
		%END;
																				
		%IF &ParamError le 0 and %UPCASE(&RunType) eq RUN and &&PhErrr&r.o&o. eq 0 and &&Statusr&r.o&o. eq 0 %THEN %DO; *********************;
			ODS PDF TEXT = " "; ODS PDF TEXT = "&&NObsRr&r.o&o. Observations Read, &&NObsUr&r.o&o. Observation Used.";
			proc print data = work._CSr&r.o&o._ noobs label ; run;
			ODS PDF TEXT = " "; ODS PDF TEXT = "Model Fit Statistics and Testing Global Null Hypothesis: BETA = 0";
			proc print data = work.Fit_&ThisRF._&ThisOutcome. noobs label ; run;
			ODS PDF TEXT = " "; ODS PDF TEXT = "Type 3 Tests";
			proc print data = work._Type3r&r.o&o._  noobs label ; run;
			%IF &&FarUsedr&r.o&o. eq 1 %THEN %DO;
				ODS PDF TEXT = " "; ODS PDF TEXT = "Parameter Estimates (before floating absolute risk)";
			%END;
			%ELSE %DO;
				ODS PDF TEXT = " "; ODS PDF TEXT = "Parameter Estimates";
			%END;

			proc print data = work.PE_&ThisRF._&ThisOutcome. (drop = ClassVal0 )noobs label ; run;
			%IF &&FarUsedr&r.o&o. eq 1 %THEN %DO;
				%IF &&Farfailr&r.o&o. eq 0 %THEN %DO; 
					ODS PDF TEXT = " "; ODS PDF TEXT = "Parameter Estimates (after floating absolute risk)"; 
					proc print data = work.FAR_&ThisRF._&ThisOutcome. noobs label ; 
						var Parameter Group HR QStdErr QLowerCL QUpperCL;
					run;
				%END;
				%ELSE %DO;
					ODS PDF TEXT = " "; ODS PDF TEXT = "^S={color=red} Floating absolute risk failed to converge!"; 
				%END;
			%END;
			%IF &&FarUsedr&r.o&o. eq 1 %THEN %DO;
				ODS PDF TEXT = " "; ODS PDF TEXT = "Hazard Ratios (before floating absolute risk)";
			%END;
			%ELSE %DO;
				ODS PDF TEXT = " "; ODS PDF TEXT = "Hazard Ratios";
			%END;
			proc print data = work.HR_&ThisRF._&ThisOutcome.  noobs label ; run;
		%END;
		ODS PDF TEXT = "&separator";
	%END;
%END;
%Mend PrintPhreg;
