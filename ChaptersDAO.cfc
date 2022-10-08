<cfcomponent displayname="ChaptersDAO">


<!---
    --- This file contains functions that query the alumni database cr_ tables to get 
	--- information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets.
    ---
    --- All of the functions in this file are for the following information:
    ---
    --- Chapters
--->

<!---
	--- Functions available through chapterData():
	---
	---init() ----------------------------------- on line 41
	---getChapters([filterStruct,orderArray]) --- on line 54
	---addChapter(chapterStruct) ---------------- on line 146
	---deactivateChapter(cid) ------------------- on line 252
	---activateChapter(cid) --------------------- on line 282
	---updateChapter(chapterStruct) ------------- on line 313
	---getRegionList() -------------------------- on line 386
	---getRegion(regionID) ---------------------- on line 412
	---addRegion(regionStruct) ------------------ on line 438
	---updateRegion(regionStruct) --------------- on line 481
	---deleteRegion(id) ------------------------- on line 526
	---getAccessData([netid]) ------------------- on line 560
	---addAccessData(accessStruct) -------------- on line 591
	---updateAccessData(accessStruct) ----------- on line 654
	---deleteAccessData(netid) ------------------ on line 717
	---getTrueBlue(cid) ------------------------- on line 744
	---getImages(filterStruct) ------------------ on line 902
	---uploadImages(filterStruct) --------------- on line 942
	---updateMasterReportData(cid) -------------- on line 1009
	---updateMasterReportData(cid) -------------- on line 1009
--->




<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="ChaptersDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * getChapters([filterStruct,orderArray])
    *
    * The following function returns a query result set of all chapters for BYU Alumni.
    * The optional filterStruct argument, if provided, will limit results provided according to the given
	* constraints. It should contain one or more of the following members:
	*
	* filterStruct = StructNew()	// create the structure
	* filterStruct.cid				// the chapter id
	* filterStruct.type				// the type of chapter, regional or professional
	* filterStruct.region			// the region the chapter is in (numeric id)
	* filterStruct.trueBlue			// the True Blue level of the chapter
	* filterStruct.active			// the active status of the chapter
	* filterStruct.testing			// flag for whether the chapter is available on dev sites
	* filterStruct.drupalNid		// the drupal node id of the chapter on alumni.byu.edu
	* filterStruct.drupalVid		// the drupal revision id of the chapter on alumni.byu.edu
	*
    * If the 'orderArray' variable is set, then the default ordering by chapter name will be 
	* overidden and the provided sorting columns will be applied. The array can be constructed
	* as follows:
	*
	* orderArray = ArrayNew(1)
	* ArrayAppend(orderArray,"column_name")
	*
	* If the function succeeds, it will return a query result set of values according to the
	* provided filters.
    * If the query fails, then the function will return a string error code.
--->
<cffunction name="getChapters" access="public" returntype="any"> <!-- ******************************************************* FIXED --Ryan ****-->
    <cfargument name="filterStruct" type="struct" required="no">
    <cfargument name="orderArray" type="array" required="no">
    <!--- build the ordering --->
    <cfif isDefined('ARGUMENTS.orderArray') AND ArrayLen(ARGUMENTS.orderArray) NEQ 0>
    	<cfset count = 1>
        <cfloop array="#ARGUMENTS.orderArray#" index="i">
            <cfset orderString = (count LT ArrayLen(ARGUMENTS.orderArray)) ? '#i#,' : '#i#'>
            <cfset count++>
        </cfloop>
    <cfelse>
        <cfset orderString = 'c.name'>
    </cfif>
    <!--- run the query --->
    <cftry>
        <cfquery datasource="alumni_db" name="chapters">
            SELECT c.*, r.name AS region_name
            FROM cr_chapters c
            INNER JOIN cr_regions r
            	ON r.id = c.region
			WHERE cid IS NOT NULL
        	<cfif isDefined('ARGUMENTS.filterStruct')>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
					AND cid = '#ARGUMENTS.filterStruct.cid#'
				</cfif>
				 <cfif StructKeyExists(ARGUMENTS.filterStruct,"type") AND TRIM(ARGUMENTS.filterStruct.type) NEQ ''>
					AND type = '#ARGUMENTS.filterStruct.type#'
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"region") AND isNumeric(ARGUMENTS.filterStruct.region)>
					AND region = #ARGUMENTS.filterStruct.region#
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"trueBlue") AND isNumeric(ARGUMENTS.filterStruct.trueBlue)>
					AND true_blue_tier = #ARGUMENTS.filterStruct.trueBlue#
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND IsBoolean(ARGUMENTS.filterStruct.active)>
					<cfset active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
					AND active = #active#
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"testing") AND IsBoolean(ARGUMENTS.filterStruct.testing)>
					<cfset testing = (ARGUMENTS.filterStruct.active) ? 1 : 0>
					AND testing = #testing#
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"drupalNid") AND isNumeric(ARGUMENTS.filterStruct.drupalNid)>
					AND drupal_nid = #ARGUMENTS.filterStruct.drupalNid#
				</cfif>
				<cfif StructKeyExists(ARGUMENTS.filterStruct,"drupalVid") AND isNumeric(ARGUMENTS.filterStruct.drupalVid)>
					AND drupal_vid = #ARGUMENTS.filterStruct.drupalVid#
				</cfif>
			</cfif>
			ORDER BY #orderString#
			
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR_4">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn chapters>
</cffunction>


