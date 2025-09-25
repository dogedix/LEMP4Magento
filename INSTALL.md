# Magento 2.4.8 LEMP 安装指南

## 🎯 安装概述

本指南将引导您完成 Magento 2.4.8 LEMP 技术栈的完整安装过程。整个安装过程大约需要 30-60 分钟，具体时间取决于服务器性能和网络状况。

## 📋 安装前检查清单

### ✅ 硬件要求
- [ ] 服务器架构: x86_64
- [ ] CPU: 最少 2 核心，推荐 4+ 核心
- [ ] 内存: 最少 8GB RAM，推荐 16GB+
- [ ] 存储: 最少 50GB 可用空间，推荐 SSD
- [ ] 网络: 稳定的互联网连接

### ✅ 系统要求
- [ ] 操作系统: Ubuntu 24.04 LTS
- [ ] 公网 IP 地址（用于 SSL 证书）
- [ ] 域名解析到服务器 IP
- [ ] SSH 访问权限

### ✅ 控制机器要求
- [ ] Ansible 2.14+
- [ ] Python 3.8+
- [ ] SSH 密钥对配置

## 🚀 详细安装步骤

### 步骤 1: 环境准备

#### 1.1 更新控制机器
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y git ansible python3-pip

# 验证 Ansible 版本
ansible --version
```

#### 1.2 生成 SSH 密钥（如果没有）
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

#### 1.3 配置目标服务器 SSH 访问
```bash
# 复制公钥到目标服务器
ssh-copy-id root@your-server-ip

# 测试连接
ssh root@your-server-ip
```

### 步骤 2: 下载和配置项目

#### 2.1 获取项目代码
```bash
# 克隆项目
git clone <项目仓库地址>
cd magento-lemp-ansible

# 确认项目结构
ls -la
```

#### 2.2 安装 Ansible 依赖
```bash
# 安装所需的 Ansible 集合
ansible-galaxy collection install -r requirements.yml --force

# 验证安装
ansible-galaxy collection list
```

### 步骤 3: 配置部署参数

#### 3.1 编辑主配置文件
```bash
# 编辑全局变量
vim group_vars/all.yml
```

**关键配置项:**
```yaml
# 域名设置
domain_name: "your-magento-site.com"  # 替换为您的域名
admin_email: "admin@your-domain.com"  # 替换为您的邮箱

# 系统设置
system_timezone: "America/Los_Angeles"  # 根据需要调整时区
system_user: "magento"
system_group: "magento"

# PHP 设置
php_default_version: "8.4"
php_memory_limit: "2G"  # 根据服务器内存调整

# MySQL 设置
mysql_innodb_buffer_pool_size: "1G"  # 根据服务器内存调整
```

#### 3.2 配置敏感信息
```bash
# 编辑加密变量文件
ansible-vault edit group_vars/vault.yml
```

**设置强密码:**
```yaml
vault_mysql_root_password: "MySuperSecureRootPassword123!"
vault_mysql_magento_password: "MagentoDbPassword456!"
vault_redis_password: "RedisSecurePassword789!"
vault_rabbitmq_password: "RabbitMQPassword101!"
vault_magento_admin_password: "AdminPassword112!"
```

> **安全提示**: 请使用包含大小写字母、数字和特殊字符的强密码，长度至少 16 位。

#### 3.3 配置服务器清单
```bash
# 编辑服务器清单
vim inventory/hosts.yml
```

```yaml
---
all:
  children:
    magento_servers:
      hosts:
        magento-server:
          ansible_host: "192.168.1.100"  # 替换为您的服务器 IP
          ansible_user: "root"            # 或其他有 sudo 权限的用户
          ansible_ssh_private_key_file: "~/.ssh/id_rsa"  # SSH 私钥路径
      vars:
        ansible_python_interpreter: /usr/bin/python3
```

### 步骤 4: 预安装验证

#### 4.1 连接测试
```bash
# 测试 Ansible 连接
ansible magento_servers -m ping

