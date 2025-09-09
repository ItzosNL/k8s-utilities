/// X509Credentials Creation based on after-install.json
Class ITZOS.K8S.Utilities.X509Credentials Extends PathHelper
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "x509Credentials";

/// Requires whole config
Parameter AfterInstallMode = "all";

/// Test the functionality
ClassMethod Test()
{
	do ..Load({
        "certificatespath": "/home/irisowner/certificates",
		"x509Credentials": [
			{
			"name": "LAB24",
			"cert": "ONS-nedap-staging.cer",
			"key": "ONS-nedap-staging.key"
			},
			{
			"name": "code24_acc",
			"cert": "code24.cer"
			}
		]
	  }
	)
}

/// Load X509Credentials from after-install.json
ClassMethod Load(config As %DynamicObject)
{
	set certificatespath = config.certificatespath
	#dim iterator As %Iterator.Object = config.x509Credentials.%GetIterator()
	#dim x509Credential As %DynamicObject

	while iterator.%GetNext(.key, .x509Credential)
	{
        write "Loading X509Credential name: ",x509Credential.name,!

		; Certificate files must be specified pathless
		set certPath = ..JoinPath(certificatespath, x509Credential.cert)

		; If the certificate file doesn't exist, skip it if so configured
		if '##class(%File).Exists(certPath)
		{
	        write "No certificate found at '",certPath,"', skipped",!
			continue
		}
		
		set keyPath = ..JoinPath(certificatespath, x509Credential.key)
		set caPath = ..JoinPath(certificatespath, x509Credential.capath)

		do ..CreateX509Credentials(x509Credential.name, certPath, keyPath, caPath)
	}
}

/// Directly creates X509 credentials
ClassMethod CreateX509Credentials(name As %String, certPath As %String = "", keyPath As %String = "", caPath As %String = "") As %Status
{
	new $Namespace
	set $Namespace = "%SYS"
		
	If ##class(%SYS.X509Credentials).%ExistsId(name)
	{
		; Don't modify existing credentials
		return $$$OK
	}
	
	set credential = ##class(%SYS.X509Credentials).%New()
	set credential.Alias = name
	
	set sc = credential.LoadCertificate(certPath)

	if $$$ISERR(sc)
	{
		write "Failed to load certificate from ",certPath,": ",$SYSTEM.Status.GetErrorText(sc),!
		return sc
	}

	if keyPath '= ""
	{
		set sc = credential.LoadPrivateKey(keyPath)

		if $$$ISERR(sc)
		{
			write "Failed to load private key from ",certPath,": ",$SYSTEM.Status.GetErrorText(sc),!
			return sc
		}
	}
	
	set credential.CAFile = caPath
	
	set sc = credential.%Save()

	if $$$ISERR(sc)
	{
		write "Failed to save X509Credential ",name,": ",$SYSTEM.Status.GetErrorText(sc),!
	}

	return sc
}

/// List x509 certificates with their expiry date
ClassMethod ListCertificates(expireInDays As %Integer = "")
{
	set query = 0
	set args = 0
	// IssuerDN, SubjectDN, 
	set query($Increment(query)) = "SELECT ID, Alias, ValidityNotBefore, ValidityNotAfter, DATEDIFF(D,CURRENT_TIMESTAMP,ValidityNotAfter) as daysValid FROM %SYS.X509Credentials"

	if expireInDays '= ""
	{
		set query($Increment(query)) = "WHERE DATEDIFF(D,CURRENT_TIMESTAMP,ValidityNotAfter) <= ?"
		set args($Increment(args)) = expireInDays
	}

    set result = ##class(%SQL.Statement).%ExecDirect(, .query, args...)

    if result.%SQLCODE < 0
    {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
    }

	set count = 0
	set spaces = "               "

    while result.%Next()
    {
		if count = 0
		{
			write "ID          Alias       ValidityNotBefore   ValidityNotAfter    daysValid",!
		}

		write result.ID,$EXTRACT(spaces, 1, 12 - $LENGTH(result.ID)),result.Alias,$EXTRACT(spaces, 1, 12 - $LENGTH(result.Alias)),result.ValidityNotBefore," ",result.ValidityNotAfter," ",result.daysValid,!
		set count = count + 1
	}
}

}
