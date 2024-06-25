/// K8S Secrets 
Class ITZOS.K8S.Utilities.Secrets
{

/// Retrieve a password from a named secret
ClassMethod RetrievePassword(name As %String) As %String
{
	set sc = $$$OK

	#dim file as %Stream.FileBinary = ##class(%Stream.FileBinary).%New()
	set path = "/home/irisowner/secrets/." _ name
	set sc = file.LinkToFile(path)

	if $$$ISERR(sc)
	{
		write "Unknown credential, file '",path,"' not found",!
		return ""
	}

	set password = file.Read(, .sc)

	if $$$ISERR(sc)
	{
		write "Error reading from file '",path,"': ",$SYSTEM.Status.GetErrorText(sc),!
		return ""
	}

	if password = ""
 	{
		write "Warning: Found empty password in file '",path,"'",!
	}
	
    // This password is already base64-decoded
	return password
}

}
