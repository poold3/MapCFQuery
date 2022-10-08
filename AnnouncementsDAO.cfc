<cfcomponent displayname="AnnouncementsDAO">
	
<!---
    --- This file contains functions that query the alumni database cr_ tables to
	--- get information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets.
    ---
    --- All of the functions in this file are for the following information:
    ---
    --- Chapter Announcements and Links
--->

<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="AnnouncementsDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getAnnouncements([filterStruct])
    *
    * The following function returns a query result set of all announcment entries for active BYU Chapters.
	* The optional filterStruct argument can have any (or none) of the following members.
	*
	* filterStruct = StructNew()		// create the struct	
	* filterStruct.id					// the id of the entry in the table
	* filterStruct.cid					// the chapter id of the chapter the announcement belongs to
	* filterStruct.current				// YES/TRUE to query only announcements that have not expired
	* filterStruct.active				// a boolean to toggle active/inactive chapters
	* filterStruct.chapterType          // the type of chapter ('regional', 'professional', etc.)
	* filterStruct.published			// a boolean to toggle between publisned and unpublished announcements
	*
	* If successful, the function will return a query result set according to the filters.
	* Otherwise it will return a string error code.
--->
<cffunction name="getAnnouncements" access="public" returntype="any"> <!--********************************** Fixed by Ryan ********************* -->
    <cfargument name="filterStruct" type="struct" required="no">
    <!-- Set the date -->
    <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>
    <cfset currentDateAsDate = parseDateTime(currentdate)>
    <!--- run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="announcements">
            SELECT c.name, c.region, a.*
            FROM #VARIABLES.tablePrefix#announcements a
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = a.cid
            WHERE id <> 0
                <cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND TRIM(ARGUMENTS.filterStruct.id) NEQ ''>
        	AND a.id = '#ARGUMENTS.filterStruct.id#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
        	AND a.cid = '#ARGUMENTS.filterStruct.cid#'
        </cfif>
		<cfif StructKeyExists(ARGUMENTS.filterStruct,"current") AND ARGUMENTS.filterStruct.current>
        	AND a.expire_date >= #currentDateAsDate#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
        	<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
             AND c.active = #active#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"published") AND isBoolean(ARGUMENTS.filterStruct.published)>
        	<cfset var published = (ARGUMENTS.filterStruct.published) ? 1 : 0>
            AND a.published = #published#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
        	AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
        </cfif>
    </cfif>
            ORDER BY c.name, a.expire_date
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "#cfcatch.Message#">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn announcements>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * addAnnouncement(announcementStruct)
	*
	* Creates a new announcement entry in the database. The structure of the accouncementStruct
	* argument must be as follows:
	*
	* announcementStruct = StructNew()
	* announcementStruct.cid
	* announcementStruct.title
	* announcementStruct.content
	* announcementStruct.expireDate
	*
	* If successful, the function will return the generated key of the new table entry. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="addAnnouncement" access="public" returntype="any">
	<cfargument name="announcementStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.announcementStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"content")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"expireDate")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addAnnouncement() - Struct Key List = #StructKeyList(ARGUMENTS.announcementStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Properly formate the expire date --->
    <cfset expireDate = DateFormat(ARGUMENTS.announcementStruct.expireDate,"yyyy-mm-dd")>
    <cfset expireDateAsDate = parseDateTime(expireDate)>
    <!-- Set the current date -->
    <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>
    <cfset currentDateAsDate = parseDateTime(currentdate)>

    <!--- Insert the data into the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertAnnouncement">
        	INSERT INTO #VARIABLES.tablePrefix#announcements
            (cid, announcement_title, announcement_content, create_date, expire_date)
            VALUES(
            	'#ARGUMENTS.announcementStruct.cid#',
                '#ARGUMENTS.announcementStruct.title#',
                '#ARGUMENTS.announcementStruct.content#',
                #currentDateAsDate#,
                #expireDateAsDate#
            )
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="newAnnouncement">
            SELECT DISTINCT id
            FROM #VARIABLES.tablePrefix#announcements
            WHERE create_date = #currentDateAsDate# AND expire_date = #expireDateAsDate# AND cid = '#ARGUMENTS.announcementStruct.cid#'
            ORDER BY id DESC
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "#cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newAnnouncement.id />
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * updateAnnouncement(announcementStruct)
	*
	* Updates an existing announcement entry in the database. The structure of the accouncementStruct
	* argument must be as follows:
	*
	* announcementStruct = StructNew()
	* announcementStruct.id
	* announcementStruct.title
	* announcementStruct.content
	* announcementStruct.expireDate
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="updateAnnouncement" access="public" returntype="string">
	<cfargument name="announcementStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.announcementStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"content")
		OR NOT StructKeyExists(ARGUMENTS.announcementStruct,"expireDate")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateAnnouncement() - Struct Key List = #StructKeyList(ARGUMENTS.announcementStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Properly formate the expire date --->
    <cfset expireDate = DateFormat(ARGUMENTS.announcementStruct.expireDate,"yyyy-mm-dd")>
    <cfset expireDateAsDate = parseDateTime(expireDate)>
    <!--- Insert the data into the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertAnnouncement" result="newAnnouncement">
        	UPDATE #VARIABLES.tablePrefix#announcements
            SET
            	announcement_title = '#ARGUMENTS.announcementStruct.title#',
                announcement_content = '#ARGUMENTS.announcementStruct.content#',
                expire_date = #expireDateAsDate#
            WHERE id = #ARGUMENTS.announcementStruct.id#
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
    * deleteAnnouncement(id)
	*
	* Removes the announcement entry with the given id from the database table.
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="deleteAnnouncement" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Delete the data from the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertAnnouncement" result="newAnnouncement">
        	DELETE FROM #VARIABLES.tablePrefix#announcements
            WHERE id = #ARGUMENTS.id#
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
    * publishAnnouncement(id)
	*
	* Allows the announcement entry with the given id to be published to alumni.byu.edu.
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="publishAnnouncement" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Update the published flag --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="publishAnnouncement">
        	UPDATE #VARIABLES.tablePrefix#announcements
            	SET
                	published = 1
            WHERE id = #ARGUMENTS.id#
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
    * unpublishAnnouncement(id)
	*
	* Forbids the announcement entry with the given id to be published to alumni.byu.edu.
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="unpublishAnnouncement" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Update the publish flag --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="unpublishAnnouncement">
        	UPDATE #VARIABLES.tablePrefix#announcements
            	SET
                	published = 0
            WHERE id = #ARGUMENTS.id#
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
    * getSiteLinks([filterStruct])
    *
    * The following function returns a query result set of all additional site links for active
	* BYU chapters.
    * The optional filterStruct argument, if provided, should have one or more of the following members:
	*
	* filterStruct = StructNew()
	* filterStruct.id
	* filterStruct.cid
	* filterStruct.active
	* filterStruct.chapterType
	*
	* If successful, the function will return a query result set according to the provided filters (if any).
	* Otherwise the function will return a string error code.
