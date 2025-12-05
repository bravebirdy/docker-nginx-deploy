#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Configuration paths
NGINX_CONF_DIR="/etc/nginx/conf.d"
LETSENCRYPT_LIVE="/etc/letsencrypt/live"

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
    # Temporarily allow unset variables for source
    set +u
    source ".env"
    set -u
else
    echo "⚠️  Warning: .env file not found in current directory" >&2
    echo "Some cleanup operations may be skipped." >&2
fi

# Set defaults
PROJECT_NAME="${PROJECT_NAME:-docker-project}"
COMPOSE_FILE_PATH="${COMPOSE_FILE_PATH:-docker-compose.yaml}"

echo "=========================================="
echo "🗑️  Starting cleanup process"
echo "=========================================="
echo ""

# Step 1: Stop and remove Docker containers
echo "🐳 Step 1: Stopping and removing Docker containers..."
echo "----------------------------------------"

if [ -f "${COMPOSE_FILE_PATH}" ]; then
    echo "📋 Configuration:"
    echo "   Project name: ${PROJECT_NAME}"
    echo "   Compose file: ${COMPOSE_FILE_PATH}"
    echo ""
    
    if docker compose -f "${COMPOSE_FILE_PATH}" -p "${PROJECT_NAME}" ps -q 2>/dev/null | grep -q .; then
        echo "🛑 Stopping containers..."
        docker compose -f "${COMPOSE_FILE_PATH}" -p "${PROJECT_NAME}" down -v
        echo "✅ Docker containers stopped and removed"
    else
        echo "ℹ️  No running containers found for project: ${PROJECT_NAME}"
    fi
else
    echo "⚠️  Warning: Docker Compose file not found: ${COMPOSE_FILE_PATH}"
    echo "   Skipping Docker cleanup"
fi

echo ""

# Step 2: Remove Nginx configuration
echo "🌐 Step 2: Removing Nginx configuration..."
echo "----------------------------------------"

if [ -z "${DOMAIN_NAME:-}" ]; then
    echo "⚠️  Warning: DOMAIN_NAME not found in .env"
    echo "   Skipping Nginx configuration removal"
else
    NGINX_CONF="${NGINX_CONF_DIR}/${DOMAIN_NAME}.conf"
    
    if [ -f "${NGINX_CONF}" ]; then
        echo "📝 Removing Nginx config: ${NGINX_CONF}"
        sudo rm -f "${NGINX_CONF}"
        
        # Test and reload nginx
        if sudo nginx -t >/dev/null 2>&1; then
            sudo nginx -s reload
            echo "✅ Nginx configuration removed and reloaded"
        else
            echo "⚠️  Warning: Nginx configuration test failed after removal"
            echo "   You may need to manually fix Nginx configuration"
        fi
    else
        echo "ℹ️  Nginx configuration file not found: ${NGINX_CONF}"
    fi
fi

echo ""

# Step 3: Remove SSL certificate
echo "🔒 Step 3: Removing SSL certificate..."
echo "----------------------------------------"

if [ -z "${DOMAIN_NAME:-}" ]; then
    echo "⚠️  Warning: DOMAIN_NAME not found in .env"
    echo "   Skipping SSL certificate removal"
else
    CERT_DIR="${LETSENCRYPT_LIVE}/${DOMAIN_NAME}"
    
    if [ -d "${CERT_DIR}" ]; then
        echo "🗑️  Removing SSL certificate for: ${DOMAIN_NAME}"
        
        # Use certbot to revoke and delete certificate if certbot is available
        if command -v certbot >/dev/null 2>&1; then
            echo "📝 Revoking certificate via certbot..."
            sudo certbot delete --cert-name "${DOMAIN_NAME}" --non-interactive --quiet 2>/dev/null || {
                echo "⚠️  Warning: Failed to revoke certificate via certbot"
                echo "   Attempting manual removal..."
                sudo rm -rf "${CERT_DIR}"
            }
            echo "✅ SSL certificate revoked and removed"
        else
            echo "⚠️  Warning: certbot not found, removing certificate directory manually"
            sudo rm -rf "${CERT_DIR}"
            echo "✅ SSL certificate directory removed"
        fi
    else
        echo "ℹ️  SSL certificate directory not found: ${CERT_DIR}"
    fi
fi

echo ""

# Final summary
echo "=========================================="
echo "🎉 Cleanup process completed!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "   ✅ Docker containers: Stopped and removed"
if [ -n "${DOMAIN_NAME:-}" ]; then
    echo "   ✅ Nginx config: Removed (${DOMAIN_NAME}.conf)"
    echo "   ✅ SSL certificate: Removed (${DOMAIN_NAME})"
else
    echo "   ⚠️  Nginx/SSL: Skipped (DOMAIN_NAME not configured)"
fi
echo ""

