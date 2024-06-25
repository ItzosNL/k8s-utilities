/// SSL Config Creation based on after-install.json
Class ITZOS.K8S.Utilities.SSLConfigs
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
		set sc = ..CreateSSLConfig(sslconfig.name, certPath, keyPath, caPath)

		if $$$ISERR(sc)
		{
			write "Failed to load SSL Config ",sslconfig.name,": ",$SYSTEM.Status.GetErrorText(sc),!
		}
	}
}

/// Create the SSL configuration
ClassMethod CreateSSLConfig(name As %String, certPath As %String = "", keyPath As %String = "", caPath As %String = "") As %Status
{
	new $Namespace
	set $Namespace = "%SYS"
		
	set props("CertificateFile") = certPath
	set props("PrivateKeyFile") = keyPath
	set props("CAFile") = caPath
    set props("CipherList") = "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384"
	
	if '##class(Security.SSLConfigs).Exists(name)
	{
		set sc = ##class(Security.SSLConfigs).Create(name, .props)
	}
	else
	{
		set sc = ##class(Security.SSLConfigs).Modify(name, .props)
	}

	return sc
}

/// Creates the SSL configurations specified in the configuration file, if any.
/// Joins multiple parts of a filesystem path with the separator that is appropriate for the current operating system.
/// We don't use %File:SubDirectoryName because it normalizes to a full path, which we may not want.
ClassMethod JoinPath(parts... As %String) As %String
{
	if parts(2) = ""
	{
		return ""
	}

	; Determine separator to use. Only caters for Windows and
	; Unix-like operating systems.
	set separator = $Select($$$isWINDOWS: "\", 1: "/")
	set path = parts(1)

	for i = 2:1:parts
	{
		set part = $Get(parts(i))
		
		if $Extract(path, *) '= separator
		{
			set path = path _ separator
		}

		set path = path _ part
	}
	
	return path
}

}
