/*****************************************************************************************
*   COX analysis system for Kadoorie                              						 *
*   Last edited: 6 Dec 2011    Corinna Hong                                              *
*****************************************************************************************/

/*========================================================================================
Part 1. - Type of run
		- Type of analysis
		- Project / analysis name and description
		- Input SAS data file for analysis and its directory
		- Output directory
		- Unique identifier
========================================================================================*/
/*----------- Type of run ----------*
%LET RunType = <value>; 		
	3 <value> are allowed:	RunType = Check  	
							RunType = Data	
							RunType = Run
- This parameter is optional.  The default <name> is Check.
- "RunType = Check" only run checking of parameters and display analysis requirement in
  a PDF file. Errors are displayed in the PDF file.
- "RunType = Data" run checking of parameters and also create data for PROC PHREG if 
  there is no errors. This option will not run the analysis.
- "RunType = Run" run checking of the parameters and also proceed with the analysis if 
  there is no errors.																	*/
%LET RunType = Run; 		

/*----------- Type of Analysis ----------*
%LET Analysis = <value>; 		
	3 <value> are allowed:	Analysis = Simple  			
							Analysis = Age-Stratified	
							Analysis = Multi-age group 
- Required. There is no default <value>.	
- For explanation of these 3 types of analysis, please see documentation
  K:\kadoorie\Analysis\macros\Cox Log\Models in Cox Analysis System Presentation 
  on 31JAN2012.pptx																		*/
%LET Analysis = Multi-age group ; *Required;

/*------------- Project name ------------*
%LET Project = <name>;
- This parameter is optional.  The default <name> is blank( ).																	
- Length of <name> should be short, i.e. less than 8 characters. The first character
  must be a letter (A, B, C, . . ., Z) or underscore (_). Subsequent characters can be 
  letters, numeric digits (0, 1, . . ., 9), or underscores. Blanks cannot appear in <name>
  because it will be the prefix of any output file names.								*/								
%LET Project = Synth2;

/*------------- Project Description ------------*
%LET ProjDesc = <literal>;
- This parameter is optional.  The default <literal> is blank ( ). This description will be
  included in the output PDF file.
- <literal> can be any combination of characters or numbers or special characters.		*/
%LET ProjDesc = Cause specific mortality by education among never-smoking never-drinkers;

/*-------- Description of this run---------*
%LET RunDesc = <literal>;
- This parameter is optional.  The default value is blank ( ). This description will be
  included in the output PDF file.
- <literal> can be any combination of characters or numbers or special characters.		*/
%LET RunDesc = grouped;

/*-------- SAS data file for analysis and its directory---------*
%LET InputDir = <dir> ;
- Required.  There is no default <dir>.
- <dir> is the directory of sas data file you would like to analyze using this system.
- Please do not enclose <dir> in single or double quotation marks.

%LET InputFile = <sasfile> ;         
- Required.  There is no default <sasfile>.
- <sasfile> is the name of sas data file you would like to analyze using this system.
- Please do not enclose <sasfile> in single or double quotation marks.					*/
%LET InputDir = K:\vep\Chennai\Data\20230214 mortality update ; *Required;
%LET InputFile = synth;  *Required;     

/*-------- Output directory---------*
%LET OutputDir = <dir> ;
- This parameter is optional.  The default <dir> is sub-directory called "Output <date>"
  under InputDir.
- OutputDir is the directory of folder you would like any files created by this system to 
  output.
- Please do not enclose <dir> in single or double quotation marks.
- Output PDF files are suffix with <date> and <time>									*/
%LET OutputDir = K:\vep\Chennai\Analyses\Smoking and drinking\20251128 response\output;

