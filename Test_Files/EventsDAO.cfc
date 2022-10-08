<cfcomponent displayname="EventsDAO">

<!---
    --- This file contains functions that query the alumni database cr_ tables to get 
	--- information about chapter reports. All return values (unless otherwise
    --- specified in the Function definition and/or name) return result sets.
    ---
    --- The datasource for all queries is set in the SESSION.CONFIG struct in /init.cfm
    ---
    --- All of the functions in this file are for the following report:
    ---
    --- Events and Activities Reports
--->


<!--- Initializer
	* This init() method is called when the component is created. If arguments are supplied
	* it will alter the default configuration for this component.
--->
<cffunction name="init" access="public" output="no" returntype="EventsDAO">
	<cfargument name="datasource" type="string" required="no" default="alumni_db">
    <cfargument name="tablePrefix" type="string" required="no" default="cr_">
    <cfset VARIABLES.datasource = ARGUMENTS.datasource>
    <cfset VARIABLES.tablePrefix = ARGUMENTS.tablePrefix>
    <cfreturn THIS>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * getEvents([filterStruct, orderArray])
    *
    * The following function returns a query result set of all events within the given year constraint
    * The optional filterStruct argument, if provided, will limit results provided according to the given
	* constraints. It should contain one or more of the following members:
	*
	* filterStruct = StructNew()	// create the structure
	* filterStruct.id				// the id of the event entry
	* filterStruct.year				// the calendar year the events should fit in
	* filterStruct.cid				// the chapter id
	* filterStruct.region			// the region of the chapter
	* filterStruct.startDate		// a start cutoff for event dates (date object)
	* filterStruct.endDate			// the end of the cutoff for event dates (date object)
	* filterStruct.category			// the category of event
	* filterStruct.type				// the type of event
	* filterStruct.submitted		// submission status of event (boolean value)
	* filterStruct.rid				// the report id of the submitted report the event belongs to
	* filterStruct.visible			// a boolean for whether the event is visible on alumni.byu.edu
	* filerStruct.active			// a boolean to toggle active/inactive chapter events
	* filterStruct.chapterType      // the type of chapter the event is associated with ('regional','professional')
	*
    * If the 'orderArray' variable is set, then the default ordering by chapter name will be 
	* overidden and the provided sorting columns will be applied. The array can be constructed
	* as follows:
	*
	* orderArray = ArrayNew(1)
	* ArrayAppend(orderArray,"column_name")
	*
	* By default, the query will already be ordered by the date and time of the event.
	*
	* If successful, the function will return the filtered query result set.
	* Otherwise it will return a string error code.
--->
<cffunction name="getEvents" access="public" returntype="any">
    <cfargument name="filterStruct" type="struct" required="no"/>
    <cfargument name="orderArray" type="array" required="no"/>
    <!--- build the ordering --->
    <cfset orderString = "event_date_time">
    <cfif isDefined('ARGUMENTS.order') AND ArrayLen(ARGUMENTS.order) NEQ 0>
        <cfloop array="#ARGUMENTS.order#" index="i">
            <cfset orderString = orderString & ',#i#'>
        </cfloop>
    </cfif>
    <!--- get the events --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="chapterEvents">
            SELECT c.name, c.region, e.*
            FROM #VARIABLES.tablePrefix#events e
            INNER JOIN #VARIABLES.tablePrefix#chapters c
            	ON c.cid = e.cid
            WHERE id <> 0
            <cfif isDefined('ARGUMENTS.filterStruct')>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND isNumeric(ARGUMENTS.filterStruct.id)>
                    AND e.id = #ARGUMENTS.filterStruct.id#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"year") AND isNumeric(ARGUMENTS.filterStruct.year)>
                    <cfset startYear = DateFormat(CreateDate(ARGUMENTS.filterStruct.year,1,1),'yyyy-mm-dd')>
                    <cfset endYear = DateFormat(CreateDate(ARGUMENTS.filterStruct.year,12,31),'yyyy-mm-dd')>
                    <cfset nextDay = DateAdd("d",1,endYear)>
                    AND e.event_date_time >= #parseDateTime(startYear)# AND e.event_date_time < #parseDateTime(nextDay)#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
                    AND e.cid = '#ARGUMENTS.filterStruct.cid#'
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"region") AND isNumeric(ARGUMENTS.filterStruct.region)>
                    AND c.region = '#ARGUMENTS.filterStruct.region#'
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"startDate") AND isDate(ARGUMENTS.filterStruct.startDate)>
                    <cfset startDate = DateFormat(ARGUMENTS.filterStruct.startDate,"yyyy-mm-dd")>
                    AND e.event_date_time >= #parseDateTime(startDate)#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"endDate") AND isDate(ARGUMENTS.filterStruct.endDate)>
                    <cfset endDate = parseDateTime(DateFormat(ARGUMENTS.filterStruct.endDate,"yyyy-mm-dd"))>
                    <cfset nextDay = DateAdd("d",1,endDate)>
                    AND e.event_date_time < #nextDay#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"category") AND isNumeric(ARGUMENTS.filterStruct.category)>
                    AND e.event_category = #ARGUMENTS.filterStruct.category#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"type") AND isNumeric(ARGUMENTS.filterStruct.type)>
                    AND e.event_type = #ARGUMENTS.filterStruct.type#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"submitted") AND isBoolean(ARGUMENTS.filterStruct.submitted)>
                    <cfset submitted = (ARGUMENTS.filterStruct.submitted) ? 1 : 0>
                    AND e.submitted = #submitted#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"rid") AND isNumeric(ARGUMENTS.filterStruct.rid)>
                    AND e.rid = #ARGUMENTS.filterStruct.rid#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"visible") AND isBoolean(ARGUMENTS.filterStruct.visible)>
                    <cfset visible = (ARGUMENTS.filterStruct.visible) ? 1 : 0>
                    AND e.visible = #visible#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
                    <cfset active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
                    AND c.active = #active#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
                    AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
                </cfif>
            </cfif>
            ORDER BY #orderString#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn chapterEvents>
