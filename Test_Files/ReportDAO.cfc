<cfcomponent displayname="ReportDAO">
	
<!---
    --- This file contains functions that query the alumni database cr_ tables to
	--- get information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets.
    ---
    --- All of the functions in this file are for the following information:
    ---
    --- Chapter Report Creation, Editing, and Access
--->

<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="ReportDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>

<!--------------------------------------------------------------------------------------------
    * getReports([filterStruct])
	* 
	* Get the existing reports from the database. The option filterStruct argument, if
	* provided, will filter the results to the desired output. The filterStruct, if used, must
	* have one or more of the following members:
	*
	* filterStruct = StructNew()
	* filterStruct.rid
	* filterStruct.type
	* filterStruct.open
	* filterStruct.date
	* filterStruct.current
	*
	* If successful, this function will return a query result set.
	* If an error occurs, this function will return a string error code.
	* 
--->
<cffunction name="getReports" access="public" returntype="any"> <!-- ********************* Fixed by Ryan *****************************************-->
	<cfargument name="filterStruct" type="struct" required="yes">
    <!--- Get the report --->
    <cftry>
    	<cfquery datasource="alumni_db" name="report">
        	SELECT *
            FROM cr_report_ids
            WHERE rid <> 0
            <cfif isDefined('ARGUMENTS.filterStruct')>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"rid") AND isNumeric(ARGUMENTS.filterStruct.rid)>
                    AND rid = #ARGUMENTS.filterStruct.rid#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"type") AND TRIM(ARGUMENTS.filterStruct.type) NEQ ''>
                    AND type = '#ARGUMENTS.filterStruct.type#'
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"open") AND isBoolean(ARGUMENTS.filterStruct.open)>
                    <cfset open = (ARGUMENTS.filterStruct.open) ? 1 : 0>
                    AND open = #open#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"date") AND isDate(ARGUMENTS.filterStruct.date)>
                    <cfset sqlDate = DateFormat(ARGUMENTS.filterStruct.date,'YYYY-MM-dd')>
                    AND start_date <= #parseDateTime(sqlDate)# AND end_date >= #parseDateTime(sqlDate)#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"current") AND isBoolean(ARGUMENTS.filterStruct.current)>
                    <cfif ARGUMENTS.filterStruct.current>
                        <cfset currentDate = Now()>
                        AND #currentDate# >= start_date AND #currentDate# <= end_date
                    </cfif>
                </cfif>
            </cfif>
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn report />
</cffunction>



<!--------------------------------------------------------------------------------------------
    * addReport(reportStruct)
	*
	* This function creates a new report entry in the database. It takes as an argument a 
	* report structure with the following format:
	*
	* reportStruct = StructNew()
	* reportStruct.type
	* reportStruct.start
	* reportStruct.end
	* reportStruct.submissionStart
	*
	* By default, reports are created closed. The start, end, and submissionStart members 
	* of the struct should be Coldfusion Date objects.
	*
	* If an error occurs, this function will return a string error code.
	* If successful, the newly generated key of the database entry will be returned
	* 
--->
<cffunction name="addReport" access="public" returntype="any">
	<cfargument name="reportStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.reportStruct,"type")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"start")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"end")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addReport() - Struct Key List = #StructKeyList(ARGUMENTS.reportStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Create the SQL formated date entries --->
    <cfset var start = DateFormat(ARGUMENTS.reportStruct.start,"YYYY-MM-DD")>
    <cfset var end = DateFormat(ARGUMENTS.reportStruct.end,"YYYY-MM-DD")>
    <cfset var submissionStart = DateFormat(ARGUMENTS.reportStruct.submissionStart,"YYYY-MM-DD")>
    <!--- Insert the data into the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertReport" result="newReport">
        	INSERT INTO #VARIABLES.tablePrefix#report_ids
            (type, start, end, submission_start)
            VALUES(
            	'#ARGUMENTS.reportStruct.type#',
                '#start#',
                '#end#',
                '#submissionStart#'
            )
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newReport.generated_key>
</cffunction>



