#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Get the directory where this script is located
# If script is executed via curl, use current directory or /tmp
if [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Script executed via curl, use current directory or /tmp
    SCRIPT_DIR="${PWD:-/tmp}"
fi

# GitHub repository URL (can be overridden by GITHUB_REPO env variable)
# Default: extract from script URL if available, or use default
GITHUB_REPO="${GITHUB_REPO:-https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main}"

# Script paths
DEPLOY_DOCKER_SCRIPT="${SCRIPT_DIR}/deploy-docker.sh"
DEPLOY_SSL_SCRIPT="${SCRIPT_DIR}/deploy-domain-ssl.sh"

# Function to download script from GitHub
download_script() {
    local script_name=$1
    local script_path=$2
    local github_url="${GITHUB_REPO}/${script_name}"
    
    echo "📥 Downloading ${script_name}..."
    if curl -fsSL "${github_url}" -o "${script_path}"; then
        chmod +x "${script_path}"
        echo "✅ ${script_name} downloaded successfully"
        return 0
    else
        echo "❌ Error: Failed to download ${script_name} from ${github_url}" >&2
        return 1
    fi
}

# Check and download required scripts if they don't exist
if [ ! -f "${DEPLOY_DOCKER_SCRIPT}" ]; then
    if ! download_script "deploy-docker.sh" "${DEPLOY_DOCKER_SCRIPT}"; then
        exit 1
    fi
fi

if [ ! -f "${DEPLOY_SSL_SCRIPT}" ]; then
    if ! download_script "deploy-domain-ssl.sh" "${DEPLOY_SSL_SCRIPT}"; then
        exit 1
    fi
fi

# Make scripts executable (in case they were already present)
chmod +x "${DEPLOY_DOCKER_SCRIPT}" "${DEPLOY_SSL_SCRIPT}"

echo "=========================================="
echo "🚀 Starting full deployment process"
echo "=========================================="
echo ""

# Step 1: Deploy Docker containers
echo "🐳 Step 1: Deploying Docker containers..."
echo "----------------------------------------"
if bash "${DEPLOY_DOCKER_SCRIPT}"; then
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
if bash "${DEPLOY_SSL_SCRIPT}"; then
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

