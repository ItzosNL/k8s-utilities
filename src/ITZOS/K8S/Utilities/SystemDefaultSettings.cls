/// Utilities for dealing with System Default Settings
Class ITZOS.K8S.Utilities.SystemDefaultSettings
{

/// Create or Update
ClassMethod CreateOrUpdate(production As %String, item As %String, varName As %String, value As %String) As %Status
{
	if ..FindSystemDefaulSetting(production, item, "*", varName, .defaultSetting) 
	{
        if (defaultSetting.HostClassName = "*") && (defaultSetting.SettingValue = value)
        {            
            write "Production ",production,": Skipping System Default Setting named '",item,":",varName,"' as it already exists with the same value",!
            return $$$OK
        }

        write "Production ",production,": Updating System Default Setting named '",item,":",varName,"' from '",defaultSetting.SettingValue,"' to '",value,"'",!
	}
    else
    {
        set defaultSetting = ##class(Ens.Config.DefaultSettings).%New()
        set defaultSetting.ProductionName = production
        set defaultSetting.ItemName = item
        set defaultSetting.SettingName = varName
        set defaultSetting.Deployable = 1

        write "Production ",production,": Creating System Default Setting named '",item,":",varName," with value '",value,"'",!
    }

    set defaultSetting.HostClassName = "*"
    set defaultSetting.SettingValue = value

	set sc = defaultSetting.%Save()

    if $$$ISERR(sc)
    {
        write "Production ",production,": Failed setting System Default Setting named '",item,":",varName,"' to '",value,"': ",$SYSTEM.Status.GetErrorText(sc),!
    }

    return sc
}

/// Find System Default setting for Production, Item and Setting name
ClassMethod FindSystemDefaulSetting(productionName As %String, itemName As %String, className As %String, settingName As %String, Output defaultSetting) As %Boolean
{
    set result = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID FROM Ens_Config.DefaultSettings WHERE (PRODUCTIONNAME = ?) AND (ItemName = ?) AND (SettingName = ?)",
                                                         productionName, itemName, settingName)
    #dim tempSetting as Ens.Config.DefaultSettings = ""
    set defaultSetting = ""

    while result.%Next()
    {
        set id = result.%Get("ID")
        set tempSetting = ##class(Ens.Config.DefaultSettings).%OpenId(id)

        if ((tempSetting.HostClassName = "*") || (className = "*") || (tempSetting.HostClassName = className))
        {
            set defaultSetting = tempSetting
            continue
        }

        write "Found setting with mismatching class name '",tempSetting.HostClassName,"', please fix the Host Class Name if you want to use it",!
    }

    return $ISOBJECT(defaultSetting)
}

}
