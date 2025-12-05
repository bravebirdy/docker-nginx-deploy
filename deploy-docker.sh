#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration variables
COMPOSE_FILE="docker-compose.yaml"
LOG_PATH="./logs/docker.log"

# Load environment variables from .env file if it exists
# PROJECT_NAME will use value from .env or default to project directory name
if [ -f "${SCRIPT_DIR}/.env" ]; then
    # Temporarily allow unset variables for source
    set +u
    source "${SCRIPT_DIR}/.env"
    set -u
fi

# Set PROJECT_NAME from .env or use default
PROJECT_NAME="${PROJECT_NAME:-docker-project}"

# Create logs directory if it does not exist
mkdir -p "$(dirname "$LOG_PATH")"

# Logging function: writes message with timestamp to both console and log file
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") $1" | tee -a "$LOG_PATH"
}

# Start deployment process
log "🚀 Start deployment..."

# Display configuration
log "📋 Configuration:"
log "   Project name: $PROJECT_NAME"
log "   Compose file: $COMPOSE_FILE"
log "   Log path: $LOG_PATH"

# Step 1: Stop old containers (ignore errors if containers don't exist)
log "🛑 Stopping old containers..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down || true

# Step 2: Build Docker image (without cache to ensure fresh build)
log "🔨 Building image..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" build --no-cache

# Step 3: Start services in detached mode
log "▶️  Starting service..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d

# Step 4: Wait for services to start and verify deployment
log "⏳ Waiting for services to start..."
sleep 5

# Check if containers are running
if docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps | grep -q "Up"; then
    log "✅ Deployment succeeded!"
    # Display container status
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
else
    log "❌ Deployment failed"
    # Show recent logs for debugging
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs --tail=50
    exit 1
fi