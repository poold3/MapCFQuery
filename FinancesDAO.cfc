<cfcomponent displayname="financesDAO">


<!---
    --- This file contains functions that query the alumni database cr_ tables to get
	---  information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets and error codes.
    ---
    --- All of the functions in this file are for the following report:
    ---
    --- Financial Report
--->

<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="financesDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * addBalance(balanceStruct)
    *
    * The following function creates a new financial balance entry for a chapter. It takes as
	* an argument a balance struct formated as follows:
	*
	* balanceStruct = StructNew()
	* balanceStruct.cid
	* balanceStruct.year
	* balanceStruct.beginBalance
	* balanceStruct.endBalance
	* balanceStruct.updatedBy
	*
	* If successful, the function will return the generated id key of the new entry. 
	* Otherwise it will return the string error code associated with the failure.
--->
<cffunction name="addBalance" access="public" returntype="any"> <!--************************** Fixed By Ryan *************************-->
	<cfargument name="balanceStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.balanceStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"year")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"beginBalance")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"endBalance")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"updatedBy")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addBalance() - Struct Key List = #StructKeyList(ARGUMENTS.balanceStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <cfset current_date = DateFormat(NOW(), 'yyyy-mm-dd')> 

    <!--- Perform the insert --->
    <cftry>
    	<cfquery datasource="alumni_db" name="insertBalance" result="newBalance">
        	INSERT INTO cr_finance
            (cid, year, begin_balance, end_balance, updated_by, update_date)
            VALUES(
            	'#ARGUMENTS.balanceStruct.cid#',
                #ARGUMENTS.balanceStruct.year#,
                #ARGUMENTS.balanceStruct.beginBalance#,
                #ARGUMENTS.balanceStruct.endBalance#,
                '#ARGUMENTS.balanceStruct.updatedBy#',
                '#current_date#'
            )
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR_RYAN">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newBalance.generated_key>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * getBalances([filterStruct, orderArray])
    *
    * The following function returns a query result set of all balance entries for active BYU Chapters
    * The filterStruct argument is option, but if used it must have one or moreof the following members:
	* 
	* filterStruct = StructNew()
	* filterStruct.id
	* filterStruct.cid
	* filterStruct.region
	* filterStruct.year
	* filterStruct.submitted
	* filterStruct.rid
	* filterStruct.active
	* filterStruct.chapterType
	* 
    * If the orderArray argument is set, the default ordering of chapter name will be overridden and the provided
    * sorting column(s) will be applied.
--->
<cffunction name="getBalances" access="public" returntype="any"> <!-- ******************** Seems to be fixed by Ryan ************************-->
    <cfargument name="filterStruct" type="struct" required="no">
    <cfargument name="order" type="array" required="no">
    <!--- Build the ordering --->
    <cfset var orderString = "">
    <cfif isDefined('ARGUMENTS.orderArray') AND ArrayLen(ARGUMENTS.orderArray) NEQ 0>
        <cfloop array="#ARGUMENTS.orderArray#" index="i">
            <cfset orderString = (i LT ArrayLen(ARGUMENTS.orderArray)) ? '#i#,' : '#i#'>
        </cfloop>
    <cfelse>
        <cfset orderString = "c.name">
    </cfif>
    <!--- run the query --->
    <cftry>
        <cfquery datasource="alumni_db" name="balance">
            SELECT f.*, c.name, c.region
            FROM #VARIABLES.tablePrefix#finance f
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = f.cid
			WHERE id <> 0 
            <cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND isNumeric(ARGUMENTS.filterStruct.id)>
				AND f.id = #ARGUMENTS.filterStruct.id#
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
				AND f.cid = '#ARGUMENTS.filterStruct.cid#'
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"region") AND isNumeric(ARGUMENTS.filterStruct.region)>
				AND c.region = '#ARGUMENTS.filterStruct.region#'
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"year") AND isNumeric(ARGUMENTS.filterStruct.year)>
				AND f.year = #ARGUMENTS.filterStruct.year#
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"submitted") AND isBoolean(ARGUMENTS.filterStruct.submitted)>
				<cfset submitted = (ARGUMENTS.filterStruct.submitted) ? 1 : 0>
				AND f.submitted = #submitted#
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"rid") AND isNumeric(ARGUMENTS.filterStruct.rid)>
				AND f.rid = #ARGUMENTS.filterStruct.rid#
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
				<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
				AND c.active = #active#
			</cfif>
			<cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
				AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
			</cfif>
            ORDER BY #orderString#
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn balance>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * updateBalance(balanceStruct)
    *
    * The following function updates the values for balance information for chapters. It takes as
	* an argument a balance struct formated as follows:
	*
	* balanceStruct = StructNew()
	* balanceStruct.id
	* balanceStruct.beginBalance
	* balanceStruct.endBalance
	* balanceStruct.updatedBy
	*
	* If successful, the function will return the empty string. Otherwise it will return the string
	* error code associated with the failure.
