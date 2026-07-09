package terraform.tagging

import data.terraform.exceptions

# naming-tagging.mdc §"Mandatory tags" — every taggable resource carries all 7.

mandatory_tags := ["environment", "project", "client", "owner", "cost_center", "managed_by", "stack"]

# Only resources whose plan actually exposes a `tags` attribute are checked —
# this avoids false positives on resource types that don't support tags at all
# (naming-tagging.mdc §3 scopes this rule to "every taggable resource").
deny contains msg if {
	some rc in input.resource_changes
	rc.change.after != null
	tags := object.get(rc.change.after, "tags", null)
	tags != null
	some tag in mandatory_tags
	not tags[tag]
	not exceptions.declared(tags, "TAG-01")
	msg := sprintf(
		"[TAG-01] %s is missing mandatory tag '%s' (naming-tagging.mdc §\"Mandatory tags\")",
		[rc.address, tag],
	)
}