/*-------- Unique Identifier---------*
%LET ID = <variable>; 
- This parameter is optional.  The default <variable> is "studyid".
- <variable> is a unique identification number that identify each subject in the dataset*/
%LET ID = ele; 
/*========================================================================================
Part 2. - Time range of follow-up period
		- Age range
		- Selects observations that meet a particular condition for analysis
========================================================================================*/
/*-------- Length of follow-up period---------*
%LET LowFU   = <value> ;
%LET HighFU  = <value> ;
- This parameter is optional.  
- The default <value> are zero(0) for LowFU and (99) for HighFU.
- <value> is any nonnegative integer.
- LowFU specifies the years from the start of the study you would like to exclude.
  E.g. %let LowFU = 5, data from the 1st day of the 5th year will be include in the analysis.
- HighFU specifies the number of years after the start of the study you would like to 
  include. E.g. %let HighFU = 10, data up to the last day of the 10th year from the start
  of the study is included.
*/
%LET LowFU   = 0 ;
%LET HighFU  = 99 ;
/* Example-------------------------------------------------------------------------------
Date of start of the study: 1JAN2000
%LET LowFU   = 0 ;
%LET HighFU  = 10 ;
Analysis will include data from 1JAN2000 to 31DEC2009
%LET LowFU   = 1 ;
%LET HighFU  = 5 ;
Analysis will include data from 1JAN2001 to 31DEC2004

/*--------Calendar year of follow-up period---------*
%LET StartDate = <date>;
%LET EndDate = <date>;
- This parameter is optional.  The default <date> is 01JAN2004 for StartDate and
  current date for EndDate.
- <date> must be in the form ddmmmyyyy.
- StartDate specifies the minimum date you would like to include in the analysis.
- EndDate specifies the maximum date you would like to include in the analysis.			*/
%LET StartDate = 01JAN1998;
%LET EndDate = 31DEC2019;

/*-------- Age range ---------*
%LET LowAge  = <value> ;
%LET HighAge = <value> ;
- This parameter is optional and will be ignore when Analysis = "Multi-age group" (please
  see AgeBand).  
- <value> is any nonnegative integer.					
- The default <value> is 35 for LowAge and 89 for HighAge.		
- If the participant didn't reach LowAge at the end of the follow-up period, this 
  participant will be excluded from the analysis.
- If the participant reached HighAge + 1 before the start of the follow-up period, this
  participant will be excluded from the analysis.
- Analysis will only include the period when the participant is between LowAge and
  HighAge. E.g. LowAge = 40 and HighAge = 79, period to include in the analysis is from
  the day of 40th birthday to the day before the 80th birthday.							*/
%LET LowAge  = 35;
%LET HighAge = 69;

/*-------- Selects observations that meet a particular condition for analysis ---------*
%LET WhereStmt =  <argument>  ;
- This parameter is optional.  The default <argument> is "1", that is to include every
  participants who satisfy the above age range and follow-up period requirement in the 
  analysis.
- <argument> is an arithmetic or logical expression that you would normally write as a
  where statement in data step or after the dataset name in a procedure.
http://support.sas.com/documentation/cdl/en/lrdict/64316/HTML/default/
viewer.htm#a000202951.htm																*/
* cut at bmi=15 now in dataset, and DM back in analyses;
%LET WhereStmt =(sm eq 0 and al eq 0);

/*========================================================================================
Part 3. - Outcome variable
		- Censor Value
		- Censoring Date
		- Study Date
========================================================================================*/
/*-------- Outcome variable ---------*
%LET Outcome = <variable list>;
- Required.  There is no default <variable list>.							
- If you put more than one variable, each will run a Cox model with each of the risk
  factor.
- Outcome variables must contain numeric values.
- **!!!** Note: Date of outcome occurred has to be provided in the input dataset having the 
  same name as outcome variable with suffix "_date".  For example, if your outcome variable 
  is called EP0003, then there should be a EP0003_date in the input dataset.
- Variables for dates of outcomes have to be SAS date values or SAS datetime values. See 
  http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#/
  documentation/cdl/en/lrcon/62955/HTML/default/a002200738.htm							*/
*Endpoints: ‘all medical excluding TB and non-TB respiratory’, 
   all causes, cancer, CHD and TB.  ;

