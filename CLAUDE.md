# APT-REPO - Debian Package Repository

## Purpose
Hosts the official CX Linux APT repository for Debian/Ubuntu package distribution.

## Repo Role in Ecosystem
- **Distribution channel** - how users install CX Linux
- Receives packages from CI/CD of other repos
- Standalone infrastructure

## Key Directories
```
apt-repo/
├── dists/
│   ├── stable/           # Stable releases
│   ├── testing/          # Beta releases
│   └── unstable/         # Nightly builds
├── pool/
│   └── main/             # Package files (.deb)
├── scripts/
│   ├── add-package.sh    # Add new package
│   ├── sign-repo.sh      # GPG signing
│   └── update-repo.sh    # Regenerate metadata
└── keys/
    └── cx.gpg.pub        # Public signing key
```

## Adding the Repository (User Instructions)
```bash
# Add GPG key
curl -fsSL https://apt.cxlinux.com/keys/cx.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cx.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/cx.gpg] https://apt.cxlinux.com stable main" | sudo tee /etc/apt/sources.list.d/cx.list

# Install
sudo apt update
sudo apt install cx
```

## Maintainer Operations

### Adding a Package
```bash
./scripts/add-package.sh cx_0.2.0_amd64.deb stable
```

### Signing the Repository
```bash
./scripts/sign-repo.sh
```

### Updating Metadata
```bash
./scripts/update-repo.sh
```

## CI/CD Integration
Other repos push packages here via GitHub Actions:
1. Build creates `.deb` file
2. CI calls `add-package.sh` via SSH
3. Repository metadata auto-updated
4. Users get updates via `apt update`

## Hosting
- Served via GitHub Pages or Cloudflare R2
- CDN for global distribution
- HTTPS only

## GPG Key Management
- Private key in GitHub Secrets
- Rotate annually
- Document key fingerprint in README
