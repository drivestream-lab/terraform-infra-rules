# Changelog

All notable changes to terraform-infra-rules. Semver: PATCH = clarification,
MINOR = new guidance (additive), MAJOR = breaking for consumers (including any
policy tightening that can fail previously-green repos).

## [0.1.1] — 2026-07-09

### Changed
- **`testing-verification.mdc`** — Makefile contract as required targets, not pasted Makefile; generic module test example (not kafka)
- **`infra-guidelines-index.mdc`** — explicit rule: no harness content in `.mdc`
- **`README.md`** — policies shipped; adoption clarifies foundation vs harness wiring

### Added
- **`scripts/check_mdc_boundary.sh`** + **`.github/workflows/ci.yml`** — block skill catalogs in constitution MDC

### Migration guide
- Optional submodule bump: `git checkout v0.1.1` in `.cursor/rules`
- No consumer Terraform changes required

## [0.1.0] — 2026-07-08

### Added
- Initial constitution: 16 rule modules
  - Always-on: `infra-guidelines-index`, `spec-driven-infra`, `plan-apply-workflow`,
    `testing-verification`, `infra-adr`
  - Code-level: `stack-architecture`, `module-structure`, `variables-outputs`,
    `naming-tagging`, `state-and-backends`, `provider-versioning`
  - Environment & security: `environments-and-promotion`, `deployment-flavors`,
    `security-baseline`, `policy-as-code`
  - Cloud overlays: `aws`, `azure`
- Rationale preamble in README mapping each rule group to the IaC failure mode
  it counters
- Kubernetes, observability, and secret-management baselines (cloud-neutral):
  `kubernetes.mdc`, `observability.mdc`, `secret-management.mdc`
- Cloud overlay mappings for the three new baselines: `azure.mdc` §12-15 (AKS
  Workload Identity, Key Vault Secrets Store CSI provider, Entra ID RBAC, Log
  Analytics Workspace / diagnostics-only Storage Account), `aws.mdc` §10-13
  (EKS/IRSA or EKS Pod Identity, Secrets Manager CSI provider, EKS access
  entries, CloudWatch Logs / diagnostics-only S3 bucket) — the AWS mapping is
  written for consistency and has not yet been validated against a real EKS
  build
- `infra-guidelines-index.mdc` updated with the three new rule modules
- `policies/` rego pack — gate 6 in `testing-verification.mdc` now has real
  checks to run, not "conftest not installed — policy gate skipped":
  - `policies/common/exceptions.rego` — shared `policy_exception_<ID>` tag +
    expiry helper used by every deny rule below
  - `policies/common/tagging.rego` (TAG-01) — mandatory tags present
  - `policies/common/security.rego` (SEC-03, SEC-04, SEC-05) — no `0.0.0.0/0`
    ingress except 80/443, no public data-store access, no public blob access.
    SEC-06 (IAM wildcards) and SEC-09 (secret leakage) intentionally not
    covered yet — noted in-file per `policy-as-code.mdc` §6
  - `policies/common/flavors.rego` (FLV-01/02/03) — flavor/size_profile
    contract enforced against actual module-call values in the plan, plus a
    raw-SKU-leak detector
  - `policies/common/lifecycle.rego` (LCY-01) — destroy/replace on a stateful
    resource is a stop-line. `prevent_destroy` presence itself is not
    plan-JSON-checkable — noted in-file, left to gate 4
  - `policies/azure/aks.rego` (AKS-01..05) — workload identity, OIDC issuer,
    Key Vault CSI add-on, network policy, local accounts disabled, all
    always-on regardless of `size_profile`
  - `policies/azure/naming.rego` (NMG-01/02/03) — naming scheme + Azure
    storage account / Key Vault length constraints
  - All seven files pass `opa check --strict` and were smoke-tested against
    synthetic plan JSON (tagging + exception expiry, AKS posture, flavor
    contract) before landing
- `infra-adr.mdc`: trigger #9 (excluding/deviating from a Tier 1 substrate
  module or any constitution default) and a new "Override contract" — every
  ADR overriding a default must cite a specific spec requirement and carry a
  review/expiry date, not just security-baseline exceptions
- `environments-and-promotion.mdc` §5: dev may relax size *and* log retention
  duration, never security baseline or logging existence
- `spec-driven-infra.mdc`: RPO/RTO is now required explicitly per stateful
  resource (silence is an incomplete spec); backup/DR reframed as a required
  decision, never a constitution-mandated default

### Pending (planned before 0.2.0)
- `policies/common/security.rego` coverage for SEC-06 (IAM least-privilege) and
  SEC-09 (secret leakage)
- `gcp.mdc` overlay
- `cost-governance.mdc`, `network-topology.mdc`, `drift-detection.mdc` — flagged
  as candidates during scaffold planning, not yet critically evaluated
