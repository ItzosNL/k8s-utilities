/// Create Service Registry entries based on after-install.json
Class ITZOS.K8S.Utilities.ServiceRegistryEntries
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "serviceregistries";

/// Load all service registry entries
ClassMethod Load(serviceregistries As %DynamicObject)
{
	#dim iterator As %Iterator.Object = serviceregistries.%GetIterator()
	#dim entry As %DynamicObject

	while iterator.%GetNext(.key, .entry)
	{
		do ..CreateOrUpdateEntry(entry.name, entry.host, entry.endpoint, entry.sslconfig)
	}
}

/// Method used to create an entry during the after-install
ClassMethod CreateOrUpdateEntry(name As %String, host As %String, endpoint As %String, sslconfig As %String)
{
	write "ServiceRegistry entry '",name,"': "

	#dim service as HS.Registry.Service.HTTP
    set id = ##class(HS.Registry.Service.Abstract).IDForNameType(name, "HTTP")
    
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

    set service.Host = host
    set service.URL = endpoint
    set service.SSLConfig = sslconfig

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
