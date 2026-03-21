# OpenCode Sandbox

Docker-based local sandbox for running OpenCode with a small host surface area.

## Install

Clone the repo somewhere stable, then install the launcher symlink:

```bash
git clone <repo-url> ~/.local/share/opencode-sandbox
cd ~/.local/share/opencode-sandbox
./install/install.sh
```

This creates:

- `~/.local/bin/opencode-sandbox` -> `~/.local/share/opencode-sandbox/scripts/opencode-sandbox`

If `~/.local/bin` is not on your `PATH`, add this line permanently to your shell
rc file such as `~/.bashrc` or `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Reload your shell config:

```bash
source ~/.bashrc
```

For `zsh`, use:

```bash
source ~/.zshrc
```

Verify the install:

```bash
command -v opencode-sandbox
```

## Usage

From any project or workspace directory:

```bash
opencode-sandbox
```

This always rebuilds the image for your current UID/GID, then mounts the current
directory at `/workspace`.

Common launcher-only commands:

```bash
opencode-sandbox --help
opencode-sandbox --init-mounts
```

Pass extra OpenCode arguments after `--`:

```bash
opencode-sandbox -- --help
opencode-sandbox -- --version
opencode-sandbox -- run "summarize this repo"
opencode-sandbox -- run --help
```

Pass arguments directly to `docker compose run` after `--compose`:

```bash
opencode-sandbox --compose --entrypoint sh
opencode-sandbox --compose -e FOO=bar --entrypoint sh
opencode-sandbox --compose --entrypoint sh -- -lc 'id && pwd && ls'
opencode-sandbox --compose --service-ports --entrypoint sh
```

Rule of thumb:

- No separator: launcher arguments like `--help` or `--init-mounts`
- After `--compose`: `docker compose run` arguments like `--entrypoint sh`
- After `--`: OpenCode arguments like `run`, `--help`, or `--version`

## Optional project mount overrides

Generate a starter file in the current directory:

```bash
opencode-sandbox --init-mounts
```

This creates `./.opencode/sandbox-mounts.yaml`.

If that file exists, it is loaded as an additional Compose file. The default
`$PWD` -> `/workspace` mount still applies.

Typical use: keep a central workspace folder mounted at `/workspace`, then add
separately stored repos or notes under `/workspace/projects/...` or
`/workspace/notes`.

Notes and reference material should be mounted read-only unless you explicitly
need write access.

## Security model

- Uses the official `ghcr.io/anomalyco/opencode` image as the base image.
- Wraps it in a local `Dockerfile` that creates a fixed `opencode` user using
  the host UID/GID.
- Keeps build-time changes in `Dockerfile` and runtime hardening in
  `compose.yaml`.
- Drops all Linux capabilities and enables `no-new-privileges`.
- Mounts only the current directory plus any explicit paths from the optional
  project override file.
- Bind-mounts your host `~/.config/opencode` into the container so auth and
  config stay in sync.
- Does not mount the full home directory, SSH keys, or the Docker socket.

This is a hardened local container workflow, not a microVM. Writable bind mounts
remain writable to code running inside the container.

## Persistence model

The container is disposable. OpenCode state is persisted with named volumes for:

- `~/.cache/opencode`
- `~/.local/share/opencode`

Config and auth come from your host `~/.config/opencode`. Cache and data are
kept in Docker volumes between runs while project files stay on the host.

## Repository layout

- `scripts/opencode-sandbox` - launcher you install on `PATH`
- `docker/Dockerfile` - wrapper image based on the official OpenCode image
- `docker/compose.yaml` - runtime definition and persistent volumes
- `docker/sandbox-mounts.example.yaml` - starter Compose override fragment
- `install/install.sh` - symlink-based installer for typical Linux setups

## Validation

Recommended checks:

```bash
docker --version
docker compose version
bash -n ~/.local/share/opencode-sandbox/scripts/opencode-sandbox
bash -n ~/.local/share/opencode-sandbox/install/install.sh
docker compose -f ~/.local/share/opencode-sandbox/docker/compose.yaml config
```

Smoke test from a project directory:

```bash
opencode-sandbox -- --version
```
