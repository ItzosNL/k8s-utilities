Include (%occStatus, %occErrors)

/// Stored procedure to pull expiry dates from the SSL Certficate
/// Uitvoeren als:
/// 
///    SELECT * FROM ITZOS_K8S_Utilities.SSLConfigExpiry()
/// 
Class ITZOS.K8S.Utilities.SSLConfigExpiry [ Abstract, Not ProcedureBlock ]
{

Query List() As %Library.Query(CONTAINID = "ID", ROWSPEC = "ID,SerialNumber,IssuerDN,SubjectDN,ValidityNotBefore:%String,ValidityNotAfter:%String,DaysValid:%Integer", SELECTMODE = "ODBC") [ SqlName = SSLConfigExpiry, SqlProc ]
{
}

/// Get a list of SSL Configs with their expiry date based on the certificate
/// This is the Execute section for the %Library.Query. All of the query logic will be performed here.
/// A new node for the ^CacheTemp global will be created and each subscript of this global will contain a row for the report.
ClassMethod ListExecute(ByRef queryHandle As %Library.Binary) As %Library.Status
{
	set sc = $$$OK
	set repid = $INCREMENT(^||CacheTemp("SSLExpiry"))

	try
    {
        #dim result as %SQL.StatementResult = ..GetSSLConfigs()

        while result.%Next()
        {
            set x509 = ##class(%SYS.X509Credentials).%New()
            set sc = x509.LoadCertificate(result.CertificateFile)

            if $$$ISERR(sc)
            {
                continue
            }

            set daysValid = ##class(%SYSTEM.SQL.Functions).DATEDIFF("D", $ZDATETIME($H, 3, 1), x509.ValidityNotAfter)

            set ^||CacheTemp("SSLExpiry", repid, result.ID) = $LISTBUILD(result.ID, x509.SerialNumber,x509.IssuerDN,x509.SubjectDN,x509.ValidityNotBefore,x509.ValidityNotAfter,daysValid)
        }   

		set queryHandle = $LISTBUILD(0, repid, 0)
	} 
    catch (ex)
    {
		set sc = ex.AsStatus()
	}
	
	return sc
}

/// Get SSLConfigs from %SYS namespace
ClassMethod GetSSLConfigs() As %SQL.StatementResult
{
    new $Namespace
    set $Namespace = "%SYS"
        
    set result = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, CertificateFile FROM Security.SSLConfigs WHERE CertificateFile is not null")

    if result.%SQLCODE < 0
    {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(result.%SQLCODE,result.%Message)
    }

    return result
}

/// This fetch method should never have to change. 
ClassMethod ListFetch(ByRef queryHandle As %Library.Binary, ByRef row As %Library.List, ByRef AtEnd As %Library.Integer = 0) As %Library.Status
{
    // Restore queryHandle
    New repid,ind

    set AtEnd = $LIST(queryHandle, 1)
    set repid = $LIST(queryHandle, 2)
    set ind = $LIST(queryHandle, 3)
    set ind = $ORDER(^||CacheTemp("SSLExpiry", repid, ind))

    if ind = ""
    {	// if there are no more rows, finish fetching
        set AtEnd = 1
        set row = ""
    }
    else
    {	// fetch row
        set row = ^||CacheTemp("SSLExpiry", repid, ind)
    }

    // Save queryHandle
    set queryHandle = $LISTBUILD(AtEnd, repid, ind)
    return $$$OK
}

/// <br>This is the Close component of the %Library.Query.
/// <br>This is standard code and should never have to change.
/// <br>This is where all the cleanup is performed, i.e. the purging of the temporary storage global ^CacheTemp.
ClassMethod ListClose(queryHandle As %Library.Binary) As %Library.Status
{
	// Clean up by purging the temporary node in ^CacheTemp global
    new repid
    set repid = $LIST(queryHandle, 2)

    kill ^||CacheTemp("SSLExpiry", repid)

    return $$$OK
}

}
