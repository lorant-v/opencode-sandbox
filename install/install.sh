#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
SOURCE_SCRIPT="$REPO_ROOT/scripts/osb"
BIN_DIR="${HOME}/.local/bin"
TARGET_SCRIPT="$BIN_DIR/osb"

guess_shell_rc() {
  local shell_name
  shell_name=$(basename "${SHELL:-}")

  case "$shell_name" in
    zsh)
      printf '%s/.zshrc' "$HOME"
      ;;
    bash|*)
      printf '%s/.bashrc' "$HOME"
      ;;
  esac
}

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

[[ -f "$SOURCE_SCRIPT" ]] || fail "launcher not found: $SOURCE_SCRIPT"

mkdir -p "$BIN_DIR"

if [[ -L "$TARGET_SCRIPT" ]]; then
  CURRENT_TARGET=$(readlink "$TARGET_SCRIPT")
  if [[ "$CURRENT_TARGET" == "$SOURCE_SCRIPT" ]]; then
    printf 'symlink already installed: %s -> %s\n' "$TARGET_SCRIPT" "$SOURCE_SCRIPT"
  else
    ln -sfn "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
    printf 'updated symlink: %s -> %s\n' "$TARGET_SCRIPT" "$SOURCE_SCRIPT"
  fi
elif [[ -e "$TARGET_SCRIPT" ]]; then
  fail "target exists and is not a symlink: $TARGET_SCRIPT"
else
  ln -s "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
  printf 'installed symlink: %s -> %s\n' "$TARGET_SCRIPT" "$SOURCE_SCRIPT"
fi

case ":$PATH:" in
  *":$BIN_DIR:"*)
    printf '%s is already on PATH\n' "$BIN_DIR"
    ;;
  *)
    RC_FILE=$(guess_shell_rc)
    printf '\nAdd this line to your shell rc file to make it permanent:\n'
    printf '  export PATH="%s:$PATH"\n' "$BIN_DIR"
    printf '\nSuggested file: %s\n' "$RC_FILE"
    printf '\nThen reload your shell, for example:\n'
    printf '  source %s\n' "$RC_FILE"
    ;;
esac

printf '\nVerify with:\n'
printf '  command -v osb\n'
