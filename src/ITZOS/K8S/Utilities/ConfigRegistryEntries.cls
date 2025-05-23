/// Create Config Registry entries based on after-install.json
Class ITZOS.K8S.Utilities.ConfigRegistryEntries
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "configregistries";

/// Test
ClassMethod Test()
{
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
		"configregistries": {
          "\\FHIR\\IgnoreMissingContentTypeCharset": "1"
        }
	})
}

/// Load all service registry entries
ClassMethod Load(configRegistryItems As %DynamicArray)
{
	#dim iterator As %Iterator.Object = configRegistryItems.%GetIterator()

	while iterator.%GetNext(.key, .value)
	{
		do ..CreateOrUpdateEntry(key, value)
	}
}

/// Method used to create a config registry entry during the after-install
ClassMethod CreateOrUpdateEntry(key As %String, value As %String)
{
	write "Set ConfigRegistry entry '",key,"' to value '",value,"': "

    set sc = ##class(HS.Registry.Config).AddUpdateKeyValue(key, value)
    
	if $$$ISERR(sc)
	{
		write " Failed: ",$System.Status.GetErrorText(sc),!
	}
	else
	{
		write " Done!",!
	}
}

}
