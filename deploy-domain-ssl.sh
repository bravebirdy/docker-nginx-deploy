#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Configuration paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NGINX_CONF_DIR="/etc/nginx/conf.d"
CERTBOT_WEBROOT="/var/www/certbot"
LETSENCRYPT_LIVE="/etc/letsencrypt/live"

# Validate environment variables
echo "🔍 Validating environment configuration..."

# Check if .env file exists
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo "❌ Error: .env file not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

# Source environment variables
set +u
source "${SCRIPT_DIR}/.env"
set -u

# Validate required variables
if [ -z "${DOMAIN_NAME:-}" ]; then
    echo "❌ Error: DOMAIN_NAME not found in .env" >&2
    exit 1
fi

if [ -z "${PORT:-}" ]; then
    echo "❌ Error: PORT not found in .env" >&2
    exit 1
fi

# Validate domain name format (supports multi-level domains)
# Pattern: one or more labels (alphanumeric, may contain hyphens) separated by dots, ending with TLD (2+ letters)
if [[ ! "${DOMAIN_NAME}" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
    echo "❌ Error: Invalid domain name format: ${DOMAIN_NAME}" >&2
    exit 1
fi

# Validate port number
if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
    echo "❌ Error: Invalid port number: ${PORT} (must be 1-65535)" >&2
    exit 1
fi

# Set email for SSL certificate
EMAIL="${SSL_EMAIL:-admin@${DOMAIN_NAME}}"
NGINX_CONF="${NGINX_CONF_DIR}/${DOMAIN_NAME}.conf"
CERT_DIR="${LETSENCRYPT_LIVE}/${DOMAIN_NAME}"

echo "📋 Configuration:"
echo "   Domain: ${DOMAIN_NAME}"
echo "   Port: ${PORT}"
echo "   Email: ${EMAIL}"
echo ""

# Step 1: Create Nginx HTTP configuration
echo "📝 Step 1: Creating Nginx HTTP configuration..."

# Create nginx config directory if it doesn't exist
sudo mkdir -p "${NGINX_CONF_DIR}"

# Generate nginx configuration
sudo tee "${NGINX_CONF}" > /dev/null <<EOF
server {
  listen 80;
  server_name ${DOMAIN_NAME};

  add_header X-Robots-Tag "noindex, nofollow";
  
  location / {
    proxy_pass http://localhost:${PORT};
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Referer \$http_referer;
    proxy_set_header Origin \$http_origin;
    
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
  }
  
  location /.well-known/acme-challenge/ {
    root ${CERTBOT_WEBROOT};
  }
}
EOF

# Test and reload nginx
if sudo nginx -t >/dev/null 2>&1; then
    sudo nginx -s reload
    echo "✅ Nginx HTTP configuration created and reloaded"
else
    echo "❌ Error: Nginx configuration test failed" >&2
    exit 1
fi

echo ""

# Step 2: Install certbot if needed
echo "🔒 Step 2: Checking certbot installation..."

if ! command -v certbot >/dev/null 2>&1; then
    echo "📦 Installing certbot..."
    sudo apt-get update -qq
    if ! sudo apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1; then
        echo "❌ Error: Failed to install certbot" >&2
        exit 1
    fi
    echo "✅ Certbot installed successfully"
else
    echo "✅ Certbot already installed"
fi

echo ""

# Step 3: Setup SSL certificate
echo "🔒 Step 3: Setting up SSL certificate..."

# Create certbot webroot directory
sudo mkdir -p "${CERTBOT_WEBROOT}"
sudo chmod 755 "${CERTBOT_WEBROOT}"

# Check if certificate already exists
if [ ! -d "${CERT_DIR}" ]; then
    # Request new SSL certificate
    echo "🎫 Requesting new SSL certificate for ${DOMAIN_NAME}..."
    if sudo certbot --nginx -d "${DOMAIN_NAME}" \
        --email "${EMAIL}" \
        --agree-tos \
        --non-interactive \
        --redirect \
        --quiet; then
        echo "✅ SSL certificate obtained and configured"
    else
        echo "❌ Error: SSL certificate request failed" >&2
        echo "Please ensure:" >&2
        echo "  1. DNS is properly configured for ${DOMAIN_NAME}" >&2
        echo "  2. Port 80 is accessible from the internet" >&2
        echo "  3. Domain points to this server" >&2
        exit 1
    fi
else
    # Certificate exists, check if nginx is configured with SSL
    echo "✅ SSL certificate already exists"
    if ! grep -q "ssl_certificate" "${NGINX_CONF}" 2>/dev/null; then
        echo "📝 Updating nginx configuration with SSL..."
        if sudo certbot --nginx -d "${DOMAIN_NAME}" \
            --non-interactive \
            --redirect \
            --quiet; then
            echo "✅ Nginx configuration updated with SSL"
        else
            echo "❌ Error: Failed to update nginx configuration with SSL" >&2
            exit 1
        fi
    else
        echo "✅ Nginx already configured with SSL"
    fi
fi

echo ""

# Step 4: Final verification
echo "🔍 Step 4: Verifying final configuration..."

if sudo nginx -t >/dev/null 2>&1; then
    sudo nginx -s reload
    echo "✅ Nginx configuration is valid and reloaded"
else
    echo "❌ Error: Nginx configuration test failed" >&2
    exit 1
fi

echo ""
echo "🎉 Setup completed successfully!"
echo "🌐 Your service is available at: https://${DOMAIN_NAME}"