# 预期输出:
# magento-server | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

#### 4.2 语法检查
```bash
# 检查 Playbook 语法
ansible-playbook site.yml --syntax-check

# 预期输出: playbook: site.yml
```

#### 4.3 试运行（可选）
```bash
# 干运行，查看将要执行的操作
ansible-playbook site.yml --check --ask-vault-pass
```

### 步骤 5: 执行安装

#### 5.1 使用自动化脚本（推荐）
```bash
# 使脚本可执行
chmod +x deploy.sh

# 执行部署
./deploy.sh 192.168.1.100 root your-domain.com
```

#### 5.2 手动执行
```bash
# 完整安装
ansible-playbook site.yml --ask-vault-pass -v

# 或者分步骤安装（可选）
ansible-playbook site.yml --tags "php" --ask-vault-pass
ansible-playbook site.yml --tags "database" --ask-vault-pass
ansible-playbook site.yml --tags "webserver" --ask-vault-pass
```

### 步骤 6: 安装过程监控

#### 6.1 实时日志监控
在另一个终端窗口中监控安装进度：

```bash
# SSH 连接到目标服务器
ssh root@your-server-ip

# 监控系统日志
sudo tail -f /var/log/syslog

# 监控特定服务
sudo journalctl -f -u nginx
sudo journalctl -f -u mysql
```

#### 6.2 安装阶段说明

| 阶段 | 描述 | 预计时间 | 关键检查点 |
|------|------|----------|------------|
| 系统更新 | 更新包管理器和基础包 | 2-5 分钟 | apt update 成功 |
| PHP 安装 | 编译安装 PHP 8.4/8.3 | 5-10 分钟 | PHP 版本验证 |
| MySQL 安装 | 安装 Percona Server 8.4 | 3-8 分钟 | 数据库服务启动 |
| Nginx 编译 | 编译 Nginx + ModSecurity | 10-20 分钟 | 编译成功，服务启动 |
| 其他服务 | 安装缓存、搜索等服务 | 5-15 分钟 | 各服务状态正常 |
| 安全配置 | 配置防火墙和安全策略 | 2-5 分钟 | 防火墙规则应用 |

### 步骤 7: 安装后验证

#### 7.1 服务状态检查
```bash
# 检查所有关键服务
ssh root@your-server-ip "systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server"

# 检查端口监听
ssh root@your-server-ip "netstat -tlnp | grep -E ':(80|443|3306|9200|6379|5672)'"
```

#### 7.2 组件功能测试
```bash
# PHP 测试
ssh root@your-server-ip "php8.4 --version && php8.4 -m | grep -c mysql"

# 数据库测试
ssh root@your-server-ip "mysql -u root -p'${MYSQL_ROOT_PASSWORD}' -e 'SELECT VERSION();'"

# Web 服务器测试
curl -I http://your-server-ip
```

### 步骤 8: Magento 2.4.8 安装

