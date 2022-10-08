<cfcomponent displayname="RostersDAO">


<!---
    --- This file contains functions that query the alumni database cr_ tables 
	--- to get information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets.
    ---
    --- All of the functions in this file are for the following report:
    ---
    --- Roster Report
--->


<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="RostersDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getPositions([filterStruct, orderArray])
    *
    * The following function returns the chapter roster positions for BYU chapters.
	* The optional filterStruct allows the developer to filter the results. If used, it should contain
	* on or more of the following members:
	*
	* filterStruct = StructNew()		// create the structure
	* filterStruct.pid					// the id of the position entry
	* filterStruct.cid					// the id of the chapter
	* filterStruct.type					// the type of position, 'leader' or 'aux'
	* filterStruct.rank					// the rank of the position, only for leader types
	* filterStruct.updateDate			// the last time the roster was updated (date object)
	* filterStruct.active				// a boolean to toggle active/inactive chapters
	* filterStruct.chapterType          // the type of the chapter ('regional', 'professional', etc.)
	*
	* If the 'orderArray' variable is set, then the default ordering by chapter name and rank will be 
	* overidden and the provided sorting columns will be applied. The array can be constructed
	* as follows:
	*
	* orderArray = ArrayNew(1)
	* ArrayAppend(orderArray,"column_name")
	*
    * If successful, the function will return a query result set according to the filters.
    * If the query fails, the function will return a string error code.
--->
<cffunction name="getPositions" access="public" returntype="any"> <!-- ******************************************************* FIXED Ryan ****-->
    <cfargument name="filterStruct" type="struct" required="no">
    <cfargument name="orderArray" type="array" required="no">
    <!--- build the ordering --->
    <cfset var orderString = "ORDER BY ">
    <cfif isDefined('ARGUMENTS.orderArray') AND ArrayLen(ARGUMENTS.orderArray) NEQ 0>
    	<cfset count = 1>
        <cfloop array="#ARGUMENTS.orderArray#" index="i">
            <cfset orderString = (count LT ArrayLen(ARGUMENTS.orderArray)) ? '#i#,' : '#i#'>
            <cfset count++>
        </cfloop>
    <cfelse>
        <cfset orderString = "c.name,rank">
    </cfif>
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="positions">
            SELECT p.*, c.name AS chapter_name, r.name AS region_name
            FROM cr_positions p
            INNER JOIN cr_chapters c
                ON c.cid = p.cid
            INNER JOIN cr_regions r
            	ON c.region = r.id
            WHERE pid <> 0
		<cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"pid") AND isNumeric(ARGUMENTS.filterStruct.pid)>
        	AND p.pid = #ARGUMENTS.filterStruct.pid#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
        	AND p.cid = '#ARGUMENTS.filterStruct.cid#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"type") AND TRIM(ARGUMENTS.filterStruct.type) NEQ ''>
        	AND p.type = '#ARGUMENTS.filterStruct.type#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"rank") AND isNumeric(ARGUMENTS.filterStruct.rank)>
        	AND p.rank = #ARGUMENTS.filterStruct.rank#
        </cfif>
		<cfif StructKeyExists(ARGUMENTS.filterStruct,"updateDate") AND isDate(ARGUMENTS.filterStruct.updateDate)>
        	<cfset updateDate = DateFormat(ARGUMENTS.filterStruct.updateDate,"yyyy-mm-dd")>
        	AND p.update_date >= '#updateDate#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
        	<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
            AND c.active = #active#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
        	AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
        </cfif>
    </cfif>
		ORDER BY #orderString#
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn positions>
</cffunction>





<!----------------------------------------------------------------------------------------------------
    * addPosition(positionStruct)
    *
    * The following function creates a new position entry in the database. The positionStruct
    * variable is of the following format:
    *
    * positionStruct = StructNew()		// create the structure
    * positionStruct.cid				// the chapter id of the position
	* positionStruct.type				// the type of position, 'leader' or 'aux'
    * positionStruct.rank				// the rank of the position (leader only)
    * positionStruct.title				// the position title
    * positionStruct.occupant			// the name of the individual holding the position
    * positionStruct.email1				// the primary email address
    * positionStruct.email2				// the secondary email address
    * positionStruct.phone1				// the primary phone
    * positionStruct.phone2				// the secondary phone
    * positionStruct.canText			// flag for the individual's ability to text (1 = yes, 0 = no)
	* positionStruct.imageId			// the name of the image file associated with this individual
    * positionStruct.updatedBy			// the NetID of the user who updated the roster information
    *
    * This function will return the generated key of the new entry if the update was successful. 
	* If it was not successful, it will return a string containing the error code.
    *
--->
<cffunction name="addPosition" access="public" returntype="any">
    <cfargument name="positionStruct" required="yes" type="struct">
    <!--- Verify the struct is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.positionStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.positionStruct,"type")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"rank")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"title")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"occupant")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"email1")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"email2")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"phone1")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"phone2")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"canText")
		OR NOT StructKeyExists(ARGUMENTS.positionStruct,"imageId")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"updatedBy")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addPosition() - Struct Key List = #StructKeyList(ARGUMENTS.positionStruct)#">
        <cfreturn errorCode />
    </cfif>

    <!-- Set the date variable -->
    <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>
    

    <!--- Update the database values --->
    <cftry>
        <cfquery datasource="alumni_db" name="updatePosition">
            INSERT INTO cr_positions
            (cid, type, rank, title, occupant, email_1, email_2, phone_1, phone_2, can_text, img_id, update_date, updated_by)
            VALUES(
            	'#ARGUMENTS.positionStruct.cid#',
                '#ARGUMENTS.positionStruct.type#',
                #ARGUMENTS.positionStruct.rank#,
                '#ARGUMENTS.positionStruct.title#',
                '#ARGUMENTS.positionStruct.occupant#',
                '#ARGUMENTS.positionStruct.email1#',
                '#ARGUMENTS.positionStruct.email2#',
                '#ARGUMENTS.positionStruct.phone1#',
                '#ARGUMENTS.positionStruct.phone2#',
                #ARGUMENTS.positionStruct.canText#,
                '#ARGUMENTS.positionStruct.imageId#',
                '#currentdate#',
                '#ARGUMENTS.positionStruct.updatedBy#'
            )
        </cfquery>
        <cfquery datasource="alumni_db" name="newPosition">
            SELECT DISTINCT pid
            FROM cr_positions
            WHERE cid = '#ARGUMENTS.positionStruct.cid#'
            ORDER BY pid DESC
        </cfquery>
    <cfcatch type="database">
        <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        <cfreturn errorCode />
    </cfcatch>
    </cftry>
    <cfreturn newPosition.pid />
