/// Get the Backup History going back to the last full backup
Class ITZOS.K8S.Utilities.BackupHistory Extends (%SerialObject, %JSON.Adaptor)
{

/// When was this backup created
/// Formatted using $ZDATETIME(3, 7), e.g. 2024-10-23T12:39:02Z
Property DateTime As %String(%JSONFIELDNAME = "datetime");

/// Age of the backup in days
Property AgeInDays As %Numeric(%JSONFIELDNAME = "age") [ Calculated, Transient ];

Method AgeInDaysGet() As %Numeric
{
    set now = $ZDATETIME($HOROLOG, -2)
    set past = $ZDATETIME($ZDATETIMEH(..DateTime, 3, 7), -2)

    #; w "; now: ",now,"; past: ",past," "
    return $JUSTIFY((now - past) / (60 * 60 * 24), 1, 1)
}

/// TYPE=Cumulative Incremental
/// Type of backup which will be performed.
/// VALUELIST = "/full/incremental/cumulative"
Property Type As %String(%JSONFIELDNAME = "butype");

/// STATUS=Completed
/// Status of the backup (Completed, Warning)
Property Status As %String(%JSONFIELDNAME = "status");

/// LOG=/irissys/data/IRIS/mgr/Backup/CumuIncrDBList_20240905_001.log
/// LogFile that was created, usefull when the Status '= Completed
Property LogFile As %String(%JSONFIELDNAME = "logfile", MAXLEN = "");

/// Status of the LogFile
Property LogFileStatus As %String(%JSONFIELDNAME = "logfile-status") [ Calculated, Transient ];

Method LogFileStatusGet() As %String
{
    return ..FileStatus(..LogFile)
}

/// DEVICE=/irissys/backups/CumuIncrDBList_20240905_001.cbk
/// Backup File that was created
Property BackupFile As %String(%JSONFIELDNAME = "backupfile", MAXLEN = "");

/// Status of the BackupFile
Property BackupFileStatus As %String(%JSONFIELDNAME = "backupfile-status") [ Calculated, Transient ];

Method BackupFileStatusGet() As %String
{
    return ..FileStatus(..BackupFile)
}

/// JOURNAL=/irissys/journal1/20240905.001
/// Journal file that was used as the basis for the backup
Property JournalFile As %String(%JSONFIELDNAME = "journalfile", MAXLEN = "");

/// Status of the JournalFile
Property JournalFileStatus As %String(%JSONFIELDNAME = "journalfile-status") [ Calculated, Transient ];

Method JournalFileStatusGet() As %String
{
    return ..FileStatus(..JournalFile)
}

/// LIST=List
/// which database(s) are in this backup?
/// Value "List" referes to the list that can be retrieved via ##class(AODBackup.DBList).Get()
Property List As %String(%JSONINCLUDE = "NONE", MAXLEN = "");

/// WIJINFO=4318488,/irissys/journal1/20240905.001,30,30,4277932,65794,4318004,30
/// Write Image Journal Information
Property WIJInformation As %String(%JSONINCLUDE = "NONE", MAXLEN = "");

/// Get File Status as string (compressed/present/absent
ClassMethod FileStatus(filename As %String) As %String
{
    #; return ##class(%File).GetFileSize(file)

    if ##class(%File).Exists(filename)
    {
        return "present"
    }

    if ##class(%File).Exists(filename _ ".gz")
    {
        return "compressed"
    }

    return "absent"
}

/// Get the Latest Full backup
/// A part of that information can also be fetched via ##class(Backup.General).GetLastFullBackupInfo()
/// However, that returns an incomplete set of information, hence we have re-implemented it based on the more detailed information available from the registry
ClassMethod GetLatestFullBackup() As ITZOS.K8S.Utilities.BackupHistory
{
    #dim record As ITZOS.K8S.Utilities.BackupHistory = ..GetLatestBackup(.qhandle)

    while $ISOBJECT(record) && (record.Type '= "Full")
    {
        set record = ..GetPreviousBackup(.qhandle)
    }

    return record
}

/// Show all backups based on ^SYS("BUHISTORY")
/// This in order to:
/// - Include the backup file name
/// - Include a proper date time
ClassMethod ShowAll()
{
    #dim record As ITZOS.K8S.Utilities.BackupHistory = ..GetLatestBackup(.qhandle)

    while record '= ""
    {
        w "Backup at ",record.DateTime,": ",record.Type,",",record.BackupFile,",",record.LogFile,",",record.Status,"; age=",record.AgeInDays,!

        set record = ..GetPreviousBackup(.qhandle)
    }
}

/// Get a list of all backups based on ^SYS("BUHISTORY")
ClassMethod GetPage(maxage As %Integer = "") As %DynamicArray
{
    #dim record As ITZOS.K8S.Utilities.BackupHistory = ..GetLatestBackup(.qhandle)

    #dim backups as %DynamicArray = []

    while record '= ""
    {
        if (+maxage = maxage) && (record.AgeInDays > maxage)
        {
            quit
        }

        do record.%JSONExportToString(.json)
        do backups.%Push({}.%FromJSON(json))

        set record = ..GetPreviousBackup(.qhandle)
    }

    return backups
}

/// Get the Latesst backup, used right after that backup has run to know the name of backup file that was created.
ClassMethod GetLatestBackup(ByRef qhandle As %String = "") As ITZOS.K8S.Utilities.BackupHistory
{
	new $Namespace
	set $Namespace = "%SYS"
    set t = $ORDER(^SYS("BUHISTORY",0))

    while t '= ""
    {
        set qhandle = t
        set t = $ORDER(^SYS("BUHISTORY",0,"LOGNOTPURGED",t))
    }

    return ..FetchProperties(qhandle)
}

/// Get Previous Backup basd on the QHandle
ClassMethod GetPreviousBackup(ByRef qhandle As %String) As ITZOS.K8S.Utilities.BackupHistory
{
	new $Namespace
	set $Namespace = "%SYS"
    set qhandle = $ORDER(^SYS("BUHISTORY",0,"LOGNOTPURGED", qhandle), -1)

    return ..FetchProperties(qhandle)
}

/// Fetch a single Backup History record from the regstry
ClassMethod FetchProperties(qhandle As %String) As ITZOS.K8S.Utilities.BackupHistory
{
    if (qhandle = "")
    {
        return ""
    }

    set record = ..%New()

    // qhandle has a $H value in which the comma has been replaced wuth a 0-digit.
    // e.g. 67081024900 ==> 67081,24900
    set record.DateTime = $ZDATETIME($EXTRACT(qhandle,1,5) _ "," _ $EXTRACT(qhandle,7,11), 3, 7)

    // DESC=Cumulative and Incremental backup of all databases that are in the backup database list.
    // DEVICE=/irissys/backups/CumuIncrDBList_20240905_001.cbk
    // JOURNAL=/irissys/journal1/20240905.001
    // LIST=List
    // LOG=/irissys/data/IRIS/mgr/Backup/CumuIncrDBList_20240905_001.log
    // STATUS=Completed
    // TYPE=Cumulative Incremental
    // WIJINFO=4318488,/irissys/journal1/20240905.001,30,30,4277932,65794,4318004,30

    set record.Type = $ZCONVERT($PIECE(^SYS("BUHISTORY", qhandle, "TYPE"), " ", 1), "l")
    set record.Status = $ZCONVERT(^SYS("BUHISTORY", qhandle, "STATUS"), "l")
    set record.LogFile = ^SYS("BUHISTORY", qhandle, "LOG")
    set record.BackupFile = ^SYS("BUHISTORY", qhandle, "DEVICE")
    set record.JournalFile = ^SYS("BUHISTORY", qhandle, "JOURNAL")
    set record.List = ^SYS("BUHISTORY", qhandle, "LIST")
    set record.WIJInformation = ^SYS("BUHISTORY", qhandle, "WIJINFO")

    return record
}

/// Show all backups based on Custom Class query History
/// The output is identical to http://xxx/csp/sys/op/UtilSysBackupLogs.csp?Recent=1
/// Unfortunately, the backup file itself is not listed in the output
ClassMethod ShowAllOld()
{
    set sc = ##class(Backup.Task).HistoryExecute(.qhandle)

    if $$$ISERR(sc)
    {
        write "Error ",$SYSTEM.Status.GetErrorText(sc),!
        return
    }


    while 1
    {
        set sc = ##class(Backup.Task).HistoryFetch(.qhandle, .row, .atEnd)

        if $$$ISERR(sc)
        {
            write "Error ",$SYSTEM.Status.GetErrorText(sc),!
            return
        }

        if (atEnd)
        {
            return
        }

        Write $LTS(row),!
    }
}

Storage Default
{
<Data name="HistoryState">
<Value name="1">
<Value>DateTime</Value>
</Value>
<Value name="2">
<Value>Type</Value>
</Value>
<Value name="3">
<Value>Status</Value>
</Value>
<Value name="4">
<Value>BackupFile</Value>
</Value>
<Value name="5">
<Value>JournalFile</Value>
</Value>
<Value name="6">
<Value>List</Value>
</Value>
<Value name="7">
<Value>LogFile</Value>
</Value>
<Value name="8">
<Value>WIJInformation</Value>
</Value>
</Data>
<State>HistoryState</State>
<StreamLocation>^ITZOS.K8S.Utilities.BackupHistoryS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
