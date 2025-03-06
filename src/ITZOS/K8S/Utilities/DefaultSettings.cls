/// Get Settings from Production and Create DefaultSettings
Class ITZOS.K8S.Utilities.DefaultSettings
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "systemdefaultspath";

/// Please ignore and log no warning
Parameter AfterInstallMode = "skip";

/// Does this type require Interop?
Parameter AfterInstallInterop As BOOLEAN = 1;

/// Export to settingsfile
ClassMethod Export(toFile As %String = "/tmp/Ens.Config.DefaultSettings.esd", productionName As %String = "") As %Status
{
    return ##class(Ens.Config.DefaultSettings).%Export(toFile, productionName)
}

/// Export from settingsfile
ClassMethod Import(fromFile As %String = "/home/irisowner/systemdefaults/Ens.Config.DefaultSettings.esd") As %Status
{
    write "Load System Default Settings from ",fromFile,":",!

    set sc = ##class(Ens.Config.DefaultSettings).%Import(fromFile, .count, .idsimported)
    
	if $$$ISERR(sc)
	{
		write "Import of System Default Settings failed: ",$System.Status.GetErrorText(sc),!
	}
    else
    {
        write "Imported ",count," System Default Settings",!
    }

    return sc
}

}
