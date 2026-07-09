package terraform.azure.naming

# naming-tagging.mdc §1 (general scheme) + azure.mdc §6-7 (Azure-specific
# length/character constraints for storage accounts and Key Vault).

name_pattern := `^[a-z0-9]+-[a-z0-9]+-(dev|stage|uat|prod)-[a-z0-9-]+$`

deny contains msg if {
	some rc in input.resource_changes
	after := rc.change.after
	after != null
	rc.type != "azurerm_storage_account" # different scheme — checked below
	rc.type != "azurerm_key_vault" # different scheme — checked below
	name := object.get(after, "name", null)
	name != null
	not regex.match(name_pattern, name)
	msg := sprintf(
		"[NMG-01] %s name %q does not match {org}-{project}-{env}-{component} (naming-tagging.mdc §1)",
		[rc.address, name],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_storage_account"
	after := rc.change.after
	after != null
	name := after.name
	not regex.match(`^[a-z0-9]{3,24}$`, name)
	msg := sprintf(
		"[NMG-02] %s storage account name %q must be lowercase alphanumeric, no hyphens, <=24 chars (azure.mdc §6)",
		[rc.address, name],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_key_vault"
	after := rc.change.after
	after != null
	name := after.name
	count(name) > 24
	msg := sprintf(
		"[NMG-03] %s key vault name %q exceeds 24 characters (azure.mdc §7)",
		[rc.address, name],
	)
}
