# Repository Guidelines For Agents

This file is for agentic coding tools operating in this repository.
It summarizes the project layout, the safest commands to run, and the
coding conventions already used in the codebase.

## Scope And Current State

- This repository is a Docker-based sandbox wrapper for running OpenCode.
- Primary implementation languages: Bash, Dockerfile syntax, and Docker Compose YAML.
- Main user-facing entrypoint: `scripts/osb`.
- Installer entrypoint: `install/install.sh`.
- Container image definition: `docker/Dockerfile`.
- Compose definitions: `docker/compose.yaml`, `docker/compose.host.yaml`, `docker/compose.container.yaml`.
- There is no app framework manifest such as `package.json`, `pyproject.toml`, `go.mod`, or `Cargo.toml` at the repo root.
- There is no dedicated unit test framework configured in this repository today.
- There is no repo-local Cursor rule file in `.cursor/rules/` or `.cursorrules`.
- There is no repo-local Copilot rule file at `.github/copilot-instructions.md`.

## Working Principles

- Make small, reviewable changes.
- Preserve the launcher's security and isolation defaults unless the task explicitly requires changing them.
- Favor changes that keep `osb` predictable from any current working directory.
- Treat this as an infrastructure repo, not an application repo.
- Do not invent frameworks, linters, or test commands that do not exist.
- If you add new validation commands, also update `README.md` when appropriate.

## Repository Layout

- `scripts/osb`: main launcher script installed on `PATH` as `osb`.
- `install/install.sh`: symlink-based installer for local Linux setups.
- `docker/Dockerfile`: wrapper image based on `ghcr.io/anomalyco/opencode`.
- `docker/compose.yaml`: shared runtime definition and project mount.
- `docker/compose.host.yaml`: host-shared OpenCode state mounts.
- `docker/compose.container.yaml`: container-only OpenCode state volumes.
- `docker/sandbox-mounts.example.yaml`: example additive mounts override.
- `README.md`: user-facing setup, usage, and validation guidance.

## Build And Run Commands

Use these commands when validating changes.

- Install launcher symlink:
  - `./install/install.sh`
- Show launcher help:
  - `./scripts/osb --help`
- Run OpenCode with default host-shared state:
  - `./scripts/osb`
- Run OpenCode with explicit host mode:
  - `./scripts/osb --state-mode host`
- Run OpenCode with explicit container mode:
  - `./scripts/osb --state-mode container`
- Pass arguments directly to OpenCode:
  - `./scripts/osb -- --version`
  - `./scripts/osb -- run --help`
- Pass arguments directly to `docker compose run`:
  - `./scripts/osb --compose --entrypoint sh`

## Lint And Validation Commands

There is no formal lint tool configured, so use syntax and config validation.

- Validate the main Bash launcher:
  - `bash -n /workspace/scripts/osb`
- Validate the installer script:
  - `bash -n /workspace/install/install.sh`
- Validate Compose config in host mode:
  - `docker compose -f /workspace/docker/compose.yaml -f /workspace/docker/compose.host.yaml config`
- Validate Compose config in container mode:
  - `docker compose -f /workspace/docker/compose.yaml -f /workspace/docker/compose.container.yaml config`
- Smoke test the full launcher path:
  - `./scripts/osb -- --version`

## Test Guidance

- There is no dedicated automated test suite in this repository.
- When asked to "run tests", choose the smallest relevant validation for the files you changed.
- For Bash-only changes, `bash -n` is the minimum required validation.
- For Compose-only changes, `docker compose ... config` is the minimum required validation.
- For changes affecting launcher behavior, run the smoke test `./scripts/osb -- --version` if Docker is available.
- If a task changes both launcher logic and Compose config, run both syntax checks and at least one smoke test.

## Running A Single Test

Since there is no test runner, "single test" means the smallest targeted check.

- Single script validation for the launcher:
  - `bash -n /workspace/scripts/osb`
- Single script validation for the installer:
  - `bash -n /workspace/install/install.sh`
