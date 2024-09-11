/// Load webterminal?
Class ITZOS.K8S.Utilities.WebTerminal
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "webterminal";

/// Add "webterminal": true to after-install.json to load webterminal
ClassMethod Load(active As %Boolean = 1)
{
	if active
	{
		write "loading webterminal package:",!
	    zpm "install webterminal"

		// TBD: Fix issues of latest release
		// - Assign %All role to /webterminalsocket
		// - Allow public read for resource %DB_{NAMESPACE}
	}
}

}
