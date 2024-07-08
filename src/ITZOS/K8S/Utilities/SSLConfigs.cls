/// SSL Config Creation based on after-install.json
Class ITZOS.K8S.Utilities.SSLConfigs Extends PathHelper
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "sslconfigs";

/// Requires whole config
Parameter AfterInstallMode = "all";

/// Test the functionality
ClassMethod Test()
{
	do ..Load({
		"sslconfigs": {
			"certificatespath": "/home/irisowner/certificates",
			"configs": [
					{
						"name": "Ons Altrecht-dev",
						"cert": "ONS-nedap-dev.pem",
						"key": "ONS-nedap-dev.key"
					}
				]
			}
		}
	)
}

/// Test the new layoutfunctionality
ClassMethod TestNew()
{
	do ..Load(
		{
		"certificatespath": "/home/irisowner/certjes",
		"sslconfigs": {
			"Ons Altrecht-dev": {
				"cert": "ONS-nedap-dev.pem",
				"key": "ONS-nedap-dev.key"
			},
			"Ons Altrecht-staging": {
				"cert": "ONS-nedap-staging.cer",
				"key": "ONS-nedap-staging.key"
			},
			"Ons Altrecht-productie": {
				"cert": "ONS-nedap-productie.pem",
				"key": "ONS-nedap-productie.key"
			},
			"VektisAGBRegister": {
				"cert": "vecozo.crt",
				"key": "vecozo.key"
			}
		}
		}
	)
}

/// Load SSLConfigs from after-install.json
/// Newest structure with global certificatespath
ClassMethod Load(config As %DynamicObject)
{
	#dim sslconfigs As %DynamicObject = config.%Get(..#AfterInstallNode)
	set certificatespath = config.certificatespath

	if sslconfigs.certificatespath '= "" /// Overwrite with local setting!
	{
		set certificatespath = sslconfigs.certificatespath
	}

	if certificatespath = ""
	{
		write "Using certificatespath ",certificatespath,!
	}
	else
	{
		write "Warning: No setting certificatespath found within ",..#AfterInstallNode," or root",!
	}

	if $ISOBJECT(sslconfigs.configs)
	{
		set sslconfigs = sslconfigs.configs
	}

	#dim iterator As %Iterator.Object = sslconfigs.%GetIterator()
	#dim sslconfig As %DynamicObject

	while iterator.%GetNext(.name, .sslconfig)
	{
		if name = "certificatespath"
		{
			continue
		}

		if (name = +name) // Old format has an array where the name is a separate property
		{
			set name = sslconfig.name
		}

        write "Loading SSLconfig name: ",name,!

		; Certificate files must be specified pathless
		set certPath = ..JoinPath(certificatespath, sslconfig.cert)

		; If the certificate file doesn't exist, skip it if so configured
		if '##class(%File).Exists(certPath)
		{
	        write "No certificate found at '",certPath,"', skipped",!
			continue
		}
		
		set keyPath = ..JoinPath(certificatespath, sslconfig.key)
		set caPath = ..JoinPath(certificatespath, sslconfig.capath)
		do ..CreateSSLConfig(name, certPath, keyPath, caPath, sslconfig.cipherList)
	}
}

/// Create the SSL configuration
ClassMethod CreateSSLConfig(name As %String, certPath As %String = "", keyPath As %String = "", caPath As %String = "", cipherList As %String = "") As %Status
{
	new $Namespace
	set $Namespace = "%SYS"
		
	set props("CertificateFile") = certPath
	set props("PrivateKeyFile") = keyPath
	set props("CAFile") = caPath

	if (cipherList '= "")
	{
	    set props("CipherList") = cipherList
	}
	
	if '##class(Security.SSLConfigs).Exists(name)
	{
		set sc = ##class(Security.SSLConfigs).Create(name, .props)
	}
	else
	{
		set sc = ##class(Security.SSLConfigs).Modify(name, .props)
	}

	if $$$ISERR(sc)
	{
		write "Failed to load SSL Config ",name,": ",$SYSTEM.Status.GetErrorText(sc),!
	}

	return sc
}

}
