#!/bin/bash
set -e

TARGET_ENV=$1

if [ -z "$TARGET_ENV" ]; then
    echo "Usage: npm run sync:env staging|dev"
    exit 1
fi

if [ -f .env ]; then
    source .env
else
    echo "❌ .env not found!"
    exit 1
fi

echo "⚠️  This will overwrite $TARGET_ENV with production data."
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

ssh root@$(cd infrastructure && terraform output -raw droplet_ip) "/root/scripts/sync-prod-to-env.sh $TARGET_ENV"