*%LET Outcome = all_ep vasc_ep; *Required;
*%let Outcome = new_ihd_ep cere_ep new_othvasc_ep all_ep vasc_ep;
*%let Outcome = cere_ep new_ihd_ep rendm_ep can_ep tb_ep res_ep vasc_ep all_ep
   othun_ep st_ep ext_ep;
*%let Outcome = residual_ep;
*%let outcome = renal_ep diabcrisis_ep diaball_ep;
*%let outcome = new_ihd_ep all_ep;
%let outcome = stroke_ep ihd_ep renal_ep cancer_ep tb_ep othres_ep residual_ep medical_ep ext_ep;
*%let outcome = tb_ep;

/*-------- Censor value ---------*
%LET CensorValue = <value list>;
- This parameter is optional.  Default <value> is '0', i.e. zero.
- If the outcome variable takes on <value>, the corresponding failure time is considered 
  to be censored.
- Number of values in <value list> equals the number of outcome variables specified 
  in %LET Outcome = <variable list>;
- */
*%LET CensorValue = 0 0 0 0 0 0 0 0 0 0 0; 
%LET CensorValue = 0 0 0 0 0 0 0 0 0; 
*%LET CensorValue = 0; 

/*-------- Censoring Date ---------*
%LET CensorDate = <Variable>;
- This parameter is optional. Default <variable> is Censroing_Date.
- Parameter CensorDate specified the date variable that the participant left the study,
  i.e. death, lost of follow-up.  If the participant is not known to have left the study,
  this date can be set to the last date for which follow-up data was collected.
- For Kadoorie study, this would be the global censoring date in the database.
- <Variable> has to be SAS date value or SAS datetime value. See 
  http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#/
  documentation/cdl/en/lrcon/62955/HTML/default/a002200738.htm							*/
%LET CensorDate = censoring_date;

/*-------- Study Date ---------*
%LET StudyDate = <Variable>;
- This parameter is optional. Default <variable> is Study_Date.
- Specified the date variable that the participant enrolled into the study.
- <Variable> has to be SAS date value or SAS datetime value. See 
  http://support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#/
  documentation/cdl/en/lrcon/62955/HTML/default/a002200738.htm							*/
%LET StudyDate = study_date;

/*-------- Unit of time variable ---------*
%LET TimeUnit = <value> ;
	4 <value> are allowed:	TimeUnit = Day  	
							TimeUnit = Week	
							TimeUnit = Month
							TimeUnit = Year
- Required.  There is no default <value>.
- Variable Time_in and Time_out in the unit of year will be in the analysis
  Dataset for your reference.  It will not be used by Proc PHREG.
"TimeUnit = Day" will use the time variable in the unit of day for Proc PHREG. 
  Suffix “_d” is added to the name of TimeVar variable.
"TimeUnit = Week" will use the time variable in the unit of week for Proc PHREG
  Suffix “_w” is added to the name of TimeVar variable.
"TimeUnit = Month" will use the time variable in the unit of month for Proc PHREG
  Suffix “_m” is added to the name of TimeVar variable.
- "TimeUnit = Year" will use the time variable in the unit of year for Proc PHREG
  Suffix “_y” is added to the name of TimeVar variable.									*/
%LET TimeUnit = Week;

/*-------- Unit of time variable ---------*
%LET TimeVar = <value> ;
	2 <value> are allowed:	TimeVar = Time_in Time_out  	
							TimeVar = Tottime	
- Required.  There is no default <value>.
- Tottime = Time_out - Time_in
- Parameter TimeVar defines how the failure time is specified in the model statement of 
  proc phreg. 
- When TimeVar = tottime, the model assumes that all participants enter follow-up at the
  same time, while the option of time_in time_out defines the start and end of an 
  individual’s period at risk , allowing them to join at different times after the origin.
- Tottime option is more efficient in terms of the running time in SAS and it generally 
  takes < 1 min per model on data with 0.5 million of participants. 
- Time_in time_out option is much more time consuming and it can take up to hours for 
  each model calculation, however it will probably be the more accurate option for many 
  analyses, particularly age stratified and multi-age group ones.
- Please refer to SAS documentation for the difference between these two methods		*/
%LET TimeVar = Time_in Time_out;

