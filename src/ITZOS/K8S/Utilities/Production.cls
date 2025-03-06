/// Production related utilities
Class ITZOS.K8S.Utilities.Production
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "production";

/// Does this type require Interop?
Parameter AfterInstallInterop As BOOLEAN = 1;

/// Test
ClassMethod Test()
{
	do ..Load("MONDRIAAN.FoundationNonProduction")
}

/// Autostart production
ClassMethod Load(productionName As %String)
{
	do ..AutoStartProduction(productionName)
}

/// Making a production Auto-Start in the current namespace
ClassMethod AutoStartProduction(productionName As %String) As %Status
{
	// Stop current production
	if ##class(Ens.Director).IsProductionRunning(.currentProduction)
	{
		write "Stop Production ",currentProduction,": "
		set sc = ##class(Ens.Director).StopProduction(0, 1)

		if $$$ISERR(sc)
		{
			write " failed: ",$System.Status.GetErrorText(sc),!
			return sc
		}

		write !
	}

	write "Start Production ",productionName,": "
	set sc = ##class(Ens.Director).StartProduction(productionName)

	if $$$ISERR(sc)
	{
		write " failed: ",$System.Status.GetErrorText(sc),!
		return sc
	}

    write !,"Make sure Production ",productionName," autostarts: "
	set sc = ##class(Ens.Director).SetAutoStart(productionName)

	if $$$ISERR(sc)
	{
        write " failed: ",$System.Status.GetErrorText(sc)
	}

    write !

	return $$$OK
}

}
