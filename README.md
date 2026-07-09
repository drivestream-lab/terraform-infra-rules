# terraform-infra-rules

**Open constitution for Terraform infrastructure** — shared agent rules (`.mdc`)
for cloud stacks: stack layering, module contracts, state discipline, deployment
flavors, security baseline, plan/apply workflow, and ADR governance.

Rules describe **how to build infra**. They do **not** contain client topology,
environment values, or resource catalogs — those live in each consumer repo under
`docs/specification/` and `envs/*/terraform.tfvars`.

|                     |                                                              |
| ------------------- | ------------------------------------------------------------ |
| **Version**         | see `VERSION` (currently **0.1.1**) · [CHANGELOG](CHANGELOG.md) |
| **Harness profile** | `terraform-infra`                                            |
| **Mount path**      | `.cursor/rules/` (git submodule)                             |
| **Pairs with**      | terraform-aws-foundation · terraform-azure-foundation · terraform-{aws,azure}-modules · IaC skills |

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

```
terraform-infra-rules/
  VERSION  README.md  CHANGELOG.md
  infra-guidelines-index.mdc     ← module index (start here)
  spec-driven-infra.mdc          plan-apply-workflow.mdc
  stack-architecture.mdc         module-structure.mdc
  variables-outputs.mdc          naming-tagging.mdc
  state-and-backends.mdc         provider-versioning.mdc
  environments-and-promotion.mdc deployment-flavors.mdc
  security-baseline.mdc          testing-verification.mdc
  policy-as-code.mdc             infra-adr.mdc
  aws.mdc  azure.mdc             ← cloud overlays (scoped)
  policies/                      ← rego mirrors (gate 6; versioned with rules)
```

## Adoption

From the consumer stack repo root:

```bash
git submodule add https://github.com/<org>/terraform-infra-rules.git .cursor/rules
cd .cursor/rules && git checkout v0.1.1 && cd ../..
git add .gitmodules .cursor/rules
```

Foundations generate stack shape only; pin the rules submodule manually or via
launchpad `apply-harness` when using the harness.

## Tooling expected by the rules

Consumer repos need: `terraform` (≥1.9), `tflint`, `trivy` (or `checkov`),
`conftest`. Required Makefile targets — `check`, `test`, `plan` — are specified in
`testing-verification.mdc`.

## Governance

| Principle | Detail |
| --- | --- |
| **Ownership** | Platform / architecture team |
| **Consumers** | Pin a release tag — never fork or edit rules in stack repos |
| **Changes** | PR here → semver tag → bump approved pairs in tenant config |
| **Policy = rules** | Rego ships here, versioned with the prose it enforces; tightening a policy is a MAJOR |
| **Client truth** | Topology → tfvars · rationale → ADRs · live state → as-built — all in the consumer repo |

## What stays in each stack repo

| Path | Purpose |
| --- | --- |
| `docs/specification/product/` | Infra spec: components, per-env matrix, SLOs, cost ceiling |
| `docs/specification/adr/` | Why it runs the way it runs (ADR-0001 = environment topology) |
| `docs/specification/as-built/` | What is live today |
| `envs/*/terraform.tfvars` | The machine-readable per-env decisions |
| `AGENTS.md` | Agent router and harness pin |

## Release process (maintainers)

1. Branch `rules/<short-description>`; peer review required
2. Machine-checkable rule changes include their rego mirror in the same PR
3. Bump `VERSION` (tightened policy or breaking consumer change = MAJOR)
4. Update README + CHANGELOG → PR → tag `vX.Y.Z` → update tenant approved pairs
