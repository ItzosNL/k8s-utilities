/// Load Intersystems Package Manager (ZPM)
Class ITZOS.K8S.Utilities.ZPM
{

/// Add InterSystems Package Manager (ZPM)
ClassMethod Load() As %Status
{
	New $NAMESPACE
	set $NAMESPACE = "%SYS"
	set httpRequest = ##class(%Net.HttpRequest).%New()
	set httpRequest.Server = "pm.community.intersystems.com"
	set httpRequest.SSLConfiguration = "Default"

	set sc = httpRequest.Get("/packages/zpm/latest/installer")

	if $$$ISERR(sc)
	{
		Do $System.Status.DisplayError(sc)
		return sc
	}

	return $system.OBJ.LoadStream(httpRequest.HttpResponse.Data, "c")
}

}
