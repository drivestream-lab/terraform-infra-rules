package terraform.flavors

# deployment-flavors.mdc — the flavor/size_profile contract. Checks the actual
# values passed into each module call in the plan's configuration, not just
# the module's own `validation` block (defense in depth: catches a caller that
# bypassed validation, e.g. via `terraform apply -var` in a break-glass flow).

deny contains msg if {
	some name, call in input.configuration.root_module.module_calls
	flavor := object.get(call.expressions, "flavor", null)
	flavor != null
	value := object.get(flavor, "constant_value", null)
	value != null
	not value in ["k8s", "vm", "managed"]
	msg := sprintf(
		"[FLV-01] module.%s flavor = %q is not one of k8s|vm|managed (deployment-flavors.mdc)",
		[name, value],
	)
}

deny contains msg if {
	some name, call in input.configuration.root_module.module_calls
	size := object.get(call.expressions, "size_profile", null)
	size != null
	value := object.get(size, "constant_value", null)
	value != null
	not value in ["s", "m", "l", "xl"]
	msg := sprintf(
		"[FLV-02] module.%s size_profile = %q is not one of s|m|l|xl (deployment-flavors.mdc)",
		[name, value],
	)
}

# deployment-flavors.mdc §2 — "callers never pass raw SKUs." A literal SKU-
# shaped string passed directly as a module argument (any argument, not just
# flavor/size_profile) is the bypass this contract forbids.
raw_sku_patterns := [
	`^Standard_[A-Z][0-9]`, # Azure VM/DB SKUs
	`^[a-z][0-9][a-z]?\.[a-z0-9]+$`, # AWS instance types, e.g. t3.medium
	`^db\.[a-z0-9.]+$`, # AWS RDS instance classes
]

deny contains msg if {
	some name, call in input.configuration.root_module.module_calls
	some arg, expr in call.expressions
	value := object.get(expr, "constant_value", null)
	is_string(value)
	some pattern in raw_sku_patterns
	regex.match(pattern, value)
	msg := sprintf(
		"[FLV-03] module.%s argument %q = %q looks like a raw SKU, not a size_profile (deployment-flavors.mdc §2)",
		[name, arg, value],
	)
}