</cffunction>






<!----------------------------------------------------------------------------------------------------
    * addEvent(eventStruct)
    *
    * The following function inserts new event information into the events table in the chapter
	* reports database. The eventStruct must be formatted as follows:
	*
	* eventStruct = StructNew()
	* eventStruct.cid
	* eventStruct.eventName
	* eventStruct.eventDateTime
	* eventStruct.eventLocationName
	* eventStruct.eventLocationAddress
	* eventStruct.eventCategory
	* eventStruct.eventType
	* eventStruct.attendance
	* eventStruct.volunteers
	* eventStruct.hours
	* eventStruct.visible
	* eventStruct.updatedBy
	*
	* All values for the struct need to be primitive Coldfusion variable types (i.e. dates need to be 
	* coldfusion date objects)
	*
	* The function will return the generated key of the new entry if the insertion is successful. 
	* Otherwise it will return a string containing the error code.
--->
<cffunction name="addEvent" access="public" returntype="any">
	<cfargument name="eventStruct" type="struct" required="yes">
    <!--- Verify the structure is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.eventStruct,"cid")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventName")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventDateTime")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventLocationName")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventLocationAddress")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventCategory")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventType")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"visible")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"updatedBy")>
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addEvent() - Struct Key List = #StructKeyList(ARGUMENTS.eventStruct)#">
        <cfreturn errorCode />
    </cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "attendance")>
		<cfset attendance="0"/>
	<cfelse>
		<cfset attendance="#ARGUMENTS.eventStruct.attendance#"/>
	</cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "hours")>
		<cfset hours="0"/>
	<cfelse>
		<cfset hours="#ARGUMENTS.eventStruct.hours#"/>
	</cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "volunteers")>
		<cfset volunteers="0"/>
	<cfelse>
		<cfset volunteers="#ARGUMENTS.eventStruct.volunteers#"/>
	</cfif>
	
    <!--- Verify the date object is correct --->
    <cfif NOT isDate(ARGUMENTS.eventStruct.eventDateTime)>
    	<cfset errorCode = "INVALID_VARIABLE_TYPE">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: variable must be a coldfusion date object">
        <cfreturn errorCode />
    </cfif>
    <!--- Format the date --->
    <cfset ARGUMENTS.eventStruct.eventDateTime = parseDateTime(dateTimeFormat(ARGUMENTS.eventStruct.eventDateTime,"yyyy-MM-dd HH:nn:ss"))>
    <!--- Insert the event into the table --->
    <cftry>
        <cfset updateDate = dateTimeFormat(Now(), "yyyy-MM-dd HH:nn:ss")>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertEvent">
        	INSERT INTO #VARIABLES.tablePrefix#events
            (cid, event_name, event_date_time, event_location_name, event_location_address,
            event_category, event_type, attendance, volunteers, hours, update_date, updated_by, visible)
            VALUES(
            	'#ARGUMENTS.eventStruct.cid#',
                '#ARGUMENTS.eventStruct.eventName#',
                #ARGUMENTS.eventStruct.eventDateTime#,
                '#ARGUMENTS.eventStruct.eventLocationName#',
                '#ARGUMENTS.eventStruct.eventLocationAddress#',
                #ARGUMENTS.eventStruct.eventCategory#,
                #ARGUMENTS.eventStruct.eventType#,
                #attendance#,
                #volunteers#,
                #hours#,
                '#updateDate#',
                '#ARGUMENTS.eventStruct.updatedBy#',
                #ARGUMENTS.eventStruct.visible#
            )
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfquery datasource="#VARIABLES.datasource#" name="newEvent">
        SELECT * FROM #VARIABLES.tablePrefix#events WHERE update_date = '#updateDate#' AND updated_by = '#ARGUMENTS.eventStruct.updatedBy#' ORDER BY id DESC
    </cfquery> 
    <cfreturn newEvent.id />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateEvent(eventStruct)
    *
    * The following function updates existing event information in the events table in the chapter
	* reports database. The eventStruct must be formatted as follows:
	*
	* eventStruct = StructNew()
	* eventStruct.id
	* eventStruct.eventName
	* eventStruct.eventDateTime
	* eventStruct.eventLocationName
	* eventStruct.eventLocationAddress
	* eventStruct.eventCategory
	* eventStruct.eventType
	* eventStruct.attendance
	* eventStruct.volunteers
	* eventStruct.hours
	* eventStruct.visible
	* eventStruct.updatedBy
	*
	* All values for the struct need to be primitive Coldfusion variable types (i.e. dates need to be 
	* coldfusion date objects)
	*
	* The function will return the empty string if the insertion is successful. Otherwise it will return
	* a string containing the error code.