</cffunction>





<!----------------------------------------------------------------------------------------------------
    * updatePosition(positionStruct)
    *
    * The following function updates the database values for the provided position. The positionStruct
    * variable is of the following format:
    *
    * positionStruct = StructNew()		// create the structure
    * positionStruct.pid				// the id of the position
    * positionStruct.rank				// the rank of the position (leader only)
    * positionStruct.title				// the position title
    * positionStruct.occupant			// the name of the individual holding the position
    * positionStruct.email1				// the primary email address
    * positionStruct.email2				// the secondary email address
    * positionStruct.phone1				// the primary phone
    * positionStruct.phone2				// the secondary phone
    * positionStruct.canText			// flag for the individual's ability to text (1 = yes, 0 = no)
    * positionStruct.updatedBy			// the NetID of the user who updated the roster information
    *
    * This function will return an empty string if the update was successful. If it was not successful, it will
    * return a string containing the error code
    *
--->
<cffunction name="updatePosition" access="public" returntype="string"> <!-- ******************* Fixed by Ryan ***************************** -->
    <cfargument name="positionStruct" required="yes" type="struct">
    <!--- Verify the struct is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.positionStruct,"pid")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"rank")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"title")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"occupant")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"email1")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"email2")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"phone1")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"phone2")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"canText")
        OR NOT StructKeyExists(ARGUMENTS.positionStruct,"updatedBy")>
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updatePosition() - Struct Key List = #StructKeyList(ARGUMENTS.positionStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Update the database values --->
    <!-- Set the date variable -->
    <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>
    <cftry>
        <cfquery datasource="alumni_db" name="updatePosition">
            UPDATE #VARIABLES.tablePrefix#positions
            SET
                rank = #ARGUMENTS.positionStruct.rank#,
                title = '#ARGUMENTS.positionStruct.title#',
                occupant = '#ARGUMENTS.positionStruct.occupant#',
                email_1 = '#ARGUMENTS.positionStruct.email1#',
                email_2 = '#ARGUMENTS.positionStruct.email2#',
                phone_1 = '#ARGUMENTS.positionStruct.phone1#',
                phone_2 = '#ARGUMENTS.positionStruct.phone2#',
                can_text = #ARGUMENTS.positionStruct.canText#,
                update_date = '#currentdate#',
                updated_by = '#ARGUMENTS.positionStruct.updatedBy#'
            WHERE
                pid = #ARGUMENTS.positionStruct.pid#
        </cfquery>
    <cfcatch>
        <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        <cfreturn errorCode />
    </cfcatch>
    </cftry>
    <cfreturn "" />
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * deletePosition(pid)
    *
    * The following function deletes the position from the database. Returns the empty string
	* if successful, otherwise an error code.
--->
<cffunction name="deletePosition" access="public" returntype="string">
	<cfargument name="pid" type="numeric" required="yes">
    <!--- Delete the entry --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="deletePosition">
        	DELETE FROM #VARIABLES.tablePrefix#positions
            WHERE pid = #ARGUMENTS.pid#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn '' />
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getSecretary(chapterId)
    *
    * The following function returns the secretary position for a specific BYU chapter.
	*
    * If successful, the function will return a query result set according to the chapterId.
    * If the query fails, the function will return a string error code.
--->
<cffunction name="getSecretary" access="public" returntype="any"> <!-- ******************************************************* FIXED Ryan ****-->
    <cfargument name="chapterId" type="any" required="yes">
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="positions">
            SELECT p.*, c.name AS chapter_name, r.name AS region_name
            FROM #VARIABLES.tablePrefix#positions p
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = p.cid
            INNER JOIN #VARIABLES.tablePrefix#regions r
            	ON c.region = r.id
            WHERE p.title = 'Secretary'
            	AND c.cid = '#ARGUMENTS.chapterId#'
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn positions>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getTreasurer(chapterId)
    *
    * The following function returns the treasurer position for a specific BYU chapter.
	*
    * If successful, the function will return a query result set according to the chapterId.
    * If the query fails, the function will return a string error code.
--->
<cffunction name="getTreasurer" access="public" returntype="any"> <!-- ******************************************************* FIXED Ryan ****-->
    <cfargument name="chapterId" type="any" required="yes">
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="positions">
            SELECT p.*, c.name AS chapter_name, r.name AS region_name
            FROM #VARIABLES.tablePrefix#positions p
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = p.cid
            INNER JOIN #VARIABLES.tablePrefix#regions r
            	ON c.region = r.id
            WHERE p.title = 'Treasurer'
            	AND c.cid = '#ARGUMENTS.chapterId#'
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn positions>
</cffunction>


</cfcomponent>