# terraform-infra-rules

**Open constitution for Terraform infrastructure** — shared agent rules (`.mdc`)
for cloud stacks: stack layering, module contracts, state discipline, deployment
flavors, security baseline, plan/apply workflow, and ADR governance.

Rules describe **how to build infra**. They do **not** contain client topology,
environment values, or resource catalogs — those live in each consumer repo under
`docs/specification/` and `envs/*/terraform.tfvars`.

| | |
|---|---|
| **License** | [MIT](LICENSE) |
| **Version** | see [`VERSION`](VERSION) (currently **0.1.2**) · [CHANGELOG](CHANGELOG.md) |
| **Mount path** | `.cursor/rules/` (git submodule) |
| **Scaffold** | `terraform-azure-foundation` — optional cookiecutter in your org |

---

## Why these rules exist (rationale)

The governance shell (versioned submodule, semver pins, index) is inherited from
the org's rules pattern. The **content** is derived from Terraform's own failure
modes — not by analogy to application code:

| IaC-specific reality | Consequence if unmanaged | Rule |
|---|---|---|
| Execution mutates the real world; `git revert` restores nothing | Irreversible data loss | `plan-apply-workflow` |
| State is shared mutable runtime | Corruption, ghost infra | `state-and-backends` |
| Declarative model — the plan diff is the only observable behavior | Review on 5k-line JSON or not at all | `testing-verification`, `policy-as-code` |
| Providers are external versioned APIs | Non-reproducible plans | `provider-versioning` |
| Cost & blast radius are code properties (`size = "xl"` is a $-decision) | Untracked spend, unjustifiable topology | `deployment-flavors`, `infra-adr`, `naming-tagging` |
| Cloud defaults are insecure (public, unencrypted, open) | One missing block = breach | `security-baseline` |
| Multi-env, multi-client delivery | Environment forks — prod deploys become first deploys | `environments-and-promotion`, `deployment-flavors` |
| Agent-driven delivery needs defined truth | Invented topology | `spec-driven-infra`, `stack-architecture`, `module-structure`, `variables-outputs` |

Priority inverts relative to application rules: the most important rules here are
**operational** (apply discipline, state, security) because the cost of a bad merge
is an outage or a bill, not tech debt.

---

## Layout

Repository root **is** the contents of a consumer's `.cursor/rules/`:

```text
terraform-infra-rules/
  VERSION
  README.md
  CHANGELOG.md
  infra-guidelines-index.mdc     ← module index (start here)
  spec-driven-infra.mdc
  plan-apply-workflow.mdc
  stack-architecture.mdc
  module-structure.mdc
  variables-outputs.mdc
  naming-tagging.mdc
  state-and-backends.mdc
  provider-versioning.mdc
  environments-and-promotion.mdc
  deployment-flavors.mdc
  security-baseline.mdc
  testing-verification.mdc
  policy-as-code.mdc
  infra-adr.mdc
  aws.mdc  azure.mdc             ← cloud overlays (scoped)
  policies/                      ← rego mirrors (gate 6; versioned with rules)
  …
```

Full module table: [`infra-guidelines-index.mdc`](infra-guidelines-index.mdc).

---

## Adoption

From the **consumer stack repo root**:

```bash
rm -rf .cursor/rules

git submodule add https://github.com/<org>/terraform-infra-rules.git .cursor/rules
cd .cursor/rules && git checkout v0.1.2 && cd ../..

git add .gitmodules .cursor/rules
git commit -m "Add Terraform infra Cursor rules at .cursor/rules (v0.1.2)"
```

Cursor loads **`.cursor/rules/*.mdc`** automatically — no copy step.

Greenfield stacks may start from `terraform-azure-foundation` in your org
(`cookiecutter … --checkout v0.1.1`), then add the rules submodule as above.

---

## Tooling expected by the rules

Consumer repos need: **Terraform** (≥1.9), **tflint**, **trivy** (or **checkov**),
**conftest**. Required Makefile targets — `check`, `test`, `plan` — are specified in
`testing-verification.mdc`. Exact config files live in the consumer repo or
scaffold — not in this constitution.

---

## Bump rules version

```bash
cd .cursor/rules
git fetch --tags
git checkout v0.1.2    # target version
cd ../..
git add .cursor/rules
git commit -m "Bump Terraform infra rules to v0.1.2"
```

Read [CHANGELOG](CHANGELOG.md) before every bump. **Breaking** releases require
consumer code changes before or alongside the submodule pointer update. Policy
tightening that can fail previously-green repos is a **MAJOR** bump.

---

## Governance

| Principle | Detail |
|-----------|--------|
| **Ownership** | Platform / architecture team owns this repo |
| **Consumers** | Pin a release tag — never fork or edit rules in stack repos |
| **Changes** | Propose via PR here; consumers update the submodule pointer only |
| **Policy = rules** | Rego ships here, versioned with the prose it enforces |
| **Client truth** | Topology → tfvars · rationale → ADRs · live state → as-built — all in the consumer repo |
| **Do not** | `gitignore` `.cursor/rules` in consumers — breaks the pinned submodule |

---

## What stays in each stack repo

| Path | Purpose |
|------|---------|
| `docs/specification/product/` | Infra spec: components, per-env matrix, SLOs, cost ceiling |
| `docs/specification/adr/` | Why it runs the way it runs (ADR-0001 = environment topology) |
| `docs/specification/as-built/` | What is live today |
| `envs/*/terraform.tfvars` | The machine-readable per-env decisions |
| `README.md` | Setup, backends, plan/apply runbook |

---

## Release process (maintainers)

1. Branch `rules/<short-description>` — edit `*.mdc` at repo root; peer review required
2. Machine-checkable rule changes include their rego mirror in the same PR
3. Bump **`VERSION`** (semver) and **`CHANGELOG.md`** (tightened policy = MAJOR)
4. Update version in this README header
5. PR → `develop` → `main`; tag and push:

```bash
git tag v0.1.2
git push origin v0.1.2
```

---

## Related repositories

| Repo | Role |
|------|------|
| `terraform-azure-foundation` | Cookiecutter scaffold for Azure infra stacks |
| `python-services-rules` | Constitution for application services this stack hosts |
| `nextjs-bff-rules` | Constitution for BFF portals that call those services |

---

## License

MIT — see [LICENSE](LICENSE).
