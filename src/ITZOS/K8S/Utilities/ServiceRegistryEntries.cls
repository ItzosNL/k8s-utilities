/// Create Service Registry entries based on after-install.json
Class ITZOS.K8S.Utilities.ServiceRegistryEntries
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "serviceregistries";

/// Test
ClassMethod Test()
{
	do ..Load([
        {
          "name": "mock-fhirserver-stu3",
          "host": "tool-mock-fhirserver-stu3.hex-tools-o",
          "url" : "/mock/fhir/1",
          "port": 80
        }
      ])
}

/// Load all service registry entries
ClassMethod Load(serviceregistries As %DynamicArray)
{
	#dim iterator As %Iterator.Object = serviceregistries.%GetIterator()
	#dim entry As %DynamicObject

	while iterator.%GetNext(.key, .entry)
	{
		do ..CreateOrUpdateEntry(entry.name, entry.host, entry.%Get("port", ""), entry.url, entry.sslconfig, entry.credentials, entry.%Get("timeout", 60))
	}
}

/// Method used to create an entry during the after-install
ClassMethod CreateOrUpdateEntry(name As %String, host As %String, port As %Integer = 443, url As %String, sslconfig As %String, credentials As %String, timeout As %Integer = 60)
{
	write "ServiceRegistry entry '",name,"': "

	#dim service as HS.Registry.Service.HTTP
    set id = ##class(HS.Registry.Service.HTTP).IDForNameType(name, "HTTP")
    
    if id '= ""
	{
        set service = ##class(HS.Registry.Service.HTTP).%OpenId(id)
		set action = "update"
	}
	else
	{
        set service = ##class(HS.Registry.Service.HTTP).%New()
		set service.Name = name
		set service.Type = "HTTP"
		set action = "create"
    }


	set service.Timeout = timeout
    set service.Host = host
    set service.Port = port
    set service.URL = url
    set service.SSLConfig = sslconfig
    set service.HTTPCredentialsConfig = credentials

    set sc = service.%Save()

	if $$$ISERR(sc)
	{
		write action," failed: ",$System.Status.GetErrorText(sc),!
	}
	else
	{
		write "Successfully ",action,"d",!
	}
}

}
