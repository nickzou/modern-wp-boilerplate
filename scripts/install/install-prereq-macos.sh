#!/bin/bash

# Install required tools
brew install node
brew install composer
brew install php
brew install terraform
brew install doctl
brew install gh

# Docker Desktop for Mac
brew install --cask docker

# Verify installations
node --version      # Should be 20+
composer --version  # Should be 2+
php --version       # Should be 8.4+
terraform --version
doctl version
gh --version
docker --version
docker-compose --version

# Start Docker Desktop
open -a Docker
