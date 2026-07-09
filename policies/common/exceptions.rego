package terraform.exceptions

# Shared exception-declaration check used by every deny rule in this repo
# (policy-as-code.mdc §4).
#
# HCL-side convention:
#
#   tags = merge(local.tags, {
#     "policy_exception_<POLICY_ID>" = "<ADR-ref>;expires=<YYYY-MM-DD>"
#   })
#
# A policy id is exception-covered only if the tag exists, names the correct
# policy id, and the expiry date has not passed. An expired exception denies
# exactly like there was never one — permanent exceptions don't exist
# (security-baseline.mdc "Enforcement").
#
# Editing this file to unblock one repo is itself a policy-as-code.mdc §4
# violation: exceptions belong in the consumer's HCL, never in the policy.

declared(tags, policy_id) if {
	tags != null
	key := sprintf("policy_exception_%s", [policy_id])
	value := tags[key]
	parts := split(value, ";")
	count(parts) == 2
	startswith(parts[1], "expires=")
	expiry_str := substring(parts[1], count("expires="), -1)
	expiry_ns := time.parse_ns("2006-01-02", expiry_str)
	expiry_ns > time.now_ns()
}
