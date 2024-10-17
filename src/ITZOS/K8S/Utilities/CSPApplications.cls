/// Installs  CSP Applicationsduring after-install
Class ITZOS.K8S.Utilities.CSPApplications
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "cspapplications";

/// Test
ClassMethod Test()
{
    do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
        "cspapplications": [
            {
                "url": "/medmij",
                "directory": "/tmp/csp/medmij",
                "resource": "",
                "authenticationMethods": 64,
                "grant": "%All",
                "description": "",
                "cookiePath": "/medmij/",
                "recurse": true,
                "autoCompile": true
            }
        ]
    })
}

/// Load all cspapplications
ClassMethod Load(cspapplications As %DynamicArray)
{
	#dim iterator As %Iterator.Object = cspapplications.%GetIterator()
	#dim cspapp As %DynamicObject

	while iterator.%GetNext(.key, .cspapp)
	{
		do ..Create(cspapp.url, cspapp.%Get("namespace", $NAMESPACE), cspapp.directory, cspapp.resource, cspapp.authenticationMethods, cspapp.grant, cspapp.description, cspapp.cookiePath, cspapp.recurse, cspapp.autoCompile)
	}
}

/// Create web application
ClassMethod Create(url As %String, namespace As %String = {$NAMESPACE}, directory As %String, resource As %String, authenticationMethods As %Integer, grant As %String, description As %String, cookiePath As %String, recurse As %Boolean, autoCompile As %String = "") As %Status
{
	#dim sc As %Status = $$$OK

	try
	{
        new $namespace
        set $namespace = "%SYS"

        /// Create/modify a CSP application
        #; #dim installer as %Installer.Installer
        #; Method CSPApplication(url As %String, namespace As %String, description As %String, directory As %String, resource As %String, recurse As %String, pLoginClass As %String, cookiePath As %String, authenticationMethods As %Integer, pLockCSPName As %Boolean, pEventClass As %String, pDefaultTimeout As %Integer, pDefaultSuperclass As %String, pUseSessionCookie As %Integer, pServeFiles As %Boolean, pServeFilesTimeout As %Integer, pCustomErrorPage As %String, pPackageName As %String, pChangePasswordPage As %String, pGroupById As %String = "", pCspZenEnabled As %Boolean = 1, pInboundWebServicesEnabled As %Boolean = 1, pTwoFactorEnabled As %Boolean = 0, pIsNameSpaceDefault As %Boolean = 0, pPermittedClasses As %String = "", autoCompile As %Boolean = 1, pDispatchClass As %String = "", pMatchRoles As %String = "", grant As %String = "") [ Internal ]

        write "Creating CSPApplication with " _ url _ " in " _ namespace _ ", using " _ directory,":",!
        set sc = ##class(%EnsembleMgr).createPortalApp(url, namespace, directory, description, resource, recurse, , grant, cookiePath, authenticationMethods)

        if $$$ISERR(sc)
        {
            write "Failed updating properties",$SYSTEM.Status.GetErrorText(sc),!
        }

        set properties("AutoCompile") = autoCompile
        
        set sc = ##class(Security.Applications).Modify(url, .properties)

        if $$$ISERR(sc)
        {
            write "Failed updating properties ",$SYSTEM.Status.GetErrorText(sc),!
        }
	}
	catch ex
	{
		set sc = ex.AsStatus()

        write "Exception in CSPApplications.Create: ",$SYSTEM.Status.GetErrorText(sc),!
	}

	return sc
}

}
