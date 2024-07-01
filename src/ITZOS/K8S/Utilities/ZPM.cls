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
		return $PARAMETER("%ZPM.Installer", "VERSION")
	}
	catch
	{
		return ""
	}
}

}
