#!/bin/bash

# Exit on error
set -e

# Download docker-compose.yaml file from https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/docker-compose.yaml
curl -fsSL https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/sample/docker-compose.yaml -o docker-compose.yaml

# Download Dockerfile file from https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/Dockerfile
curl -fsSL https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/sample/Dockerfile -o Dockerfile