/*========================================================================================
Part 4. - Risk factor
========================================================================================*/
/*-------- Risk factor variable ---------*
%LET RF = <variable list>;
- Required.  There is no default <variable>.
- If you put more than one RF, each RF will run a Cox model with each of the outcome.	*/
%LET RF = edu4; *Required;

/*-------- Risk factor band boundaries ---------*
%LET RFBand = <band list>;
- Required.  There is no default <band list>. Band list for each 
  risk factor should be enclosed in square brackets "[10 20 30]". Any number not in 
  between paired square brackets will be ignored.
- If risk factor is to be included in the model as a continuous variable, RFBand should 
  set to blank"[ ]".
- Risk factor can not be continuous when running Multi-Age Group analysis.
- If Cent is filled, RFBand should set to "[ ]".
- Number of <band list> should equal the number of risk factor variables specified 
  in %LET RF = <variable list>;
- "Min" designates the minimum value of the risk factor variable. "Max" designates the
  maximum value of the risk factor variable. If "Max" is specified, the maximum value
  will be included in the interval. 
- For example, [10 20 30] does these intervals: 10 <= x < 20, 20 <= x < 30.
- For example, [Min 10 20 30 Max] does these intervals: minimum <= x < 10, 10 <= x < 20, 
  20 <= x < 30, 30 <= x <= maximum.													 	*/								
*%LET RFband = [Min 19.75 21.43 22.89 24.49 26.80 Max]; *Required;
%LET RFband = [Min 1.5 2.5 3.5 Max]; *Required;
/*-------- Risk factor band boundaries mid-point reference---------*
%LET RFmid  = <mid-point list>;  
- Required.
- Mid-point list of each risk factor should be enclosed in square brackets "[15 25]".
  Any number not in between paired square brackets will be ignored.
- The default <mid-point list> is the median of each risk factor bands if RFBand is 
  filled. If you'd like to choose default midpoints, please provide blank space 
  enclosed by square brackets, i.e. [ ].
- If you'd like to include this risk factor as continuous variable or if you'd like to
  use Cent parameter for this risk factor, please provide blank space enclosed by 
  square brackets, i.e. [ ].
- Number of <mid-point list> of each risk factor enclosed in paired brackets should 
  equal the number of <band list> minus 1 of the corresponding risk factor variable. 
- If both RFmid and Cent is filled but RFband is blank"[ ]", <mid-point list> of RFmid 
  will be ignored and Cent option will be used.											*/
%LET RFmid   =  [ ];     *Required;

/*--------- Partition observations into centile groups -----------*
%LET Cent = <value list>;
 	<value> allowed:	Cent = NA  			
						Cent = <value>	
- Required. There is no default.
- "Cent = NA" indicates that Cent parameter is not applicable to the corresponding risk
  factor. I.e. RFBand is filled, or risk factor is to be included in the model as a 
  continuous variable.
- Common <value> are Cent=10 for deciles, Cent=5 for quintiles, and Cent=4 
  for quartiles.						
- Number of value in <value list> should equal the number of risk factor variables 
  specified in %LET RF = <variable list>.												*/
%LET Cent = NA; *Required;

/*--------- Risk factor baseline level -----------*
%LET RFbase = <level list> ; *Required;
 	<level> allowed:	RFbase = First  			
						RFbase = <value>	
						RFbase = Last 
						RFbase = NA
- Required.  There is no default <level list>.
- "RFbase = First" designates the first ordered level as baseline reference level.
- "RFbase = Last" designates the last ordered level as baseline reference level.
- "RFbase = NA" designates for continuous risk factor.
- Number of level in <level list> should equal the number of risk factor variables 
  specified in %LET RF = <variable list>.
- <level> can be any whole number from 1 to the number of band minus one. For example, 
  RFband = [Min 10 20 Max], RFbase = 1 is the same as RFbase = First, which set the group
  Min<= x < 10 as baseline reference level. RFbase = 3, the same as RFbase = Last, set the 
  group 20 <= x < Max as baseline reference level. 										*/