--->
<cffunction name="updateEvent" access="public" returntype="string">
	<cfargument name="eventStruct" type="struct" required="yes">
    <!--- Verify the structure is formated correctly --->
    <cfif NOT StructKeyExists(ARGUMENTS.eventStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventName")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventDateTime")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventLocationName")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventLocationAddress")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventCategory")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"eventType")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"visible")
		OR NOT StructKeyExists(ARGUMENTS.eventStruct,"updatedBy")>
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateEvent() - Struct Key List = #StructKeyList(ARGUMENTS.eventStruct)#">
        <cfreturn errorCode />
    </cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "attendance")>
		<cfset attendance="0"/>
	<cfelse>
		<cfset attendance="#ARGUMENTS.eventStruct.attendance#"/>
	</cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "hours")>
		<cfset hours="0"/>
	<cfelse>
		<cfset hours="#ARGUMENTS.eventStruct.hours#"/>
	</cfif>
	
	<cfif NOT StructKeyExists(ARGUMENTS.eventStruct, "volunteers")>
		<cfset volunteers="0"/>
	<cfelse>
		<cfset volunteers="#ARGUMENTS.eventStruct.volunteers#"/>
	</cfif>
	
    <!--- Verify the date object is correct --->
    <cfif NOT isDate(ARGUMENTS.eventStruct.eventDateTime)>
    	<cfset errorCode = "INVALID_VARIABLE_TYPE">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: variable must be a coldfusion date object">
        <cfreturn errorCode />
    </cfif>
    <!--- Format the date --->
    <cfset ARGUMENTS.eventStruct.eventDateTime = parseDateTime(DateTimeFormat(ARGUMENTS.eventStruct.eventDateTime,"yyyy-MM-dd HH:nn:ss"))>
    <cfset updateDate = dateTimeFormat(Now(), "yyyy-MM-dd HH:nn:ss")>
    <!--- Update the event in the table --->
    <cftry>

    	<cfquery datasource="#VARIABLES.datasource#" name="updateEvent">
        	UPDATE #VARIABLES.tablePrefix#events
            SET
                event_name = '#ARGUMENTS.eventStruct.eventName#',
                event_date_time = #ARGUMENTS.eventStruct.eventDateTime#,
                event_location_name = '#ARGUMENTS.eventStruct.eventLocationName#',
                event_location_address = '#ARGUMENTS.eventStruct.eventLocationAddress#',
                event_category = #ARGUMENTS.eventStruct.eventCategory#,
                event_type = #ARGUMENTS.eventStruct.eventType#,
                attendance = #attendance#,
                volunteers = #volunteers#,
                hours = #hours#,
                visible = #ARGUMENTS.eventStruct.visible#,
                update_date = '#updateDate#',
                updated_by = '#ARGUMENTS.eventStruct.updatedBy#'
            WHERE id = #ARGUMENTS.eventStruct.id#
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
    * deleteEvent(id)
    *
    * The following function removes the event with the provided id from the database.
	* If successful, the empty string will be returned.
	* Otherwise a string error code will be returned.
--->
<cffunction name="deleteEvent" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Delete the event --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteEvent">
        	DELETE FROM #VARIABLES.tablePrefix#events
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Delete the event's visible information, if it exists --->
        <cfquery datasource="#VARIABLES.datasource#" name="deleteEvent">
        	DELETE FROM #VARIABLES.tablePrefix#events_visible
            WHERE eid = #ARGUMENTS.id#
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
    * getVisibleEventInfo([filterStruct])
	*
	* Returns a query resut set containing a list of visible events according to the constraints in
	* the filterStruct. The filterStruct (if used) must contain one or more of the following members:
	*
	* filterStruct = StructNew()	// create the structure
	* filterStruct.id				// the id of the event entry
	* filterStruct.eid				// the event id of the event
	* filterStruct.published		// whether the event is published or not
	* filterStruct.current			// boolean flag to display only events that haven't expired
	* filterStruct.active			// only look at visible events from an active chapter
	* filterStruct.chapterType      // look at info from the specified chapter type
	*
	* If successful, the function will a query result set. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="getVisibleEventInfo" access="public" returntype="any"> <!--**************** Fixed by Ryan **************************-->
	<cfargument name="filterStruct" type="struct" required="no">
