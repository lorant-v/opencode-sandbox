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

- `~/.local/bin/osb` -> `~/.local/share/opencode-sandbox/scripts/osb`

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
command -v osb
```

## Usage

From any project or workspace directory:

```bash
osb
```

This always rebuilds the image for your current UID/GID, then mounts the current
directory at `/workspace`.

By default, OpenCode state uses `host` mode, which shares these host directories
with the container:

- `~/.config/opencode`
- `~/.cache/opencode`
- `~/.local/share/opencode`

Common launcher-only commands:

```bash
osb --help
osb --init-mounts
osb --state-mode container
```

Choose how OpenCode state is stored:

```bash
osb --state-mode host
osb --state-mode container
```

- `host` - share OpenCode config, cache, and data with the host
- `container` - keep OpenCode config, cache, and data in Docker volumes

Pass extra OpenCode arguments after `--`:

```bash
osb -- --help
osb --state-mode container -- --version
osb -- --version
osb -- run "summarize this repo"
osb -- run --help
```

Pass arguments directly to `docker compose run` after `--compose`:

```bash
osb --compose --entrypoint sh
osb --compose -e FOO=bar --entrypoint sh
osb --state-mode container --compose --entrypoint sh
osb --compose --entrypoint sh -- -lc 'id && pwd && ls'
osb --compose --service-ports --entrypoint sh
```

Rule of thumb:

- No separator: launcher arguments like `--help` or `--init-mounts`
- After `--compose`: `docker compose run` arguments like `--entrypoint sh`
- After `--`: OpenCode arguments like `run`, `--help`, or `--version`

## Optional project mount overrides

Generate a starter file in the current directory:

```bash
osb --init-mounts
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
  `compose.yaml` plus a state-mode overlay.
- Drops all Linux capabilities and enables `no-new-privileges`.
- Mounts only the current directory plus any explicit paths from the optional
  project override file.
- Supports either host-shared or container-only OpenCode state.
- Does not mount the full home directory, SSH keys, or the Docker socket.

This is a hardened local container workflow, not a microVM. Writable bind mounts
remain writable to code running inside the container.

## Persistence model

Choose one of two modes with `--state-mode`:

- `host` (default)
  - shares host `~/.config/opencode`
  - shares host `~/.cache/opencode`
  - shares host `~/.local/share/opencode`
- `container`
  - stores OpenCode config in a Docker volume
  - stores OpenCode cache in a Docker volume
  - stores OpenCode data in a Docker volume

In both modes, project files stay on the host at `/workspace` and the container
itself remains disposable.

## Repository layout

- `scripts/osb` - launcher you install on `PATH`
- `docker/Dockerfile` - wrapper image based on the official OpenCode image
- `docker/compose.yaml` - shared runtime definition
- `docker/compose.host.yaml` - host-shared OpenCode state mounts
- `docker/compose.container.yaml` - container-only OpenCode state volumes
- `docker/sandbox-mounts.example.yaml` - starter Compose override fragment
- `install/install.sh` - symlink-based installer for typical Linux setups

## Validation

Recommended checks:

```bash
docker --version
docker compose version
bash -n ~/.local/share/opencode-sandbox/scripts/osb
bash -n ~/.local/share/opencode-sandbox/install/install.sh
HOST_OPENCODE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode" \
HOST_OPENCODE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/opencode" \
HOST_OPENCODE_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencode" \
docker compose -f ~/.local/share/opencode-sandbox/docker/compose.yaml \
  -f ~/.local/share/opencode-sandbox/docker/compose.host.yaml config
```

Smoke test from a project directory:

```bash
osb -- --version
```
