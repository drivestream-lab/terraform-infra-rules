package terraform.security

import data.terraform.exceptions

# security-baseline.mdc §3 — default deny, no 0.0.0.0/0 / ::/0 ingress except 80/443.
# Covers the two most common plan shapes (Azure NSG rule, AWS security group
# ingress rule). Not exhaustive across every provider's network primitive —
# extend as new resource types show up in real plans.

deny contains msg if {
	some rc in input.resource_changes
	after := rc.change.after
	after != null
	after.direction == "Inbound"
	after.access == "Allow"
	prefixes := object.get(after, "source_address_prefixes", [object.get(after, "source_address_prefix", "")])
	"0.0.0.0/0" in prefixes
	port := object.get(after, "destination_port_range", "")
	port != "80"
	port != "443"
	tags := object.get(after, "tags", {})
	not exceptions.declared(tags, "SEC-03")
	msg := sprintf(
		"[SEC-03] %s (NSG rule) allows ingress from 0.0.0.0/0 on port %v (security-baseline.mdc §3)",
		[rc.address, port],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	after := rc.change.after
	after != null
	cidrs := object.get(after, "cidr_blocks", [])
	"0.0.0.0/0" in cidrs
	from_port := object.get(after, "from_port", -1)
	from_port != 80
	from_port != 443
	tags := object.get(after, "tags", {})
	not exceptions.declared(tags, "SEC-03")
	msg := sprintf(
		"[SEC-03] %s (security group rule) allows ingress from 0.0.0.0/0 on port %v (security-baseline.mdc §3)",
		[rc.address, from_port],
	)
}

# security-baseline.mdc §4 — data stores never publicly addressable.
deny contains msg if {
	some rc in input.resource_changes
	after := rc.change.after
	after != null
	flag := public_access_flag(after)
	flag == true
	tags := object.get(after, "tags", {})
	not exceptions.declared(tags, "SEC-04")
	msg := sprintf(
		"[SEC-04] %s enables public network access (security-baseline.mdc §4)",
		[rc.address],
	)
}

public_access_flag(after) := after.public_network_access_enabled if {
	"public_network_access_enabled" in object.keys(after)
} else := after.publicly_accessible if {
	"publicly_accessible" in object.keys(after)
}

# security-baseline.mdc §5 — storage blocks public access at the account/bucket
# level, not per object.
deny contains msg if {
	some rc in input.resource_changes
	after := rc.change.after
	after != null
	object.get(after, "allow_nested_items_to_be_public", false) == true
	tags := object.get(after, "tags", {})
	not exceptions.declared(tags, "SEC-05")
	msg := sprintf(
		"[SEC-05] %s allows public blob access at the account level (security-baseline.mdc §5)",
		[rc.address],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "aws_s3_bucket_public_access_block"
	after := rc.change.after
	after != null
	some flag in ["block_public_acls", "block_public_policy", "ignore_public_acls", "restrict_public_buckets"]
	after[flag] != true
	not exceptions.declared({}, "SEC-05")
	msg := sprintf(
		"[SEC-05] %s does not fully block public access (%s = %v) (security-baseline.mdc §5)",
		[rc.address, flag, after[flag]],
	)
}

# NOTE on coverage: §6 (IAM least-privilege / no wildcards) and §9 (no secret
# values in .tf/.tfvars/outputs) are not yet implemented here — §6 requires
# parsing embedded IAM policy documents, §9 is largely a source-scan concern
# (gate 4's job) rather than a plan-diff concern. Flagged per policy-as-code.mdc
# §6: prose without a rego mirror must say so, not pretend coverage exists.