%LET RFbase = First; *Required;

/* Example-------------------------------------------------------------------------------
			  Continuous	 	Band with mid		Band using default mid		Cent
%LET RF = 	   A    		 	 B 			  		C 					 	 	D ; 
%LET RFband =  [ ]  		 	[10 20 30] 	  		[Min 10 20 30 Max] 	 	 	[ ];
%LET RFmid  =  [ ]  		 	[15 25] 	  		[ ] 				 	 	[ ];    
%LET Cent =    NA   		 	NA 			  		NA 					 	 	5;
%LET RFbase =  NA   		    2 			  		First 				 	 	Last ; 

- 4 risk factor variables.
- Risk factor A will be included as continuous variable.
- Risk factor B will have 2 bands 10<=B<20, 20<=B<30, "15" is the mid-point reference to 
  10<=B<20, "25" is the mid-point reference to 20<=B<30. 20<=B<30 will be the reference 
  group.
- Risk factor C will have 4 bands Min<=C<10, 10<=C<20, 20<=C<30, 30<=C<Max. Median value 
  of C where Minimum<=C<10 will be the mid-point reference to Min<=C<10. Median value 
  of C where 10<=C<20 will be the mid-point reference to 10<=C<20, etc. First level, 
  i.e. Min<=C<10, will be the reference group.
- Risk factor D will have 5 groups which is the 5 quintiles of the risk factor variable.
  Last quintile will be the reference group.
----------------------------------------------------------------------------------------*/
/*========================================================================================
Part 5. - Covariates
========================================================================================*/
/*-------- Covariate variable ---------*
%LET Covars = <variable list>;
- This parameter is optional.  The default <variable list> is blank.					*/
%LET Covars =;
/*-------- Specify if covariate variable is classification variable ---------*
%LET CovClass = <value list> ;
 	2 <value> are allowed:	CovClass = 0  			
							CovClass = 1	
- This parameter is optional.  The default <value list> is all zeros for all covariates.
  That means none of the covariate variables is classification variable.
- Number of values in <value list> equals the number of covariate variables specified 
  in %LET Covars = <variable list>;
- "CovClass = 0" designates the covariate in the corresponding position in %Let Covars is
  NOT a classification variable and will NOT be included in the class statement.
- CovClass = 1 designates the covariate in the corresponding position in %Let Covars is
  a classification variable and will be included in the class statement.
- E.g. for the previous %LET Covars example, the default CovClass = 0 0 0;. If only alcohol
  needs to be in the class statement, then CovClass = 0 0 1;.							*/
%LET CovClass =;

/*-------- Sorting order for the levels of classification variables ---------*
%LET CovOrder = <value list> ;
 	2 <value> are allowed:	CovOrder = F  			
							CovOrder = I	
							CovOrder = NA
- This parameter is optional.  The default <value list> is F for all classification 
  covariates.
- "CovOrder = F" designates to use external formatted value to sort the levels.
- "CovOrder = I" designates to use unformatted value to sort the levels.
- "CovOrder = NA" is for covariate that is not classification variable.
- Number of values in <value list> equals the number of covariate variables specified 
  in %LET Covars = <variable list>;														*/
%LET CovOrder =;

/*--------- Covariate baseline level -----------*
%LET CovBase = <level list> ;
 	<level> allowed:	CovBase = First  			
						CovBase = <value>	
						CovBase = Last 
						CovBase = NA
- This parameter is optional and it is filled only when covariate has more than 1 group.
  The default <value> is First for all classification covariates.
- "CovBase = NA" is for covariate that is not classification variable.
- "CovBase = First" designates the first ordered level as baseline reference level.
- "CovBase = Last" designates the last ordered level as baseline reference level.
- <value> can be any whole number from 1 to the number of band minus one. 				
- Number of values in <value list> equals the number of covariate variables specified 
  in %LET Covars = <variable list>;														*/
%LET CovBase =;

