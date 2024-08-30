/// Namespace Utilities
Class ITZOS.K8S.Utilities.Namespace
{

/// Does namespace exist?
ClassMethod NamespaceExists(namespace As %String) As %Boolean
{
	new $NAMESPACE
	set $NAMESPACE = "%SYS"

	return ##class(Config.Namespaces).Exists(namespace)
}

}
