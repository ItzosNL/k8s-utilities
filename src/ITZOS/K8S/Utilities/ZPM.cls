/// Load Intersystems Package Manager (ZPM)
Class ITZOS.K8S.Utilities.ZPM
{

/// Add InterSystems Package Manager (ZPM)
ClassMethod Load() As %Status
{
	set version = ..GetVersion()

	if (version '= "")
	{
		write "Found ZPM ",version,", skip loading!",!
		return $$$OK
	}

	New $NAMESPACE
	set $NAMESPACE = "%SYS"
	set httpRequest = ##class(%Net.HttpRequest).%New()
	set httpRequest.Server = "pm.community.intersystems.com"
	set httpRequest.SSLConfiguration = "Default"
	set location = "/packages/zpm/latest/installer"

	set sc = httpRequest.Get(location)

	if $$$ISERR(sc)
	{
		write "Failed to open location https://",httpRequest.Server,location,": ",$System.Status.GetErrorText(sc),!
		return sc
	}

	return $system.OBJ.LoadStream(httpRequest.HttpResponse.Data, "c")
}

/// Get ZPM version
ClassMethod GetVersion() As %Status
{
	try
	{
		return $PARAMETER("IPM.Installer", "VERSION")
	}
	catch
	{
		return ""
	}
}

/// Get current Version of specified package
ClassMethod GetPackageVersion(namespace As %String, packageName As %String) As %String
{
	new $NAMESPACE
	set $NAMESPACE = namespace
	
	if '$$$comClassDefined("%IPM.Storage.Module")
	{
		// Don't error in namespaces without IPM enabled
		return ""
	}

	#dim result as %SQL.StatementResult = ##class(%SQL.Statement).%ExecDirect(, "SELECT VersionString FROM %IPM_Storage.ModuleItem WHERE Name = ?", packageName)

	if (result.%SQLCODE < 0)
	{
		throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
	}

	if result.%Next()
	{
		return result.VersionString
	}

	return ""
}

/// Returns 0 if the current version is lower version than the target version
ClassMethod IsVersionGreateOrEqual(current As %String, target As %String) As %Boolean
{
    if (current = target)
    {
        return 1
    }

    #dim currentSemver as %ZPM.PackageManager.Core.SemanticVersion = ##class(%ZPM.PackageManager.Core.SemanticVersion).FromString(current)
    #dim targetSemver as %ZPM.PackageManager.Core.SemanticVersion = ##class(%ZPM.PackageManager.Core.SemanticVersion).FromString(target)

    return currentSemver.Follows(targetSemver)
}

}
