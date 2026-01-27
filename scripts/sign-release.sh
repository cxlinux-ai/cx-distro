#!/bin/bash
# sign-release.sh - Sign APT Release files with GPG
#
# This script signs the Release file in each distribution directory
# to create InRelease (clearsigned) and Release.gpg (detached signature)
#
# Usage: ./scripts/sign-release.sh [GPG_KEY_ID]
#
# Environment variables:
#   GPG_KEY_ID       - GPG key ID to sign with (or pass as argument)
#   GPG_PASSPHRASE   - Optional passphrase for the key
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DISTS_DIR="${REPO_ROOT}/dists"

# Get GPG key ID from argument or environment
GPG_KEY_ID="${1:-${GPG_KEY_ID:-}}"

if [ -z "$GPG_KEY_ID" ]; then
    echo "Error: GPG_KEY_ID not set"
    echo "Usage: $0 <GPG_KEY_ID>"
    echo "   or: GPG_KEY_ID=<key> $0"
    exit 1
fi

echo "Signing Release files with key: $GPG_KEY_ID"

# Configure GPG for non-interactive use
GPG_OPTS="--batch --yes --armor"

if [ -n "${GPG_PASSPHRASE:-}" ]; then
    GPG_OPTS="$GPG_OPTS --pinentry-mode loopback --passphrase-fd 0"
fi

# Find and sign all Release files
find "$DISTS_DIR" -name "Release" -type f | while read -r release_file; do
    dist_dir="$(dirname "$release_file")"
    echo "Signing: $release_file"

    # Remove old signatures
    rm -f "${dist_dir}/Release.gpg" "${dist_dir}/InRelease"

    # Create detached signature (Release.gpg)
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        echo "$GPG_PASSPHRASE" | gpg $GPG_OPTS -u "$GPG_KEY_ID" \
            --detach-sign -o "${dist_dir}/Release.gpg" "$release_file"
    else
        gpg $GPG_OPTS -u "$GPG_KEY_ID" \
            --detach-sign -o "${dist_dir}/Release.gpg" "$release_file"
    fi
    echo "  Created: ${dist_dir}/Release.gpg"

    # Create clearsigned file (InRelease)
    if [ -n "${GPG_PASSPHRASE:-}" ]; then
        echo "$GPG_PASSPHRASE" | gpg $GPG_OPTS -u "$GPG_KEY_ID" \
            --clearsign -o "${dist_dir}/InRelease" "$release_file"
    else
        gpg $GPG_OPTS -u "$GPG_KEY_ID" \
            --clearsign -o "${dist_dir}/InRelease" "$release_file"
    fi
    echo "  Created: ${dist_dir}/InRelease"
done

echo "Done! All Release files signed."
