#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Bootstrap/update this repo on a server, then install scripts into PATH.

Intended usage (remote):
  wget -qO- https://git.recwebnetwork.com/scripts/update-scripts.sh | sudo bash

Env vars:
  RESOURCES_REPO_URL   Git repo URL to clone/pull
  RESOURCES_REF        Git ref to checkout (branch/tag/commit). Default: main
  RESOURCES_DIR        Where to clone the repo. Default: /opt/resources
  RESOURCES_INSTALL_TO Where to install scripts. Default: /usr/local/bin

Examples:
  RESOURCES_REF=stable wget -qO- https://git.recwebnetwork.com/scripts/update-scripts.sh | sudo bash
  RESOURCES_INSTALL_TO="$HOME/.local/bin" bash ./scripts/update-scripts.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# NOTE: set this to your canonical git URL for this repo.
repo_url="${RESOURCES_REPO_URL:-}"
ref="${RESOURCES_REF:-main}"
repo_dir="${RESOURCES_DIR:-/opt/resources}"
install_to="${RESOURCES_INSTALL_TO:-/usr/local/bin}"

if [[ -z "$repo_url" ]]; then
	cat <<'EOF' >&2
RESOURCES_REPO_URL is not set.

Set it to the git clone URL of this repository, e.g.:
  export RESOURCES_REPO_URL="https://git.recwebnetwork.com/<owner>/<repo>.git"

Then run again.
EOF
    exit 2
fi

need_sudo=""
if [[ ${EUID:-0} -ne 0 ]]; then
    need_sudo="sudo"
fi

ensure_git() {
    if command -v git >/dev/null 2>&1; then
        return 0
    fi
    
    # Best-effort install for Debian/Ubuntu.
    if command -v apt-get >/dev/null 2>&1; then
        $need_sudo apt-get update -qq
        $need_sudo apt-get install -y git >/dev/null
        return 0
    fi
    
    echo "git is required but was not found." >&2
    echo "Install git and re-run." >&2
    exit 1
}

ensure_git

# Clone or update the repo
if [[ -d "$repo_dir/.git" ]]; then
    echo "Updating repo in: $repo_dir"
    $need_sudo git -C "$repo_dir" fetch --prune --tags
    $need_sudo git -C "$repo_dir" checkout -q "$ref" || $need_sudo git -C "$repo_dir" checkout -q -B "$ref" "origin/$ref"
    $need_sudo git -C "$repo_dir" pull --ff-only
else
    echo "Cloning repo to: $repo_dir"
    $need_sudo mkdir -p "$(dirname "$repo_dir")"
    $need_sudo git clone "$repo_url" "$repo_dir"
    $need_sudo git -C "$repo_dir" checkout -q "$ref" || true
fi

# Install scripts
if [[ ! -f "$repo_dir/scripts/install.sh" ]]; then
    echo "Missing installer: $repo_dir/scripts/install.sh" >&2
    exit 1
fi

echo "Installing scripts to: $install_to"
$need_sudo bash "$repo_dir/scripts/install.sh" "$install_to"

echo "Done. Try: $(basename "$install_to")/goto or just 'goto' if $install_to is in PATH."
