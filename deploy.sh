#!/bin/bash

# Exit on error and pipe failures (temporarily disable -u for BASH_SOURCE check)
set -eo pipefail

# Get the directory where this script is located
# If script is executed via curl, use current directory or /tmp
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "${SCRIPT_SOURCE}" ] && [ -f "${SCRIPT_SOURCE}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_SOURCE}")" && pwd)"
else
    # Script executed via curl, use current directory or /tmp
    SCRIPT_DIR="${PWD:-/tmp}"
fi

# Re-enable strict mode (including -u for undefined variables)
set -euo pipefail

# GitHub repository URL (can be overridden by GITHUB_REPO env variable)
# Default: extract from script URL if available, or use default
GITHUB_REPO="${GITHUB_REPO:-https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main}"

# Script URLs
DEPLOY_DOCKER_SCRIPT_URL="${GITHUB_REPO}/deploy-docker.sh"
DEPLOY_SSL_SCRIPT_URL="${GITHUB_REPO}/deploy-domain-ssl.sh"

echo "=========================================="
echo "🚀 Starting full deployment process"
echo "=========================================="
echo ""

# Step 1: Deploy Docker containers
echo "🐳 Step 1: Deploying Docker containers..."
echo "----------------------------------------"
if bash <(curl -fsSL "${DEPLOY_DOCKER_SCRIPT_URL}"); then
    echo ""
    echo "✅ Docker deployment completed successfully"
    echo ""
else
    echo ""
    echo "❌ Error: Docker deployment failed" >&2
    exit 1
fi

# Step 2: Setup Nginx and SSL
echo "🔒 Step 2: Setting up Nginx and SSL..."
echo "----------------------------------------"
if bash <(curl -fsSL "${DEPLOY_SSL_SCRIPT_URL}"); then
    echo ""
    echo "✅ Nginx and SSL setup completed successfully"
    echo ""
else
    echo ""
    echo "❌ Error: Nginx and SSL setup failed" >&2
    exit 1
fi

# Final success message
echo "=========================================="
echo "🎉 Full deployment completed successfully!"
echo "=========================================="

