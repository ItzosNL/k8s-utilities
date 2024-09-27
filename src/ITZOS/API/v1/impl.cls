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
    do ##class(ALTRECHTESB.DB.ApiAccessLog).LogAndCheckAccessAttempt("GET", "/versions")
    
	try
	{
        set components = []
		set response = {
			"code": 200,
			"components": (components)
		}

		#; set result = ##class(%SQL.Statement).%ExecDirect(, "Select parent, _Default from %Dictionary.ParameterDefinition where parent like '%ALTRECHT%' and Name = 'Version' and sequencenumber < 3")

		#; if result.%SQLCODE < 0
		#; {
		#; 	throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
		#; }

		#; while result.%Next()
		#; {
		#; 	do response.versions.%Set(result.parent, result."_Default")
		#; }

		return ..ReturnJSON(response)
	}
	catch ex
	{
	    return ..ReturnJSON(..CreateErrorResponseForStatus(ex.AsStatus()), 500)
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