--->
<cffunction name="getSiteLinks" access="public" returntype="any"> <!--************************************** Fixed by Ryan **********************-->
    <cfargument name="filterStruct" type="struct" required="no">

    <!--- run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="siteLinks">
            SELECT s.*, c.name AS chapter_name, c.region AS chapter_region
            FROM #VARIABLES.tablePrefix#site_links s
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = s.cid
            WHERE id <> 0
                <cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND TRIM(ARGUMENTS.filterStruct.id) NEQ ''>
        	 AND s.id = #ARGUMENTS.filterStruct.id#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
        	AND s.cid = '#ARGUMENTS.filterStruct.cid#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
        	<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
            AND c.active = #active#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
        	AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
        </cfif>
    </cfif>
            ORDER BY c.name
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn siteLinks>
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * addSiteLinks(linkStruct)
    *
    * Creates a new entry in the database for chapter site links. The provided linkStruct must be
	* formated as follows:
	*
	* linkStruct = StructNew()
	* linkStruct.cid
	* linkStruct.facebook
	* linkStruct.instagram
	* linkStruct.twitter
	* linkStruct.linkedin
	* linkStruct.website
	* linkStruct.donate
	* linkStruct.updatedBy
	*
	* If successful, the function will return the generated key of the new table entry. Otherwise, it
	* will return the string error code associated with the failure.
