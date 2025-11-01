# Modern WordPress Boilerplate

A complete modern WordPress development and deployment system with infrastructure as code, automated DevOps workflows, and cutting-edge frontend tooling.

## ✨ Features

- 🏗️ **Infrastructure as Code** - Terraform + DigitalOcean
- 🚀 **Multi-Environment** - Prod, Staging, Dev + unlimited previews
- ⚡ **Performance** - Redis, Nginx caching, Cloudflare CDN, BladeOne templates
- 🎨 **Modern Frontend** - Tailwind 4, TypeScript, Alpine.js, Gutenberg blocks
- 🔐 **Security** - SSL, Fail2ban, UFW firewall
- 📊 **Monitoring** - Netdata real-time metrics
- 🧪 **Testing** - Pest PHP, TypeScript type checking

## 🚀 Quick Start

**5 minute setup:**
```bash
# 1. Clone repo
git clone git@github.com:yourusername/modern-wp-boilerplate.git
cd modern-wp-boilerplate

# 2. Copy and configure environment
cp .env.example .env
vim .env  # Fill in your values

# 3. Install dependencies
npm install

# 4. Setup local environment and development tools
npm run setup:local

# 5. Start local development
npm run env:start

# 6. Start developmen with hot reload
npm run watch

# 7. Deploy infrastructure (when you're ready)
npm run setup:infra
```

Visit: http://localhost:8888

**Need help?** See [Installation Guide](docs/INSTALLATION.md) for detailed setup.

## 📚 Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Prerequisites, tools, authentication
- **[Quick Start](docs/QUICK_START.md)** - Get up and running fast
- **[Development Guide](docs/DEVELOPMENT.md)** - Frontend workflow, local dev
- **[Deployment Guide](docs/DEPLOYMENT.md)** - CI/CD, production deploys
- **[Infrastructure Guide](docs/INFRASTRUCTURE.md)** - Terraform, server architecture
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 📋 Common Commands
```bash
# Development
npm run watch          # Start dev with hot reload
npm run dev            # Build for development
npm run prod           # Build for production

# Environment Management
npm run env:start      # Start local WordPress
npm run sync:local     # Pull production data to local
npm run sync:staging   # Sync prod → staging
npm run sync:dev       # Sync prod → dev

# Infrastructure
npm run ssh            # SSH into server
cd infrastructure && terraform apply  # Deploy changes
```

## 🏗️ Tech Stack

**Backend:** WordPress, PHP 8.4, MySQL 8.4, Nginx, Redis  
**Frontend:** Tailwind CSS 4, TypeScript, Alpine.js, BladeOne  
**Infrastructure:** Terraform, DigitalOcean, Cloudflare, Ubuntu 24.04  
**DevOps:** GitHub Actions, Docker (wp-env), Composer, Netdata

## 🌍 Environments

- **Production**: https://yourdomain.com
- **Staging**: https://staging.yourdomain.com
- **Dev**: https://dev.yourdomain.com
- **Monitoring**: https://monitoring.yourdomain.com
- **Previews**: https://feature-branch.yourdomain.com (auto-created)

## 💰 Cost

**~$12-13/month total**
- DigitalOcean Droplet: $12/month (2GB)
- Cloudflare: Free
- Domain: ~$10-15/year

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

ISC

## 👤 Author

**Nick Zou**

---

**⭐ Star this repo if you find it useful!**