/* Example-------------------------------------------------------------------------------
%LET Covars = 	X	Y1		Y2		Y3	; 
%LET CovClass=  0	1		1		1	;
%LET CovOrder=  NA	I		F		F	;
%LET CovBase=   NA	FIRST	First	Last	; 

In this example, variables Y1, Y2, Y3 contain integers from 0 to 9
i.e. : 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 and all three variables have the same format:
Proc Format;
	value CVf	0 = 'zero'
				1 = 'one'
				2 = 'two'
				3 = 'three'
				4 = 'four'
				5 = 'five'
				6 = 'six'
				7 = 'seven'
				8 = 'eight'
				9 = 'nine';
- X will be included in the model as a continuous covariate
- Y1 will be included as a categorical covariate with reference group = 0 (1st group
  order by internal value, i.e. 0 to 9, to order)
- Y2 will be included as categorical covariate with reference group = 8 (1st group order
  by formatted value, i.e. eight, five, four, nine, one, seven, six, three, two, zero).
- Y3 will be included as categorical covariate with reference group = 0 (last group order
  by formatted value, i.e. eight, five, four, nine, one, seven, six, three, two, zero).
----------------------------------------------------------------------------------------*/
/*========================================================================================
Part 6. - Strata and Age group
========================================================================================*/
/*-------- Strata ---------*
%LET Strata = <variable list>;
- This parameter is optional.  The default <variable list> is blank( ).					
- This option will run stratified proportional hazards model(s) which stratify on 
  variable(s) specify in <variable list>. The regression coefficients are assumed to be 
  the same in each stratum although the beaseline hazard functions may be different and 
  completely unrelated. This is used when the proportional hazards assumption is violated
  for these covariate.																	*/
%LET Strata =sex;

/*-------- Date of Birth variable ---------*
%LET DoB = <variable>;
- This parameter is optional.  The default <variable> is DoB.						
- Format of this <variable> has to be SAS date value or SAS datetime value. See http://
  support.sas.com/documentation/cdl/en/lrcon/62955/HTML/default/viewer.htm#/documentation/
  cdl/en/lrcon/62955/HTML/default/a002200738.htm										*/
%LET DoB = daborn;

/*-------- Age band ---------*
%LET XAge = <value>;
- This parameter is used when Analysis = "Age-Stratified" or "Multi-age group" and it is 
  set to blank( ) when Analysis = "Simple".
- This parameter is optional.  The default <mid-point list> is 5.
- This parameter specifies the number of year in each age strata.
- XAgeGrp will be created in the analysis dataset.
- For age-stratified analysis, the lowest XAgeGrp has its range starts from the value
  of LowAge, the highest XAgeGrp has its range ends at the value of HighAge.	
- For multi-age group analysis, the lowest XAgeGrp has its range starts from the smallest
  value from AgeBand, the highest XAgeGrp has its range ends at the largest value from
  AgeBand.																				*/
%LET XAge = 5;

/*-------- Age band ---------*
%LET AgeBand = <band list>;
- This parameter is required when Analysis = "Multi-age group".
- Only positive integers are allowed in <band list>.
- This parameter is set to blank( ) when Analysis = "Simple" or "Age-Stratified".
- For example, [10 20 30] does these intervals: 10 <= x < 20, 20 <= x < 30.
- Difference between each pair of consecutive numbers should be multiples of XAge.
- The group with the lowest value is the reference group								*/
%LET AgeBand =35 70;

/*-------- Age band boundaries mid-point reference---------*
%LET AgeMid  = <mid-point list>;  
- This parameter is used when Analysis = "Multi-age group".
- This parameter is set to blank( ) when Analysis = "Simple" or "Age-Stratified".
- This parameter is optional.  The default <mid-point list> is the median of each age 
  band if AgeBand is filled.															*/
%LET AgeMid =;    

options nofmterr;          
%Include "K:\china\Kadoorie\Analysis\macros\Corinna\Cox Analysis Sytem Routines\Run Cox Analysis System v1.sas";
