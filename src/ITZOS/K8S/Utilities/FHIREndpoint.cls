/// Create InteropAdapter
Class ITZOS.K8S.Utilities.FHIREndpoint
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "fhirEndpoint";

/// Test
ClassMethod Test()
{
    do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
        "fhirEndpoint": "/fhir/stu3"
      })
}

/// Load Backup config
ClassMethod Load(url As %String)
{
    try
    {
        write "Adding FHIR Endpoint '" _ url _ "': "
        do ##class(HS.FHIRServer.Installer).InstallCSPAppInterop(url)
        write "succeeded",!
    }
    catch ex
    {
        Set sc = ex.AsStatus()
        write "failed: ",$SYSTEM.Status.GetErrorText(sc),!
    }
}

}
