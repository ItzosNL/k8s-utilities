/// Generic KPN/Itzos Beheer API<br/>
/// Business logic class defined by OpenAPI in ITZOS.API.v1.spec<br/>
/// Updated Sep 27, 2024 09:40:01
Class ITZOS.API.v1.impl Extends ITZOS.API.RestHelper [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

/// Get Swagger spec of this API
ClassMethod OpenAPI() As %DynamicObject
{
    #; do ##class(ITZOS.API.ApiAccessLog).LogAndCheckAccessAttempt("GET", "/swagger")

	set specification = {}.%FromJSON(##class(%Dictionary.XDataDefinition).%OpenId(..%PackageName()_".spec||OpenAPI").Data)
	
	; Dynamically place host in response
	#dim %request As %CSP.Request
	set specification.host = %request.GetCgiEnv("HTTP_HOST")
	set specification.info.version = $PARAMETER($PIECE($CLASSNAME(), ".", 1, *-1) _ ".spec", "Version")

	; If called without https, change the scheme
	if '%request.Secure
    {
        Set specification.schemes = ["http"]
    }
	
	return specification
}

/// Ping service
ClassMethod Ping() As %Stream.Object
{
    #; do ##class(ITZOS.API.ApiAccessLog).LogAndCheckAccessAttempt("GET", "/ping")

    set %response.Status = ..#HTTP200OK
    set %response.ContentType = ..#CONTENTTYPETEXT
    return "pong"
}

/// Status van de interoperability productie<br/>
/// The method arguments hold values for:<br/>
///     namespace, Namespace to be queried<br/>
ClassMethod GetInteropStatus(namespace As %String) As %DynamicObject
{
	if $GET(namespace) '= ""
	{
		new $NAMESPACE
		set $NAMESPACE = namespace
	}
	else
	{
		set namespace = $NAMESPACE
	}

    do ##class(ALTRECHTESB.DB.ApiAccessLog).LogAndCheckAccessAttempt("GET", "/versions")
    
	try
	{
		set sc = ##class(Ens.Director).GetProductionStatus(.productionName, .state, , 1)
		set response = {
			"code": 200,
			"namespace": (namespace),
			"production": (productionName),
			"status": (##class(Ens.Config.Production).ProductionStateToText(state, 0))
		}

		set started = $GET(^Ens.Configuration("csp", "Activity", productionName, "started"))

		if (started '= "")
		{
			set response.startedAt = $REPLACE(started, " ", "T")
		}

		set stopped = $GET(^Ens.Configuration("csp", "Activity", productionName, "stopped"))

		if (stopped '= "")
		{
			set response.stoppedAt = $REPLACE(stopped, " ", "T")
		}

        #dim components as %DynamicArray = []
		set response.components = components

		// Types:
		// Empty: Retrieve all items 
		// 1: Business Service
		// 2: Business Process
		// 3: Business Operation
		set tType = ""
		set primaryOnly = 0
		set tRS = ##class(%ResultSet).%New("Ens.Config.Production:EnumerateConfigItems")
		set tStatus = tRS.%Execute(productionName, tType, primaryOnly)

		while tRS.%Next(.tStatus)
		{
			#dim item as %DynamicObject = {
				"businessType": ($CASE(tRS.BusinessType, 1: "service", 2: "process", 3: "operation", : "unexpected value '" _ tRS.BusinessType _ "'")),
				"configName" : (tRS.ConfigName)
			}

			// Additional information available:
			#; CommentOrClassName,
			#; ClassName
			#; RequestClasses
			#; ResponseClasses
			#; ItemId:%Integer
			#; SeqNum
			#; BusPartner
			#; Categories
			#; AlertGroups

			if 'tRS.enabled
			{
				// Gray: Disabled
				set item.status = "disabled"
				set item.statuscolor = "gray"
			}
			elseif '..JobExists(tRS.ConfigName, .error)
			{
				// Light green: Not running but enabled
				set item.status = "not-running-but-enabled"
				set item.statuscolor = "lightgreen"
			}
			elseif (error '= "")
			{
				set item.status = "enabled-with-error"
				set item.error = error
				set item.color = "red"
			}
			else // enabled and running, now check the last messageheader
			{
				do ..GetComponentStatus(tRS.ConfigName, item)
			}

			do components.%Push(item)
		}
		
		return ..ReturnJSON(response)
	}
	catch ex
	{
	    return ..ReturnJSON(..CreateErrorResponseForStatus(ex.AsStatus()), 500)
	}
}

/// Get component status based on 
ClassMethod GetComponentStatus(configname As %String, item As %DynamicObject)
{
	// SELECT top 1 Status * FROM Ens.MessageHeader where TargetQueueName = ? order by id desc

	// Red: Error: Last error to the components queue is "Error"

	// Purple: Retrying: ???

	// Green: Running: Status of last message to the components queue is "Completed"

	// Yellow: Inactive: ???
	set item.status = "enabled"
	set item.color = "green (but logic is not yet complete)"
}

/// List jobs
ClassMethod JobExists(configname As %String, Output error As %String) As %Boolean
{
	set tRS = ##class(%ResultSet).%New("Ens.Job:Enumerate")
	set tStatus = tRS.%Execute()

	while tRS.%Next(.tStatus)
	{
		if tRS.ConfigName = configname
		{
			if tRS.Detail '= configname
			{
				set error = tRS.Detail
			}
			else
			{
				set error = ""
			}
			return 1
		}
	}

	return 0
}

/// List jobs
ClassMethod ListJobs()
{
	set tRS = ##class(%ResultSet).%New("Ens.Job:Enumerate")
	set tStatus = tRS.%Execute()

	while tRS.%Next(.tStatus)
	{
		w tRS.Job,", ",tRS.ConfigName,!
	}
}

/// Create response for unexpected status
ClassMethod CreateErrorResponseForStatus(sc As %Status, message As %String = "") As %DynamicObject
{
    set error = $System.Status.GetErrorText(sc)

    if message '= ""
    {
        set error = message _ ": " _ error
    }

    $$$LOGERROR(error)

    if '..#ExposeServerExceptions
    {
        set error = "Something unexpected happened"
    }

    return ..ReturnError(error, 500)
}

}
