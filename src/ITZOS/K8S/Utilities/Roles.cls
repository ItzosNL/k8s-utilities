/// Create Roles during AfterInsstall
Class ITZOS.K8S.Utilities.Roles
{

/// Node from the after-install.config processed by this class.
Parameter AfterInstallNode = "roles";

/// Testmethods
ClassMethod Test()
{
	do ..Load([
        {
          "name": "MinddistrictRole",
          "description": "Role used for Minddistrict REST Passthrough",
          "members": [ "UnknownUser" ]
        }
      ])
}

/// Load all Users
ClassMethod Load(roles As %DynamicArray)
{
	#dim iterator As %Iterator.Object = roles.%GetIterator()
	#dim roleDefinition As %DynamicObject

	while iterator.%GetNext(.key, .roleDefinition)
	{
		do ..Create(roleDefinition.name, roleDefinition.description, roleDefinition.members)
	}
}

/// Method used to create a roleDefinition during the after-install
ClassMethod Create(name As %String, description As %String, members As %DynamicArray)
{
	new $Namespace
	set $Namespace = "%SYS"

	write "Role '",name,"': "

    // Check if the role already exists | Quit if true
    if ##class(Security.Roles).Exists(name, .role)
	{
		#dim role as Security.Roles

		if role.Description '= description
		{
			set role.Description = description
			set sc = role.%Save()

			if $$$ISERR(sc)
			{
				write "Update failed: ",$System.Status.GetErrorText(sc),!
			}
			else
			{
				write "Updated",!
			}
		}
		else
		{
			write "Already exists, not updated",!
		}
	}
	else
	{
		set sc = ##class(Security.Roles).Create(name, description)
		
		if $$$ISERR(sc)
		{
			write "Creation failed: ",$System.Status.GetErrorText(sc),!
		}
		else
		{
			write "Created",!
		}
	}

	for index = 1:1:members.%Size()
	{
		set member = members.%Get(index - 1)

		do ..AssignRoleToUser(member, name)
	}
}

/// Method used to create a roleDefinition during the after-install
ClassMethod AssignRoleToUser(username As %String, rolename As %String = "MinddistrictRole")
{
	new $Namespace
	set $Namespace = "%SYS"

    // Get the user 
    if '##class(Security.Users).Exists(username, .user)
	{
		write "User " _ username _ " does not exists; cannot assign role " _ rolename,!
		return
	}

	#dim user as Security.Users

	for index = 1:1:user.Roles.Count()
	{
		if user.Roles.GetAt(index) = rolename
		{
			write "User " _ username _ " already has role " _ rolename,!
			return
		}
	}

	do user.Roles.Insert(rolename)
	set sc = user.%Save()

	if $$$ISERR(sc)
	{
		write "Update user " _ username _ " failed, user " _ rolename," has not added: ",$System.Status.GetErrorText(sc),!
	}
	else
	{
		write "User " _ username _ ": Added role " _ rolename,!
	}
}

}
