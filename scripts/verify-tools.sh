#!/bin/bash
set -e

# Quick verification script
echo "Node: $(node --version)"
echo "npm: $(npm --version)"
echo "Composer: $(composer --version)"
echo "PHP: $(php --version)"
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "Terraform: $(terraform --version)"
echo "doctl: $(doctl version)"
echo "gh: $(gh --version)"

# Test Docker
docker run hello-world
```

**Expected output:**
```
Node: v2x.x.x
npm: 1x.x.x
Composer: version 2.x.x
PHP: 8.4.x
Docker: version 24.x.x
Docker Compose: version v2.x.x
Terraform: v1.x.x
doctl: doctl version 1.x.x
gh: gh version 2.x.x

# Docker hello-world should run successfully
