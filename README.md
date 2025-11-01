# Modern WP Boilerplate

A production-ready WordPress development system combining modern DevOps practices with cutting-edge frontend tooling.

## Features

### 🏗️ Infrastructure & DevOps
- **Infrastructure as Code** - Terraform-managed DigitalOcean droplets
- **Multi-Environment** - Production, Staging, Dev + unlimited preview environments
- **Automated CI/CD** - GitHub Actions for testing and deployment
- **SSL & Security** - Automatic Wildcard SSL, Fail2ban, UFW firewall
- **Monitoring** - Real-time server metrics with Netdata
- **Backups** - Automated weekly backups with easy restore
- **Environment Sync** - One-command sync between environments

### ⚡ Performance
- **BladeOne Template Cache** - Pre-compiled Blade templates
- **Redis Object Cache** - Database query caching
- **Nginx FastCGI Cache** - Full page caching
- **Cloudflare CDN** - Global edge caching

### 📦 Dependency Management
- **Composer (Project)** - WordPress plugins, testing tools
- **Composer (Theme)** - Theme-specific dependencies (BladeOne)
- **npm** - Frontend tooling and build system
- **Modular Architecture** - Plugins, themes, and tools independently managed

### 🎨 Frontend Development
- **BladeOne Templates** - Standalone implementation of the Blade templating engine
- **Tailwind CSS 4** - Utility-first CSS with JIT compilation
- **TypeScript** - Type-safe JavaScript with hot reload
- **Alpine.js** - Lightweight reactive framework
- **Gutenberg Blocks** - Custom block development with @wordpress/scripts
- **Lightning CSS** - Ultra-fast CSS bundling and minification
- **Parcel** - Zero-config TypeScript bundler
- **Browser Sync** - Live reload during development

### 🧪 Testing & Quality
- **Pest PHP** - Modern PHP testing framework
- **TypeScript** - Static type checking
- **Biome** - Fast JS/TS linting and formatting
- **PHP Linting** - Built-in syntax checking

### 🛠️ Developer Experience
- **wp-env** - Local WordPress environment with Docker
- **Composer** - PHP dependency management
- **Code Quality** - PHP linting, formatting, and type checking
- **Watch Mode** - Auto-rebuild on file changes with parallel task execution
- **Hot Reloading** - Instant feedback during development
- **SSH Access** - Quick server access via npm scripts

## 🚀 Quick Start

### Prerequisites

#### Required Tools:
- Node.js 20+
- PHP 8.4+
- Composer 2+
- Docker
- Terraform
- GitHub CLI
- doctl (DigitalOcean CLI)
- DigitalOcean account
- Cloudflare account with domain
- SSH key pair

#### Required Accounts:
- DigitalOcean account
- Cloudflare account
- Domains registered and added to Cloudflare
- GitHub account
- SSH key pair

### 1. Create from Template

Click "Use this template" on GitHub or clone:
```bash
git clone git@github.com:yourusername/modern-wp-boilerplate.git my-project
cd my-project
```

### 2. Configure Environment Variables

Copy and rename the example file:
```bash
cp .env.example .env
```

Edit `.env` with your values:
```bash
vim .env # or use your preferred editor
```

Fill in the required values:
```bash
# Theme Configuration
THEME_SLUG=your-theme-name        # Your custom theme slug

# GitHub (for CI/CD)
REPO_OWNER=yourusername            # Your GitHub username
REPO_NAME=my-new-project           # Your repo name

# DigitalOcean
TF_DO_TOKEN=dop_v1_xxxxx          # Get from: cloud.digitalocean.com/account/api/tokens
TF_SSH_KEY_ID=12345678             # Get from: doctl compute ssh-key list
TF_PROJECT_NAME=MyProject          # Display name for droplet
TF_REGION=nyc3                     # Choose: nyc3, sfo3, lon1, fra1, etc.
TF_DROPLET_SIZE=s-1vcpu-2gb        # See: digitalocean.com/pricing

# Cloudflare
TF_CF_TOKEN=xxxxx                  # Get from: dash.cloudflare.com/profile/api-tokens
TF_CF_ZONE_ID=xxxxx                # Get from your domain's overview page
TF_DOMAIN_NAME=yourdomain.com      # Your domain

# Database Passwords (generate random strong passwords!)
TF_MYSQL_ROOT_PASSWORD=xxx
TF_WORDPRESS_PROD_PASSWORD=xxx
TF_WORDPRESS_STAGING_PASSWORD=xxx
TF_WORDPRESS_DEV_PASSWORD=xxx

# WordPress Admin
TF_WP_DEFAULT_USERNAME=admin
TF_WP_DEFAULT_USER_EMAIL=admin@yourdomain.com
TF_WP_DEFAULT_USER_PASSWORD=xxx    # Generate strong password!

# SSL & Monitoring
TF_SSL_EMAIL=admin@yourdomain.com
TF_MONITORING_PASSWORD=xxx         # For https://monitoring.yourdomain.com

# SSH Key
TF_SSH_PRIVATE_KEY_PATH=~/.ssh/id_ed25519  # Path to your private key
```

### 3. Install Dependencies
```bash
# Install Node dependencies
npm install

# Install all Composer dependencies (project + theme)
npm run composer:install
```

### 3. Set Up Infrastructure
```bash
npm run setup:infra
# Follow prompts to configure DigitalOcean, Cloudflare, domain, etc.

npm run setup:wp
# Follow prompts to configure WordPress theme name, etc.
```
```
