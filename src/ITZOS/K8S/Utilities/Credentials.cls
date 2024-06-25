/// Create Credentials based on after-install.json
Class ITZOS.K8S.Utilities.Credentials
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "credentials";

/// Load all Credentials
ClassMethod Load(credentials As %DynamicObject)
{
	#dim iterator As %Iterator.Object = credentials.%GetIterator()
	#dim credential As %DynamicObject

	while iterator.%GetNext(.key, .credential)
	{
        write "Loading Credential name: ",credential.name,":"

		set password = ##class(ITZOS.K8S.Utilities.Secrets).RetrievePassword(credential.password)

		set sc = ..CreateOrUpdateCredential(credential.name, credential.username, password)

		if $$$ISERR(sc)
		{
			write "failed, ",$System.Status.GetErrorText(sc),!
		}
		else
		{
			write "done",!
		}
	}
}

/// Create or Update a Credential
ClassMethod CreateOrUpdateCredential(id As %String, username As %String, password As %String) As %Status
{
    set credential = ##class(Ens.Config.Credentials).%OpenId(id, , .sc)

    if $$$ISERR(sc) // Not found
    {
        set credential = ##class(Ens.Config.Credentials).%New()
        set credential.SystemName = id
    }

    set credential.Username = username
    set credential.Password = password

    return credential.%Save()
}

}