--->
<cffunction name="updateBalance" access="public" returntype="string">
	<cfargument name="balanceStruct" type="struct" required="yes"/>
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.balanceStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"beginBalance")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"endBalance")
		OR NOT StructKeyExists(ARGUMENTS.balanceStruct,"updatedBy")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateBalance() - Struct Key List = #StructKeyList(ARGUMENTS.balanceStruct)#">
        <cfreturn errorCode />
        
    </cfif>
      <cfset update_date = NOW()>


    <!--- Perform the update --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateBalance">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
                begin_balance = #balanceStruct.beginBalance#,
                end_balance = #balanceStruct.endBalance#,
                update_date = #update_date#,
                updated_by = '#balanceStruct.updatedBy#'
            WHERE id = #balanceStruct.id#
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



<!----------------------------------------------------------------------------------------------------
    * addIncome(incomeStruct)
    *
    * The following function creates a new income entry. The provided income struct must be formated
	* as follows:
	*
	* incomeStruct = StructNew()
	* incomeStruct.fid
	* incomeStruct.description
	* incomeStruct.amount
	* incomeStruct.date
	* incomeStruct.updatedBy
	* incomeStruct.category
	* incomeStruct.specify
	* incomeStruct.eventName
	*
	* The the insert is successful, the function will return the generated id of the new entry.
	* Otherwise it will return the error code associated with the failure
--->
<cffunction name="addIncome" access="public" returntype="any">
	<cfargument name="incomeStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.incomeStruct,"fid")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"amount")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"date")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"updatedBy")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"category")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"specify")
   		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"eventName")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addIncome() - Struct Key List = #StructKeyList(ARGUMENTS.incomeStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <cfset update_date = DateFormat(NOW(), 'yyyy-mm-dd')>
    <!--- Format the date properly --->
    <cfset ARGUMENTS.incomeStruct.date = DateFormat(ARGUMENTS.incomeStruct.date,'yyyy-mm-dd')>
    <!--- Insert the data --->
    <cftry>
    	<!--- First create the new income entry --->
    	<cfquery datasource="alumni_db" name="insertIncome" result="newIncome">
        	INSERT INTO CR_INCOME
            (fid, description, amount, eventdate, category, specify, event_name)
            VALUES(
            	#ARGUMENTS.incomeStruct.fid#,
                '#ARGUMENTS.incomeStruct.description#',
                #ARGUMENTS.incomeStruct.amount#,
                '#ARGUMENTS.incomeStruct.date#',
                #ARGUMENTS.incomeStruct.category#,
                '#ARGUMENTS.incomeStruct.specify#',
                '#ARGUMENTS.incomeStruct.eventName#'

            )
        </cfquery>

        <cfquery datasource="alumni_db" name="CheckFID">
            SELECT ID FROM CR_INCOME
            ORDER BY ID DESC
        </cfquery>


        <!--- Then update the end_balance, update_date and updated_by values of the finance report --->
		<cfquery datasource="alumni_db" name="updateReport">
        	UPDATE cr_finance
            SET
            	end_balance = end_balance + #ARGUMENTS.incomeStruct.amount#,
                updated_by = '#ARGUMENTS.incomeStruct.updatedBy#',
                update_date = '#update_date#'
            WHERE id = #ARGUMENTS.incomeStruct.fid#
        </cfquery>
    	<cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn CheckFID.ID />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateIncome(incomeStruct)
    *
    * The following function updaets an existing income entry. The provided income struct must be formated
	* as follows:
	*
	* incomeStruct = StructNew()
	* incomeStruct.id
	* incomeStruct.fid
	* incomeStruct.description
	* incomeStruct.amount
	* incomeStruct.date
	* incomeStruct.updatedBy
	* incomeStruct.category
	* incomeStruct.specify
	* incomeStruct.eventName
	*
	* The the update is successful, the function will return the empty string.
	* Otherwise it will return the error code associated with the failure