<cfset currentdate = DateFormat(NOW(), 'yyyy/mm/dd')>
<cfset currentDateAsDate = parseDateTime(currentdate)>
    <!--- Get the visible event --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="visibleEvents">
        	SELECT e.*, c.name, c.region
            FROM #VARIABLES.tablePrefix#events_visible e
            INNER JOIN #VARIABLES.tablePrefix#events ev
            	ON ev.id = e.eid
            INNER JOIN #VARIABLES.tablePrefix#chapters c
            	ON c.cid = ev.cid
            WHERE e.id <> 0
    <cfif isDefined('filterStruct')>
    	<cfif StructKeyExists(ARGUMENTS.filterStruct,"id") AND isNumeric(ARGUMENTS.filterStruct.id)>
        	 AND e.id = #ARGUMENTS.filterStruct.id#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"eid") AND isNumeric(ARGUMENTS.filterStruct.eid)>
        	AND e.eid = #ARGUMENTS.filterStruct.eid#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"published") AND isBoolean(ARGUMENTS.filterStruct.published)>
        	<cfset var published = (ARGUMENTS.filterStruct.published) ? 1 : 0>
        	 AND e.published = #published#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"current") AND ARGUMENTS.filterStruct.current>
        	 AND TO_DATE(e.expire_date, 'YYYY/MM/DD HH24:MI:SS') >= #currentDateAsDate#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
        	<cfset var active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
        	 AND c.active = #active#
        </cfif>
        <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
        	 AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
        </cfif>
    </cfif>


        </cfquery>
        <cfcatch>
        	<cfset errorCode = "#cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn visibleEvents />
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * addVisibleEventInfo(visibleEventStruct)
	*
	* Inserts new visible event information into the database. The provided visibleEventStruct argument
	* must be formated as follows:
	*
	* visibleEventStruct = StructNew()		// create the structure
	* visibleEventStruct.eid				// the event id associated with the info
	* visibleEventStruct.title				// the title to display when the info is published
	* visibleEventStruct.needTicket			// a boolean value - whether or not the event requires a ticket
	* visibleEventStruct.ticketLink			// a valid URL link to the ticket site
	* visibleEventStruct.needRegister		// a boolean value - whether or not the event requires registration
	* visibleEventStruct.registerLink		// a valid URL link to the registration site
	* visibleEventStruct.description		// a brief description of the event
	* visibleEventStruct.expireDate			// the date the notification should be taken off the site
	*
	* If successful, the function will return the generated key of the new entry. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="addVisibleEventInfo" access="public" returntype="any">
	<cfargument name="visibleEventStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"eid")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"needTicket")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"ticketLink")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"needRegister")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"registerLink")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"expireDate")>
        
		<cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: addVisibleEventInfo() - Struct Key List = #StructKeyList(ARGUMENTS.visibleEventStruct)#">
        <cfreturn errorCode />
    
    </cfif>
    <!--- Verify the date object is correct --->
    <cfif NOT isDate(ARGUMENTS.visibleEventStruct.expireDate)>
    	<cfset errorCode = "INVALID_VARIABLE_TYPE">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: variable must be a coldfusion date object">
        <cfreturn errorCode />
    </cfif>
    <!--- Format the date --->
    <cfset ARGUMENTS.visibleEventStruct.expireDate = DateTimeFormat(ARGUMENTS.visibleEventStruct.expireDate,"YYYY-MM-dd HH:nn:ss")>
    <cfset currentDate = DateTimeFormat(Now(),"YYYY-MM-dd HH:nn:ss")>
    <!--- Insert the info into the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertVisibleEvent">
        	INSERT INTO #VARIABLES.tablePrefix#events_visible
            (eid, display_title, need_ticket, ticket_link, need_register, register_link, create_date, expire_date, description)
            VALUES(
            	#ARGUMENTS.visibleEventStruct.eid#,
                '#ARGUMENTS.visibleEventStruct.title#',
                #ARGUMENTS.visibleEventStruct.needTicket#,
                '#ARGUMENTS.visibleEventStruct.ticketLink#',
                #ARGUMENTS.visibleEventStruct.needRegister#,
                '#ARGUMENTS.visibleEventStruct.registerLink#',
                '#currentDate#',
                '#ARGUMENTS.visibleEventStruct.expireDate#',
                '#ARGUMENTS.visibleEventStruct.description#'
            )
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfquery datasource="#VARIABLES.datasource#" name="newVisibleEvent">
        SELECT id FROM #VARIABLES.tablePrefix#events_visible WHERE eid = #ARGUMENTS.visibleEventStruct.eid# AND display_title = '#ARGUMENTS.visibleEventStruct.title#' ORDER BY id DESC
    </cfquery>
    <cfreturn newVisibleEvent.id />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateVisibleEventInfo(visibleEventStruct)
	*
	* Updates existing visible event information into the database. The provided visibleEventStruct argument
	* must be formated as follows:
	*
	* visibleEventStruct = StructNew()		// create the structure
	* visibleEventStruct.eid				// the event id of the entry
	* visibleEventStruct.title				// the title to display when the info is published
	* visibleEventStruct.needTicket			// a boolean value - whether or not the event requires a ticket
	* visibleEventStruct.ticketLink			// a valid URL link to the ticket site
	* visibleEventStruct.needRegister		// a boolean value - whether or not the event requires registration
	* visibleEventStruct.registerLink		// a valid URL link to the registration site
	* visibleEventStruct.description		// a brief description of the event
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="updateVisibleEventInfo" access="public" returntype="string">
	<cfargument name="visibleEventStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"eid")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"title")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"needTicket")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"ticketLink")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"needRegister")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"registerLink")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"description")
		OR NOT StructKeyExists(ARGUMENTS.visibleEventStruct,"expireDate")>
        
		<cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateVisibleEventInfo() - Struct Key List = #StructKeyList(ARGUMENTS.visibleEventStruct)#">
        <cfreturn errorCode />
    
    </cfif>
    <!--- Verify the date object is correct --->
    <cfif NOT isDate(ARGUMENTS.visibleEventStruct.expireDate)>
    	<cfset errorCode = "INVALID_VARIABLE_TYPE">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: variable must be a coldfusion date object">
        <cfreturn errorCode />
    </cfif>
    <!--- Format the date --->
    <cfset ARGUMENTS.visibleEventStruct.expireDate = DateTimeFormat(ARGUMENTS.visibleEventStruct.expireDate,"YYYY-MM-dd HH:nn:ss")>
    <!--- Update the info in the database --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="updateVisibleEvent">
        	UPDATE #VARIABLES.tablePrefix#events_visible
            SET
                display_title= '#ARGUMENTS.visibleEventStruct.title#',
                need_ticket = #ARGUMENTS.visibleEventStruct.needTicket#,
                ticket_link = '#ARGUMENTS.visibleEventStruct.ticketLink#',
                need_register = #ARGUMENTS.visibleEventStruct.needRegister#,
                register_link = '#ARGUMENTS.visibleEventStruct.registerLink#',
                description = '#ARGUMENTS.visibleEventStruct.description#',
                expire_date = '#ARGUMENTS.visibleEventStruct.expireDate#'
            WHERE eid = #ARGUMENTS.visibleEventStruct.eid#
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
    * publishEvent(id)
	*
	* Allows the event entry in the visible table with the given id to be published to alumni.byu.edu.
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="publishEvent" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Update the publish Flag --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="publishEvent">
        	UPDATE #VARIABLES.tablePrefix#events_visible
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
    * unpublishEvent(id)
	*
	* Forbids the event entry in the visible table with the given id to be published to alumni.byu.edu.
	*
	* If successful, the function will return the empty string. Otherwise it
	* will return a string error code describing the reason for failure.
