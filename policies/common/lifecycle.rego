package terraform.lifecycle

import data.terraform.exceptions

# plan-apply-workflow.mdc §5 — "a plan that shows destroy or replace on a
# stateful resource is a stop-line." Checked directly against the plan diff.
#
# plan-apply-workflow.mdc §4 (prevent_destroy must be set) is NOT checked
# here — a `lifecycle { prevent_destroy = true }` meta-argument does not
# appear in `terraform show -json` plan output, only in source. That half of
# the rule is a static-config-scan concern (gate 4 / tflint territory), not a
# plan-diff concern — flagged per policy-as-code.mdc §6 rather than claimed.

stateful_type_fragments := [
	"postgresql", "mysql", "storage_account", "s3_bucket", "key_vault",
	"redis", "cosmosdb", "kubernetes_cluster", "persistent_volume",
	"rds_", "db_instance", "dynamodb_table",
]

is_stateful(resource_type) if {
	some frag in stateful_type_fragments
	contains(resource_type, frag)
}

deny contains msg if {
	some rc in input.resource_changes
	is_stateful(rc.type)
	"delete" in rc.change.actions
	before := object.get(rc.change, "before", {})
	tags := object.get(before, "tags", {})
	not exceptions.declared(tags, "LCY-01")
	msg := sprintf(
		"[LCY-01] %s (%s) plans to destroy or replace a stateful resource — stop-line per plan-apply-workflow.mdc §5",
		[rc.address, rc.type],
	)
}