--->
<cffunction name="updateIncome" access="public" returntype="string">
	<cfargument name="incomeStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.incomeStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"fid")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"amount")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"date")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"updatedBy")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"category")
		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"specify")
   		OR NOT StructKeyExists(ARGUMENTS.incomeStruct,"eventName")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateIncome() - Struct Key List = #StructKeyList(ARGUMENTS.incomeStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Format the date properly --->
    <cfset ARGUMENTS.incomeStruct.date = DateFormat(ARGUMENTS.incomeStruct.date,'yyyy-mm-dd')>
       <cfset update_date = DateFormat(NOW(), 'yyyy-mm-dd')>
    <!--- Insert the data --->
    <cftry>
    	<!--- First update the income entry --->
    	<cfquery datasource="#VARIABLES.datasource#" name="updateIncome">
        	UPDATE #VARIABLES.tablePrefix#income
            SET
                description = '#ARGUMENTS.incomeStruct.description#',
                amount = #ARGUMENTS.incomeStruct.amount#,
                eventdate = '#ARGUMENTS.incomeStruct.date#',
                category = #ARGUMENTS.incomeStruct.category#,
                specify = '#ARGUMENTS.incomeStruct.specify#',
                event_name = '#ARGUMENTS.incomeStruct.eventName#'
            WHERE id = #ARGUMENTS.incomeStruct.id#
        </cfquery>
        <!--- Get the toal income and expense entries in order to calculate the end balance --->
        <cfquery datasource="#VARIABLES.datasource#" name="income">
        	SELECT SUM(amount) AS total
            FROM #VARIABLES.tablePrefix#income
            WHERE fid = #ARGUMENTS.incomeStruct.fid#
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="expense">
        	SELECT SUM(amount) AS total
            FROM #VARIABLES.tablePrefix#expense
            WHERE fid = #ARGUMENTS.incomeStruct.fid#
        </cfquery>
        <!--- Then update the end_balance, update_date and updated_by values of the finance report --->
        <!--- Check also to make sure the expense total --->
		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
                <cfif (IsNull(#expense.total#))>
                end_balance = begin_balance + #income.total#,
                <cfelse>
                end_balance = begin_balance + #income.total# - #expense.total#,
                </cfif>
                updated_by = '#ARGUMENTS.incomeStruct.updatedBy#',
                update_date = '#update_date#'
            WHERE id = #ARGUMENTS.incomeStruct.fid#
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



<!----------------------------------------------------------------------------------------------------
    * getIncome([filterStruct])
    *
    * The following function returns a query result set of all income entries for active BYU Chapters
	* according to the conditions given by the filterStruct. The filterStruct variable, if used,
	* should contain one or more of the following members:
	*
	* filterStruct = StructNew()
	* filterStruct.id
	* filterStruct.fid
	*
	* If successful, the function will return a query result set.
	* Otherwise, it will return a string error code
--->
<cffunction name="getIncome" access="public" returntype="any"> <!-- ************************ Fixed by Ryan *****************************-->
    <cfargument name="filterStruct" type="struct" required="no">
    <!--- build the ordering --->
    <cfset var orderString = "ORDER BY date, description">
    <!--- run the query --->
    <cftry>
    	<cfquery datasource="alumni_db" name="income">
            SELECT *
            FROM cr_income
            WHERE id <> 0
                <cfif isDefined('ARGUMENTS.filterStruct')>
                    <cfif StructKeyExists(ARGUMENTS.filterStruct,"id")>
                         AND id = #ARGUMENTS.filterStruct.id#
                    </cfif>
                    <cfif StructKeyExists(ARGUMENTS.filterStruct,"fid")>
                        AND fid = #ARGUMENTS.filterStruct.fid#
                    </cfif>
                </cfif>
            ORDER BY eventdate, description
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn income>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * deleteIncome(id,deletor)
    *
    * The following function deletes the income entry with the provided id. Returns the empty string
	* if successful, otherwise an error code. The deletor argument is the netID of the user who
	* performed the delete
--->
<cffunction name="deleteIncome" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <cfargument name="deletor" type="string" requried="yes">
    <cfset updatedate = NOW()>
    <!--- Delete the entry --->
    <cftry>
    	<!--- First get the amount of the income entry --->
        <cfquery datasource="#VARIABLES.datasource#" name="income">
        	SELECT *
            FROM #VARIABLES.tablePrefix#income
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Then delete the entry --->
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteIncome">
        	DELETE FROM #VARIABLES.tablePrefix#income
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Then update the end_balance, update_date and updated_by values of the finance report --->
		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
            	end_balance = end_balance - #income.amount#,
                updated_by = '#ARGUMENTS.deletor#',
                update_date = #updatedate#
            WHERE id = #income.fid#
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


<!----------------------------------------------------------------------------------------------------
    * addExpense(expenseStruct)
    *
    * The following function creates a new income entry. The provided income struct must be formated
	* as follows:
	*
	* expenseStruct = StructNew()
	* expenseStruct.fid
	* expenseStruct.description
	* expenseStruct.amount
	* expenseStruct.date
	* expenseStruct.updatedBy
	* expenseStruct.category
	* expenseStruct.specify
	* expenseStruct.eventName
	*
	* The the insert is successful, the function will return the generated id of the new entry.
	* Otherwise it will return the error code associated with the failure
--->
<cffunction name="addExpense" access="public" returntype="any">
	<cfargument name="expenseStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.expenseStruct,"fid")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"amount")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"date")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"updatedBy")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"category")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"specify")
   		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"eventName")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addExpense Struct Key List = #StructKeyList(ARGUMENTS.expenseStruct)#">
        <cfreturn errorCode />
        
    </cfif>
       <cfset update_date = DateFormat(NOW(), 'yyyy-mm-dd')>
    <!--- Format the date properly --->
    <cfset ARGUMENTS.expenseStruct.date = DateFormat(ARGUMENTS.expenseStruct.date,'yyyy-mm-dd')>
    <!--- Insert the data --->
    <cftry>
		<!--- First create the expense entry --->
    	<cfquery datasource="#VARIABLES.datasource#" name="insertExpense" result="newExpense">
        	INSERT INTO #VARIABLES.tablePrefix#expense
            (fid, description, amount, eventdate, category, specify, event_name)
            VALUES(
            	#ARGUMENTS.expenseStruct.fid#,
                '#ARGUMENTS.expenseStruct.description#',
                #ARGUMENTS.expenseStruct.amount#,
                '#ARGUMENTS.expenseStruct.date#',
                #ARGUMENTS.expenseStruct.category#,
                '#ARGUMENTS.expenseStruct.specify#',
                '#ARGUMENTS.expenseStruct.eventName#'
            )
        </cfquery>
        <!--- Then update the update_date and updated_by values of the finance report --->
        <cfquery datasource="alumni_db" name="CheckFID">
            SELECT ID FROM CR_EXPENSE
            ORDER BY ID DESC
        </cfquery>
       

		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
            	end_balance = end_balance - #ARGUMENTS.expenseStruct.amount#,
                updated_by = '#ARGUMENTS.expenseStruct.updatedBy#',
                update_date = '#update_date#'
            WHERE id = #ARGUMENTS.expenseStruct.fid#
        </cfquery>
    	<cfcatch type="database">
        	<cfset errorCode = "#cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn CheckFID.ID />
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * updateExpense(expenseStruct)
    *
    * The following function updaets an existing expense entry. The provided expense struct must be formated
	* as follows:
	*
	* expenseStruct = StructNew()
	* expenseStruct.id
	* expenseStruct.fid
	* expenseStruct.description
	* expenseStruct.category
	* expenseStruct.amount
	* expenseStruct.date
	* expenseStruct.updatedBy
	* expenseStruct.specify
	* expenseStruct.eventName
	*
	* The the update is successful, the function will return the empty string.
	* Otherwise it will return the error code associated with the failure
--->
<cffunction name="updateExpense" access="public" returntype="string">
	<cfargument name="expenseStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.expenseStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"fid")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"category")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"amount")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"date")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"updatedBy")
		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"specify")
   		OR NOT StructKeyExists(ARGUMENTS.expenseStruct,"eventName")>
    	
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateExpense() - Struct Key List = #StructKeyList(ARGUMENTS.expenseStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Format the date properly --->
    <cfset ARGUMENTS.expenseStruct.date = DateFormat(ARGUMENTS.expenseStruct.date,'yyyy-mm-dd')>
    <cfset update_date = DateFormat(NOW(), 'yyyy-mm-dd')>
    <!--- Insert the data --->
    <cftry>
    	<!--- First update the expense entry --->
    	<cfquery datasource="#VARIABLES.datasource#" name="updateExpense">
        	UPDATE #VARIABLES.tablePrefix#expense
            SET
                description = '#ARGUMENTS.expenseStruct.description#',
                category = #ARGUMENTS.expenseStruct.category#,
                amount = #ARGUMENTS.expenseStruct.amount#,
                specify = '#ARGUMENTS.expenseStruct.specify#',
                eventdate = '#ARGUMENTS.expenseStruct.date#'
            WHERE id = #ARGUMENTS.expenseStruct.id#
        </cfquery>
        <!--- Get the toal income and expense entries in order to calculate the end balance --->
        <cfquery datasource="#VARIABLES.datasource#" name="income">
        	SELECT SUM(amount) AS total
            FROM #VARIABLES.tablePrefix#income
            WHERE fid = #ARGUMENTS.expenseStruct.fid#
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="expense">
        	SELECT SUM(amount) AS total
            FROM #VARIABLES.tablePrefix#expense
            WHERE fid = #ARGUMENTS.expenseStruct.fid#
        </cfquery>
        <!--- Then update the update_date and updated_by values of the finance report --->
		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
            	end_balance = begin_balance + #income.total# - #expense.total#,
                updated_by = '#ARGUMENTS.expenseStruct.updatedBy#',
                update_date = '#update_date#'
            WHERE id = #ARGUMENTS.expenseStruct.fid#
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="eventName">
        	UPDATE #VARIABLES.tablePrefix#expense
        	SET
        		event_name = '#ARGUMENTS.expenseStruct.eventName#'
        	WHERE id = #ARGUMENTS.expenseStruct.id#
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



