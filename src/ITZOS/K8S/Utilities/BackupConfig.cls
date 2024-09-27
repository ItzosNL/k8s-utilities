Include %occOptions

/// Create BackupConfig based on after-install.json
Class ITZOS.K8S.Utilities.BackupConfig
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "backup-config";

/// Test
ClassMethod Test()
{
	#; "databases" : ["USER","IRISLIB","ALTRECHT_DATA"],
	do ..Load({
        "databases" : ["USER","ALTRECHT_DATA"],
		"useArchiveOnDemand": true,
		"email": {
          "emailOnCompletion": "theo.stolker@intersystems.com",
          "emailOnError": "theo.stolker@intersystems.com",
          "openOutputFile": true,
          "emailOutput": true
        },	
        "fullBackup": {
          "name": "Itzos Weekly",
          "folder": "/irissys/backups",
          "type": "full",
          "schema": {
              "type": "On Demand",
              "day": "mo",
              "time": "00:00:00"
          }
        },	
        "cumulativeBackup": {
          "name": "Itzos Daily",
          "folder": "/irissys/backups",
          "type": "Cumulative",
          "schema": {
              "type": "On Demand",
              "day": "tu,we,th,fr,sa,su",
              "time": "00:00:00"
          }
        }
      })
}

/// Load Backup config
ClassMethod Load(backupconfig As %DynamicObject)
{
	do ..AddDatabases(backupconfig.databases)
	do ..UpdateSystemTasks("FullDBList", backupconfig.fullBackup.folder)
	do ..UpdateSystemTasks("CumuIncrDBList", backupconfig.cumulativeBackup.folder)
	do ..CreateTaskSchedule(backupconfig.fullBackup, backupconfig.useArchiveOnDemand, backupconfig.email)
	do ..CreateTaskSchedule(backupconfig.cumulativeBackup, backupconfig.useArchiveOnDemand, backupconfig.email)
}

/// Add databases
ClassMethod AddDatabases(databases As %DynamicArray)
{
	new $Namespace
	set $Namespace = "%SYS"

	do ##class(Backup.General).ClearDatabaseList()

	for index = 0:1:databases.%Size() - 1
	{
		set database = databases.%Get(index)
		set sc = ##class(Backup.General).AddDatabaseToList(database)
	
		if $$$ISERR(sc)
		{
			write "Failed to add database '",database,"' to the backup list: ",$SYSTEM.Status.GetErrorText(sc),!
		}
		else
		{
			write "Database '",database,"' has been added to the backup list",!
		}
	}
}

/// Create Task Schedule
ClassMethod CreateTaskSchedule(backup As %DynamicObject, useArchiveOnDemand As %Boolean, email As %DynamicObject) As %Status
{
	write "Task schedule for ",backup.name

	if useArchiveOnDemand
	{
		write " using ArchiveOnDemand"
		set namespace = $NAMESPACE

		if $ZCONVERT(backup.type, "l") = "full"
		{
			set taskClass = "AODBackup.Full"
		}
		else
		{
			set taskClass = "AODBackup.Cumulative"
		}
	}
	else
	{
		set namespace = "%SYS"

		; System defined task classes
		if $ZCONVERT(backup.type, "l") = "full"
		{
			set taskClass = "%SYS.Task.BackupFullDatabaseList"
		}
		else
		{
			set taskClass = "%SYS.Task.BackupCumulativeDatabaseList"
		}
	}

	write ":",!

	return ##class(ITZOS.K8S.Utilities.ScheduledTasks).CreateOrUpdateTaskSchedule(backup.name, "Create a " _ backup.type _ " backup", taskClass, { "Device": (backup.folder) }, backup.schema.type, backup.schema.time, backup.schema.day, namespace, email)
}

/// Update the specified standard Backup Task with the proper folder (property Device)
ClassMethod UpdateSystemTasks(name As %String, folder As %String) As %Status
{
	new $Namespace
	set $Namespace = "%SYS"

	set task = ##class(Backup.Task).%OpenId(name)
	set task.Device = folder
	write name," -> ",task.Device,!

	set sc = task.%Save()

	if $$$ISERR(sc)
	{
		write "Failed to update Device for System Backup task ",name,": ",$SYSTEM.Status.GetErrorText(sc),!
	}

	return sc
}

}