<!-----------------------------------------------------------------------------------------------------
	* addChapter(chapterStruct)
	*
	* The following function adds a new chapter to the cr_chapters database table. To add a chapter you
	* must conform to the format of the following struct:
	*
	* chapterStruct = StructNew();
    * chapterStruct.name
	* chapterStruct.type
    * chapterStruct.state
    * chapterStruct.region
    * chapterStruct.size
    * chapterStruct.donors
	* 
	* The function will return the generated key if the chapter was added successfully, 
	* otherwise it will return a string error code message
	*
--->
<cffunction name="addChapter" access="public" returntype="any">
	<cfargument name="chapterStruct" type="struct" required="yes">
   <!--- Make sure the chapter struct is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.chapterStruct,"name")
        OR NOT StructKeyExists(ARGUMENTS.chapterStruct,"type")
        OR NOT StructKeyExists(ARGUMENTS.chapterStruct,"state")
        OR NOT StructKeyExists(ARGUMENTS.chapterStruct,"region")
        OR NOT StructKeyExists(ARGUMENTS.chapterStruct,"size")
        OR NOT StructKeyExists(ARGUMENTS.chapterStruct,"donors")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addChapter() - Struct Key List = #StructKeyList(ARGUMENTS.chapterStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Build the new chapter id for a regional chapter --->
    <cfif ARGUMENTS.chapterStruct.type EQ 'regional'>
		<cfset chapterId = UCase(ARGUMENTS.chapterStruct.state)>
        <cftry>
            <cfquery datasource="#VARIABLES.datasource#" name="sameStateChapters">
                SELECT cid
                FROM #VARIABLES.tablePrefix#chapters
                WHERE cid LIKE '#chapterId#%'
            </cfquery>
            <cfcatch>
                <cfset errorCode = "DATABASE_EXECUTION_ERROR_1">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
        <cfif sameStateChapters.recordCount LT 10>
            <cfset chapterId = chapterId & "00" & (sameStateChapters.recordCount + 1)>
        <cfelseif sameStateChapters.recordCount LT 100>
            <cfset chapterId = chapterId & "0" & (sameStateChapters.recordCount + 1)>
        <cfelse>
            <cfset chapterId = chapterId & (sameStateChapters.recordCount +1)>
        </cfif>
    </cfif>
    <!--- Create the chapter id for a professional chapter --->
    <cfif ARGUMENTS.chapterStruct.type EQ 'professional'>
    	<cfset chapterId = "PRO">
        <cftry>
            <cfquery datasource="#VARIABLES.datasource#" name="proChapters">
                SELECT cid
                FROM #VARIABLES.tablePrefix#chapters
                WHERE cid LIKE '#chapterId#%'
            </cfquery>
            <cfcatch>
                <cfset errorCode = "DATABASE_EXECUTION_ERROR_2">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
        <cfif proChapters.recordCount LT 10>
            <cfset chapterId = chapterId & "00" & (proChapters.recordCount + 1)>
        <cfelseif proChapters.recordCount LT 100>
            <cfset chapterId = chapterId & "0" & (proChapters.recordCount + 1)>
        <cfelse>
            <cfset chapterId = chapterId & (proChapters.recordCount + 1)>
        </cfif>
    </cfif>
    <!--- Insert the new chapter into the database --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="addChapter" result="newChapter">
            INSERT INTO #VARIABLES.tablePrefix#chapters
            (cid, type, name, region, sizenew, donors)
            VALUES(
                '#chapterId#',
                '#ARGUMENTS.chapterStruct.type#',
                '#ARGUMENTS.chapterStruct.name#',
                '#ARGUMENTS.chapterStruct.region#',
                #ARGUMENTS.chapterStruct.size#,
                #ARGUMENTS.chapterStruct.donors#
            )
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR_3 #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn chapterId>
</cffunction>