<!----------------------------------------------------------------------------------------------------
    * getExpenses(filterStruct)
    *
    * The following function returns a query result set of all expense entries for active BYU Chapters
	* according to the conditions given by the filterStruct. The filterStruct variable, if used,
	* should contain one or more of the following members:
	*
	* filterStruct = StructNew()
	* filterStruct.id
	* filterStruct.fid
	*
	* If successful, the function will return a query result set.
	* Otherwise, it will return a string error code
--->
<cffunction name="getExpenses" access="public" returntype="any"> <!--*********************** Fixed by Ryan ***************************-->
    <cfargument name="filterStruct" type="struct" required="yes">
    <!--- build the ordering --->
    <cfset var orderString = "description, eventdate">
    <!--- run the query --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="expense">
            SELECT *
            FROM cr_expense
            WHERE id <> 0
        <cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"id")>
        	AND id = #ARGUMENTS.filterStruct.id#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"fid")>
        	AND fid = #ARGUMENTS.filterStruct.fid#
        </cfif>
        ORDER BY #orderString#
    </cfif>
            
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn expense>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * deleteExpense(id,deletor)
    *
    * The following function deletes the expense entry with the provided id. Returns the empty string
	* if successful, otherwise an error code. The deletor argument is the netid of the user who is
	* performing the delete.
	*
