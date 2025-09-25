# Magento 2.4.8 LEMP 本地开发环境

这是一个基于 Ansible 的本地开发环境自动安装项目，专为在 Ubuntu 24.04 上快速搭建完整的 Magento 2.4.8 LEMP 技术栈。

## 🏗️ 技术栈

| 组件 | 版本 | 用途 |
|------|------|------|
| **Web 服务器** |
| Nginx | 1.27 + ModSecurity | 高性能 Web 服务器，集成 WAF |
| **编程语言** |
| PHP | 8.4 + 8.3 | 支持双版本，包含所有 Magento 必需扩展 |
| **数据库** |
| Percona MySQL | 8.4 | 高性能 MySQL 兼容数据库 |
| **搜索引擎** |
| OpenSearch | 2.19 | Elasticsearch 兼容的搜索引擎 |
| **缓存** |
| Valkey | 8 | Redis 兼容的高性能缓存系统 |
| Varnish | 7.6 | HTTP 加速器和反向代理缓存 |
| **消息队列** |
| RabbitMQ | 4.1 | 消息队列服务 |
| **包管理** |
| Composer | 2.8 | PHP 依赖管理工具 |
| **安全工具** |
| Fail2ban | Latest | 入侵防护系统 |
| Certbot | Latest | Let's Encrypt SSL 证书管理 |
| **管理工具** |
| Webmin | Latest | Web 系统管理界面 |
| phpMyAdmin | Latest | MySQL 数据库管理界面 |

## 📋 系统要求

### 本地开发机器
- **操作系统**: Ubuntu 24.04 LTS
- **CPU**: x86_64 架构，推荐 4+ 核心
- **内存**: 最少 8GB RAM，推荐 16GB+
- **存储**: 最少 50GB 可用空间，推荐 SSD
- **用户权限**: sudo 访问权限
- **网络**: 仅需本地网络（无需公网 IP 或域名）

## 🚀 超简单安装

### 一键安装（仅需一个命令！）

```bash
# 1. 克隆项目
git clone https://github.com/dogedix/LEMP4Magento.git
cd LEMP4Magento

# 2. 运行安装脚本
./install-local.sh
```

就这么简单！🎉 整个 LEMP 环境将自动安装和配置。

### 可选：自定义配置

如果需要修改默认设置，编辑 `group_vars/vault.yml`：

```bash
# 编辑敏感配置（可选）
ansible-vault edit group_vars/vault.yml
```

默认密码（可直接使用）：
- MySQL root: `StrongRootPassword123!`
- MySQL magento: `StrongMagentoPassword123!`
- Redis: `StrongRedisPassword123!`
- RabbitMQ: `StrongRabbitPassword123!`
- Magento admin: `Admin123!`

## 📁 项目结构

```
magento-lemp-ansible/
├── ansible.cfg                 # Ansible 配置文件
├── site.yml                   # 主 Playbook
├── deploy.sh                  # 部署脚本
├── requirements.yml           # Ansible 集合依赖
├── inventory/
│   └── hosts.yml             # 服务器清单
├── group_vars/
│   ├── all.yml               # 全局变量
│   └── vault.yml             # 加密变量
└── roles/                    # 角色目录
    ├── php/                  # PHP 8.4/8.3 安装配置
    ├── nginx/                # Nginx + ModSecurity
    ├── percona/              # Percona MySQL 8.4
    ├── opensearch/           # OpenSearch 2.19
    ├── valkey/               # Valkey 8 缓存
    ├── rabbitmq/             # RabbitMQ 4.1
    ├── varnish/              # Varnish 7.6
    ├── composer/             # Composer 2.8
    ├── security/             # 安全工具
    └── admin-tools/          # 管理工具
```

## 🔧 角色说明

### PHP 角色
- 安装 PHP 8.4 和 8.3 双版本
- 配置所有 Magento 必需的 PHP 扩展
- 优化 PHP-FPM 配置用于 Magento
- 设置 OPcache 加速