--->
<cffunction name="unpublishEvent" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Update the publish Flag --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="unpublishEvent">
        	UPDATE #VARIABLES.tablePrefix#events_visible
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
    * getEventYearRange([cid])
    *
    * The following function returns a query result set containing two variables: minYear and maxYear. 
	* They represent the range of years covered by all events entered by chapters.
    * Has an optional argument 'cid' that, if provided, will limit the range to include only events created
    * by the specified chapter
--->
<cffunction name="getEventYearRange" access="public" returntype="any">
    <cfargument name="cid" type="string" required="no"/>
    <!--- Get the year range --->
    <cftry>
         <cfquery datasource="#VARIABLES.datasource#" name="yearRange">
            SELECT MIN(EXTRACT(YEAR FROM event_date_time)) AS minYear, MAX(EXTRACT(YEAR FROM event_date_time)) AS maxYear 
            FROM #VARIABLES.tablePrefix#events 
            <cfif (isDefined('ARGUMENTS.cid') AND TRIM(ARGUMENTS.cid) NEQ '')>
                WHERE cid = '#ARGUMENTS.cid#'
            </cfif>
        </cfquery>   
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry> 
    <cfreturn yearRange>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getEventStats([filterStruct])
    *
    * The following function returns a query result set containing statistics about events.
	* The optional 'filterStruct' argument, if provided, will filter through the results and provide
	* data according to the given constraints. If used, it should have one or more of the following
	* members:
	*
	* filterStruct = StructNew()		// create the structure
	* filterStruct.year					// the calendar year the events should fall in
	* filterStruct.cid					// the id of the chapter the event belongs to
	* filterStruct.region				// the region the chapter belongs to
	* filterStruct.startDate			// a start cutoff for the events
	* filterStruct.endDate				// the end of the cutoff for events
	* filterStruct.submitted			// a boolean for only retrieving submitted events
	* filterStruct.rid					// the report id of the report the event belongs to
	* filterStruct.visible				// a boolean for publically visible events (alumni.byu.edu)
	* filterStruct.active				// a boolean to toggle active/inactive chapter events
	* filterStruct.chapterType          // a string value of the chapter type ('regional','professional')
	*
    * If successful, the function will return a query result set with data about event attendance,
	* volunteers, and hours.
	* Otherwise the function will return a string error code.
