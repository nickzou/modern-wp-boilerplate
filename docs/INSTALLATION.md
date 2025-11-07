## Installation Instructions

### macOS (Homebrew)

```bash
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
```

Can't be bothered? Just run:

```bash
bash ./scripts/install/install-prereq-macos.sh
```

### Linux (Ubuntu/Debian)

```bash
# Node.js
## Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

## in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

## Download and install Node.js:
nvm install 25

## Verify the Node.js version:
node -v # Should print "v25.1.0".

## Verify npm version:
npm -v # Should print "11.6.2".

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# PHP 8.4
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install php8.4 php8.4-cli php8.4-common

# Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (so you don't need sudo)
sudo usermod -aG docker $USER
newgrp docker

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# doctl
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.146.0-linux-amd64.tar.gz
tar xf ~/doctl-1.146.0-linux-amd64.tar.gz
sudo mv ~/doctl /usr/local/bin

# GitHub CLI
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y

# Verify Docker
docker run hello-world
```