--->
<cffunction name="addSiteLinks" access="public" returntype="any">
	<cfargument name="linkStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(linkStruct,"cid")
		OR NOT StructKeyExists(linkStruct,"facebook")
		OR NOT StructKeyExists(linkStruct,"instagram")
		OR NOT StructKeyExists(linkStruct,"twitter")
		OR NOT StructKeyExists(linkStruct,"linkedin")
		OR NOT StructKeyExists(linkStruct,"website")
		OR NOT StructKeyExists(linkStruct,"donate")
		OR NOT StructKeyExists(linkStruct,"updatedBy")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addSiteLinks() - Struct Key List = #StructKeyList(ARGUMENTS.linkStruct)#">
        <cfreturn errorCode />
        
    </cfif>
       <!-- Set the date outside of the query -->
        <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>
    <!--- Insert the data into the table --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertLinks">
        	INSERT INTO #VARIABLES.tablePrefix#site_links
            (cid, fb_link, insta_link, tw_link, lin_link, web_link, donate_link, update_date, updated_by)
            VALUES(
            	'#ARGUMENTS.linkStruct.cid#',
                '#ARGUMENTS.linkStruct.facebook#',
                '#ARGUMENTS.linkStruct.instagram#',
                '#ARGUMENTS.linkStruct.twitter#',
                '#ARGUMENTS.linkStruct.linkedin#',
                '#ARGUMENTS.linkStruct.website#',
                '#ARGUMENTS.linkStruct.donate#',
                '#currentdate#',
                '#ARGUMENTS.linkStruct.updatedBy#'
            )
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="getNewId">
            SELECT DISTINCT id
            FROM #VARIABLES.tablePrefix#site_links
            WHERE cid = '#ARGUMENTS.linkStruct.cid#'
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn getNewId.id />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateSiteLinks(linkStruct)
    *
    * Updates an existing entry in the database for chapter site links. The provided linkStruct must be
	* formated as follows:
	*
	* linkStruct = StructNew()
	* linkStruct.id
	* linkStruct.facebook
	* linkStruct.instagram
	* linkStruct.twitter
	* linkStruct.linkedin
	* linkStruct.website
	* linkStruct.donate
	* linkStruct.updatedBy
	*
	* If successful, the function will return the empty string. Otherwise, it
	* will return the string error code associated with the failure.
--->
<cffunction name="updateSiteLinks" access="public" returntype="string">
	<cfargument name="linkStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(linkStruct,"id")
		OR NOT StructKeyExists(linkStruct,"facebook")
		OR NOT StructKeyExists(linkStruct,"instagram")
		OR NOT StructKeyExists(linkStruct,"twitter")
		OR NOT StructKeyExists(linkStruct,"linkedin")
		OR NOT StructKeyExists(linkStruct,"website")
		OR NOT StructKeyExists(linkStruct,"donate")
		OR NOT StructKeyExists(linkStruct,"updatedBy")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateSiteLinks() - Struct Key List = #StructKeyList(ARGUMENTS.linkStruct)#">
        <cfreturn errorCode />
        
    </cfif>
        <!-- Set the date outside of the query -->
        <cfset currentdate = DateFormat(NOW(), 'yyyy-mm-dd')>

    <!--- Insert the data into the table --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateLinks">
        	UPDATE #VARIABLES.tablePrefix#site_links
            SET
                fb_link = '#ARGUMENTS.linkStruct.facebook#',
                insta_link = '#ARGUMENTS.linkStruct.instagram#',
                tw_link = '#ARGUMENTS.linkStruct.twitter#',
                lin_link = '#ARGUMENTS.linkStruct.linkedin#',
                web_link = '#ARGUMENTS.linkStruct.website#',
                donate_link = '#ARGUMENTS.linkStruct.donate#',
                update_date = '#currentdate#',
                updated_by = '#ARGUMENTS.linkStruct.updatedBy#'
            WHERE id = '#ARGUMENTS.linkStruct.id#'
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE EXECUTION ERROR">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn '' />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getDescription([filterStruct])
    *
    * The following function returns a query result set of all description entries for active BYU Chapters.
	* The optional filterStruct argument can have any (or none) of the following members.
	*
	* filterStruct = StructNew()		// create the struct	
	* filterStruct.id					// the id of the entry in the table
	* filterStruct.cid					// the chapter id of the chapter the description belongs to
	* filterStruct.active				// a boolean to toggle active/inactive chapters
	* filterStruct.chapterType          // the type of chapter ('regional', 'professional', etc.)
	*
	* If successful, the function will return a query result set according to the filters.
	* Otherwise it will return a string error code.
