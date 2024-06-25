/// After-install actions based on after-install.json 
Class ITZOS.K8S.AfterInstall
{

/// Execute after-install actions
ClassMethod ExecuteActions(configmapFilename As %String, setMonitorConfig As %Boolean = 0)
{
    set config = {}.%FromJSONFile(configmapFilename)
 
    if setMonitorConfig && $ISOBJECT(config.monitoring)
    {
        write "Set up monitoring config: ", !
        do ##class(IRISELK.BusinessOperation.Config).SetConfig(configmapFilename)
    }

    if $ISOBJECT(config.systemSecurityParameters)
    {
        write "Set System Security Parameters: ", !
        do ##class(ITZOS.K8S.Utilities.SystemSecurityParameters).Load(config.systemSecurityParameters)
    }

    if $ISOBJECT(config.sslconfigs)
    {
        write "Loading SSLconfigs: ", !
        do ##class(ITZOS.K8S.Utilities.SSLConfigs).Load(config.sslconfigs)
    }

    if $ISOBJECT(config.credentials)
    {
        write "Loading Credentials: ", !
        do ##class(ITZOS.K8S.Utilities.Credentials).Load(config.credentials)
    }

    if $ISOBJECT(config.sqlconfigs)
    {
        write "Loading SQL Connections: ", !
        do ##class(ITZOS.K8S.Utilities.SQLConnections).Load(config.sqlconfigs)
    }

    if $ISOBJECT(config.users)
    {
        write "Loading Users: ", !
        do ##class(ITZOS.K8S.Utilities.Users).Create(config.users)
    }

    if $ISOBJECT(config.serviceregistries)
    {
        write "Loading service registry entries: ", !
        do ##class(ITZOS.K8S.Utilities.ServiceRegistryEntries).Load(config.serviceregistries)
    }

    if $ISOBJECT(config."backup-config")
    {
        write "Loading Backup configuration: ", !
        do ##class(ITZOS.K8S.Utilities.BackupConfig).Load(config."backup-config")
    }
}

/// Get Registered After-inatall classes 
ClassMethod GetAfterInstallHandlers()
{
    set result = ##class(%SQL.Statement).%ExecDirect(, "Select parent, _Default from %Dictionary.ParameterDefinition where parent like ? and Name = 'AfterInstallNode' and sequencenumber < 3")

    if result.%SQLCODE < 0
    {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
    }

    while result.%Next()
    {
        write result.parent," handles ",result."_Default",!
    }
}

}
