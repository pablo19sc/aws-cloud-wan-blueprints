# AGENTS.md

> **Purpose.** Written for an **AI agent working in a local clone** of this repository: editing a page, adding or changing a pattern, validating a change, or deploying a pattern to test a policy. For Cloud WAN knowledge and the workflow that turns requirements into a policy document, load [`SKILLS.md`](SKILLS.md). For a human introduction, start with [`README.md`](README.md).

## Find your way around

[`llms.txt`](llms.txt) is the index: every `policy/` page, `guidance/` page and `infra/` pattern, each with the question it answers. Read it before listing directories or searching.

| Tree | Contains | Organised by |
|------|----------|--------------|
| [`policy/`](policy/) | What a network policy can express, one page per area of the policy document | The policy document's top-level arrays, in assembly order |
| [`guidance/`](guidance/) | Scenario deep dives that compose several capabilities | The scenario, catalogued in [`guidance/README.md`](guidance/README.md) |
| [`infra/`](infra/) | Deployable CloudFormation and Terraform patterns | Which attachment types they create |

The trees are decoupled on purpose: **a use case is a policy, not a directory**. Do not look for a directory matching a requirement; compose the policy from the `policy/` pages, then pick the pattern that creates the attachment types it needs. The only complete policy documents in the repository are `infra/<pattern>/baseline*.json`.

## Rules that are easy to break

[`CONVENTIONS.md`](CONVENTIONS.md) is the authoritative contract. These are the rules a change most often breaks:

- **Never hand-edit `infra/*/cloudformation/core_network*.yaml`.** Each is generated from its suffix-paired `baseline*.json`, and CI fails when the two drift. Change the JSON, then keep the template in step — see [Baseline documents and generated CloudFormation](CONVENTIONS.md#baseline-documents-and-generated-cloudformation).
- **`policy/` and `guidance/` ship snippets only** — a fragment of one array, inline next to the prose that explains it. Never add a complete policy document there.
- **Keep the indexes in sync in the same change.** Adding, removing or renaming a page or pattern means updating `llms.txt` and the catalogs listed in [Catalog and agent-index synchronization](CONVENTIONS.md#catalog-and-agent-index-synchronization). A page missing from `llms.txt` is a bug.
- **Treat file paths as a public interface.** `llms.txt`, the `policy/` pages, `policy/README.md`, `guidance/README.md` and the `infra/<pattern>/README.md` files are linked by path from outside this repository, including the AWS Cloud WAN agent skill. Do not rename or move them without calling it out in the pull request.
- **Do not hard-wrap human-facing markdown.** One paragraph is one line.
- **Keep CloudFormation and Terraform in parity**, and put the MIT-0 license header on every new IaC source file.
- **Never invent policy syntax.** Confirm a field, action or match condition against the [AWS Cloud WAN policy documentation](https://docs.aws.amazon.com/network-manager/latest/cloudwan/cloudwan-policies-json.html) before writing it on a page.

## Validate a change

Every check is static: none needs AWS credentials or creates a resource. Run the ones that match what you changed, and say in your hand-back which ran and which did not.

| You changed | Run |
|-------------|-----|
| `policy/*.md`, `guidance/*.md`, `baseline*.json`, or a generated `core_network*.yaml` | `python3 .github/scripts/check_policies.py` (needs PyYAML `6.0.2`) |
| Any markdown file, or `llms.txt` | `lychee --no-progress --max-retries 2 --accept 200,206,429 <files>` |
| Terraform | `terraform fmt`, `terraform validate`, `tflint`, `terraform-docs` — through pre-commit |
| CloudFormation | `cfn-lint` — through pre-commit |
| Anything, before opening a pull request | `pre-commit run --all-files` |

The tool versions and install steps are in [Local checks (pre-commit)](CONTRIBUTING.md#local-checks-pre-commit); CI's job-by-job mapping is in [CI-aligned repository checks](CONVENTIONS.md#9-ci-aligned-repository-checks). If a tool is not installed, say so rather than reporting the check as passed.

## Contribute

Follow [`CONTRIBUTING.md`](CONTRIBUTING.md): work on a branch of a fork, open an issue first for significant work, and fill in the [pull request template](.github/pull_request_template.md) — its checklist mirrors the rules above for each area a change touches.

## Deploy a pattern to test a policy

- **Ask before deploying.** Every pattern creates billable resources in the user's account; Core Network Edges bill hourly per Region regardless of traffic. Read the pattern README's *Cost* section first, recommend a non-production account, and run the pattern's cleanup steps when finished.
- **Point a pattern at another policy** with the steps in [Deploying a policy of your own](infra/README.md#deploying-a-policy-of-your-own).
- **Keep the association contract.** The tags a pattern applies — or, for hybrid attachments, the attachment types it creates — must match the policy's `attachment-policies`, or attachments reach `AVAILABLE` and never associate — see [How attachments are associated](infra/README.md#how-attachments-are-associated).
- **Validate against the service before executing.** Creating a policy version produces a change set that changes nothing until executed; it is the authoritative check — see [Validating a policy](policy/README.md#validating-a-policy).
