/// Common logic for scheduled lookupTables
Class ITZOS.K8S.Utilities.LookupTables
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "lookupTables";

/// Test Load method
ClassMethod Test()
{
	do ..Load({
      "SubjectAltNames": {
        "Dummy": "medmij.deenigeechtepgo.nl,dvza-preprod.healthexchange.nl"
      },
      "MedMij.Registratie": {
        "MaxAgeGNL": 600,
        "MaxAgeOCL": 600,
        "MaxAgeWHL": 600,
        "MaxAgeZAL": 1000
      },
      "OAuth2_Authorize_Settings": {
        "ApprovalStatusTTL": 30,
        "DoneStatusTTL": 1314000,
        "ExpiredStatusTTL": 108000,
        "InitialStatusTTL": 30,
        "LoggedInStatusTTL": 15,
        "ManageStatusTTL": 30
      }
  })
}

/// Load Lookuptables from after-install.json
ClassMethod Load(lookupTables As %DynamicObject)
{
	#dim iterator As %Iterator.Object = lookupTables.%GetIterator()
	#dim properties As %DynamicObject

	while iterator.%GetNext(.tableName, .properties)
	{
		do ..CreateOrUpdateLookupTable(tableName, properties)
	}
}

/// Create Legacy Task
ClassMethod CreateOrUpdateLookupTable(tableName As %String, properties As %DynamicObject)
{
	write "Updating properties in LookupTable ",tableName,":",!

	#dim iterator As %Iterator.Object = properties.%GetIterator()

	while iterator.%GetNext(.key, .value)
	{
		set sc = ##class(Ens.Util.LookupTable).%UpdateValue(tableName, key, value)

		if $$$ISERR(sc)
		{
			write "Failed to set property ",key," to value '",value,"': ",$SYSTEM.Status.GetErrorText(sc),!
		}
		else
		{
			write "Updated property ",key," to value '",value,"'",!
		}
	}
}

/// Set named Property
ClassMethod SetProperty(properties As %SYS.Task, propertyName As %String, value As %String, separator As %String = "|")
{
	set settings = $LISTTOSTRING(properties.Settings, separator)
	set found = 0

	if settings '= ""
	{
		for index = 1:2:$LENGTH(settings, separator)
		{
			set setting = $PIECE(settings, separator, index)

			if setting '= propertyName
			{
				continue
			}

			set found = 1

			if $PIECE(settings, separator, index + 1) '= value
			{
				write "Updating setting ",propertyName," to ",value,": ",! 
				set $PIECE(settings, separator, index + 1) = value
			}
			else
			{
				write "Setting ",propertyName," already has the proper value",! 
			}
		}
	}

	if 'found // Setting not found, now adding it!
	{
		if settings '= ""
		{
			set settings = settings _ separator
		}

		write "Adding setting ",propertyName," with ",value,": ",! 
		set settings = settings _ propertyName _ separator _ value 
	}

	set properties.Settings = $LISTFROMSTRING(settings, separator)
}

}
