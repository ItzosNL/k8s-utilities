/// Retrieve latest release from Github 
Class ITZOS.K8S.Utilities.Github
{

/// Load specified release of the specified package from a tarball (tar.gz) location like
///      https://api.github.com/repos/ItzosNL/k8s-utilities/tarball/1.0.0.009
ClassMethod LoadRelease(ownerAndRepo As %String = "ItzosNL/k8s-utilities", tag As %String = "latest") As %Status
{
    if tag = "latest"
    {
        set sc = ##class(ITZOS.K8S.Utilities.Github).GetLatestReleaseDescription(ownerAndRepo, .latest)

        if $$$ISERR(sc)
        {
            return sc
        }

        set tag = latest."tag_name"
    }

    write "Retrieving release ",tag," from https://api.github.com/repos/",ownerAndRepo,":",!

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
        return sc
    }

	return sc
}

/// Get a description of the latest release for the specified package
/// e.g. "https://api.github.com/repos/ItzosNL/k8s-utilities/releases/latest"
ClassMethod GetLatestReleaseDescription(ownerAndRepo As %String = "ItzosNL/k8s-utilities", Output latest As %DynamicObject) As %Status
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
