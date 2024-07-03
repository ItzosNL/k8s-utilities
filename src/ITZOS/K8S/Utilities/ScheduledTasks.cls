/// Common logic for scheduled tasks
Class ITZOS.K8S.Utilities.ScheduledTasks
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "tasks";

/// Test load method
ClassMethod Test()
{
	do ..Load([
        {
          "name": "Archiveer vorige maand",
          "description": "Archiveer Aanleveringen en Logregels van vorige maand",
          "taskClass": "%SYS.Task.RunLegacyTask",
          "type": "Monthly",
          "day": 2,
          "time": "02:00:00",
		  "properties": {
			"ExecuteCode": "do ##class(MMLOGGINGPKG.BS.LoggingService).StartProcess(\"ArchiveLastMonth\")"	
		  }
        }
      ])
}

/// Load ScheduledTasks from after-install.json
ClassMethod Load(tasks As %DynamicObject)
{
	#dim iterator As %Iterator.Object = tasks.%GetIterator()
	#dim task As %DynamicObject

	while iterator.%GetNext(.key, .task)
	{
		do ..CreateOrUpdateTaskSchedule(task.name, task.description, task.taskClass, task.properties, task.type, task.time, task.day)
	}
}

/// Create Legacy Task
ClassMethod CreateLegayTask(name As %String, executeCode As %String, timingType As %String, startTime As %String, days As %String = "", namespace As %String = {$NAMESPACE}) As %Status
{
	return ..CreateOrUpdateTaskSchedule(name, "Run " _ name, "%SYS.Task.RunLegacyTask", { "ExecuteCode": (executeCode) }, timingType, startTime, days, namespace)
}

/// Create Or Update Task Schedule
ClassMethod CreateOrUpdateTaskSchedule(name As %String, description As %String, taskClass As %String, properties As %DynamicObject, timingType As %String, startTime As %String, days As %String = "", namespace As %String = {$NAMESPACE}) As %Status
{
	write "Creating task ",name,":",!

	#dim task as %SYS.Task = ##class(%SYS.Task).OpenId(name)

	if task = ""
	{
		set task = ##class(%SYS.Task).%New()
		set task.Name = name
    	set task.RescheduleOnStart = 1
		set action = "create"
	}
	else
	{
		set action = "update"
	}

	set task.NameSpace = namespace
    set task.TaskClass = taskClass

    do ..SetProperties(task, properties)
	do ..SetTaskTiming(task, timingType, startTime, days, .description)
	set task.Description = description

	set sc = task.%Save()

	if $$$ISERR(sc)
	{
		write "Failed to ",action," Task Schedule ",name,": ",$SYSTEM.Status.GetErrorText(sc),!
	}
	else
	{
		write "Successfully ",action,"d Task Schedule ",name,!
	}

	return sc
}

/// Set Task timing and add to desription
/// timingType - Daily, Weekly, Monthly or "On Demand"
/// startTime - 24-hour time representation of the time to run like "23:00:00" to run at 11 PM The task is set to run once at that specified date and time
/// days:
/// - for Weekly tasks, a pattern like "tu,we,th,fr,sa,su" specifiying the days the task should run. 
/// - For Monthly tasks, the day of the month for which the task should run
ClassMethod SetTaskTiming(task As %SYS.Task, timingType As %String, startTime As %String, days As %String = "", ByRef description As %String)
{
	set task.StartDate = $Horolog + 1

    if $ZSTRIP(timingType, "*W") = "OnDemand"
    {
        set task.TimePeriod = 5
        set task.TimePeriodEvery = ""
        set description = description _ " on demand"
    }
    else
    {
        set task.TimePeriodEvery = 1 	// Run every 1 day or week
        set task.DailyFrequency = 0 	// Once
        set task.DailyStartTime = $ZTIMEH(startTime, 1)

        if timingType = "Daily"
        {
            set description = description _ " once every day at " _ startTime
            set task.TimePeriod = 0
        }
        elseif timingType = "Weekly"
        {
            set description = description _ " once at " _ startTime _ " on every " _ days
            set task.TimePeriod = 1
        	set task.TimePeriodDay = ""

            for index = 1:1:$LENGTH(days, ",")
            {
                set day = $PIECE(days, ",", index)
                set task.TimePeriodDay = task.TimePeriodDay _ $ListFind($ListBuild("su", "mo", "tu", "we", "th", "fr", "sa"), day)
            }

            write "Days: ",days," -> ",task.TimePeriodDay,!
        }
        elseif timingType = "Monthly"
        {
			/// Run the second day of every month
			/// TimePeriod=2,TimePeriodEvery=1,TimePeriodDay=1<br><br>
            set description = description _ " once every month on day " _ days _ " at " _ startTime
            set task.TimePeriod = 2
        	set task.TimePeriodDay = days
        }
    }
}

/// Set properties from a DynamicArray
ClassMethod SetProperties(task As %SYS.Task, properties As %DynamicObject)
{
	if $ISOBJECT(properties)
	{
		#dim iterator As %Iterator.Object = properties.%GetIterator()

		while iterator.%GetNext(.key, .value)
		{
			do ..SetProperty(task, key, value)
		}
	}
}

/// Set named Property
ClassMethod SetProperty(task As %SYS.Task, propertyName As %String, value As %String, separator As %String = "|")
{
	set settings = $LISTTOSTRING(task.Settings, separator)
	set found = 0

	if settings '= ""
	{
		for index = 1:2:$LENGTH(settings, separator)
		{
			set setting = $PIECE(settings, separator, index)

			if setting '= propertyName
			{
				continue
			}

			set found = 1

			if $PIECE(settings, separator, index + 1) '= value
			{
				write "Updating setting ",propertyName," to ",value,": ",! 
				set $PIECE(settings, separator, index + 1) = value
			}
			else
			{
				write "Setting ",propertyName," already has the proper value",! 
			}
		}
	}

	if 'found // Setting not found, now adding it!
	{
		if settings '= ""
		{
			set settings = settings _ separator
		}

		write "Adding setting ",propertyName," with ",value,": ",! 
		set settings = settings _ propertyName _ separator _ value 
	}

	set task.Settings = $LISTFROMSTRING(settings, separator)
}

}
