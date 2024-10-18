/// Configure TaskManagerEmail
Class ITZOS.K8S.Utilities.TaskManagerEmail
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "taskManagerEmail";

/// Test
ClassMethod Test()
{
	do ##class(ITZOS.K8S.AfterInstall).ExecuteActions2({
 		"taskManagerEmail": {
			"server": "smtp.healthexchange.nl",
			"port": 25,
			"sslconfig": "Default",
			"useStartTLS": true,
			"authUser": "",
			"authPassword": "",
			"timezone": "",
			"replyTo": "noreply.esb-altrecht-o@healthexchange.nl",
			"sender": "noreply.esb-altrecht-o@healthexchange.nl",
			"subjectSuccess": "Scheduler process #(NAME)# - #(SUCCESS)#",
			"subjectFailure": "Scheduler process #(NAME)# - #(SUCCESS)#",
			"messageSuccess": "Scheduler process #(NAME)# - Scheduled for #(SCHEDULED)# on #(SERVER)#:#(INSTANCE)#, #(SUCCESS)# executing Code #(TASKCLASS)# at #(LASTFINISHED)# was successful!",
			"messageFailure": "Scheduler process #(NAME)# - Scheduled for #(SCHEDULED)# on #(SERVER)#:#(INSTANCE)#, #(SUCCESS)# executing Code #(TASKCLASS)# at #(LASTFINISHED)# met resultaat #(ERROR)#\r\n\r\n#(STATUS)#"
		}
	})
}

/// Load Task Manager Email Settings
ClassMethod Load(settings As %DynamicObject)
{
	// See https://docs.intersystems.com/irisforhealthlatest/csp/documatic/%25CSP.Documatic.cls?LIBRARY=%25SYS&CLASSNAME=%25SYS.Task.Config

	write "Load Task Manager email settings: "
	do ##class(%SYS.Task.Config).EmailSet("Server", settings.server)
	do ##class(%SYS.Task.Config).EmailSet("Port", settings.port)
	do ##class(%SYS.Task.Config).EmailSet("SSLConfiguration", settings.sslconfig)
	do ##class(%SYS.Task.Config).EmailSet("UseSTARTTLS", settings.useStartTLS)
	do ##class(%SYS.Task.Config).EmailSet("AuthUser", settings.authUser)
	do ##class(%SYS.Task.Config).EmailSet("AuthPassword", settings.authPassword)

	do ##class(%SYS.Task.Config).EmailSet("TimeZone", settings.timeone)

	do ##class(%SYS.Task.Config).EmailSet("ReplyTo", settings.replyTo)
	do ##class(%SYS.Task.Config).EmailSet("Sender", settings.sender)

	if (settings.subjectSuccess '= "") do ##class(%SYS.Task.Config).EmailSet("SubjectSuccess", settings.subjectSuccess)
	if (settings.subjectFailure '= "") do ##class(%SYS.Task.Config).EmailSet("SubjectFailure", settings.subjectFailure)
	if (settings.messageSuccess '= "") do ##class(%SYS.Task.Config).EmailSet("MessageSuccess", settings.messageSuccess)
	if (settings.messageFailure '= "") do ##class(%SYS.Task.Config).EmailSet("MessageFailure", settings.messageFailure)

	write "done",!
}

}
