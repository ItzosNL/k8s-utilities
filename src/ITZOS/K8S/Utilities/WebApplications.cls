Include %occInclude

/// Handle creation of Web Applications
Class ITZOS.K8S.Utilities.WebApplications
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "webapplications";

/// Test
ClassMethod Test()
{
	do ..Load([ 
        {
          "url": "/fhir/stu3",
          "dispatchClass": "HS.FHIR.vSTU3.REST.Handler",
          "role": "%DB_MMRES",
          "description": "InterSystems FHIR endpoint",
          "fhirCSPConfig": {
              "serviceConfigName": "HS.FHIR.Service.STU3"
           }
        },
        {
          "url": "/medmij/fhir",
          "dispatchClass": "HS.FHIR.vSTU3.REST.Handler",
          "role": "%DB_MMRES",
          "description": "Internal FHIR endpoint for $is-allowed calls",
          "fhirCSPConfig": {
              "serviceConfigName": "MedMij.FHIR"
          }
        }
      ])
}

/// Load all webapplications
ClassMethod Load(webapplications As %DynamicArray)
{
	#dim iterator As %Iterator.Object = webapplications.%GetIterator()
	#dim webapp As %DynamicObject

	while iterator.%GetNext(.key, .webapp)
	{
		do ..Create(webapp.url, webapp.%Get("namespace", $NAMESPACE), webapp.dispatchClass, webapp.role, webapp.description)

		if $ISOBJECT(webapp.fhirCSPConfig) // Also add FHIRCSPConfig
		{
			do ..CreateFHIRCSPConfig(webapp.url, webapp.fhirCSPConfig.serviceConfigName)
		}
	}
}

/// Create web application
ClassMethod Create(url As %String, namespace As %String = {$NAMESPACE}, dispatchClass As %String, role = {$$$AllRoleName}, description As %String = "") As %Status
{
	#dim sc As %Status = $$$OK

	try
	{
		New $namespace
		set $namespace = "%SYS"

		set properties("AutheEnabled") = $$$AutheUnauthenticated
		set properties("NameSpace") = namespace
		set properties("IsNameSpaceDefault") = $$$NO
		set properties("DispatchClass") = dispatchClass
		set properties("MatchRoles") = ":" _ role
		set properties("Description") = description

		if ('##class(Security.Applications).Exists(url))
		{
			write "Creating WebApplication with url='",url,"' and dispatchClass='",dispatchClass,"'"

			set sc = ##class(Security.Applications).Create(url, .properties)
		}
		else
		{
			write "Updating WebApplication with url='",url,"' and dispatchClass='",dispatchClass,"'"

			set sc = ##class(Security.Applications).Modify(url, .properties)
		}
	}
	catch ex
	{
		set sc = ex.AsStatus()
	}

	if $$$ISERR(sc)
	{
		write " failed: ",$System.Status.GetErrorText(sc)
	}

	write !

	return sc
}

/// Creates a "classical" FHIR CSP configuration.
/// This class is deprecated but still used in dva211
/// Currently hardcoded for version STU3.
ClassMethod CreateFHIRCSPConfig(url As %String, serviceConfigName As %String) As %Status
{
	#dim config As HS.Registry.FHIRCSPConfig

	if ##class(HS.Registry.FHIRCSPConfig).URLIndexExists(url)
	{
		set config = ##class(HS.Registry.FHIRCSPConfig).URLIndexOpen(url)
		set action = "updating"
	}
	else
	{
		set config = ##class(HS.Registry.FHIRCSPConfig).%New()
		set config.URL = url
		set config.FHIRVersion = "STU3"
		set config.ServiceClassName = "HS.FHIR.Service"
		set config.ConformanceId = "InterSystemsFHIR"
		set action = "creating"
	}

	write action," FHIRCSPConfig: ",!

	set config.ServiceConfigName = serviceConfigName
	
	set sc = config.%Save()

	if $$$ISERR(sc)
	{
		write "Failed " _ action _ " FHIRCSPConfig: ",$SYSTEM.Status.GetErrorText(sc),!
	}
	
	return sc
}

}
