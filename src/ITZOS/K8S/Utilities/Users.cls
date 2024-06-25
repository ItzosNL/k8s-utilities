/// Create users based on after-install.json
Class ITZOS.K8S.Utilities.Users
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "users";

/// Load all Users
ClassMethod Load(users As %DynamicObject)
{
	#dim iterator As %Iterator.Object = users.%GetIterator()
	#dim user As %DynamicObject

	while iterator.%GetNext(.key, .user)
	{
		set password = ##class(ITZOS.K8S.Utilities.Secrets).RetrievePassword(user.password)

		do ..CreateUser(user.name, password, user.roles, user.changePassword, user.fullname, user.comment)
	}
}

/// Method used to create a user during the after-install
ClassMethod CreateUser(username As %String, password As %String, roles As %String, changePassword As %Boolean, fullname As %String, comment As %String)
{
	new $Namespace
	set $Namespace = "%SYS"

	write "User '",username,"': "

    // Check if the user already exists | Quit if true
    if ##class(Security.Users).Exists(username)
	{
		write "Already exists",!
	    return
	}

	set properties("FullName") = fullname
	set properties("Comment") = comment
	set properties("Password") = password
	set properties("UserRoles") = roles
	set properties("ChangePassword") = changePassword
	set properties("AccountNeverExpires") = 1
	set properties("PasswordNeverExpires") = 1

	set sc = ##class(Security.Users).Create(username, .properties)
    
	if $$$ISERR(sc)
	{
		write "Creation failed: ",$System.Status.GetErrorText(sc),!
	}
	else
	{
		write "Created",!
	}
}

}
