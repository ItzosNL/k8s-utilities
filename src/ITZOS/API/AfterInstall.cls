/// Add webapplication for KPN/Itzos /beheer API
Class ITZOS.API.AfterInstall
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "beheerapi";

/// Add /beheer webapplication
ClassMethod Load(active As %Boolean = 1)
{
	if active
	{
		do ..AddBeheerWebApplcation()
	}
}

/// Add /beheer webapplication
ClassMethod AddBeheerWebApplcation()
{
	do ##class(ITZOS.K8S.Utilities.WebApplications).Load([
        {
          "url": "/beheer",
          "dispatchClass": "ITZOS.API.v1.disp",
          "role": "%All"
        }
	])
}

}
