#!/usr/bin/env bash
set -euo pipefail

# claude-bell installer
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/claude-bell/main/install.sh | bash

PREFIX="${CLAUDE_BELL_PREFIX:-/usr/local}"
REPO="https://github.com/USER/claude-bell"
BRANCH="main"

printf 'Installing claude-bell to %s...\n' "${PREFIX}"

# Create temp directory
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

# Download
if command -v curl &>/dev/null; then
    curl -fsSL "${REPO}/archive/refs/heads/${BRANCH}.tar.gz" -o "${TMP}/archive.tar.gz"
elif command -v wget &>/dev/null; then
    wget -q "${REPO}/archive/refs/heads/${BRANCH}.tar.gz" -O "${TMP}/archive.tar.gz"
else
    printf 'Error: curl or wget required.\n' >&2
    exit 1
fi

# Extract and install
tar -xzf "${TMP}/archive.tar.gz" -C "${TMP}"
cd "${TMP}/claude-bell-${BRANCH}"

# Use sudo if needed
if [[ -w "${PREFIX}/bin" ]]; then
    make install PREFIX="${PREFIX}"
else
    printf 'Need sudo for install to %s\n' "${PREFIX}"
    sudo make install PREFIX="${PREFIX}"
fi

printf '\nclaude-bell installed successfully!\n'
printf 'Run "claude-bell --version" to verify.\n'