--->
<cffunction name="deleteExpense" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <cfargument name="deletor" type="string" required="yes">
    <cfset updatedate = NOW()>
    <!--- Delete the entry --->
    <cftry>
    	<!--- First get the amount of the expense entry --->
        <cfquery datasource="#VARIABLES.datasource#" name="expense">
        	SELECT *
            FROM #VARIABLES.tablePrefix#expense
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Then delete the entry --->
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteExpense">
        	DELETE FROM #VARIABLES.tablePrefix#expense
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Then update the end_balance, update_date and updated_by values of the finance report --->
		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
        	UPDATE #VARIABLES.tablePrefix#finance
            SET
            	end_balance = end_balance + #expense.amount#,
                updated_by = '#ARGUMENTS.deletor#',
                update_date = #updatedate#
            WHERE id = #expense.fid#
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



<!----------------------------------------------------------------------------------------------------
    * getFinanceYearRange([cid])
    *
    * The following function returns a query result set providing a list of the available years of reports
    * for financial reports.
    * If the 'cid' variable is specified, then the list will be restricted to only include years of reports
    * for the provided chapter
--->
<cffunction name="getFinanceYearRange" access="public" returntype="query"> <!--*********************** Fixed by Ryan *********************-->
    <cfargument name="cid" type="string" required="no">
    <!--- Build the where clause --->
    <cfset whereString = (isDefined('ARGUMENTS.cid') AND TRIM(ARGUMENTS.cid) NEQ '') ? 
											'AND cid = "#ARGUMENTS.cid#"' : "">
    <!--- Run the query --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="years">
            SELECT MIN(year) AS minYear, MAX(year) AS maxYear
            FROM #VARIABLES.tablePrefix#finance
            <cfif isDefined('ARGUMENTS.cid') AND TRIM(ARGUMENTS.cid) NEQ ''>
                WHERE cid ='#ARGUMENTS.cid#'
            </cfif>
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn years>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getIncomeCategoriesList()
    *
    * The following function returns a query result set containing the available income categories
