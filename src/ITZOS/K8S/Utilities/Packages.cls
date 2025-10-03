/// Compile packages during after-install, e.g. after installing the Monitoring package
Class ITZOS.K8S.Utilities.Packages
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "compile-packages";

/// Test
ClassMethod Test()
{
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
      "compile-packages": "KIBANALOG"
	})
}

/// Load specified packages
ClassMethod Load(packages As %String)
{
	do ##class(ITZOS.K8S.Installer).Finish(packages)
}

}
