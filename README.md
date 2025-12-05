# Docker + Nginx + SSL Automated Deployment

A simple, all-in-one script for deploying Docker containers, setting up Nginx reverse proxy, and automatically obtaining Let's Encrypt SSL certificates.

## ✨ Features

- 🐳 Build, stop, and start Docker containers automatically
- 🔒 Configure free SSL certificates via Let's Encrypt
- 🌐 Automated Nginx reverse proxy (HTTP/HTTPS support)
- 📝 Deployment process logging
- ✅ Robust error handling and verification

## 🚀 Quick Start

1. **Prepare `.env` file** in your project root:

    ```env
    PROJECT_NAME=your-project-name      # Docker Compose project name
    DOMAIN_NAME=yourdomain.com          # Your domain (should resolve to this server)
    PORT=8000                           # Internal container port
    SSL_EMAIL=admin@yourdomain.com      # (Optional) Email for SSL
    COMPOSE_FILE_PATH=docker-compose.yaml    # (Optional) docker-compose.yaml path
    ```

2. **Ensure a `docker-compose.yaml` file** exists (or specify its path via `COMPOSE_FILE_PATH` in `.env`).

3. **One-command deployment**:

    ```bash
    curl -fsSL https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/deploy.sh | bash
    ```

   > The script will download all dependencies (`deploy-docker.sh` and `deploy-domain-ssl.sh`). Write permissions are required in the current directory.

## 📋 What the Script Does

1. **Docker Deployment**
   - Stops old containers
   - Builds Docker images (no cache)
   - Starts the services
   - Checks if containers are running

2. **Nginx & SSL Configuration**
   - Validates environment variables
   - Generates Nginx HTTP config (port 80)
   - Installs `certbot` if needed
   - Requests & configures Let's Encrypt SSL certificates
   - Sets up HTTPS redirect

- **Logs:** `./logs/docker.log`  
- **Nginx config:** `/etc/nginx/conf.d/${DOMAIN_NAME}.conf`  
- **SSL cert:** `/etc/letsencrypt/live/${DOMAIN_NAME}/`

## ⚙️ Requirements

- **OS:** Debian/Ubuntu (sudo/root required)
- **Docker:** Docker & Compose installed
- **Nginx:** Installed
- **Domain:** Points to this server
- **Ports:** 80 and 443 must be open & accessible

## 📝 Main Environment Variables

| Variable        | Required? | Example / Default         |
|-----------------|-----------|--------------------------|
| DOMAIN_NAME     | Yes       | `example.com`            |
| PORT            | Yes       | `8000`                   |
| PROJECT_NAME    | No        | `docker-project`         |
| SSL_EMAIL       | No        | `admin@${DOMAIN_NAME}`   |
| COMPOSE_FILE_PATH | No     | `docker-compose.yaml`    |

## ⚠️ Notes

- Domain **must** resolve to your server, or SSL will fail
- Ensure firewall allows ports 80 & 443
- Sudo necessary for Nginx and SSL setup
- First certificate issuance may take a few minutes
- Certificates auto-renew (valid 90 days)

## 🔍 Troubleshooting

- **SSL failed:**  
  - Verify DNS points to your server  
  - Ensure port 80 is open  
  - Check with `sudo certbot certificates`

- **Nginx errors:**  
  - Test config: `sudo nginx -t`  
  - Errors: `sudo tail -f /var/log/nginx/error.log`

- **Docker errors:**  
  - Logs: `docker compose logs`  
  - Check `docker-compose.yaml`  
  - Check deployment log: `cat ./logs/docker.log`

## 📄 License

See [LICENSE](LICENSE) for details.
