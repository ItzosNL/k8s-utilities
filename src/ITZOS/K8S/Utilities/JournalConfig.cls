Include %occErrors

/// Journal Configuration
Class ITZOS.K8S.Utilities.JournalConfig
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "basejournalpath";

/// Load the Journal Config
ClassMethod Load(basejournalpath As %String) As %Status
{
	return ..SetJournalConfig(basejournalpath)
}

/// Set Journal Config
ClassMethod SetJournalConfig(basejournalpath As %String) As %Status
{
	new $Namespace
	set $Namespace = "%SYS"

	write "Setting Config.Journal Directories based on path '" _ basejournalpath _ "': "

	// First check if base folder exists:
	if '##class(%File).DirectoryExists(basejournalpath)
	{
		write " does not exists, abort!",!
		return $$$ERROR($$$DirectoryNotExist, basejournalpath)
	}

	set sc = ##class(Config.Journal).Get(.props)

	if $$$ISERR(sc)
	{
		write "Failed to get Config.Journal properties: ",$SYSTEM.Status.GetErrorText(sc),!
		return sc
	}

	if (props("CurrentDirectory") '= (basejournalpath _ "/journal1/"))
	 || (props("AlternateDirectory") '= (basejournalpath _ "/journal2/"))
	{
		set sc = $$$OK
		set props("CurrentDirectory") = ..Ensure(basejournalpath _ "/journal1/", .sc)
		set props("AlternateDirectory") = ..Ensure(basejournalpath _ "/journal2/", .sc)

		if $$$ISERR(sc)
		{
			write "Failed to create subfolders: ",$SYSTEM.Status.GetErrorText(sc),!
			return sc
		}

		set sc = ##class(Config.Journal).Modify(.props)

		if $$$ISERR(sc)
		{
			write "Failed to set Config.Journal properties: ",$SYSTEM.Status.GetErrorText(sc),!
			return sc
		}

		write "Done",!
		return $$$OK
	}

	write "Skipped because the Directories already have the proper value",!
	return $$$OK
}

/// Ensure Directory exists
ClassMethod Ensure(directory As %String, ByRef sc As %Status) As %String
{
	if '##class(%File).DirectoryExists(directory)
	{
		if '##class(%File).CreateDirectory(directory, .error)
		{
			set sc = $SYSTEM.Status.AppendStatus(sc, $$$ERROR($$$GeneralError, "Failed to create directory '" _ directory _ "': error " _ error))
		}
	}

	return directory
}

}