--->
<cffunction name="getEventStats" access="public" returntype="any">
    <cfargument name="filterStruct" type="struct" required="no">
    <!--- Build the where clause --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="eventStats">
            SELECT COUNT(id) AS total_events, 
            	   SUM(attendance) AS total_attendance,
                   (SUM(attendance)/COUNT(id)) AS average_attendance,
                   SUM(volunteers) AS total_volunteers,
                   (SUM(volunteers)/COUNT(id)) AS average_volunteers,
                   SUM(hours) AS total_hours,
                   (SUM(hours)/COUNT(id)) AS average_hours 
            FROM #VARIABLES.tablePrefix#events e
            INNER JOIN #VARIABLES.tablePrefix#chapters c
            	ON c.cid = e.cid
            WHERE id <> 0
            <cfif isDefined('ARGUMENTS.filterStruct')>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"year") AND isNumeric(ARGUMENTS.filterStruct.year)>
                    <cfset startYear = DateFormat(CreateDate(ARGUMENTS.filterStruct.year,1,1),'yyyy-mm-dd')>
                    <cfset endYear = DateFormat(CreateDate(ARGUMENTS.filterStruct.year,12,31),'yyyy-mm-dd')>
                    <cfset nextDay = DateAdd("d",1,endYear)>
                    AND e.event_date_time >= #parseDateTime(startYear)# AND e.event_date_time < #parseDateTime(nextDay)#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"cid") AND TRIM(ARGUMENTS.filterStruct.cid) NEQ ''>
                    AND e.cid = '#ARGUMENTS.filterStruct.cid#'
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"region") AND isNumeric(ARGUMENTS.filterStruct.region)>
                    AND c.region = '#ARGUMENTS.filterStruct.region#'
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"startDate") AND isDate(ARGUMENTS.filterStruct.startDate)>
                    <cfset startDate = DateFormat(ARGUMENTS.filterStruct.startDate,"yyyy-mm-dd")>
                    AND e.event_date_time >= #parseDateTime(startDate)#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"endDate") AND isDate(ARGUMENTS.filterStruct.endDate)>
                    <cfset endDate = DateFormat(ARGUMENTS.filterStruct.endDate,"yyyy-mm-dd")>
                    <cfset nextDay = DateAdd("d",1,endDate)>
                    AND e.event_date_time < #nextDay#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"submitted") AND isBoolean(ARGUMENTS.filterStruct.submitted)>
                    <cfset submitted = (ARGUMENTS.filterStruct.submitted) ? 1 : 0>
                    AND e.submitted = #submitted#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"rid") AND isNumeric(ARGUMENTS.filterStruct.rid)>
                    AND e.rid = #ARGUMENTS.filterStruct.rid#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"visible") AND isBoolean(ARGUMENTS.filterStruct.visible)>
                    <cfset visible = (ARGUMENTS.filterStruct.visible) ? 1 : 0>
                    AND e.visible = #visible#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"active") AND isBoolean(ARGUMENTS.filterStruct.active)>
                    <cfset active = (ARGUMENTS.filterStruct.active) ? 1 : 0>
                    AND c.active = #active#
                </cfif>
                <cfif StructKeyExists(ARGUMENTS.filterStruct,"chapterType") AND TRIM(ARGUMENTS.filterStruct.chapterType) NEQ ''>
                    AND c.type = '#ARGUMENTS.filterStruct.chapterType#'
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
    <cfreturn eventStats>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getEventCategoriesList()
    *
    * The following function returns a query result set containing the available event categories
--->
<cffunction name="getEventCategoriesList" access="public" returntype="query">
	<cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="categories">
            SELECT *
            FROM #VARIABLES.tablePrefix#categories
            WHERE active = 1
            	AND id <> 0
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
    * getEventCategory(categoryId)
    *
    * The following function returns the string name of the category with the given id
--->
<cffunction name="getEventCategory" access="public" returntype="string">
	<cfargument name="categoryId" type="numeric" required="yes"/>
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="category">
            SELECT *
            FROM #VARIABLES.tablePrefix#categories
            WHERE id = #ARGUMENTS.categoryId#
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn category.category_name>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getEventTypesList([categoryID])
    *
    * The following function returns a query result set containing the available event types.
    * If the 'categoryID' variable is specified, it will return only the types associated with the categoryID