--->
<cffunction name="getDescription" access="public" returntype="any"> <!--********************************** Fixed by Ryan ********************* -->
    <cfargument name="filterStruct" type="struct" required="no">
    <!--- run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="descriptions">
            SELECT c.name, c.region, a.*
            FROM #VARIABLES.tablePrefix#description a
            INNER JOIN #VARIABLES.tablePrefix#chapters c
                ON c.cid = a.cid
                WHERE id <> 0
                    <cfif isDefined('ARGUMENTS.filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND TRIM(ARGUMENTS.filterStruct.id) NEQ ''>
        	AND a.id = #ARGUMENTS.filterStruct.id#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
        	 AND a.cid = '#ARGUMENTS.filterStruct.cid#'
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
        	<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
             AND c.active = #active#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
        AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
        </cfif>
    </cfif> 
            ORDER BY c.name
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "#cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <!--- return the result --->
    <cfreturn descriptions>
</cffunction>

<!----------------------------------------------------------------------------------------------------
	* addDescription(descriptionStruct)
	*
	* Creates a description for each chapter page. The structure of the descriptionStruct must
	* be as follows:
	*
	* descriptionStruct = StructNew()
	* descriptionStruct.cid
	* descriptionStruct.content
	*
	* If successful, the function will return the generated key of the new table entry. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="addDescription" access="public" returntype="any">
	<cfargument name="descriptionStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.descriptionStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.descriptionStruct,"content")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addDescription() - Struct Key List = #StructKeyList(ARGUMENTS.descriptionStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Insert the data into the database --->
    <cftry>
        <cfset currentDate = Now()>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateDescription">
        	INSERT INTO #VARIABLES.tablePrefix#description
            (cid, description_content, create_date)
            VALUES(
            	'#ARGUMENTS.descriptionStruct.cid#',
                '#ARGUMENTS.descriptionStruct.content#',
                #currentDate#
            )
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="newDescription">
            SELECT DISTINCT id
            FROM #VARIABLES.tablePrefix#description
            WHERE cid = '#ARGUMENTS.descriptionStruct.cid#'
            ORDER BY id DESC
        </cfquery>
        <cfcatch type="database">
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
            <cflog file="chapter-reports" type="error" 
                   text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newDescription.id />
</cffunction>

<!----------------------------------------------------------------------------------------------------
    * updateDescription(descriptionStruct)
	*
	* Updates an existing description entry in the database. The structure of the descriptionStruct
	* argument must be as follows:
	*
	* descriptionStruct = StructNew()
	* descriptionStruct.id
	* descriptionStruct.content
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="updateDescription" access="public" returntype="string">
	<cfargument name="descriptionStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.descriptionStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.descriptionStruct,"content")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateDescription() - Struct Key List = #StructKeyList(ARGUMENTS.descriptionStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Insert the data into the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateDescription" result="newDescription">
        	UPDATE #VARIABLES.tablePrefix#description
            SET
                description_content = '#ARGUMENTS.descriptionStruct.content#'
            WHERE id = #ARGUMENTS.descriptionStruct.id#
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
    
    
</cfcomponent>