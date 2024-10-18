/// Create Monitoring namespace
Class ITZOS.K8S.InstallMonitoring
{

Parameter Namespace As String = "MONITORING";

Parameter PackageName As String = "intersystems-monitoring";

/// Check status of Monitoring namespcace and package in after-install
ClassMethod Check(config As %DynamicObject)
{
	set namespaceExists = ##class(ITZOS.K8S.Utilities.Namespace).NamespaceExists(..#Namespace)
	write "Monitoring namespace does ",$CASE(namespaceExists, 1:"", :"not "),"exist",!

	if config.enabled = "" // Not set, change to default (true)
	{
		do config.%Set("enabled", 1, "boolean")
	}

	write "Monitoring should be ",$CASE(config.enabled, 1:"en", :"dis"),"abled",!

	if config.enabled
	{
		if 'namespaceExists
		{
			write "Creating Monitoring namespace and installing package:",!

		    do ..Install()
		}
		else
		{
		    set targetVersion = $SYSTEM.Util.GetEnviron("monitoringVersion")
			set currentVersion = ##class(ITZOS.K8S.Utilities.ZPM).GetPackageVersion(..#Namespace, ..#PackageName) 

			if (currentVersion = "") || ((targetVersion '= "") && '##class(ITZOS.K8S.Utilities.ZPM).IsVersionGreateOrEqual(currentVersion, targetVersion))
			{
				write "Updating package " _ ..#PackageName _ " to latest version:",!

				do ..InstallPackage()
			}
			else
			{
				write "No need to update package " _ ..#PackageName _ ":",!
			}
		}
	}
	elseif ('config.enabled) && namespaceExists
	{
		// We are using a local copy to avoid the need to install the package for the need of disabling it.
		do ..StopProduction()
	}
}

/// Create namespace and Load Package, and finish installation
ClassMethod Install(namespace As %String = {..#Namespace})
{
	do ##class(ITZOS.K8S.Utilities.Namespace).Create(..#Namespace)

	do ..InstallPackage()
}

/// Install intersystems-monitoring package 
ClassMethod InstallPackage()
{
	new $NAMESPACE
	set $NAMESPACE = ..#Namespace

	write "Loading package " _ ..#PackageName _ ":",!

	// This installs the intersystems-monitoring package
	ZPM "install " _ ..#PackageName
}

/// Stop the production and remove auto-start
ClassMethod StopProduction(namespace As %String = {..#Namespace}) As %Status
{
	new $NAMESPACE
	set $NAMESPACE = namespace
	set sc = $$$OK

	// Only start production of not already running
	if '##class(Ens.Director).IsProductionRunning()
	{
        write "Stop Production for namespace ",namespace,": "
		set sc = ##class(Ens.Director).StopProduction()

		if $$$ISERR(sc)
		{
			write " failed: ",$System.Status.GetErrorText(sc)
			return sc
		}
	}

    write "Remove Autostart for namespace ",namespace,": "
	set sc = ##class(Ens.Director).SetAutoStart()

	if $$$ISERR(sc)
	{
        write " failed: ",$System.Status.GetErrorText(sc)
	}

    write !

	return sc
}

}