<!-----------------------------------------------------------------------------------------------------
	* deactivateChapter(cid)
	*
	* The following function takes as a parameter the id of a chapter and sets its active status
	* to zero.
	* If the update is successful, the function will return an empty string. Otherwise it will return
	* the error code.
	*
--->
<cffunction name="deactivateChapter" access="public" returntype="string">
	<cfargument name="cid" type="string" required="yes">
    <!--- Set the active statis of the provided chapter to zero --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="deactivateChapter">
            UPDATE #VARIABLES.tablePrefix#chapters
            SET
                active = 0
            WHERE cid = '#ARGUMENTS.cid#'
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn "">
</cffunction>


<!-----------------------------------------------------------------------------------------------------
	* activateChapter(cid)
	*
	* The following function takes as a parameter the id of a chapter and sets its active status
	* to one.
	* If the update is successful, the function will return an empty string. Otherwise it will return
	* the error code.
	*
--->
<cffunction name="activateChapter" access="public" returntype="string">
	<cfargument name="cid" type="string" required="yes">
    <!--- Set the active statis of the provided chapter to one --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="activateChapter">
            UPDATE #VARIABLES.tablePrefix#chapters
            SET
                active = 1
            WHERE cid = '#ARGUMENTS.cid#'
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn "">
</cffunction>



<!-----------------------------------------------------------------------------------------------------
	* updateChapter(chapterStruct)
	*
	* The following function takes as a paramter a chapter info struct (defined below) and the
	* chapter id of the chapter the developer wishes to update.
	*
	* chapterStruct = StructNew();
	* chapterStruct.cid
    * chapterStruct.name
    * chapterStruct.region
    * chapterStruct.size
    * chapterStruct.donors
	* 
	* The following option, if specified, will also update the last time accessed
	*
	* chapterStruct.lastAccess
	*
	* This function will return an empty string if successful, otherwise it will return a string
	* containing the error code.
	*
--->
<cffunction name="updateChapter" access="public" returntype="string">
    <cfargument name="chapterStruct" type="struct" required="yes">
    <!--- Make sure the chapter struct is formated correctly with the cid --->
    <cfif NOT StructKeyExists(ARGUMENTS.chapterStruct,"cid")>
    	<cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateChapter() - Struct Key List = #StructKeyList(ARGUMENTS.chapterStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Construct the update string --->
	<cftry>
        <!--- Update the database with the chapter info --->
		<cfif StructKeyExists(ARGUMENTS.chapterStruct,"name")>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapter">
				UPDATE #VARIABLES.tablePrefix#chapters
				SET name = '#ARGUMENTS.chapterStruct.name#'
				WHERE cid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
		</cfif>
		<cfif StructKeyExists(ARGUMENTS.chapterStruct,"region")>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapter">
				UPDATE #VARIABLES.tablePrefix#chapters
				SET region = '#ARGUMENTS.chapterStruct.region#'
				WHERE cid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapterChair">
				UPDATE CHAPTER_CHAIRS
				SET alumni_board = '#ARGUMENTS.chapterStruct.region#', date_updated = '#DateFormat(Now(), "mm/dd/yyyy")#'
				WHERE chpid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
		</cfif>
		<cfif StructKeyExists(ARGUMENTS.chapterStruct,"size")>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapter">
				UPDATE #VARIABLES.tablePrefix#chapters
				SET sizenew = '#ARGUMENTS.chapterStruct.size#'
				WHERE cid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
		</cfif>
		<cfif StructKeyExists(ARGUMENTS.chapterStruct,"donors")>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapter">
				UPDATE #VARIABLES.tablePrefix#chapters
				SET donors = '#ARGUMENTS.chapterStruct.donors#'
				WHERE cid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
		</cfif>
		<cfif StructKeyExists(ARGUMENTS.chapterStruct,"lastAccess")>
			<cfset lastVisit = DateTimeFormat(ARGUMENTS.chapterStruct.lastAccess,"yyyy-mm-dd HH:nn:ss")>
			<cfquery datasource="#VARIABLES.datasource#" name="updateChapter">
				UPDATE #VARIABLES.tablePrefix#chapters
				SET last_visit = '#lastVisit#'
				WHERE cid = '#ARGUMENTS.chapterStruct.cid#'
			</cfquery>
		</cfif>
        
        <cfcatch type="database">
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn ''/>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getRegionList()
    *
    * The following function returns a query result set of all currently specified chapter regions.
	* Data for these regions can be found under the cr_regions table in the alumni database on enclave.
	* If the query fails, the function will return a string error code.
