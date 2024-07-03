/// SQLConnection handling on after-install.json
Class ITZOS.K8S.Utilities.SQLConnections
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "sqlconfigs";

/// Test
ClassMethod Test()
{
	do ..Load([
        {
          "name": "DWH-ESB",
          "url": "jdbc:sqlserver://178.22.82.142:51444;databaseName=UniqESB;encrypt=true;trustServerCertificate=true",
          "user": "ESB",
          "password": "jdbc-dwh",
          "classpath": "/tmp/mssql-jdbc-10.2.1.jre11.jar",
          "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
        },
        {
          "name": "DWH-ESB-uit",
          "url": "jdbc:sqlserver://178.22.82.142:51444;databaseName=UniqESB_uit;encrypt=true;trustServerCertificate=true",
          "user": "ESB",
          "password": "jdbc-dwh",
          "classpath": "/tmp/mssql-jdbc-10.2.1.jre11.jar",
          "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver"
        }
      ])
}

/// Load SQLConnections from after-install.json
ClassMethod Load(sqlconfigs As %DynamicObject)
{
	#dim iterator As %Iterator.Object = sqlconfigs.%GetIterator()
	#dim sqlconfig As %DynamicObject

	while iterator.%GetNext(.key, .sqlconfig)
	{
        write "Loading SQLconfig name: ",sqlconfig.name,!

		set password = ##class(ITZOS.K8S.Utilities.Secrets).RetrievePassword(sqlconfig.password)
		set sc = ..CreateOrUpdateSQLConnection(sqlconfig.name, sqlconfig.url, sqlconfig.user, password, sqlconfig.classpath, sqlconfig.driver)

		if $$$ISERR(sc)
		{
			write "Failed to create SQLConnection ",sqlconfig.name,": ",$SYSTEM.Status.GetErrorText(sc),!
		}
	}
}

/// Create SQL connection
ClassMethod CreateOrUpdateSQLConnection(name As %String, url As %String, user As %String, password As %String, classpath As %String, driver As %String) As %Status
{
	#dim sqlConnection As %Library.SQLConnection

	if (##class(%Library.SQLConnection).NameIndexExists(name)) 
	{
		set sqlConnection = ##class(%Library.SQLConnection).NameIndexOpen(name)
	}
	else
	{
		set sqlConnection = ##class(%Library.SQLConnection).%New()	
	}

	set sqlConnection.Name = name
	set sqlConnection.URL = url
	set sqlConnection.Usr = user
	set sqlConnection.pwd = password
	set sqlConnection.bUnicodeStream = 0
	set sqlConnection.classpath = classpath
	set sqlConnection.driver = driver
	set sqlConnection.isJDBC = 1
	set sqlConnection.needlongdatalen = 0
	set sqlConnection.nodefq = 0
	set sqlConnection.nofnconv = 0
	set sqlConnection.nvl = 0
	set sqlConnection.useCAST = 0
	set sqlConnection.useCASTCHAR = 0

	return sqlConnection.%Save()
}

}
