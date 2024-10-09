/// Enable or Disable SystemAuditevents during AfterInstall
Class ITZOS.K8S.Utilities.SystemAuditevents
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "auditEvents";

/// Testmethods
ClassMethod Test()
{
	do ..Load(
        {
          "%System/%Login/LoginFlailure": true,
          "LoginFailure": true,
          "%Login/JobStart": false
        }
      )
}

/// Enable or Disable specified SystemAuditevents 
ClassMethod Load(events As %DynamicObject)
{
	#dim iterator As %Iterator.Object = events.%GetIterator()
	#dim eventStatus As %DynamicObject

	while iterator.%GetNext(.eventName, .eventStatus)
	{
		do ..Toggle(eventName, eventStatus)
	}
}

/// Method used to create a eventStatus during the after-install
ClassMethod Toggle(name As %String, enabled As %Boolean)
{
	new $Namespace
	set $Namespace = "%SYS"
	set action = $CASE(enabled, 1:"enabled", :"disabled")

	if $LENGTH(name, "/") = 1
	{
		set name = "%System/%Login/" _ name
	}
	elseif $LENGTH(name, "/") = 2
	{
		set name = "%System/" _ name
	}

	write "SystemAuditevent  '",name,"': "

    // Check if the event already exists | Quit if true
    if ##class(Security.Events).Exists($PIECE(name, "/", 1), $PIECE(name, "/", 2), $PIECE(name, "/", 3), .event, .sc)
	{
		#dim event as Security.Events

		if event.Enabled '= enabled
		{
			set event.Enabled = enabled
			set sc = event.%Save()

			if $$$ISERR(sc)
			{
				write "Update to ",action," failed: ",$System.Status.GetErrorText(sc),!
			}
			else
			{
				write "Updated to ",action,!
			}
		}
		else
		{
			write "Already ",action," not updated",!
		}
	}
	else
	{
		write "`Not found!",!
	}
}

}