--->
<cffunction name="getRegionList" access="public" returntype="any">
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="regions">
            SELECT *
            FROM #VARIABLES.tablePrefix#regions
            ORDER BY name
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn regions>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * getRegion(regionID)
    *
    * The following function returns the result set of the region with the provided id. The set
    * contains the region name and area id.
    * If the query fails, the function will return a string error code.
--->
<cffunction name="getRegion" access="public" returntype="any">
	<cfargument name="regionID" type="numeric" required="yes">
	<cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="region">
            SELECT name, aid
            FROM #VARIABLES.tablePrefix#regions
            WHERE id = #ARGUMENTS.regionID#
        </cfquery>
        <cfcatch>
            <cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn region />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * addRegion(regionStruct)
    *
    * The following function adds a new region within the chapter reports database.
	* The region struct needs to be in the following format:
	*
	* regionStruct = StructNew()
	* regionStruct.name
	*
	* Currently there is no regionStruct.aid property.
	*
	* If the insert is successful, the function will return newly generated key. Otherwise the function
	* will return the error code as a string
--->
<cffunction name="addRegion" access="public" returntype="any">
	<cfargument name="regionStruct" required="yes">
    <!--- Verify the struct is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.regionStruct,"name")>
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addRegion() - Struct Key List = #StructKeyList(ARGUMENTS.regionStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Perform the insert --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertRegion">
        	INSERT INTO #VARIABLES.tablePrefix#regions
            (name)
            VALUES(
            	'#ARGUMENTS.regionStruct.name#'
            )
        </cfquery>
		<cfquery datasource="#VARIABLES.datasource#" name="newRegion">
			SELECT DISTINCT id
			FROM #VARIABLES.tablePrefix#regions
			WHERE name = '#ARGUMENTS.regionStruct.name#'
			ORDER BY id DESC
		</cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newRegion.id />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateRegion(regionStruct)
    *
    * The following function updates region information within the chapter reports database.
	* The region struct needs to be in the following format:
	*
	* regionStruct = StructNew()
	* regionStruct.id
	* regionStruct.name
	*
	* Currently there is no regionStruct.aid property.
	*
	* If the update is successful, the function will return the empty string. Otherwise the function
	* will return the error code as a string
--->
<cffunction name="updateRegion" access="public" returntype="string">
	<cfargument name="regionStruct" required="yes">
    <!--- Verify the struct is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.regionStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.regionStruct,"name")>
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateRegion() - Struct Key List = #StructKeyList(ARGUMENTS.regionStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Perform the update --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateRegion">
        	UPDATE #VARIABLES.tablePrefix#regions
            SET
            	name = '#ARGUMENTS.regionStruct.name#'
            WHERE
            	id = #ARGUMENTS.regionStruct.id#
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
    * deleteRegion(id)
    *
    * The following function deletes an existing region within the chapter reports database.
	*
	* If the delete is successful, the function will return the empty string. Otherwise the function
	* will return the error code as a string
--->
<cffunction name="deleteRegion" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Perform the delete --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteRegion">
        	DELETE FROM #VARIABLES.tablePrefix#regions
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- We also need to set the regions of all the chapters assigned to this region to 0 --->
        <cfquery datasource="#VARIABLES.datasource#" name="updateChapterRegions">
        	UPDATE #VARIABLES.tablePrefix#chapters
            SET
            	region = 0
            WHERE region = #ARGUMENTS.id#
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
    * getAccessData([netid])
    *
    * The following function returns a query result set containing user access permissions and data
	* for the user with the specified netid.
	*
	* If an error occurs, the function will return a string error code
