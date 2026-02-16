---
layout: default
title: Package Repository
---

# CX Linux APT Repository

Official package repository for CX Linux.

## Quick Setup

```bash
# 1. Add GPG key
curl -fsSL https://repo.cxlinux.ai/pub.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cx-archive-keyring.gpg

# 2. Add repository
echo "deb [signed-by=/usr/share/keyrings/cx-archive-keyring.gpg] https://repo.cxlinux.ai cx main" | sudo tee /etc/apt/sources.list.d/cx.list

# 3. Update and install
sudo apt update
sudo apt install cx-branding
```

## Available Packages

| Package | Description |
|---------|-------------|
| `cx-branding` | Visual identity, themes, wallpapers |
| `cx-core` | Core system tools (coming soon) |
| `cx-full` | Complete desktop meta-package (coming soon) |

## Repository Structure


