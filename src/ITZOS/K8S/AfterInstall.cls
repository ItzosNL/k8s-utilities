/// After-install actions based on after-install.json 
Class ITZOS.K8S.AfterInstall
{

/// Load System default Settings and after-install.json from configMap
ClassMethod LoadConfigmaps(configmapFolder As %String)
{
    do ##class(ITZOS.K8S.Utilities.DefaultSettings).Import(configmapFolder _ "/Ens.Config.DefaultSettings.esd")

    write "Execute after-install actions based on the configmap:", !
    do ..ExecuteActions(configmapFolder _ "/after-install.json")
    write "Finished running after-install steps!",!
}

/// Execute after-install actions
ClassMethod ExecuteActions(configmapFilename As %String)
{
    set config = {}.%FromJSONFile(configmapFilename)
    #dim allHandlers as %DynamicObject = ..GetAfterInstallHandlers()
	#dim iterator As %Iterator.Object = config.%GetIterator()

	while iterator.%GetNext(.key, .value)
	{
        #; write "Handling key ",key,!
        #dim handlers as %DynamicArray = allHandlers.%Get(key)

        if '$ISOBJECT(handlers)
        {
            write "No handler found for node ",key," (skipped)",! 
            continue
        }

        if (key = "monitoring") && 'value.enabled
        {
            write "Skipping Monitoring since it is not enabled",! 
            continue
        }

        for index = 1:1:handlers.%Size()
        {
            set handlerClass = handlers.%Get(index - 1)
            
            write "Calling ",handlerClass," to deal with node ",key 

            if $PARAMETER(handlerClass, "AfterInstallMode")  = "file"
            {
                write " passing file ",configmapFilename,": ",!
                do $CLASSMETHOD(handlerClass, "LoadFile", configmapFilename)
            }
            else
            {
                write " passing node: ",!
                do $CLASSMETHOD(handlerClass, "Load", value)
            }
        }
	}
}

/// Handle one node of the configuration
/// Description
/// Get Registered After-inatall classes 
ClassMethod GetAfterInstallHandlers() As %DynamicObject
{
    set result = ##class(%SQL.Statement).%ExecDirect(, "Select parent, _Default from %Dictionary.ParameterDefinition where Name = 'AfterInstallNode'")

    if result.%SQLCODE < 0
    {
        write result.%Message,!
        return {}
    }

    set allHandlers = {}

    while result.%Next()
    {
        #dim handlers as %DynamicArray = allHandlers.%Get(result."_Default")

        if '$ISOBJECT(handlers)
        {
            set handlers = ##class(%DynamicArray).%New()
            do allHandlers.%Set(result."_Default", handlers)
        }

        #; write "Adding handler ",result.parent," for ",result."_Default",":",!
        do handlers.%Push(result.parent)
    }

    return allHandlers
}

}
