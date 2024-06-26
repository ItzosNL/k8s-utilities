/// Create users based on after-install.json
Class ITZOS.K8S.Utilities.CompileAll
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "compile-all";

/// Compile all classes in Namespace
ClassMethod Load(doCompileAll As %Boolean)
{
	if (doCompileAll)
	{
		write "CompileAll in namespace ",$NAMESPACE,": ",!

		set sc = $SYSTEM.OBJ.CompileAll()

		if $$$ISERR(sc)
		{
			write "CompileAll failed: ",$SYSTEM.Status.GetErrorText(sc),!
			return
		}
	}
}

}
