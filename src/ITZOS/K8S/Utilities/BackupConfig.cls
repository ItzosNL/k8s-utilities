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
            "folder": "altrecht-a/",
            "access-key": "ZWhlYWx0aC1pcmlzLWJ1",
            "access-secret": "aodbackup"
          }
        }
      },
      "backup-config": {
        #; "databases" : [
        #;   "ALTRECHT"
        #; ],
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
              "day": "tu",
              "time": "06:00:00"
          }
        },	
        "cumulativeBackup": {
          "name": "Itzos Daily",
          "folder": "/irissys/backups",
          "type": "Cumulative",
          "schema": {
              "type": "On Demand",
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

	if (backupconfig.databases = "") || (..AddDatabases(backupconfig.databases) = 0) // No databases found
	{
		write "No Databases Found, adding DATA database for the current namespace:",!
		do ..AddDatabases([ (##class(ITZOS.K8S.Utilities.Namespace).GetDataDatabaseForNamespace()) ])
	}

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
ClassMethod AddDatabases(databases As %DynamicArray) As %Integer
{
	new $Namespace
	set $Namespace = "%SYS"

	do ##class(Backup.General).ClearDatabaseList()

	set count = 0

	for index = 0:1:databases.%Size() - 1
	{
		set database = databases.%Get(index)

		if ..DatabaseExistsAndNotReadonly(.database)
		{
			set sc = ##class(Backup.General).AddDatabaseToList(database)
		
			if $$$ISERR(sc)
			{
				write "Failed to add database '",database,"' to the backup list: ",$SYSTEM.Status.GetErrorText(sc),!
			}
			else
			{
				write "Database '",database,"' has been added to the backup list",!
				set count = count + 1
			}
		}
	}

	return count
}

/// Check if the specified database exists and is not readonly
ClassMethod DatabaseExistsAndNotReadonly(ByRef database As %String) As %Boolean
{
	new $Namespace
	set $Namespace = "%SYS"

    // Return the ^system^directory where the database is located.<br> 
    set serverAndDb = ##class(Config.Databases).DatabaseByName(database)

    if (serverAndDb = "")
	{
		if (database [ "_DATA")
		{
			set database2 = $REPLACE(database, "_DATA", "")
			set serverAndDb2 = ##class(Config.Databases).DatabaseByName(database2)

			if (serverAndDb2 '= "")
			{
				write "WARNING: Database ",database," does not exist, using database ",database2,! 
				set serverAndDb = serverAndDb2
				set database = database2
			}
		}
		else // Maybe namespace is specified, see if there is a separate database for DATA
		{
			set database2 = ##class(ITZOS.K8S.Utilities.Namespace).GetDataDatabaseForNamespace(database)

			if (database2 '= "")
			{
				set serverAndDb2 = ##class(Config.Databases).DatabaseByName(database2)

				if (serverAndDb2 '= "")
				{
					write "WARNING: Database ",database," does not exist, using database ",database2,! 
					set serverAndDb = serverAndDb2
					set database = database2
				}
			}
		}
	}

    if serverAndDb = ""
    {
        write "WARNING: Database ",database," does not exist (skipped)",!
        return 0	
    }

    set db = ##Class(SYS.Database).%OpenId($PIECE(serverAndDb, "^", 3))

    if db.ReadOnly
    {
        write "WARNING: Database ",database," is readonly (skipped)",!
        return 0
    }

    return 1
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
