/// Load webterminal?
Class ITZOS.K8S.Utilities.WebTerminal
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "webterminal";

/// Add "webterminal": true to after-install.json to load webterminal
ClassMethod Load(active As %Boolean)
{
	if active
	{
		do ..ActivateWebterminal()
	}
}

/// Activate "webterminal"
ClassMethod ActivateWebterminal()
{
	write "loading webterminal package:",!
	zpm "install webterminal"

	// Fix issues of latest release
	// - Assign %All role to /webterminalsocket
	do ..AssignAllRoleToWebterminalSocket()

	// - Allow public read for resource %DB_{NAMESPACE}
	do ..AllowPublicReadForResource()
}

/// Assign %All role to /webterminalsocket Web application
ClassMethod AssignAllRoleToWebterminalSocket()
{
	#dim sc As %Status = $$$OK
	set url = "/terminalsocket"

	try
	{
		New $namespace
		set $namespace = "%SYS"

		write "Get WebApplication with url '",url,"': "

		set sc = ##class(Security.Applications).Get(url, .properties)

		if $$$ISOK(sc)
		{
			write !,"Found properties(""MatchRoles"")=", properties("MatchRoles"),!

			if properties("MatchRoles") '[ (":" _ $$$AllRoleName)
			{
				set properties("MatchRoles") = properties("MatchRoles") _ ":" _ $$$AllRoleName
				write "Added %All role: ", properties("MatchRoles"),!
				set sc = ##class(Security.Applications).Modify(url, .properties)
			}
			else
			{
				write "%All role: already present!",!
			}
		}
		else
		{
			write "Not found",!
		}
	}
	catch ex
	{
		set sc = ex.AsStatus()
	}

	if $$$ISERR(sc)
	{
		write "failed: ",$System.Status.GetErrorText(sc)
	}
	else
	{
		write "succeeded"
	}

	write !

	return sc
}

/// Allow public read for resource %DB_{NAMESPACE}
ClassMethod AllowPublicReadForResource()
{
	set resource = "%DB_" _ $NAMESPACE

	try
	{
		new $namespace
		set $namespace = "%SYS"

		write "Get Resource '",resource,"': "

		set sc = ##class(Security.Resources).Get(resource, .properties)

		if $$$ISOK(sc)
		{
			write !,"Found properties(""PublicPermission"")='", properties("PublicPermission"),"'",!

			if properties("PublicPermission") = ""
			{
				write "Enabling Public Read: "
				set properties("PublicPermission") = "R"
				set sc = ##class(Security.Resources).Modify(resource, .properties)
			}
			else
			{
				write "Public Read already enabled",!
			}
		}
		else
		{
			write "Not found",!
		}
	}
	catch ex
	{
		set sc = ex.AsStatus()
	}

	if $$$ISERR(sc)
	{
		write "failed: ",$System.Status.GetErrorText(sc)
	}
	else
	{
		write "succeeded"
	}

	write !

	return sc
}

}