--->
<cffunction name="getEventTypesList" access="public" returntype="query">
    <cfargument name="categoryID" type="numeric" required="no">
    <!--- Make sure the category isn't 'other'. If it is, return the table holding other type information --->
    <cfif isDefined('ARGUMENTS.categoryId') AND ARGUMENTS.categoryId EQ 6>
    	<cftry>
            <cfquery datasource="#VARIABLES.datasource#" name="types">
                SELECT *
                FROM #VARIABLES.tablePrefix#types_other
            </cfquery>
            <cfcatch>
                <cfset errorCode = "DATABASE_EXECUTION_ERROR">
                <cflog file="chapter-reports" type="error" 
                    text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
                <cfreturn errorCode />
            </cfcatch>
        </cftry>
        <cfreturn types>
    </cfif>
    <cfset var whereString = 'WHERE active = 1 AND id <> 0'>
    <cfset whereString = (isDefined('ARGUMENTS.categoryID') AND TRIM(ARGUMENTS.categoryID) NEQ '') ? 
									whereString & ' AND category_id = #ARGUMENTS.categoryID#' : whereString>
    <!--- Run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="types">
            SELECT *
            FROM #VARIABLES.tablePrefix#types
            #whereString#
        </cfquery>
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn types>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * getEventType(typeId)
    *
    * The following function returns the string name of the type with the given type id
--->
<cffunction name="getEventType" access="public" returntype="string">
    <cfargument name="typeId" type="numeric" required="yes">
    <!--- Run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="type">
            SELECT *
            FROM #VARIABLES.tablePrefix#types
            WHERE id = #ARGUMENTS.typeId#
        </cfquery>
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn type.type_name>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * getEventTypeOther([typeId, typeValue])
    *
    * The following function returns the result set of the type with the given type id or type value name for types
	* in the types_other table (category id of 6)
--->
<cffunction name="getEventTypeOther" access="public" returntype="any">
    <cfargument name="typeId" type="numeric" required="no">
    <cfargument name="typeValue" type="string" required="no">
    <!--- Run the query --->
    <cftry>
        <cfquery datasource="#VARIABLES.datasource#" name="otherType">
            SELECT *
            FROM #VARIABLES.tablePrefix#types_other
            WHERE id IS NOT NULL
            <cfif isDefined('ARGUMENTS.typeId')>
                AND id = #ARGUMENTS.typeId#
            </cfif>
            <cfif isDefined('ARGUMENTS.typeValue')>
                AND type_value = '#ARGUMENTS.typeValue#'
            </cfif>
        </cfquery>
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn otherType>
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * addEventCategory(categoryName)
    *
    * Creates a new category for chapter events and activities.
	* This function returns the generated key of the new entry if successful, otherwise an error code
--->
<cffunction name="addEventCategory" access="public" returntype="any">
	<cfargument name="categoryName" type="string" required="yes">
    <!--- Insert the new category --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertCategory">
            INSERT INTO #VARIABLES.tablePrefix#categories
            (category_name)
            VALUES(
                '#ARGUMENTS.categoryName#'
            )
        </cfquery>
        <cfquery datasource="#VARIABLES.datasource#" name="newCategory">
            SELECT DISTINCT id
            FROM #VARIABLES.tablePrefix#categories
            WHERE category_name = '#ARGUMENTS.categoryName#'
            ORDER BY id DESC
        </cfquery>
        <cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn newCategory.id />
</cffunction>


<!----------------------------------------------------------------------------------------------------
    * updateEventCategory(categoryStruct)
    *
    * Updates an existing entry in the category table in the database. The categoryStruct must be
	* formated as follows:
	*
	* categoryStruct = StructNew()	// create the structure
	* categoryStruct.id				// the id of the entry
	* categoryStruct.name			// the new name of the category
	* 
	* This function returns the empty string if successful, otherwise an error code
--->
<cffunction name="updateEventCategory" access="public" returntype="string">
	<cfargument name="categoryStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.categoryStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.categoryStruct,"name")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateEventCategory() - Struct Key List = #StructKeyList(ARGUMENTS.categoryStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Update the existing category --->
    <cftry>
    	<cfquery datasource="#VARIABLES.datasource#" name="insertCategory" result="newCategory">
            UPDATE #VARIABLES.tablePrefix#categories
            SET
                category_name = '#ARGUMENTS.categoryStruct.name#'
            WHERE id = #ARGUMENTS.categoryStruct.id#
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
    * deleteEventCategory(id)
    *
    * The following function sets the active state of the event category with the given
    * id to 0. This is done to presernve the original category name for events in the past.
    * All event types under this category will also have their active states set to 0.
    *
	* If successful, the empty string will be returned.
	* Otherwise a string error code will be returned.
--->
<cffunction name="deleteEventCategory" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- If the event category is 6, return. We don't want to delete the 'other' category --->
    <cfif ARGUMENTS.id EQ 6>
    	<cfset errorCode = "ILLEGAL_DELETE">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: Attempted to delte the 'other' category from the event list">
        <cfreturn errorCode />
    </cfif>
    <!--- Delete the event --->
    <cftry>
    	<!--- First deactivate the category --->
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteEventCategory">
        	UPDATE #VARIABLES.tablePrefix#categories
            SET active = 0
            WHERE id = #ARGUMENTS.id#
        </cfquery>
        <!--- Now set all of the types that were children of this category to 0 --->
        <cfquery datasource="#VARIABLES.datasource#" name="setTypes">
        	UPDATE #VARIABLES.tablePrefix#types
            SET
            	active = 0
            WHERE category_id = #ARGUMENTS.id#
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
    * addEventType(typeName, categoryId)
    *
    * Creates a new type under the provided category. Providing a category ID of 6 will put the
	* type in the types_other table.
	* This function returns the generated key of the new entry if successful, otherwise an error code
