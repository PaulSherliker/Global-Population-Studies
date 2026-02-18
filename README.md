These files comprise the Kadoorie Cox Macro System, originally written by Corrina Hong

To run the system, download the SAS files into a folder, and replace the macro variable path in "Run Cox Analysis System v1.sas" with the path to that folder.

The "Cox Analysis System Control File.sas" can then be used to set the options and run the system, making sure to point the "%include" statement at the end to the "Run Cox Analysis System v1.sas" file in the main folder.

The documentation subbranch contains some documentation of the system, including a version of the control file with extensive comments (but initially with no "%include" statement to run the system). This includes information about setting up the dataset.

Of particular note in creating the dataset: each endpoint is a 0/1 variable (only, never missing) and must have an attached date, either the date of the event or a date of censoring for that event (never missing).
The endpoint variable (eg. end01) implies that the endpoint date has the same name with "_date" added, (eg. end01_date). This is separate from the censoring_date variable. All date variables must have a SAS date format applied in the dataset (so endpoint dates, study entry dates, censoring dates and date of birth).

This system is legacy code. It works at time of writing (Feb 2026) but at some point changes to the way the SAS Output Delivery System works will break it.
