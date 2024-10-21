Include %occErrors

/// Common logic for Remote Database
Class ITZOS.K8S.Utilities.RemoteDB
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "remotedb";

/// Test load method
ClassMethod Test()
{
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
		"remotedb": {
			"databasename": "REMOTE_DATABASE",
			"remoteserver": "IRIS-0",
			"directory": "/irissys/data/IRIS/mgr/MMLOGGING_DATA/",
			"globalmapping": {
				"namespace": "MMLOGGING",
				"globalnames": [
					"MMLOGGINGPKG.DB.Aanlevering*",
					"MMLOGGINGPKG.DB.Logregel*"
				]
			}
		}
	})
}

/// Load Remote Database from after-install.json
ClassMethod Load(db As %DynamicArray)
{
	do ..CreateRemoteDB(db.databasename, db.remoteserver, db.directory)

	#dim iterator As %Iterator.Object = db.globalmapping.globalnames.%GetIterator()

	while iterator.%GetNext(, .global)
	{
		do ..CreateOrUpdateGlobalMapping(db.globalmapping.namespace, global, db.databasename)
	}
}

/// Create Remte Database
ClassMethod CreateRemoteDB(name As %String, remoteserver As %String, directory As %String) As %Status
{
    new $NAMESPACE
    set $NAMESPACE = "%SYS"

	write "Creating Remote Database with name ",name," on remote server ",remoteserver," at directory ",directory,":",!

    set sc = ##class(Config.Databases).Get(name, .properties)

    set properties("Server") = remoteserver	; Name of the dataserver in the ECP configuration
    set properties("Directory") = directory	; Same directory name as on the Dataserver where the iris.dat is located

	if $SYSTEM.Status.GetErrorCodes(sc) = $$$CPFNameDoesNotExist
	{
		set action = "create"
	    set sc = ##class(Config.Databases).Create(name, .properties)
	}
	else
	{
		set action = "update"
	    set sc = ##class(Config.Databases).Modify(name, .properties)
	}

	if $$$ISERR(sc)
	{
		write "Failed to ",action," Remote Database ",name,": ",$SYSTEM.Status.GetErrorText(sc),!
	}
	else
	{
		write "Successfully ",action,"d Remote Database ",name,!
	}

	return sc
}

/// Add GlobalMapping from Application namespace to the Remote Database
ClassMethod CreateOrUpdateGlobalMapping(namespace As %String, globalname As %String, databasename As %String) As %Status
{
    new $NAMESPACE
    set $NAMESPACE = "%SYS"

	write "Creating Global Mapping for ",globalname," in namespace ",namespace," to database ",databasename,":",!

    set sc = ##class(Config.MapGlobals).Get(namespace, globalname, .properties)

    set properties("Database") = databasename	; Remote database

	if $SYSTEM.Status.GetErrorCodes(sc) = $$$CPFMapDoesNotExist
	{
		set action = "create"
	    set sc = ##class(Config.MapGlobals).Create(namespace, globalname, .properties)
	}
	else
	{
		set action = "update"
	    set sc = ##class(Config.MapGlobals).Modify(namespace, globalname, .properties)
	}

	if $$$ISERR(sc)
	{
		write "Failed to ",action," Global Mapping for ",globalname,": ",$SYSTEM.Status.GetErrorText(sc),!
	}
	else
	{
		write "Successfully ",action,"d Global Mapping for ",globalname,!
	}

	return sc
}

}