--->
<cffunction name="addEventType" access="public" returntype="any">
    <cfargument name="typeName" type="string" required="yes">
    <cfargument name="categoryId" type="numeric" required="yes">
    <!--- Run the query --->
    <cftry>
    	<cfif ARGUMENTS.categoryId EQ 6>
        	<cfquery datasource="#VARIABLES.datasource#" name="insertType">
                INSERT INTO #VARIABLES.tablePrefix#types_other
                (type_value)
                VALUES(
                	'#ARGUMENTS.typeName#'
                )
            </cfquery>
            <cfquery datasource="#VARIABLES.datasource#" name="newType">
                SELECT * FROM #VARIABLES.tablePrefix#types_other WHERE type_value = '#ARGUMENTS.typeName#' ORDER BY id DESC
            </cfquery>
            <cfreturn newType.id>
        <cfelse>
        	<cfquery datasource="#VARIABLES.datasource#" name="insertType" result="newType">
                INSERT INTO #VARIABLES.tablePrefix#types
                (type_name,category_id)
                VALUES(
                	'#ARGUMENTS.typeName#',
                    #ARGUMENTS.categoryId#
                )
            </cfquery>
            <cfquery datasource="#VARIABLES.datasource#" name="newType">
                SELECT * FROM #VARIABLES.tablePrefix#types WHERE type_name = '#ARGUMENTS.typeName#' AND category_id = #ARGUMENTS.categoryId# ORDER BY id DESC
            </cfquery>
            <cfreturn newType.id>
        </cfif>
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * updateEventType(typeStruct)
    *
    * Updates an existing entry in one of two tables in the database: the table with predefined types
	* or the table of user-defined types (category id of 6). The typeStruct argument must be formatted
	* as follows:
	*
	* typeStruct = StructNew()		// create the structure
	* typeStruct.id					// the id of the entry
	* typeStruct.categoryId			// the category the type falls under
	* typeStruct.name				// the new name of the type
	*
	* This function returns the empty string if successful, otherwise an error code
--->
<cffunction name="updateEventType" access="public" returntype="string">
    <cfargument name="typeStruct" type="struct" required="yes">
    <!--- Verify the struct --->
    <cfif NOT StructKeyExists(ARGUMENTS.typeStruct,"id")
		OR NOT StructKeyExists(ARGUMENTS.typeStruct,"categoryId")
		OR NOT StructKeyExists(ARGUMENTS.typeStruct,"name")>
        
        <cfset errorCode = "INVALID_STRUCT_FORMAT">
        <cflog file="chapter-reports" type="error" 
            text="#errorCode#: updateEventType() - Struct Key List = #StructKeyList(ARGUMENTS.typeStruct)#">
        <cfreturn errorCode />
        
    </cfif>
    <!--- Run the query update --->
    <cftry>
    	<cfif ARGUMENTS.typeStruct.categoryId EQ 6>
        	<cfquery datasource="#VARIABLES.datasource#" name="updateType">
                UPDATE #VARIABLES.tablePrefix#types_other
                SET
                	type_value = '#ARGUMENTS.typeStruct.name#'
                WHERE id = #ARGUMENTS.typeStruct.id#
            </cfquery>
        <cfelse>
        	<cfquery datasource="#VARIABLES.datasource#" name="updateType">
                UPDATE #VARIABLES.tablePrefix#types
                SET
                	type_name = '#ARGUMENTS.typeStruct.name#',
                    category_id = #ARGUMENTS.typeStruct.categoryId#
                WHERE id = #ARGUMENTS.typeStruct.id#
            </cfquery>
        </cfif>
    	<cfcatch>
        	<cfset errorCode = "DATABASE_EXECUTION_ERROR">
        	<cflog file="chapter-reports" type="error" 
            	text="#errorCode#: #cfcatch.Message# -:- #cfcatch.queryError# -:- QUERY: #cfcatch.Sql#">
            <cfreturn errorCode />
        </cfcatch>
    </cftry>
    <cfreturn ''>
</cffunction>



<!----------------------------------------------------------------------------------------------------
    * deleteEventType(id)
    *
    * The following function sets the active state of the event type with the given id to 0.
    * This is done to preserve the name and provide a record for events that have already been
    * recorded.
	* This will not delete user-defined event types (part of the 'other' category).
	*
	* If successful, the empty string will be returned.
	* Otherwise a string error code will be returned.
--->
<cffunction name="deleteEventType" access="public" returntype="string">
	<cfargument name="id" type="numeric" required="yes">
    <!--- Delete the event --->
    <cftry>
		<!--- First delete the event type --->
    	<cfquery datasource="#VARIABLES.datasource#" name="deleteEventType">
        	UPDATE #VARIABLES.tablePrefix#types
            SET active = 0
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

</cfcomponent>