### Nginx 角色
- 编译安装 Nginx 1.27 源码
- 集成 ModSecurity 3.x WAF
- 部署 OWASP Core Rule Set
- 配置 Magento 专用虚拟主机
- SSL/TLS 安全配置

### Percona 角色
- 安装 Percona Server 8.4
- MySQL 性能优化配置
- 创建 Magento 数据库和用户
- 安全加固配置

### 其他角色
- **OpenSearch**: 搜索引擎配置
- **Valkey**: Redis 兼容缓存
- **RabbitMQ**: 消息队列服务
- **Varnish**: HTTP 缓存加速
- **Security**: 防火墙和入侵防护
- **Admin-tools**: 管理界面

## 🛡️ 安全特性

### 网络安全
- UFW 防火墙配置
- Fail2ban 入侵防护
- SSH 安全加固
- ModSecurity WAF 保护

### 应用安全
- SSL/TLS 证书自动申请和续期
- 安全 HTTP 头配置
- 数据库访问限制
- 文件权限优化

### 系统安全
- 内核安全参数调优
- 禁用不必要的网络协议
- 系统日志监控
- 自动安全更新

## 📊 部署后验证

### 服务状态检查

```bash
# 检查所有服务状态
systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server varnish

# 检查端口监听
netstat -tlnp | grep -E ':(80|443|3306|9200|6379|5672|6081)'

# 检查日志
tail -f /var/log/nginx/error.log
tail -f /var/log/mysql/error.log
```

### 功能测试

```bash
# PHP 版本检查
php8.4 --version
php8.4 -m | grep -E '(mysql|redis|opcache)'

# 数据库连接测试
mysql -u magento_user -p magento

# Redis 连接测试
valkey-cli ping

# OpenSearch 状态
curl http://localhost:9200/_cluster/health

# RabbitMQ 状态
rabbitmqctl status
```

## 🛒 安装 Magento 2.4.8

环境安装完成后，安装 Magento：

### 1. 安装 Magento

```bash
# 进入 Web 目录
cd /var/www

# 安装 Magento 2.4.8（需要 Magento Marketplace 认证密钥）
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition magento

# 设置权限
cd magento
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chmod u+x bin/magento
```

### 2. 快速安装命令

```bash
cd /var/www/magento
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

### 3. 运行 Magento 安装

```bash
php bin/magento setup:install \\
    --base-url=https://your-domain.com/ \\
    --db-host=localhost \\
    --db-name=magento \\
    --db-user=magento_user \\
    --db-password=your-magento-db-password \\
    --admin-firstname=Admin \\
    --admin-lastname=User \\
    --admin-email=admin@your-domain.com \\
    --admin-user=admin \\
    --admin-password=your-admin-password \\
    --language=en_US \\
    --currency=USD \\
    --timezone=America/Los_Angeles \\
    --use-rewrites=1 \\
    --search-engine=opensearch \\
    --opensearch-host=localhost \\
    --opensearch-port=9200 \\
    --session-save=redis \\
    --session-save-redis-host=127.0.0.1 \\
    --session-save-redis-port=6379 \\
    --session-save-redis-password=your-redis-password \\
    --cache-backend=redis \\
    --cache-backend-redis-server=127.0.0.1 \\
    --cache-backend-redis-port=6379 \\
    --cache-backend-redis-password=your-redis-password
```

### 4. 配置 Cron 任务

```bash
# 添加 Magento cron
crontab -e

