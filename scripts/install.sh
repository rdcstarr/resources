#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Install repo scripts into a directory on this machine.

Usage:
  ./scripts/install.sh            # installs to /usr/local/bin
  ./scripts/install.sh <dest>     # installs to <dest>

Examples:
  sudo ./scripts/install.sh
  ./scripts/install.sh "$HOME/.local/bin"
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

dest="${1:-/usr/local/bin}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

need_sudo=""
if [[ ! -d "$dest" ]]; then
    need_sudo="sudo"
fi
if [[ -d "$dest" && ! -w "$dest" ]]; then
    need_sudo="sudo"
fi

$need_sudo mkdir -p "$dest"

installed=0
for src in "$script_dir"/*; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src")"
    if [[ "$base" == "install.sh" || "$base" == "install" ]]; then
        continue
    fi
    
    $need_sudo install -m 0755 "$src" "$dest/$base"
    echo "Installed: $dest/$base"
    installed=$((installed + 1))
done

if [[ $installed -eq 0 ]]; then
    echo "No scripts found to install in: $script_dir" >&2
    exit 1
fi
