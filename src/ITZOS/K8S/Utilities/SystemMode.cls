/// Set the SystemMode
Class ITZOS.K8S.Utilities.SystemMode
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "system-mode";

/// Test
ClassMethod Test()
{
    do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
      "system-mode": "DEVELOPMENT"
    }, "")
}

ClassMethod Load(systemMode As %String)
{
	new $NAMESPACE
	set $NAMESPACE = "%SYS"

    write "Setting SystemMode = '",systemMode,"' "

    set properties("SystemMode") = systemMode
    set sc = ##Class(Config.Startup).Modify(.properties)

    if $$$ISERR(sc)
    {
        write " failed: ",$System.Status.GetErrorText(sc),!
    }
    else
    {
        write "done",!
    }
}

}
