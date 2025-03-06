/// After-install actions based on after-install.json 
Class ITZOS.K8S.AfterInstall
{

/// Load System default Settings and after-install.json from configMap
ClassMethod LoadConfigmaps(configmapFolder As %String)
{
    do ##class(ITZOS.K8S.AfterInstall).MapITZOSPackagetoAll()

    // we found out ZPM may be in disrepair, so we reload it 
    do ##class(ITZOS.K8S.Utilities.ZPM).Load()

    set configmapFilename = configmapFolder _ "/after-install.json"
    #dim config as %DynamicObject = {}.%FromJSONFile(configmapFilename)

    if ('config.%IsDefined("interop")) || config.interop
    {
        if config.systemdefaultspath = ""
        {
            // Original hard-coded path
            set config.systemdefaultspath = configmapFolder _ "/Ens.Config.DefaultSettings.esd"
        }

        do ##class(ITZOS.K8S.Utilities.DefaultSettings).Import(config.systemdefaultspath)
    }

    write "Execute after-install actions based on the configmap:", !
    do ..ExecuteActions2(config, configmapFilename)
    write "Finished running after-install steps!",!
}

/// Create package mapping for Itzos Package to %All namespace
ClassMethod MapITZOSPackagetoAll() As %Status
{
    new $NAMESPACE
    set $NAMESPACE = "USER"

	do ##class(ITZOS.K8S.Utilities.Namespace).CreateALLNamespace()
	do ##class(ITZOS.K8S.Utilities.Namespace).CreatePackageMappingToALL("ITZOS")
}

/// Execute after-install actions
ClassMethod ExecuteActions(configmapFilename As %String)
{
    set config = {}.%FromJSONFile(configmapFilename)
    do ..ExecuteActions2(config, configmapFilename)
}

/// Execute after-install actions version 2 - expects json as input
ClassMethod ExecuteActions2(config As %DynamicObject, configmapFilename As %String = "")
{
    if $ISOBJECT(config.monitoring)
    {
        // This check turns out to be necessary because we have seen outdated or none-existent package!
        do ##class(ITZOS.K8S.InstallMonitoring).Check(config.monitoring)
    }

    set hasInterop = ('config.%IsDefined("interop")) || config.interop
    #dim allHandlers as %DynamicObject = ..GetAfterInstallHandlers()
	#dim iterator As %Iterator.Object = config.%GetIterator()

	while iterator.%GetNext(.key, .value)
	{
        if (key = "interop")
        {
            write "interop is ",$CASE(value, 1: "enabled", : "disabled"),!
            continue
        }

        #; write "Handling key ",key,!
        #dim handlers as %DynamicArray = allHandlers.%Get(key)

        if '$ISOBJECT(handlers)
        {
            write "No handler found for node ",key," (skipped)",! 
            continue
        }

        for index = 1:1:handlers.%Size()
        {
            set handlerClass = handlers.%Get(index - 1)
            set requiresInterop = ($PARAMETER(handlerClass, "AfterInstallInterop") = 1)

            if requiresInterop && ('hasInterop)
            {
                write "Skipping ",handlerClass," because it requires interop and interop is disabled",key 
                continue // skip!
            }

            set afterInstallMode = $PARAMETER(handlerClass, "AfterInstallMode")
            if afterInstallMode = "skip"
            {
                continue // skip!
            }

            if afterInstallMode = "display-only"
            {
                do $CLASSMETHOD(handlerClass, "Display", value)
                continue
            }

            write "Calling ",handlerClass," to deal with node ",key 

            if afterInstallMode = "file"
            {
                write " passing file ",configmapFilename,": ",!
                do $CLASSMETHOD(handlerClass, "LoadFile", configmapFilename)
            }
            elseif afterInstallMode = "all"
            {
                write " passing whole config: ",!
                do $CLASSMETHOD(handlerClass, "Load", config)
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
