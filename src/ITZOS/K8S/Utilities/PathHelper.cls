/// Path helper for certicate files
Class ITZOS.K8S.Utilities.PathHelper
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "certificatespath";

/// Please ignore and log no warning
Parameter AfterInstallMode = "display-only";

/// Display the value found
ClassMethod Display(value As %String) As %Status
{
    write "Using certificatespath ",value,!
}

/// Joins multiple parts of a filesystem path with the separator that is appropriate for the current operating system.
/// We don't use %File:SubDirectoryName because it normalizes to a full path, which we may not want.
ClassMethod JoinPath(parts... As %String) As %String
{
	if parts(2) = ""
	{
		return ""
	}

	; Determine separator to use. Only caters for Windows and
	; Unix-like operating systems.
	set separator = $Select($$$isWINDOWS: "\", 1: "/")
	set path = parts(1)

	for i = 2:1:parts
	{
		set part = $Get(parts(i))
		
		if $Extract(path, *) '= separator
		{
			set path = path _ separator
		}

		set path = path _ part
	}
	
	return path
}

}