#### 8.1 获取 Magento 认证密钥
1. 访问 [Magento Marketplace](https://marketplace.magento.com/)
2. 注册/登录账户
3. 前往 **My Profile** > **Access Keys**
4. 创建新的访问密钥
5. 记录 **Public Key** 和 **Private Key**

#### 8.2 下载和安装 Magento
```bash
# 连接到服务器
ssh root@your-server-ip

# 切换到 magento 用户
sudo su - magento

# 配置 Composer 认证
cd /var/www
composer config --global http-basic.repo.magento.com \\
    YOUR_PUBLIC_KEY YOUR_PRIVATE_KEY

# 创建 Magento 项目
composer create-project \\
    --repository-url=https://repo.magento.com/ \\
    magento/project-community-edition:2.4.8 \\
    magento

# 设置权限
cd magento
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R magento:www-data .
chmod u+x bin/magento
```

#### 8.3 运行 Magento 安装向导
```bash
# 替换下面的变量为实际值
DOMAIN="your-domain.com"
DB_PASSWORD="your-mysql-magento-password"
ADMIN_PASSWORD="your-admin-password"
ADMIN_EMAIL="admin@your-domain.com"
REDIS_PASSWORD="your-redis-password"

# 执行安装
php bin/magento setup:install \\
    --base-url=https://${DOMAIN}/ \\
    --db-host=localhost \\
    --db-name=magento \\
    --db-user=magento_user \\
    --db-password=${DB_PASSWORD} \\
    --admin-firstname=Admin \\
    --admin-lastname=User \\
    --admin-email=${ADMIN_EMAIL} \\
    --admin-user=admin \\
    --admin-password=${ADMIN_PASSWORD} \\
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
    --session-save-redis-password=${REDIS_PASSWORD} \\
    --cache-backend=redis \\
    --cache-backend-redis-server=127.0.0.1 \\
    --cache-backend-redis-port=6379 \\
    --cache-backend-redis-password=${REDIS_PASSWORD}
```

### 步骤 9: SSL 证书配置

#### 9.1 申请 Let's Encrypt 证书
```bash
# 确保域名已解析到服务器
nslookup your-domain.com

# 申请证书
sudo certbot --nginx --non-interactive --agree-tos \\
    --email admin@your-domain.com \\
    -d your-domain.com -d www.your-domain.com
```

#### 9.2 验证 SSL 配置
```bash
# 测试 HTTPS 访问
curl -I https://your-domain.com

# 检查证书信息
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### 步骤 10: 最终配置

#### 10.1 配置 Cron 任务
```bash
# 编辑 magento 用户的 crontab
sudo crontab -u magento -e

# 添加以下行
* * * * * /usr/bin/php8.4 /var/www/magento/bin/magento cron:run 2>&1 | grep -v "Ran jobs by schedule" >> /var/www/magento/var/log/magento.cron.log
* * * * * /usr/bin/php8.4 /var/www/magento/update/cron.php >> /var/www/magento/var/log/update.cron.log
* * * * * /usr/bin/php8.4 /var/www/magento/bin/magento setup:cron:run >> /var/www/magento/var/log/setup.cron.log
```

#### 10.2 配置 Magento 模式
```bash
# 切换到生产模式
cd /var/www/magento
php bin/magento deploy:mode:set production

# 清理缓存
php bin/magento cache:flush
php bin/magento cache:clean

# 重新索引
php bin/magento indexer:reindex
```

## 🎉 安装完成

### 访问您的 Magento 站点

- **前台**: https://your-domain.com
- **后台**: https://your-domain.com/admin
  - 用户名: `admin`
  - 密码: 您在 vault.yml 中设置的密码

### 管理界面

- **Webmin**: https://your-server-ip:10000
- **phpMyAdmin**: https://your-domain.com/phpmyadmin
- **RabbitMQ**: http://your-server-ip:15672

## 🔧 故障排除

### 常见错误和解决方案

#### Ansible 连接失败
```bash
# 检查 SSH 连接
ssh -vvv root@your-server-ip

# 检查防火墙
sudo ufw status
```

#### Nginx 编译失败
```bash
# 检查编译依赖
apt list --installed | grep build-essential

# 查看编译日志
journalctl -u nginx -f
```

#### MySQL 连接错误
```bash
# 检查 MySQL 服务
systemctl status mysql

# 查看 MySQL 错误日志
tail -f /var/log/mysql/error.log
```

#### SSL 证书申请失败
```bash
# 检查域名解析
dig your-domain.com

# 手动申请证书
certbot --nginx --manual -d your-domain.com
```

### 获取帮助

如果遇到问题，请：

1. 检查相关服务的日志文件
2. 查看 Ansible 的详细输出 (`-vvv` 参数)
3. 参考 README.md 中的故障排除部分
4. 在项目 GitHub 页面提交 Issue

---

**恭喜！** 您已经成功安装了 Magento 2.4.8 LEMP 技术栈。现在可以开始配置您的电商网站了！
