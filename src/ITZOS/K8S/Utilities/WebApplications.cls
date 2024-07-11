Include %occInclude

/// Handle creation of Web Applications
Class ITZOS.K8S.Utilities.WebApplications
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "webapplications";

/// Load all webapplications
ClassMethod Load(webapplications As %DynamicObject)
{
	#dim iterator As %Iterator.Object = webapplications.%GetIterator()
	#dim webapp As %DynamicObject

	while iterator.%GetNext(.key, .webapp)
	{
		do ..Create(webapp.url, , webapp.dispatchClass, webapp.role, webapp.description)
	}
}

/// Create web application
ClassMethod Create(url As %String, namespace As %String = {$NAMESPACE}, dispatchClass As %String, role = {$$$AllRoleName}, description As %String = "") As %Status
{
	#dim sc As %Status = $$$OK

	try
	{
		New $namespace
		Set $namespace = "%SYS"

		set properties("AutheEnabled") = $$$AutheUnauthenticated
		set properties("NameSpace") = namespace
		set properties("IsNameSpaceDefault") = $$$NO
		set properties("DispatchClass") = dispatchClass
		set properties("MatchRoles") = ":" _ role
		Set properties("Description") = description

		if ('##class(Security.Applications).Exists(url))
		{
			write "Creating WebApplication with url='",url,"' and dispatchClass'",dispatchClass,"'"

			set sc = ##class(Security.Applications).Create(url, .properties)
		}
		else
		{
			write "Updating WebApplication with url='",url,"' and dispatchClass'",dispatchClass,"'"

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

}