--->

<cffunction name="getAccessData" access="public" returntype="any">
	<cfargument name="netid" type="string" required="no">
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="accessData">
        	SELECT *
            FROM #VARIABLES.tablePrefix#access
			<cfif isDefined('ARGUMENTS.netid') AND trim(ARGUMENTS.netid) NEQ ''>
				WHERE netid = '#ARGUMENTS.netid#'
			</cfif>
            ORDER BY last_name
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn accessData/>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * addAccessData(accessStruct)
    *
    * The following function creates a new entry with the access information according to the provided accessStruct.
	* The required struct must be formatted as follows:
	*
	* accessStruct = StructNew()
	* accessStruct.netid
	* accessStruct.cid
	* accessStruct.firstName
	* accessStruct.lastName
	* accessStruct.level
	* accessStruct.data
	* accessStruct.lastAccess
	*
	* Upon success, the function will return the empty string.
	* If an error occurs, the function will return a string error code
--->
<cffunction name="addAccessData" access="public" returntype="string">
	<cfargument name="accessStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.accessStruct,"netid")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"firstName")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"lastName")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"level")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"data")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"lastAccess")>
    	<cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateAccessData() - Struct Key List = #StructKeyList(ARGUMENTS.accessStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Update the data --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="addData" result="newAccessData">
        	INSERT INTO #VARIABLES.tablePrefix#access
            (netid, first_name, last_name, cid, access_level, access_data, last_access)
            VALUES(
            	'#ARGUMENTS.accessStruct.netid#',
            	'#ARGUMENTS.accessStruct.firstName#',
                '#ARGUMENTS.accessStruct.lastName#',
                '#ARGUMENTS.accessStruct.cid#',
            	'#ARGUMENTS.accessStruct.level#',
                '#ARGUMENTS.accessStruct.data#',
                <cfif trim(ARGUMENTS.accessStruct.lastAccess) EQ ''>
                NULL
                <cfelse>
                '#DateTimeFormat(ARGUMENTS.accessStruct.lastAccess,"yyyy-mm-dd HH:nn:ss")#'
                </cfif>
            )
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn '' />
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * updateAccessData(accessStruct)
    *
    * The following function updates the access information according to the provided accessStruct.
	* The required struct must be formatted as follows:
	*
	* accessStruct = StructNew()
	* accessStruct.netid
	* accessStruct.cid
	* accessStruct.firstName
	* accessStruct.lastName
	* accessStruct.level
	* accessStruct.data
	* accessStruct.lastAccess
	*
	* Upon success, the function will return the empty string.
	* If an error occurs, the function will return a string error code
--->
<cffunction name="updateAccessData" access="public" returntype="string">
	<cfargument name="accessStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.accessStruct,"netid")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"firstName")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"lastName")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"level")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"data")
		OR NOT StructKeyExists(ARGUMENTS.accessStruct,"lastAccess")>
    	<cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateAccessData() - Struct Key List = #StructKeyList(ARGUMENTS.accessStruct)#">
        <cfreturn errorCode />
    </cfif>
    <!--- Update the data --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateData">
        	UPDATE #VARIABLES.tablePrefix#access
            SET
            	first_name = '#ARGUMENTS.accessStruct.firstName#',
                last_name = '#ARGUMENTS.accessStruct.lastName#',
                cid = '#ARGUMENTS.accessStruct.cid#',
            	access_level = '#ARGUMENTS.accessStruct.level#',
                access_data = '#ARGUMENTS.accessStruct.data#',
                <cfif trim(ARGUMENTS.accessStruct.lastAccess) EQ ''>
                last_access = NULL
                <cfelse>
                <cfset lastVisit = DateTimeFormat(ARGUMENTS.accessStruct.lastAccess,"yyyy-mm-dd HH:nn:ss")>
                last_access = '#lastVisit#'
                </cfif>
            WHERE netid = '#ARGUMENTS.accessStruct.netid#'
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
    * deleteAccessData(netid)
    *
    * The following function removes the user access data associated with the proviede netid from
	* the chapter reports database.
	*
	* If successful, the function will return the empty string.
	* If an error occurs, the function will return a string error code. 