<!--------------------------------------------------------------------------------------------
    * updateReport(reportStruct)
	* This function updates an existing report entry in the database. It takes as an argument a 
	* report structure with the following format:
	*
	* reportStruct = StructNew()
	* reportStruct.id
	* reportStruct.start
	* reportStruct.end
	* reportStruct.submissionStart
	* reportStruct.status
	*
	* By default, reports are created closed. The start, end, and submissionStart members 
	* of the struct should be Coldfusion Date objects.
	*
	* If an error occurs, this function will return a string error code.
	* If successful, the function will return the empty string
	* 
--->
<cffunction name="updateReport" access="public" returntype="string">
	<cfargument name="reportStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.reportStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"start")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"end")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"submissionStart")
		OR NOT StructKeyExists(ARGUMENTS.reportStruct,"status")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateReport() - Struct Key List = #StructKeyList(ARGUMENTS.reportStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Create the SQL formated date entries --->
    <cfset var start = DateFormat(ARGUMENTS.reportStruct.start,"YYYY-MM-DD")>
    <cfset var end = DateFormat(ARGUMENTS.reportStruct.end,"YYYY-MM-DD")>
    <cfset var submissionStart = DateFormat(ARGUMENTS.reportStruct.submissionStart,"YYYY-MM-DD")>
    <!--- Update the data in the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#report_ids
			SET
                start = '#start#',
                end = '#end#',
                submission_start = '#submissionStart#',
                open = #ARGUMENTS.reportStruct.status#
            WHERE rid = #ARGUMENTS.reportStruct.id#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn ''>
</cffunction>






<!--------------------------------------------------------------------------------------------
    * submitReport(rid,cid,submitor)
	* The following function submits information to a report for the chapter with the provided
	* chapter id. It uses the given rid to find the report's type and start/end dates.
	* It then uses this information to submit event and finance information for the chapter.
	* The submitor is the netid of the user who submitted the report.
	*
	* If successful, the function will return the empty string.
	* Otherwise, it will return a string error code.
	* 
--->
<cffunction name="submitReport" access="public" returntype="any">
	<cfargument name="rid" type="numeric" required="yes"/>
    <cfargument name="cid" type="string" required="yes"/>
    <cfargument name="submitor" type="string" required="yes"/>
    <!--- Get the report information --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="currentReport">
        	SELECT *
            FROM #VARIABLES.tablePrefix#report_ids
            WHERE rid = #ARGUMENTS.rid#
        </cfquery>

        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfif currentReport.recordCount EQ 0>
    	<cfset errorCode = "INVALID_REPORT_ID">
        <cfreturn errorCode />
    </cfif>

    <!-- Set the submitted_date -->
    <cfset submitteddate = dateTimeFormat(NOW(), 'mm/dd/yyyy HH:nn')>

    <!--- Check the type --->
    <cfif currentReport.type EQ 'event'>
    	<!--- Submit the event entries that fit in the currentReport --->
        <cftry>
            <cfscript>
				currentReportStart = dateTimeFormat(currentReport.start_date, "yyyy-mm-dd HH:nn");
				currentReportStartDate = parseDateTime(currentReportStart);
				currentReportEnd = dateTimeFormat(currentReport.end_date, "yyyy-mm-dd HH:nn");
				nextDay = DateAdd("d",1,currentReportEnd);
				currentReportEndDate = parseDateTime(nextDay);
			</cfscript>
            <cfquery datasource="#VARIABLES.datasource#" name="submitEvents">
                UPDATE #VARIABLES.tablePrefix#events
                SET
                	rid = #ARGUMENTS.rid#,
                    submitted = 1,
                    submitted_date = '#submitteddate#',
                    submitted_by = '#ARGUMENTS.submitor#'
                WHERE cid = '#ARGUMENTS.cid#' AND event_date_time >= #currentReportStartDate# AND event_date_time < #currentReportEndDate#
            </cfquery>

            <cfcatch type="database">
                <cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
    <cfelseif currentReport.type EQ 'financial'>
    <cfset currentyear = YEAR(NOW())>

    	<!--- Submit the finance entries that fit in the report --->
        <cftry>
            <cfquery datasource="#VARIABLES.datasource#" name="submitFinances">
                UPDATE #VARIABLES.tablePrefix#finance
                SET
                	rid = #ARGUMENTS.rid#,
                    submitted = 1,
                    submitted_date = '#submitteddate#',
                    submitted_by = '#ARGUMENTS.submitor#'
                WHERE cid = '#ARGUMENTS.cid#' AND year = #currentyear#
            </cfquery>
            <cfcatch type="database">
                <cfset errorCode = "#cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
    
    <cfelse>
    	<cfset errorCode = "INVALID_REPORT_TYPE">
        <cfreturn errorCode />
    </cfif>
    <cfreturn '' />