--->
<cffunction name="getIncomeCategoriesList" access="public" returntype="query">
	<cftry>
        <cfquery datasource="alumni_db" name="categories">
            SELECT *
            FROM #VARIABLES.tablePrefix#income_type
            WHERE active = 1
            	AND cid <> 0
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn categories>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getExpenseCategoriesList()
    *
    * The following function returns a query result set containing the available Expense categories
--->
<cffunction name="getExpenseCategoriesList" access="public" returntype="query">
	<cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="categories">
            SELECT *
            FROM #VARIABLES.tablePrefix#expense_type
            WHERE active = 1
            	AND cid <> 0
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn categories>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getIncomeCategory(categoryId)
    *
    * The following function returns the string name of the category with the given id
--->
<cffunction name="getIncomeCategory" access="public" returntype="string"> <!--******************** Fixed by Ryan ******************** -->
	<cfargument name="categoryId" type="numeric" required="yes"/>
    <cftry>
        <cfquery datasource="alumni_db" name="category">
            SELECT *
            FROM cr_income_type
            WHERE cid = #ARGUMENTS.categoryId#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn category.type>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getExpenseCategory(categoryId)
    *
    * The following function returns the string name of the category with the given id
--->
<cffunction name="getExpenseCategory" access="public" returntype="string">
	<cfargument name="categoryId" type="numeric" required="yes"/>
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="category">
            SELECT *
            FROM #VARIABLES.tablePrefix#expense_type
            WHERE cid = #ARGUMENTS.categoryId#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn category.type>
</cffunction>


</cfcomponent>