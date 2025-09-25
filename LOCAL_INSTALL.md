# 🏠 本地安装指南

## 🎯 本地开发环境

这个项目已经专门为**本地开发**优化，无需任何远程服务器配置。

### ⚡ 快速安装

```bash
# 1. 进入项目目录
cd /home/doge/LEMP4Magento

# 2. 运行本地安装脚本
./install-local.sh
```

就这么简单！🎉

### 📋 安装要求

- **系统**: Ubuntu 24.04 LTS
- **用户**: doge (当前用户)
- **权限**: sudo 访问权限
- **网络**: 无需公网 IP 或域名

### 🔧 自动安装内容

安装脚本将自动配置：

| 组件 | 版本 | 访问方式 |
|------|------|----------|
| **Nginx** | 1.27 + ModSecurity | http://localhost |
| **PHP** | 8.4/8.3 | CLI + FPM |
| **MySQL** | Percona 8.4 | localhost:3306 |
| **OpenSearch** | 2.19 | localhost:9200 |
| **Redis** | Valkey 8 | localhost:6379 |
| **RabbitMQ** | 4.1 | localhost:5672 |
| **Varnish** | 7.6 | localhost:6081 |
| **phpMyAdmin** | Latest | http://localhost/phpmyadmin |
| **Webmin** | Latest | http://localhost:10000 |

### 📁 目录结构

```
/var/www/                    # Web 根目录 (doge:www-data)
├── phpmyadmin/              # 数据库管理界面
└── (your-magento-sites)/    # 您的 Magento 站点
```

### 🛒 安装 Magento

环境就绪后，安装 Magento：

```bash
# 进入 Web 目录
cd /var/www

# 安装 Magento 2.4.8
composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition \
    magento

# 设置权限
cd magento
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chmod u+x bin/magento

# 运行 Magento 安装
php bin/magento setup:install \
    --base-url=http://localhost/magento/ \
    --db-host=localhost \
    --db-name=magento \
    --db-user=magento_user \
    --db-password=StrongMagentoPassword123! \
    --admin-firstname=Admin \
    --admin-lastname=User \
    --admin-email=admin@localhost \
    --admin-user=admin \
    --admin-password=Admin123! \
    --language=en_US \
    --currency=USD \
    --timezone=America/Los_Angeles \
    --use-rewrites=1 \
    --search-engine=opensearch \
    --opensearch-host=localhost \
    --opensearch-port=9200 \
    --session-save=redis \
    --session-save-redis-host=127.0.0.1 \
    --session-save-redis-port=6379 \
    --cache-backend=redis \
    --cache-backend-redis-server=127.0.0.1 \
    --cache-backend-redis-port=6379
```

### 🌐 访问您的网站

安装完成后：

- **前台**: http://localhost/magento
- **后台**: http://localhost/magento/admin
  - 用户名: `admin`
  - 密码: `Admin123!`

### 🛠️ 管理工具

- **phpMyAdmin**: http://localhost/phpmyadmin
  - 用户: `magento_user`
  - 密码: `StrongMagentoPassword123!`

- **Webmin**: http://localhost:10000
  - 用户: `doge`
  - 密码: 您的系统密码

### 📊 服务管理

```bash
# 检查所有服务状态
sudo systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server varnish

# 重启服务
sudo systemctl restart nginx
sudo systemctl restart php8.4-fpm
sudo systemctl restart mysql

# 查看服务日志
sudo journalctl -fu nginx
sudo journalctl -fu php8.4-fpm
sudo journalctl -fu mysql
```

### 🗄️ 数据库管理

```bash
# 连接 MySQL
mysql -u magento_user -p

# 或使用 root 用户
mysql -u root -p

# 创建新数据库 (多站点)
CREATE DATABASE magento_site2;
GRANT ALL PRIVILEGES ON magento_site2.* TO 'magento_user'@'localhost';
```

### 🔧 开发配置

#### Magento 开发模式

```bash
cd /var/www/magento

# 切换到开发模式
php bin/magento deploy:mode:set developer

# 禁用缓存 (开发时)
php bin/magento cache:disable

# 启用所有模块
php bin/magento module:enable --all
```

#### PHP 调试

```bash
# 查看 PHP 配置
php -i | grep -E "(error|debug|display)"

# 编辑 PHP 配置
sudo nano /etc/php/8.4/fpm/php.ini

# 重启 PHP-FPM
sudo systemctl restart php8.4-fpm
```

### 🎯 多站点支持

```bash
# 在 /var/www 中创建多个站点
cd /var/www

# 站点 1
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition site1

# 站点 2
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition site2

# 访问方式：
# http://localhost/site1
# http://localhost/site2
```

### 🚨 故障排除

#### 服务启动失败

```bash
# 检查错误日志
sudo journalctl -xe

# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :3306
```

#### 权限问题

```bash
# 重置 /var/www 权限
sudo chown -R doge:www-data /var/www
sudo chmod -R 755 /var/www

# Magento 特定权限
cd /var/www/magento
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
```

#### 内存不足

```bash
# 增加 PHP 内存限制
sudo nano /etc/php/8.4/fpm/php.ini
# memory_limit = 4G

# 重启 PHP-FPM
sudo systemctl restart php8.4-fpm
```

### 🎉 优势

本地开发环境的优势：

1. **🚀 快速**: 无需网络配置和 SSL 证书
2. **🔧 简单**: 一个命令完成所有安装
3. **💰 免费**: 无需购买域名或服务器
4. **🛡️ 安全**: 仅本地访问，无外部暴露
5. **⚡ 高效**: 本地资源，响应速度快
6. **🔄 灵活**: 可同时运行多个 Magento 站点

---

**开始您的 Magento 开发之旅吧！** 🚀
