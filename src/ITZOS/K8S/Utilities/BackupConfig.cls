Include %occOptions

/// Create BackupConfig based on after-install.json
Class ITZOS.K8S.Utilities.BackupConfig
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "backup-config";

/// We want to process the whole config, to see if the "AODBackup" package has been loaded, and if so, get its namespace
Parameter AfterInstallMode = "all";

/// Test
ClassMethod Test()
{
	#; Adding "IRISLIB" as database will cause a warning in th backup because it is a readonly database
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
		"packages": {
			"AODBackup": {
			  "namespace": "AODBackup",
			  "owner": "ItzosNL",
			  "repo": "k8s-archiveonline-backup",
			  "config": {
				"bucket": "ehealth-iris-bu",
				"folder": "mmlogging-o/",
				"access-key": "ZWhlYWx0aC1pcmlzLWJ1",
				"access-secret": "mkls-aodbackup"
				}
			}
		},
		"backup-config": {
          	"databases" : [
			    "MMLOGGING_DATA"
			],
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
					"type": "Weekly",
					"day": "tu",
					"time": "06:00:00"
				}
			},	
			"cumulativeBackup": {
				"name": "Itzos Daily",
				"folder": "/irissys/backups",
				"type": "Cumulative",
				"schema": {
					"type": "Weekly",
					"day": "mo,we,th,fr",
					"time": "06:00:00"
				}
			}
		}
	})
}

/// Load Backup config
ClassMethod Load(config As %DynamicObject)
{
	set backupconfig = config."backup-config"

	do ..AddDatabases(backupconfig.databases)
	do ..UpdateSystemTasks("FullDBList", backupconfig.fullBackup.folder)
	do ..UpdateSystemTasks("CumuIncrDBList", backupconfig.cumulativeBackup.folder)

	// Do we need to use ArchivingOnDemand? If so, in what namespace do we run the backup?

	set AODBackup = config.packages.AODBackup

	if $ISOBJECT(AODBackup)
	{
		set useArchiveOnDemand = 1
		set namespace = AODBackup.namespace

		if (namespace = "")
		{
			set namespace = $NAMESPACE // Use current namespace
		}
	}
	else
	{
		set useArchiveOnDemand = 0
		set namespace = "%SYS"
	}

	do ..CreateTaskSchedule(backupconfig.fullBackup, useArchiveOnDemand, namespace, backupconfig.email)
	do ..CreateTaskSchedule(backupconfig.cumulativeBackup, useArchiveOnDemand, namespace, backupconfig.email)
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
ClassMethod CreateTaskSchedule(backup As %DynamicObject, useArchiveOnDemand As %Boolean, namespace As %String, email As %DynamicObject) As %Status
{
	write "Task schedule for ",backup.name

	if useArchiveOnDemand
	{
		write " using ArchiveOnDemand"

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
