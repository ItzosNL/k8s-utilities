/// Retrieve packages from Github 
Class ITZOS.K8S.Utilities.Github
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "packages";

/// Gitub root
Parameter GithubRoot = "https://api.github.com/repos/";

/// Test packages only
/// It is better to test via ##class(ITZOS.K8S.Utilities.BackupConfig).Test()
ClassMethod Test()
{
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
      "packages": {
          "AODBackup": {
              "namespace": "AODBackup",
              "owner": "ItzosNL",
              "repo": "k8s-archiveonline-backup",
              "config": {
                "folder": "altrecht-o"
              }
            }
        }
	})
}

/// Load packages config
ClassMethod Load(packages As %DynamicObject)
{
	#dim iterator As %Iterator.Object = packages.%GetIterator()
	#dim properties As %DynamicObject

	while iterator.%GetNext(.package, .properties)
	{       
		do ..LoadPackage(package, properties) //, properties.owner, properties.repo)
	}
}

/// Load specified package release from a tarball (tar.gz) location like and execute LoadConfig() method
ClassMethod LoadPackage(packageName As %String, properties As %DynamicObject) As %Status
{
    set ownerAndRepo = properties.owner _ "/" _ properties.repo
    write "Loading package ",packageName," from ",..#GithubRoot,ownerAndRepo

    if properties.namespace '= "" // Namespace has been specified, load into that namespace
    {
        write " into namespace ",properties.namespace,": ",!

    	do ##class(ITZOS.K8S.Utilities.Namespace).Create(properties.namespace)

        // Now switch to specified namespace
        new $NAMESPACE
        set $NAMESPACE = properties.namespace
    }
    else
    {
        write ": ",!
    }

    set currentVersion = ..GetCurrentVersion(packageName) // Get current version
    set sc = ..GetLatestReleaseDescription(ownerAndRepo, .latestRelease)

    if $$$ISERR(sc)
    {
        return sc
    }

    set latest = latestRelease."tag_name"

    write "Current version is '",currentVersion,"'; latest version is '",latest,"'",!

    if latest '= currentVersion
    {
        set sc = ..LoadRelease(ownerAndRepo, latest)
    }
    else
    {
        write "Latest package version already installed, skipped",!
    }

    if $$$ISOK(sc)
    {
        set sc = ..ExecuteLoadConfig(packageName, properties)
    }

    return sc
}

///  execute load config method
ClassMethod ExecuteLoadConfig(packageName As %String, properties As %DynamicObject) As %Status
{
    set classname = packageName _ ".Manifest"
    set methodname = "LoadConfig"
	set compMethod = ##class(%Dictionary.CompiledMethod).%OpenId(classname _ "||" _ methodname)
	
    if (compMethod '= "")
    {
        kill compMethod

        // Now execute the LoacConfig method for this package
        do $CLASSMETHOD(classname, methodname, properties)
    }
    
    return $$$OK
}

/// Load specified release of the specified package from a tarball (tar.gz) location like
///      https://api.github.com/repos/ItzosNL/k8s-utilities/tarball/1.0.0.009
ClassMethod LoadRelease(ownerAndRepo As %String, tag As %String) As %Status
{
    write "Retrieving release ",tag," from ",..#GithubRoot,ownerAndRepo,":",!

    set sc = ..PerformHttpRequest("/repos/" _ ownerAndRepo _ "/tarball/" _ tag, .response)

    if $$$ISOK(sc)
    {
        #dim response As %Net.HttpResponse
        set tarball = ##class(%Stream.FileBinary).%New()
        set tarball.Filename = tarball.NewFileName("tar.gz", "/tmp")
        write "Saving release ",tarball.Filename,":",!
        do tarball.CopyFrom(response.Data)
        do tarball.Rewind()

        set sc = ..LoadSrcFolderFromTarBall(tarball.Filename)
    }

    return sc
}

/// Get current package version from the Manifest
ClassMethod GetCurrentVersion(packageName As %String) As %String
{
	try
	{
		return $PARAMETER(packageName _ ".Manifest", "VERSION")
	}
	catch ex
	{
		return ""
	}
}

/// Load the Src folder from the tarball
ClassMethod LoadSrcFolderFromTarBall(filename As %String, isGzip As %Boolean = 1) As %Status
{
    #dim extracted As ITZOS.K8S.Utilities.FileBinaryTar = ##class(ITZOS.K8S.Utilities.FileBinaryTar).ExtractFile(filename, isGzip)
    #dim rootfolder As ITZOS.K8S.Utilities.FileBinaryTar = extracted.GetNext("")
    #dim srcFolder as ITZOS.K8S.Utilities.FileBinaryTar

    write "Loading release from ",filename,":",!
    set sc = extracted.FindPath(rootfolder.name _ "src", .srcFolder)

    if $$$ISERR(sc)
    {
        write "Failed to find 'src' folder: ",$System.Status.GetErrorText(sc),!
        return sc
    }

    write "Extract to /tmp: ",!
    set sc = srcFolder.ExtractTo("/tmp")

    if $$$ISERR(sc)
    {
        write "Failed to extract src folder to /tmp: ",$System.Status.GetErrorText(sc),!
        return sc
    }

    set folder = "/tmp/" _ rootfolder.name _ "src"
    write "Import folder '",folder,"': ",!
    set sc = $System.OBJ.ImportDir(folder, "*", "ck", , 1)

    if $$$ISERR(sc)
    {
        write "Failed to import folder ",folder,": ",$System.Status.GetErrorText(sc),!
    }

	return sc
}

/// Get a description of the latest release for the specified package
/// e.g. "https://api.github.com/repos/ItzosNL/k8s-utilities/releases/latest"
ClassMethod GetLatestReleaseDescription(ownerAndRepo As %String, Output latest As %DynamicObject) As %Status
{
    write "Finding latest release for ",ownerAndRepo,":",!

    set sc = ..PerformHttpRequest("/repos/" _ ownerAndRepo _ "/releases/latest", .response)

    if $$$ISOK(sc)
    {
        try
        {
            #dim response As %Net.HttpResponse
            set latest = ##class(%DynamicObject).%FromJSON(response.Data)
        }
        catch ex
        {
            set sc = ex.AsStatus()
            write "Exception when parsing reponse json: ",$System.Status.GetErrorText(sc),!
        }
    }

    return sc
}

/// Initialize and execute an HTTP request
ClassMethod PerformHttpRequest(location As %String, response As %Net.HttpResponse) As %Status
{
    set httpRequest = ##class(%Net.HttpRequest).%New()
    set httpRequest.Server = "api.github.com"
    set httpRequest.SSLConfiguration = "Default"

    set sc = httpRequest.Get(location)

    if $$$ISERR(sc)
    {
        write "Failed to open location https://",httpRequest.Server,location,": ",$System.Status.GetErrorText(sc),!
    }
    else
    {
        set response = httpRequest.HttpResponse
    }

    return sc
}

}
