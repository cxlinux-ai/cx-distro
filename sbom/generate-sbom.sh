#!/bin/bash
# CX Linux SBOM Generation
# Generates Software Bill of Materials in CycloneDX and SPDX formats
# Copyright 2025 AI Venture Holdings LLC
# SPDX-License-Identifier: BUSL-1.1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-${SCRIPT_DIR}/../output/sbom}"
VERSION="${CX_VERSION:-0.1.0}"
DATE=$(date -Iseconds)
UUID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")

GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $*"; }

mkdir -p "$OUTPUT_DIR"

log "Generating SBOM for CX Linux v${VERSION}"

# Generate CycloneDX SBOM
cat > "${OUTPUT_DIR}/cx-linux-${VERSION}.cdx.json" << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:${UUID}",
  "version": 1,
  "metadata": {
    "timestamp": "${DATE}",
    "tools": [{"vendor": "AI Venture Holdings LLC", "name": "cx-sbom-generator", "version": "1.0.0"}],
    "component": {
      "type": "operating-system",
      "name": "CX Linux",
      "version": "${VERSION}",
      "description": "AI-Native Linux Distribution",
      "supplier": {"name": "AI Venture Holdings LLC", "url": ["https://cxlinux-ai.com"]},
      "licenses": [{"license": {"id": "Apache-2.0"}}]
    }
  },
  "components": [
    {"type": "library", "name": "cx-core", "version": "${VERSION}", "purl": "pkg:deb/cx/cx-core@${VERSION}"},
    {"type": "library", "name": "cx-full", "version": "${VERSION}", "purl": "pkg:deb/cx/cx-full@${VERSION}"},
    {"type": "operating-system", "name": "Debian", "version": "13", "purl": "pkg:generic/debian@13"},
    {"type": "library", "name": "python3", "version": "3.11", "purl": "pkg:deb/debian/python3@3.11"},
    {"type": "library", "name": "firejail", "purl": "pkg:deb/debian/firejail"},
    {"type": "library", "name": "apparmor", "purl": "pkg:deb/debian/apparmor"}
  ]
}
EOF

log "CycloneDX: ${OUTPUT_DIR}/cx-linux-${VERSION}.cdx.json"

# Generate SPDX SBOM
cat > "${OUTPUT_DIR}/cx-linux-${VERSION}.spdx.json" << EOF
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "CX Linux ${VERSION}",
  "documentNamespace": "https://cxlinux-ai.com/spdx/${VERSION}",
  "creationInfo": {"created": "${DATE}", "creators": ["Organization: AI Venture Holdings LLC", "Tool: cx-sbom-generator-1.0.0"]},
  "packages": [
    {"SPDXID": "SPDXRef-cx-linux", "name": "CX Linux", "versionInfo": "${VERSION}", "licenseConcluded": "Apache-2.0", "downloadLocation": "https://cxlinux-ai.com"},
    {"SPDXID": "SPDXRef-cx-core", "name": "cx-core", "versionInfo": "${VERSION}", "licenseConcluded": "Apache-2.0", "downloadLocation": "https://repo.cxlinux-ai.com"},
    {"SPDXID": "SPDXRef-debian", "name": "Debian", "versionInfo": "13", "licenseConcluded": "NOASSERTION", "downloadLocation": "https://debian.org"}
  ],
  "relationships": [
    {"spdxElementId": "SPDXRef-DOCUMENT", "relatedSpdxElement": "SPDXRef-cx-linux", "relationshipType": "DESCRIBES"},
    {"spdxElementId": "SPDXRef-cx-linux", "relatedSpdxElement": "SPDXRef-cx-core", "relationshipType": "CONTAINS"},
    {"spdxElementId": "SPDXRef-cx-linux", "relatedSpdxElement": "SPDXRef-debian", "relationshipType": "DEPENDS_ON"}
  ]
}
EOF

log "SPDX: ${OUTPUT_DIR}/cx-linux-${VERSION}.spdx.json"
log "SBOM generation complete"
