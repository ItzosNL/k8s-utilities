/// Create OAuth2server during after-install
Class ITZOS.K8S.Utilities.OAuth2Server Extends %RegisteredObject
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "oAuth2Server";

/// Test
ClassMethod Test()
{
    do ..Load({
        "description": "MedMij Authorization Server",
        "issuerEndpointHost": "localhost",
        "authenticateClass": "MMAUTHPKG.OAuth2.Server.Authenticate",
        "customizationRoles": "%All",
        "supportSession": false,
        "allowPublicClientRefresh": true,
        "returnRefreshToken": "a",
        "supportedGrantTypes": "A",
        "accessTokenInterval": 900,
        "authorizationCodeInterval": 900,
        "refreshTokenInterval": 15811200,
        "sessionInterval": 3600,
        "clientSecretInterval": 0,
        "supportedScopes": { "71befc0d-f9ef-4766-88ba-a7655773e1af": "Default scope (unused)" },
        "defaultScope": "71befc0d-f9ef-4766-88ba-a7655773e1af",
        "allowUnsupportedScopes": true
       })
}

/// Creates/configures an OAuth2 Authorization server during after-install
ClassMethod Load(oAuth2Server As %String)
{
	do ..CreateOAuth2Server(
        oAuth2Server.description,
        oAuth2Server.issuerEndpointHost,
        oAuth2Server.authenticateClass,
        oAuth2Server.%Get("namespace", $NAMESPACE),
        oAuth2Server.customizationRoles,
        oAuth2Server.supportSession,
        oAuth2Server.allowPublicClientRefresh,
        oAuth2Server.returnRefreshToken,
        oAuth2Server.supportedGrantTypes,
        oAuth2Server.accessTokenInterval,
        oAuth2Server.authorizationCodeInterval,
        oAuth2Server.refreshTokenInterval,
        oAuth2Server.sessionInterval,
        oAuth2Server.%Get("clientSecretInterval", 0),
        oAuth2Server.supportedScopes,
        oAuth2Server.defaultScope,
        oAuth2Server.allowUnsupportedScopes)
}

/// Creates/configure an OAuth2 Authorization server 
/// Needs at least one supported scope
ClassMethod CreateOAuth2Server(description As %String, issuerEndpointHost As %String, authenticateClass As %String, namespace As %String = {$NAMESPACE}, customizationRoles As %String, supportSession As %Boolean, allowPublicClientRefresh As %Boolean, returnRefreshToken As %String, supportedGrantTypes As %String, accessTokenInterval As %Integer, authorizationCodeInterval As %Integer, refreshTokenInterval As %Integer, sessionInterval As %Integer, clientSecretInterval As %Integer, supportedScopes As %DynamicObject, defaultScope As %String, allowUnsupportedScopes As %Boolean = 0)
{
	new $Namespace
	set $Namespace = "%SYS"

	#dim server As OAuth2.Server.Configuration = ##class(OAuth2.Server.Configuration).Open(.sc)

    if $$$ISERR(sc)
	{
		write "Failed Open the existing OAuth2.Server.Configuration: ",$System.Status.GetErrorText(sc),!
    	return sc
	}

    if server = ""
    {
        write "Create new OAuth2.Server.Configuration: "

        set server = ##class(OAuth2.Server.Configuration).%New()
    }
    else
    {
        write "Update existing OAuth2.Server.Configuration: "
    }
	
	set server.Description = description
	set server.IssuerEndpoint.Host = issuerEndpointHost
	set server.AuthenticateClass = authenticateClass
	set server.CustomizationNamespace = namespace
	set server.CustomizationRoles = customizationRoles
	set server.SupportSession = supportSession
	set server.AllowPublicClientRefresh = allowPublicClientRefresh
	set server.ReturnRefreshToken = returnRefreshToken
	set server.SupportedGrantTypes = supportedGrantTypes
	set server.AccessTokenInterval = accessTokenInterval
	set server.AuthorizationCodeInterval = authorizationCodeInterval
	set server.RefreshTokenInterval = refreshTokenInterval
	set server.SessionInterval = sessionInterval
	set server.ClientSecretInterval = clientSecretInterval

    #dim iterator As %Iterator.Object = supportedScopes.%GetIterator()

    while iterator.%GetNext(.scope, .scopeDescription)
    {
    	do server.SupportedScopes.SetAt(scopeDescription, scope)
    }

	set server.DefaultScope = defaultScope
	set server.AllowUnsupportedScope = allowUnsupportedScopes
	
	set sc = server.%Save()

    if $$$ISERR(sc)
	{
		write "failed: ",$System.Status.GetErrorText(sc),!
	}
    else
    {
        write "done."
    }

	return sc
}

}
