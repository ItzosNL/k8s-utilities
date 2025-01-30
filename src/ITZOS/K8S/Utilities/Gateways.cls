/// Modify External Language Servers - also known as Gateways
Class ITZOS.K8S.Utilities.Gateways
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "gateways";

/// Test
ClassMethod Test()
{
	do ..Load([
        #; {
		#; 	"Name": "%Java Server",
		#; 	"JavaHome": "/usr/lib/jvm/java-11-openjdk-amd64/",
		#; 	"ClassPath": "/home/irisowner/java_lib/FHIRValidator/hapi-fhir-validator.jar",
		#; 	"JVMArgs": ""
		#; },
		{
			"Name": "%XSLT Server",
			"JavaHome": "/usr/lib/jvm/java-11-openjdk-amd64/",
			"JVMArgs": "-Xrs -d64 -server -XX:+UseG1GC -Xms256M -Xmx2048M -XX:+UseStringDeduplication"
        }
	])
}

/// Load all Gateways
ClassMethod Load(gateways As %DynamicObject)
{
	#dim iterator As %Iterator.Object = gateways.%GetIterator()
	#dim gateway As %DynamicObject

	while iterator.%GetNext(, .gateway)
	{
		write "Modifying " _ gateway.Name _ ": "

		set sc = ..ModifyGateway(gateway)

		if $$$ISERR(sc)
		{
			write "failed, ",$System.Status.GetErrorText(sc),!
		}
		else
		{
			write "done",!
		}
	}
}

/// Modify Gateway
ClassMethod ModifyGateway(gateway) As %Status
{
	new $NAMESPACE
	set $NAMESPACE = "%SYS"

	try
	{
		set isRunning = $system.external.isServerRunning(gateway.Name)

		if (isRunning)
		{
			w "[ stopping server ]: "
			do $system.external.stopServer(gateway.Name)
			w "stopped, "
		}

		set modifiedserver = $system.external.modifyServer(gateway)

		return $$$OK
	}
	catch ex
	{
		return ex.AsStatus()
	}
}

/// Koppeltaal flavor
ClassMethod JavaServerforKoppeltaal() As %Status
{
	new $NAMESPACE
	set $NAMESPACE = "%SYS"
	
	set properties("JavaHome") = "/usr/lib/jvm/java-11-openjdk-amd64/"
	set properties("ClassPath") = "/home/irisowner/java_lib/FHIRValidator/hapi-fhir-validator.jar"
	
	return ##class(Config.Gateways).Modify("%Java Server", .properties)
}

}