</cffunction>




<!--------------------------------------------------------------------------------------------
    * getHelp([id])
	* This function returns a query result set of the help entries in the database. If the 
	* id argument is specified, then only the information about the help entry with that id
	* will be returned.
	*
	* Help entries can be managed on the admin site.
	*
	* If the function fails, a string error code will be returned.
	* 
--->
<cffunction name="getHelp" access="public" returntype="any">
	<cfargument name="id" type="numeric" required="no">
    <!--- Add the id to the where clause if it exists --->
    <cfset whereString = "">
    <cfif isDefined('ARGUMENTS.id') AND TRIM(ARGUMENTS.id) NEQ ''>
    	<cfset whereString = 'WHERE id = #ARGUMENTS.id#'>
    </cfif>
    <!--- Run the query --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="helps">
        	SELECT *
            FROM #VARIABLES.tablePrefix#help
            #whereString#
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn helps />
</cffunction>


<!--------------------------------------------------------------------------------------------
    * addHelp(helpStruct)
	* This function creates a new help topic entry for chapter reports. It requires the
	* argument helpStruct to be in the following format:
	*
	* helpStruct = StructNew();
	* helpStruct.title
	* helpStruct.description
	* helpStruct.videoFile
	*
	* If successful, the function will return the generated key of the new help entry.
	* Otherwise, it will return a string error code.
	* 
--->
<cffunction name="addHelp" access="public" returntype="any">
	<cfargument name="helpStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.helpStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.helpStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.helpStruct,"videoFile")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addHelp() - Struct Key List = #StructKeyList(ARGUMENTS.helpStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Insert the new help entry --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertHelp" result="newHelp">
        	INSERT INTO #VARIABLES.tablePrefix#help
            (title, video, description)
            VALUES(
            	'#ARGUMENTS.helpStruct.title#',
                '#ARGUMENTS.helpStruct.videoFile#',
                '#ARGUMENTS.helpStruct.description#'
            )
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newHelp.generated_key />
</cffunction>




<!--------------------------------------------------------------------------------------------
    * updateHelp(helpStruct)
	* This function updates an existing help topic entry for chapter reports. It requires the
	* argument helpStruct to be in the following format:
	*
	* helpStruct = StructNew();
	* helpStruct.id
	* helpStruct.title
	* helpStruct.description
	* helpStruct.videoFile
	*
	* If successful, the function will return the empty string
	* Otherwise, it will return a string error code.
	* 
--->
<cffunction name="updateHelp" access="public" returntype="any">
	<cfargument name="helpStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.helpStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.helpStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.helpStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.helpStruct,"videoFile")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateHelp() - Struct Key List = #StructKeyList(ARGUMENTS.helpStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Update the existing help entry --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateHelp">
        	UPDATE #VARIABLES.tablePrefix#help
            SET
            	title = '#ARGUMENTS.helpStruct.title#',
                video = '#ARGUMENTS.helpStruct.videoFile#',
                description = '#ARGUMENTS.helpStruct.description#'
            WHERE id = #ARGUMENTS.helpStruct.id#
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn '' />
</cffunction>






<!--------------------------------------------------------------------------------------------
    * deleteHelp(id)
	* This function delete the help entry with the provided id.
	*
	* If successful, the function will return the empty string
	* Otherwise, it will return a string error code.
	* 
--->
<cffunction name="deleteHelp" access="public" returntype="any">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Delete the existing help entry --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteHelp">
        	DELETE FROM #VARIABLES.tablePrefix#help
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn '' />
</cffunction>




    
    
</cfcomponent>