--->
<cffunction name="deleteAccessData" access="public" returntype="any">
	<cfargument name="netid" type="string" required="yes">
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteData">
        	DELETE FROM #VARIABLES.tablePrefix#access
            WHERE netid = '#ARGUMENTS.netid#'
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn ''/>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getTrueBlue(cid)
    *
    * The following function returns a struct containing information about the true blue status
	*  of the chapter with the provided cid. The returned struct will be in the following format:
	*
	* trueBlueStruct.leaderCount				// the number of leader positions filled
	* trueBlueStruct.categoryCount				// the number of categories that have events
	* trueBlueStruct.studentEngagementEvent		// boolean, chapter has a student engagement event
	* trueBlueStruct.alumniEngagementEvent		// boolean, chapter has an alumni engagement event
	* trueBlueStruct.replenishmentGrantEvent	// boolean, chapter has a replenishment grant event
	* trueBlueStruct.influenceOfTheYEvent		// boolean, chapter has an influence of the Y event
	* trueBlueStruct.tier						// the tier level of the chapter		
	*
	* If successful, the function will return the true blue struct of the chapter.
	* Otherwise it will return a string error code.
	*
--->
<cffunction name="getTrueBlue" access="public" returntype="any">
	<cfargument name="cid" type="string" required="yes">
    <!--- Initialize the struct --->
    <cfscript>
		var trueBlueStruct = {
			leaderCount = 0,
			categoryCount = 0,
			studentEngagementEvent = FALSE,
			alumniEngagementEvent = FALSE,
			replenishmentGrantEvent = FALSE,
			influenceOfTheYEvent = FALSE,
			tier = 0
		};
	</cfscript>
    <!--- First get the roster and determine how many positions are filled --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="roster">
        	SELECT *
            FROM #VARIABLES.tablePrefix#positions
            WHERE cid = '#ARGUMENTS.cid#'
            	AND type = 'leader'
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR_1">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfloop query="#roster#">
    	<cfif trim(occupant) NEQ '' AND lcase(trim(occupant)) NEQ 'open' AND lcase(trim(occupant)) NEQ 'available'
			AND len(trim(occupant)) GT 5>
            <cfset trueBlueStruct.leaderCount++>
        </cfif>
    </cfloop>
    <!--- Now determine the event category count --->
    <!--- First get the report we are currently in --->
    <cftry>
		<cfset currentDate = Now()>
		<cfquery datasource="#VARIABLES.datasource#" name="report">
			SELECT *
			FROM #VARIABLES.tablePrefix#report_ids
			WHERE type = 'event' AND end_date >= #currentDate#
		</cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR_2">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- Only proceed if a report exists. --->
    <cfif report.recordCount NEQ 0>
    	<!--- Now we need to get all the events that fit in this report--->
        <cftry>
			<cfscript>
				dateTimeStart = dateTimeFormat(report.start_date, "yyyy.mm.dd");
				startDate = parseDateTime(dateTimeStart);
				dateTimeEnd = dateTimeFormat(report.end_date, "yyyy.mm.dd");
				nextDay = DateAdd("d",1,dateTimeEnd);
				endDate = parseDateTime(nextDay);
			</cfscript>
            <cfquery datasource="#VARIABLES.datasource#" name="events">
                SELECT *
                FROM #VARIABLES.tablePrefix#events
                WHERE cid = '#ARGUMENTS.cid#' AND event_date_time >= #startDate# AND event_date_time < #endDate#
            </cfquery>
            <cfcatch type="database">
                <cfset errorCode = "DATABASE_EXECUTION_ERROR_3">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
        <!--- Make sure events exists before we proceed --->
        <cfif events.recordCount NEQ 0>
			<!--- We need to check for 4 different categories of events (the first 4 event ids) 
                 1 = Student Engagement
                 2 = Alumni Engagement
                 3 = Enlarge the Influence of the Y
                 4 = Replenishment --->
            <cfloop query="#events#">
            	<cfscript>
            		if(attendance > 0){
						switch(event_category){
							case 1:
								trueBlueStruct.studentEngagementEvent = TRUE;
								break;
							case 2:
								trueBlueStruct.alumniEngagementEvent = TRUE;
								break;
							case 3: 
								trueBlueStruct.influenceOfTheYEvent = TRUE;
								break;
							case 4:
								trueBlueStruct.replenishmentGrantEvent = TRUE;
								break;
							default: 
								break;
						}
					}
				</cfscript>
            </cfloop>
            <cfscript>
				if(trueBlueStruct.studentEngagementEvent) trueBlueStruct.categoryCount++;
				if(trueBlueStruct.alumniEngagementEvent) trueBlueStruct.categoryCount++;
				if(trueBlueStruct.influenceOfTheYEvent) trueBlueStruct.categoryCount++;
				if(trueBlueStruct.replenishmentGrantEvent) trueBlueStruct.categoryCount++;
			</cfscript>
        </cfif>
    </cfif>
    <!--- Now we need to update the true blue tier value in the chapter table --->
    <cfscript>
		if(trueBlueStruct.leaderCount >= 4 && trueBlueStruct.categoryCount == 4){
			trueBlueStruct.tier = 1;
		}
		else if(trueBlueStruct.leaderCount >= 4 && trueBlueStruct.categoryCount == 3){
			trueBlueStruct.tier = 2;
		}
		else if(trueBlueStruct.leaderCount >= 3 && trueBlueStruct.categoryCount > 0){
			trueBlueStruct.tier = 3;
		}
		else{
			trueBlueStruct.tier = 4;	
		}
	</cfscript>
	<cftry>
		<cfquery datasource="#VARIABLES.datasource#" name="updateTier">
			UPDATE #VARIABLES.tablePrefix#chapters
			SET
            	true_blue_tier = #trueBlueStruct.tier#
            WHERE cid = '#ARGUMENTS.cid#'
		</cfquery>
		<cfcatch type="database">
			<cfset errorCode = "DATABASE_EXECUTION_ERROR_4">
			<cflog file="chapter-reports" type="error" 
				text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
			<cfreturn errorCode />
		</cfcatch>
	</cftry>
    <cfreturn trueBlueStruct />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getImages(filterStruct)
    *
    * The following function gets the images for the user's chapter.
    *
	* filterStruct = StructNew()	// create the structure
	* filterStruct.cid				// the chapter id
	*
	* If successful, the function will return the image data.
	* If an error occurs, the function will return a string error code. 
