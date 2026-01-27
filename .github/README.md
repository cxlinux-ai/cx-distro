# CX Linux CI/CD

This directory contains GitHub Actions workflows for automated building and testing of CX Linux.

## Workflows

### `build-iso.yml` - ISO Builder 🚀

**Automatically builds CX Linux ISOs on every push to main branch**

#### Triggers:
- ✅ **Push to main** - Builds offline ISO by default
- ✅ **Pull requests** - Builds to test changes
- ✅ **Manual dispatch** - Choose build type (offline/netinst/all)

#### What it does:
1. **Frees up disk space** - Removes unnecessary GitHub runner packages
2. **Installs dependencies** - Uses `make deps` to install build tools
3. **Runs verification** - Tests Ubuntu 24.04 configuration
4. **Builds packages** - Creates .deb packages for CX components
5. **Builds ISO** - Runs `make iso-offline` (or selected type)
6. **Generates SBOM** - Creates Software Bill of Materials
7. **Uploads artifacts** - ISO files available for download
8. **Creates release** - Automatic GitHub release on main branch

#### Build Types:
- `offline` - Full ISO with all packages (~2-4GB)
- `netinst` - Network installer (~500MB)
- `all` - Both offline and netinst

#### Outputs:
- **ISO files** - Bootable CX Linux images
- **Checksums** - SHA256/SHA512 verification files
- **Build logs** - Complete build output for debugging
- **SBOM** - Software Bill of Materials for security

## Usage

### Automatic Builds
Just push to main branch:
```bash
git push origin main
```

The workflow will automatically build and create a GitHub release with the ISO.

### Manual Builds
Go to GitHub Actions tab → "Build CX Linux ISO" → "Run workflow" → Choose build type

### Download ISOs
1. Go to GitHub releases
2. Download `cx-linux-*.iso` file
3. Verify with provided checksums:
   ```bash
   sha256sum -c SHA256SUMS
   ```

## Build Environment

- **Runner**: `ubuntu-24.04` (GitHub's latest Ubuntu LTS)
- **Timeout**: 120 minutes (ISO builds can take time)
- **Disk space**: ~20GB available after cleanup
- **Cache**: Live-build components cached for faster rebuilds

## Monitoring

### Successful Build
✅ Green checkmark on commit
✅ New GitHub release created
✅ ISO artifacts available for download

### Failed Build
❌ Red X on commit
📋 Build logs available in failed workflow
🔍 Check Ubuntu verification step first

## Security

- All builds run in GitHub's secure runners
- SBOM generated for supply chain security
- Checksums provided for ISO integrity
- Build logs preserved for audit

## Local Testing

Test the workflow configuration locally:
```bash
# Verify Ubuntu configuration
./tests/verify-ubuntu.sh

# Test package builds
make package

# Test ISO build (requires Ubuntu/Debian)
make iso
```

---
**Ready for cloud-based CX Linux ISO builds! 🎉**