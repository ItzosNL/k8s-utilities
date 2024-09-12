/// Handle System security Parameters
Class ITZOS.K8S.Utilities.SystemSecurityParameters
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "systemSecurityParameters";

/// Test
/// - Wachtwoorden dienen na 52 weken gewijzigd te worden.
/// - Wachtwoorden moeten voldoen aan:
///   •	12 karakters (max 32)
///   •	minimaal 1 hoofdletter
///   •	minimaal 1 kleine letter
///   •	minimaal 1 cijfer
///   •	minimaal leesteken
ClassMethod Test()
{
    do ..Load({
        "passwordExpirationDays": 364,
        "passwordPattern": "12.32ANP"
      })
}

/// Set System-Wide Security Parameters, see https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=ASECMGMT#ASECMGMT_syssttngs
ClassMethod Load(systemSecurityParameters As %DynamicObject)
{
	new $namespace
	set $namespace = "%SYS"

	if systemSecurityParameters.passwordExpirationDays '= ""
	{
		set props("PasswordExpirationDays") = systemSecurityParameters.passwordExpirationDays
	}

	if (systemSecurityParameters.inactiveLimit '= "")
	{
		set props("InactiveLimit") = systemSecurityParameters.inactiveLimit
	}

	if (systemSecurityParameters.passwordPattern '= "")
	{
		set props("PasswordPattern") = systemSecurityParameters.passwordPattern
	}

	set sc = ##class(Security.System).Modify(,.props)

	if $$$ISERR(sc)
	{
		write "Failed to set security parameters: ",$SYSTEM.Status.GetErrorText(sc),!
	}
	else
	{
		write "Changed security parameters",!
	}
}

}
