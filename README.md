# Docker + Nginx + SSL 自动化部署脚本

一套通用的自动化部署脚本，用于快速部署 Docker 容器并配置 Nginx 反向代理和 Let's Encrypt SSL 证书。

## ✨ 功能特性

- 🐳 **Docker 自动化部署**：一键构建、停止和启动 Docker 容器
- 🔒 **SSL 证书自动配置**：使用 Let's Encrypt 自动获取和配置免费 SSL 证书
- 🌐 **Nginx 反向代理**：自动配置 Nginx 反向代理，支持 HTTP/HTTPS
- 📝 **日志记录**：自动记录部署过程日志
- ✅ **错误处理**：完善的错误检查和验证机制

## 🚀 快速开始

### 1. 配置环境变量

在项目根目录创建 `.env` 文件：

```bash
# 项目名称（用于 Docker Compose 项目标识）
PROJECT_NAME=your-project-name

# 域名（需要已解析到服务器 IP）
DOMAIN_NAME=yourdomain.com

# 应用端口（Docker 容器内部端口）
PORT=8000

# SSL 证书邮箱（可选，默认为 admin@DOMAIN_NAME）
SSL_EMAIL=admin@yourdomain.com
```

### 2. 准备 Docker Compose 文件

确保项目根目录存在 `docker-compose.yaml` 文件。

### 3. 一键部署

使用 curl 直接下载并执行部署脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/bravebirdy/docker-nginx-deploy/main/deploy.sh | bash
```

**使用说明**：
- 脚本会自动下载依赖的 `deploy-docker.sh` 和 `deploy-domain-ssl.sh` 到当前目录
- 确保当前目录有写入权限

## 📋 部署流程

脚本会自动执行以下步骤：

1. **Docker 部署**
   - 停止旧容器
   - 构建 Docker 镜像（无缓存）
   - 启动服务
   - 验证容器运行状态

2. **Nginx 和 SSL 配置**
   - 验证环境变量配置
   - 创建 Nginx HTTP 配置（端口 80）
   - 安装 certbot（如未安装）
   - 获取并配置 SSL 证书（Let's Encrypt）
   - 自动配置 HTTPS 重定向

**日志文件**：`./logs/docker.log`  
**Nginx 配置**：`/etc/nginx/conf.d/${DOMAIN_NAME}.conf`  
**SSL 证书**：`/etc/letsencrypt/live/${DOMAIN_NAME}/`

## ⚙️ 环境要求

- **操作系统**：Debian/Ubuntu（需要 root/sudo 权限）
- **Docker**：已安装 Docker 和 Docker Compose
- **Nginx**：已安装 Nginx
- **域名**：域名已正确解析到服务器 IP
- **端口**：确保端口 80 和 443 未被占用且可访问

## 📝 配置说明

### 必需环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `DOMAIN_NAME` | 域名（需已解析） | `example.com` |
| `PORT` | 应用端口（1-65535） | `8000` |

### 可选环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `PROJECT_NAME` | Docker Compose 项目名称 | `docker-project` |
| `SSL_EMAIL` | SSL 证书邮箱 | `admin@${DOMAIN_NAME}` |

## ⚠️ 注意事项

1. **域名解析**：确保域名已正确解析到服务器 IP，否则 SSL 证书申请会失败
2. **端口访问**：确保服务器防火墙开放端口 80 和 443
3. **权限要求**：脚本需要 sudo 权限来配置 Nginx 和 SSL
4. **首次部署**：首次部署 SSL 证书可能需要几分钟时间
5. **证书续期**：Let's Encrypt 证书有效期为 90 天，certbot 会自动续期

## 🔍 故障排查

### SSL 证书申请失败

- 检查域名是否正确解析到服务器
- 确认端口 80 可以从外网访问
- 查看 certbot 日志：`sudo certbot certificates`

### Nginx 配置错误

- 测试配置：`sudo nginx -t`
- 查看错误日志：`sudo tail -f /var/log/nginx/error.log`

### Docker 容器启动失败

- 查看容器日志：`docker compose logs`
- 检查 `docker-compose.yaml` 配置
- 查看部署日志：`cat ./logs/docker.log`

## 📄 许可证

查看 [LICENSE](LICENSE) 文件了解详情。
