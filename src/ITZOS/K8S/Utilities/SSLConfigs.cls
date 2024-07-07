/// SSL Config Creation based on after-install.json
Class ITZOS.K8S.Utilities.SSLConfigs Extends PathHelper
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "sslconfigs";

/// Load SSLConfigs from after-install.json
/// New structure with certificatespath inside sslconfigs
ClassMethod Load(sslconfigs As %DynamicObject)
{
	#dim iterator As %Iterator.Object = sslconfigs.configs.%GetIterator()
	#dim sslconfig As %DynamicObject

	while iterator.%GetNext(.key, .sslconfig)
	{
        write "Loading SSLconfig name: ",sslconfig.name,!

		; Certificate files must be specified pathless
		set certPath = ..JoinPath(sslconfigs.certificatespath, sslconfig.cert)

		; If the certificate file doesn't exist, skip it if so configured
		if '##class(%File).Exists(certPath)
		{
	        write "No certificate found at '",certPath,"', skipped",!
			continue
		}
		
		set keyPath = ..JoinPath(sslconfigs.certificatespath, sslconfig.key)
		set caPath = ..JoinPath(sslconfigs.certificatespath, sslconfig.capath)
		do ..CreateSSLConfig(sslconfig.name, certPath, keyPath, caPath, sslconfig.cipherList)
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