- Single Compose validation in host mode:
  - `docker compose -f /workspace/docker/compose.yaml -f /workspace/docker/compose.host.yaml config`
- Single Compose validation in container mode:
  - `docker compose -f /workspace/docker/compose.yaml -f /workspace/docker/compose.container.yaml config`
- Single end-to-end smoke test:
  - `./scripts/osb -- --version`

## Bash Style Guidelines

- Use `#!/usr/bin/env bash` for Bash scripts.
- Keep `set -euo pipefail` at the top of executable scripts unless there is a strong reason not to.
- Prefer `lower_snake_case` for function names.
- Prefer uppercase names for script-level constants and environment-derived globals.
- Quote variable expansions by default: `"$var"`, `"${arr[@]}"`.
- Prefer `[[ ... ]]` over `[` for Bash conditionals.
- Prefer `case` statements over long `if` chains for option parsing.
- Use arrays for command construction instead of string concatenation.
- Use `local` inside functions for temporary variables.
- Keep functions short and focused around one responsibility.
- Prefer helper functions like `fail()` for consistent fatal error reporting.
- Print user-facing errors to stderr.
- Exit non-zero on invalid input or missing dependencies.
- Check for required commands with `command -v ... >/dev/null 2>&1`.
- Check for required files explicitly before using them.
- Keep output concise and actionable.

## Formatting Conventions

- Follow the existing 2-space indentation style in shell, YAML, and Dockerfile continuations.
- Keep line wrapping readable rather than aggressively compact.
- Match existing heredoc and usage-text formatting when editing CLI help output.
- Prefer one logical step per line in chained shell commands.
- Align related variable definitions in a simple top-of-file configuration block when practical.
- Avoid unnecessary comments; add them only when behavior is subtle or security-sensitive.

## Imports, Dependencies, And External Commands

- Bash has no imports, but external command dependencies should remain explicit and minimal.
- Existing required tools are `docker`, `docker compose`, and standard Unix utilities.
- Do not add new required dependencies unless the task clearly justifies them.
- If you add a dependency, document it in `README.md` and validate failure behavior in the script.
- Prefer portable shell utilities already used in the repo.
- Avoid hidden assumptions about host state beyond what the README documents.

## Naming Conventions

- Functions: `lower_snake_case`.
- Constants and top-level script variables: `UPPER_SNAKE_CASE`.
- Compose service and volume names should stay descriptive and stable.
- File names should remain lowercase with hyphen or dot separators, matching current repo patterns.
- Prefer names that describe intent, not implementation trivia.

## Error Handling Expectations

- Fail fast on missing arguments, missing files, invalid modes, or missing executables.
- Error messages should explain what failed and, when possible, which path or value caused it.
- Prefer explicit validation before side effects.
- Keep installer failures non-destructive; do not overwrite non-symlink files silently.
- Maintain current safety around mount file creation and state mode selection.
- When changing CLI behavior, keep `--help` output accurate.

## Dockerfile And Compose Guidelines

- Preserve the non-root runtime model unless the task explicitly requires a security change.
- Keep package installation consolidated in a single `RUN` layer when possible.
- Use `&&` chaining in Dockerfile setup steps so failures stop the build immediately.
- Keep `WORKDIR /workspace` aligned with launcher expectations.
- Preserve the `ENTRYPOINT ["opencode"]` contract unless coordinated with launcher changes.
- In Compose files, prefer explicit bind and volume objects with `type`, `source`, and `target` keys.
- Do not weaken `cap_drop: [ALL]` or `no-new-privileges:true` without clear justification.
- Keep host mode and container mode overlays narrowly scoped to state-storage differences.

## Agent-Specific Advice

- Before editing, inspect the touched file and follow its local patterns.
- Prefer targeted edits over rewrites, especially in shell scripts.
- Do not claim a lint or test suite exists when it does not.
- When reporting validation, be explicit about which checks were run and which were not run.
- If Docker is unavailable, say so clearly and fall back to syntax-only validation.
- If you add a real test harness in the future, update this file with exact single-test commands.