# 添加以下行
* * * * * /usr/bin/php8.4 /var/www/magento/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /var/www/magento/var/log/magento.cron.log
* * * * * /usr/bin/php8.4 /var/www/magento/update/cron.php >> /var/www/magento/var/log/update.cron.log
* * * * * /usr/bin/php8.4 /var/www/magento/bin/magento setup:cron:run >> /var/www/magento/var/log/setup.cron.log
```

## 🌐 访问您的本地环境

安装完成后，您可以通过以下地址访问：

### Magento 网站
- **前台**: http://localhost/magento
- **后台**: http://localhost/magento/admin
  - 用户名: `admin`
  - 密码: `Admin123!`

### 管理工具
- **phpMyAdmin**: http://localhost/phpmyadmin
  - 用户: `magento_user` 或 `root`
  - 密码: `StrongMagentoPassword123!` 或 `StrongRootPassword123!`

- **Webmin**: http://localhost:10000
  - 用户: `doge`
  - 密码: 您的系统用户密码

### 服务端口
- **Nginx**: http://localhost:80
- **MySQL**: localhost:3306
- **OpenSearch**: http://localhost:9200
- **Redis**: localhost:6379
- **RabbitMQ**: localhost:5672 (管理界面: http://localhost:15672)
- **Varnish**: localhost:6081

## 📝 维护和监控

### 日志位置

```bash
# Nginx 日志
/var/log/nginx/access.log
/var/log/nginx/error.log

# PHP 日志
/var/log/php/magento-error.log
/var/log/php/magento-access.log

# MySQL 日志
/var/log/mysql/error.log
/var/log/mysql/slow.log

# OpenSearch 日志
/var/log/opensearch/

# Magento 日志
/var/www/magento/var/log/
```

### 性能监控

```bash
# 系统资源监控
htop
iotop
nethogs

# MySQL 性能
mysqladmin processlist
mysqladmin extended-status

# PHP-FPM 状态
systemctl status php8.4-fpm
```

### 备份策略

```bash
# 数据库备份
mysqldump -u root -p magento > backup_$(date +%Y%m%d_%H%M%S).sql

# 文件备份
tar -czf magento_files_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/magento

# 自动备份脚本
/scripts/backup.sh
```

## 🚨 故障排除

### 常见问题

1. **Nginx 编译失败**
   ```bash
   # 检查依赖包
   apt list --installed | grep -E "(build-essential|libpcre3-dev|libssl-dev)"
   
   # 重新安装依赖
   ansible-playbook site.yml --tags nginx --ask-vault-pass
   ```

2. **PHP 扩展缺失**
   ```bash
   # 检查已安装扩展
   php8.4 -m
   
   # 重新安装 PHP
   ansible-playbook site.yml --tags php --ask-vault-pass
   ```

3. **数据库连接失败**
   ```bash
   # 检查 MySQL 状态
   systemctl status mysql
   
   # 检查用户权限
   mysql -u root -p -e "SHOW GRANTS FOR 'magento_user'@'localhost';"
   ```

4. **SSL 证书申请失败**
   ```bash
   # 手动申请证书
   certbot --nginx --non-interactive --agree-tos --email admin@your-domain.com -d your-domain.com
   ```

### 性能优化

1. **MySQL 调优**
   - 根据服务器内存调整 `innodb_buffer_pool_size`
   - 监控慢查询日志
   - 定期优化表结构

2. **PHP 调优**
   - 调整 `php-fpm` 进程数
   - 优化 `opcache` 设置
   - 增加内存限制

3. **Nginx 调优**
   - 调整 `worker_processes` 和 `worker_connections`
   - 启用 gzip 压缩
   - 配置静态文件缓存

## 📞 技术支持

### 文档和资源
- [Magento 官方文档](https://devdocs.magento.com/)
- [Ansible 官方文档](https://docs.ansible.com/)
- [Nginx 官方文档](https://nginx.org/en/docs/)

### 日志分析
- 使用 `tail -f` 实时监控日志
- 使用 `grep` 过滤特定错误
- 配置日志轮转避免磁盘空间不足

### 社区支持
- Magento 开发者社区
- Stack Overflow
- GitHub Issues

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

---

**注意**: 这是一个生产级别的部署方案，请在生产环境使用前充分测试。建议先在测试环境中验证所有功能。
