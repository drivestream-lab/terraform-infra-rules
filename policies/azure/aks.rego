package terraform.azure.aks

# kubernetes.mdc + azure.mdc §12-14 — always-on AKS posture. size_profile may
# change node SKU/count; it never changes any of the checks below.

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	after := rc.change.after
	after != null
	object.get(after, "workload_identity_enabled", false) != true
	msg := sprintf(
		"[AKS-01] %s does not enable workload_identity_enabled (kubernetes.mdc §1-2, azure.mdc §12)",
		[rc.address],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	after := rc.change.after
	after != null
	object.get(after, "oidc_issuer_enabled", false) != true
	msg := sprintf(
		"[AKS-02] %s does not enable oidc_issuer_enabled (kubernetes.mdc §2)",
		[rc.address],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	after := rc.change.after
	after != null
	count(object.get(after, "key_vault_secrets_provider", [])) == 0
	msg := sprintf(
		"[AKS-03] %s does not enable the key_vault_secrets_provider add-on (kubernetes.mdc §3, azure.mdc §13)",
		[rc.address],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	after := rc.change.after
	after != null
	profiles := object.get(after, "network_profile", [{}])
	count(profiles) > 0
	object.get(profiles[0], "network_policy", null) == null
	msg := sprintf(
		"[AKS-04] %s does not set network_profile.network_policy (kubernetes.mdc §4)",
		[rc.address],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "azurerm_kubernetes_cluster"
	after := rc.change.after
	after != null
	object.get(after, "local_account_disabled", false) != true
	msg := sprintf(
		"[AKS-05] %s does not disable local accounts (kubernetes.mdc §6, azure.mdc §14)",
		[rc.address],
	)
}

# NOTE: pod security standard enforcement (kubernetes.mdc §5) and node-pool
# separation (§7) are namespace/node-pool-level facts not fully visible on the
# azurerm_kubernetes_cluster resource alone — plan-review only for now.