--->
<cffunction name="getImages" access="public" returntype="any">
	<cfargument name="filterStruct" type="struct" required="no">
    <!--- build the where clause based on the filter struct --->
    <cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
        	<cfset whereString = 'WHERE i.cid = "#ARGUMENTS.filterStruct.cid#"'>
        </cfif>
    </cfif>
    <!---Run the query--->
	<cftry>
		<cfquery datasource="#VARIABLES.datasource#" name="imageData">
            SELECT i.*
            FROM #VARIABLES.tablePrefix#images i
            INNER JOIN #VARIABLES.tablePrefix#chapters c
            	ON c.cid = i.cid
            #whereString#
		</cfquery>
		<cfcatch type="database">
			<cfset errorCode="DATABASE_EXECUTION_ERROR">
			<cflog file="chapter-reports" type="error"
				text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY : #cfcatch.Sql#">
			<cfreturn errorCode />
		</cfcatch>
	</cftry>
	<cfreturn imageData>
</cffunction>
			

<!----------------------------------------------------------------------------------------------------
    * uploadImages(imageStruct)
    *
    * The following function gets the images for the user's chapter.
    *
	* imageStruct = StructNew()		// create the structure
	* imageStruct.cid				// the chapter id
	* imageStruct.img1_id           // the first image
	* imageStruct.img2_id           // the second image
	* imageStruct.img3_id           // the third image
	* imageStruct.img4_id           // the fourth image
	* imageStruct.img5_id           // the fifth image
	* imageStruct.img6_id           // the sixth image
	* imageStruct.img7_id           // the seventh image
	* imageStruct.img8_id           // the eighth image
	* imageStruct.img9_id           // the ninth image
	* imageStruct.img10_id           // the tenth image
	*
	* If successful, the function will upload the image data.
	* If an error occurs, the function will return a string error code. 
