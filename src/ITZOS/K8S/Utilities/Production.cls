/// Production related utilities
Class ITZOS.K8S.Utilities.Production
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "production";

/// Autostart production
ClassMethod Load(productionName As %String)
{
	do ..AutoStartProduction(productionName)
}

/// Making a production Auto-Start in the current namespace
ClassMethod AutoStartProduction(productionName As %String) As %Status
{
	// Only start production of not already running
	if '##class(Ens.Director).IsProductionRunning()
	{
        write "Start Production ",productionName,": "
		set sc = ##class(Ens.Director).StartProduction(productionName)

		if $$$ISERR(sc)
		{
			write " failed: ",$System.Status.GetErrorText(sc)
			return sc
		}
	}

    write "Make sure Production ",productionName," autostarts: "
	set sc = ##class(Ens.Director).SetAutoStart(productionName)

	if $$$ISERR(sc)
	{
        write " failed: ",$System.Status.GetErrorText(sc)
	}

    write !

	return $$$OK
}

}