--->
<cffunction name="uploadImages" access="public" returntype="any">
	<cfargument name="imageStruct" type="struct" required="yes">
    <!--- verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.imageStruct,"cid")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img1_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img2_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img3_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img4_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img5_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img6_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img7_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img8_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img9_id")
       	OR NOT StructKeyExists(ARGUMENTS.imageStruct, "img10_id")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: uploadImages() - Struct Key List = #StructKeyList(ARGUMENTS.imageStruct)#">
        <cfreturn errorCode />
    </cfif>
	<cftry>
		<cfquery datasource="#VARIABLES.datasource#" name="updateImages" result="newImages">
        	UPDATE #VARIABLES.tablePrefix#images
            SET
               	img1_id = '#ARGUMENTS.imageStruct.img1_id#',
               	img2_id = '#ARGUMENTS.imageStruct.img2_id#',
               	img3_id = '#ARGUMENTS.imageStruct.img3_id#',
               	img4_id = '#ARGUMENTS.imageStruct.img4_id#',
               	img5_id = '#ARGUMENTS.imageStruct.img5_id#',
               	img6_id = '#ARGUMENTS.imageStruct.img6_id#',
               	img7_id = '#ARGUMENTS.imageStruct.img7_id#',
               	img8_id = '#ARGUMENTS.imageStruct.img8_id#',
               	img9_id = '#ARGUMENTS.imageStruct.img9_id#',
               	img10_id = '#ARGUMENTS.imageStruct.img10_id#'
            WHERE cid = #ARGUMENTS.imageStruct.cid#
		</cfquery>
		<cfcatch type="database">
			<cfset errorCode="DATABASE_EXECUTION_ERROR">
			<cflog file="chapter-reports" type="error"
				text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY : #cfcatch.Sql#">
			<cfreturn errorCode />
		</cfcatch>
	</cftry>
	<cfreturn '' />
</cffunction>

<!----------------------------------------------------------------------------------------------------
	* updateReportData(dataStruct)
	* 
	* The following updates a chapter's data for the master report.
	* The struct should be formatted as follows:
	* 
	* dataStruct = StructNew();
	* dataStruct.cid
	* dataStruct.grants
	* dataStruct.attendance
	*
	* If successful, the function will update the report data.
	* If there is an error, the function will return a string error code.
--->
<cffunction name="updateReportData" access="public" returntype="any">
	<cfargument name="dataStruct" type="struct" required="yes">
	<!---Verify the struct--->
	<cfif NOT StructKeyExists(ARGUMENTS.dataStruct, "cid")
		  OR NOT StructKeyExists(ARGUMENTS.dataStruct, "grants")
		  OR NOT StructKeyExists(ARGUMENTS.dataStruct, "attendance")>
		<cfset errorCode = "INVALID_STRUCT_FORMAT">
		<cflog file="chapter-reports" type="error" text="#errorCode#: updateReportData() - StructKeyList = #StructKeyList(ARGUMENTS.dataStruct)#">
		<cfreturn errorCode>
	</cfif>
	
	<cftry>
		<cfquery datasource="#VARIABLES.datasource#" name="updateReport">
		
			UPDATE #VARIABLES.tablePrefix#master_report_data
			SET
				grants = '#ARGUMENTS.dataStruct.grants#',
				attendance = '#ARGUMENTS.dataStruct.attendance#'
			WHERE cid = '#ARGUMENTS.dataStruct.cid#'
		
		</cfquery>
		<cfcatch type="database">
			<cfset errorCode="DATABASE_EXECUTION_ERROR">
			<cflog file="chapter-reports" type="error"
				   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY : #cfcatch.Sql#">
			<cfreturn errorCode />
		</cfcatch>
	</cftry>
	<cfreturn ''/>
	
</cffunction>

<!----------------------------------------------------------------------------------------------
	* getReportData(cid)
	*
	* This function gets the report data for a specific chapter, as specified
	* by the cid passed in.
	* 
	* If there is an error when trying to get the data from the database,
	* an error is thrown. Otherwise, a query with the report data for that
	* chapter is returned.
--->	
<cffunction name="getReportData" access="public" returntype="any">
	<cfargument name="cid" type="string" required="yes">
	<cftry>
		<cfquery datasource="#VARIABLES.datasource#" name="getReport">
		
			SELECT d.*
			FROM #VARIABLES.tablePrefix#master_report_data d
			WHERE d.cid = '#cid#'
		
		</cfquery>
		<cfcatch type="database">
			<cfset errorCode="DATABASE_EXECUTION_ERROR">
				<cflog file="chapter-reports" type="error"
					   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY : #cfcatch.Sql#">
				<cfreturn errorCode />
		</cfcatch>
	</cftry>
	<cfreturn getReport>
		
</cffunction>

</cfcomponent>