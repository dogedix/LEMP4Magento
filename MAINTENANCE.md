# Magento 2.4.8 LEMP 维护指南

## 📊 日常监控

### 系统资源监控

#### CPU 和内存监控
```bash
# 实时系统资源监控
htop

# 查看系统负载
uptime
w

# 内存使用情况
free -h
cat /proc/meminfo

# 磁盘空间检查
df -h
du -sh /var/www/magento/*
```

#### 服务状态监控
```bash
# 检查所有关键服务
systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server varnish

# 检查服务启动时间
systemctl show nginx --property=ActiveEnterTimestamp
systemctl show mysql --property=ActiveEnterTimestamp

# 检查端口监听
netstat -tlnp | grep -E ':(80|443|3306|9200|6379|5672|6081)'
ss -tlnp | grep -E ':(80|443|3306|9200|6379|5672|6081)'
```

### 性能监控

#### Web 服务器性能
```bash
# Nginx 状态
curl http://localhost/nginx_status

# PHP-FPM 状态
curl http://localhost/status?full

# 连接数统计
netstat -an | grep :80 | wc -l
netstat -an | grep :443 | wc -l
```

#### 数据库性能
```bash
# MySQL 进程列表
mysqladmin processlist -u root -p

# MySQL 状态变量
mysqladmin extended-status -u root -p | grep -E '(Connections|Questions|Queries|Threads)'

# 慢查询检查
tail -f /var/log/mysql/slow.log

# 数据库大小
mysql -u root -p -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB' FROM information_schema.tables WHERE table_schema='magento' GROUP BY table_schema;"
```

## 🛠️ 定期维护任务

### 每日任务

#### 日志文件检查
```bash
#!/bin/bash
# daily_log_check.sh

echo "=== 每日日志检查 $(date) ==="

# 检查错误日志大小
echo "日志文件大小:"
du -sh /var/log/nginx/error.log
du -sh /var/log/mysql/error.log
du -sh /var/www/magento/var/log/system.log

# 检查最近的错误
echo "最近 24 小时的 Nginx 错误:"
grep "$(date -d '1 day ago' '+%d/%b/%Y')" /var/log/nginx/error.log | tail -10

echo "最近 24 小时的 MySQL 错误:"
grep "$(date '+%Y-%m-%d')" /var/log/mysql/error.log | tail -10

echo "最近 24 小时的 Magento 错误:"
grep "$(date '+%Y-%m-%d')" /var/www/magento/var/log/system.log | tail -10
```

#### 磁盘空间清理
```bash
#!/bin/bash
# daily_cleanup.sh

echo "=== 每日清理任务 $(date) ==="

# 清理 Magento 日志（保留 7 天）
find /var/www/magento/var/log/ -name "*.log" -mtime +7 -delete
find /var/www/magento/var/report/ -name "*" -mtime +7 -delete

# 清理生成的静态文件（如果需要）
# rm -rf /var/www/magento/var/view_preprocessed/*
# rm -rf /var/www/magento/pub/static/*

# 清理系统临时文件
find /tmp -type f -atime +7 -delete

# 清理 APT 缓存
apt-get clean

echo "清理完成"
```

### 每周任务

#### 数据库优化
```bash
#!/bin/bash
# weekly_db_maintenance.sh

echo "=== 每周数据库维护 $(date) ==="

# 创建数据库备份
mysqldump -u root -p magento --single-transaction --routines --triggers > "/backup/magento_$(date +%Y%m%d_%H%M%S).sql"

# 数据库表优化
mysql -u root -p magento -e "SELECT CONCAT('OPTIMIZE TABLE ', table_name, ';') FROM information_schema.tables WHERE table_schema='magento';" | grep -v CONCAT > /tmp/optimize.sql
mysql -u root -p magento < /tmp/optimize.sql

# 分析表结构
mysql -u root -p magento -e "SELECT CONCAT('ANALYZE TABLE ', table_name, ';') FROM information_schema.tables WHERE table_schema='magento';" | grep -v CONCAT > /tmp/analyze.sql
mysql -u root -p magento < /tmp/analyze.sql

echo "数据库维护完成"
```

#### 安全扫描
```bash
#!/bin/bash
# weekly_security_scan.sh

echo "=== 每周安全扫描 $(date) ==="

# 检查系统更新
apt list --upgradable

# 检查失败的登录尝试
grep "Failed password" /var/log/auth.log | tail -20

# 检查 fail2ban 状态
fail2ban-client status
fail2ban-client status sshd

# 检查文件权限
find /var/www/magento -type f -perm /o+w

echo "安全扫描完成"
```

### 每月任务

#### 系统更新
```bash
#!/bin/bash
# monthly_system_update.sh

echo "=== 每月系统更新 $(date) ==="

# 备份当前配置
cp -r /etc/nginx/ /backup/nginx_$(date +%Y%m%d)/
cp /etc/mysql/my.cnf /backup/mysql_$(date +%Y%m%d).cnf

# 更新包列表
apt update

# 显示可更新的包
apt list --upgradable

# 自动更新安全补丁
unattended-upgrade -d

echo "系统更新完成，请手动审查并安装其他更新"
```

## 🔧 性能优化

### MySQL 优化

#### 监控和调整 InnoDB
```bash
# 检查 InnoDB 状态
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "BUFFER POOL AND MEMORY"

# 优化建议脚本
#!/bin/bash
# mysql_optimization.sh

MYSQL_USER="root"
MYSQL_PASS="your_password"

echo "=== MySQL 性能分析 ==="

# 缓冲池命中率
BUFFER_POOL_HIT_RATE=$(mysql -u $MYSQL_USER -p$MYSQL_PASS -e "
    SELECT ROUND(100 - (Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests * 100), 2) as hit_rate 
    FROM information_schema.global_status 
    WHERE variable_name IN ('Innodb_buffer_pool_reads', 'Innodb_buffer_pool_read_requests');"
)

echo "InnoDB 缓冲池命中率: $BUFFER_POOL_HIT_RATE%"

# 连接数分析
mysql -u $MYSQL_USER -p$MYSQL_PASS -e "
    SELECT 
        variable_name, 
        variable_value 
    FROM information_schema.global_status 
    WHERE variable_name IN (
        'Connections', 
        'Max_used_connections', 
        'Threads_connected'
    );"
```

#### 慢查询优化
```bash
# 启用慢查询日志分析
pt-query-digest /var/log/mysql/slow.log > /tmp/slow_query_analysis.txt

# 查看最耗时的查询
head -50 /tmp/slow_query_analysis.txt
```

### PHP 优化

#### OPcache 监控
```bash
# 创建 OPcache 监控脚本
cat > /var/www/html/opcache-status.php << 'EOF'
<?php
if (function_exists('opcache_get_status')) {
    $status = opcache_get_status();
    $config = opcache_get_configuration();
    
    echo "OPcache 状态:\n";
    echo "启用状态: " . ($status['opcache_enabled'] ? '是' : '否') . "\n";
    echo "内存使用: " . round($status['memory_usage']['used_memory'] / 1024 / 1024, 2) . "MB / " . 
         round($status['memory_usage']['free_memory'] / 1024 / 1024, 2) . "MB\n";
    echo "缓存命中率: " . round($status['opcache_statistics']['opcache_hit_rate'], 2) . "%\n";
    echo "缓存的脚本数: " . $status['opcache_statistics']['num_cached_scripts'] . "\n";
} else {
    echo "OPcache 未启用\n";
}
?>
EOF

# 执行监控
php /var/www/html/opcache-status.php
```

#### PHP-FPM 调优
```bash
# 监控 PHP-FPM 池状态
curl http://localhost/status?json | jq '.'

# 分析 PHP-FPM 日志
tail -f /var/log/php/magento-access.log | awk '{
    request_time = $(NF-1)
    if (request_time > 5) {
        print "慢请求: " $0
    }
}'
```

### Nginx 优化

#### 连接监控
```bash
# 监控 Nginx 连接状态
curl http://localhost/nginx_status

# 分析访问日志
#!/bin/bash
# nginx_analysis.sh

LOG_FILE="/var/log/nginx/access.log"

echo "=== Nginx 访问分析 ==="

# 最常访问的页面
echo "最常访问的页面:"
awk '{print $7}' $LOG_FILE | sort | uniq -c | sort -nr | head -10

# 响应时间分析
echo "平均响应时间:"
awk '{sum += $NF; count++} END {print sum/count " seconds"}' $LOG_FILE

# 状态码统计
echo "HTTP 状态码统计:"
awk '{print $9}' $LOG_FILE | sort | uniq -c | sort -nr
```

## 🔐 安全维护

### SSL 证书管理

#### 证书状态检查
```bash
#!/bin/bash
# ssl_check.sh

DOMAIN="your-domain.com"

echo "=== SSL 证书检查 ==="

# 检查证书到期时间
openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -dates

# 检查证书详情
openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -subject -issuer

# 测试证书链
openssl verify -CAfile "/etc/letsencrypt/live/$DOMAIN/chain.pem" "/etc/letsencrypt/live/$DOMAIN/cert.pem"

# 检查自动续期状态
systemctl status certbot.timer
```

### 安全扫描

#### 文件完整性检查
```bash
#!/bin/bash
# file_integrity_check.sh

echo "=== 文件完整性检查 ==="

# 检查 Magento 核心文件
cd /var/www/magento
php bin/magento dev:tests:run integrity

# 检查可疑文件
find /var/www/magento -name "*.php" -exec grep -l "eval\|base64_decode\|shell_exec" {} \;

# 检查文件权限
find /var/www/magento -type f -perm /o+w -exec ls -la {} \;
```

#### 网络安全监控
```bash
#!/bin/bash
# network_security_monitor.sh

echo "=== 网络安全监控 ==="

# 检查活动连接
netstat -tuln

# 检查防火墙状态
ufw status verbose

# 检查 fail2ban 统计
fail2ban-client status
for jail in $(fail2ban-client status | grep "Jail list:" | cut -f2 | sed 's/,//g'); do
    echo "=== $jail ==="
    fail2ban-client status $jail
done
```

## 📦 备份和恢复

### 自动备份脚本

```bash
#!/bin/bash
# magento_backup.sh

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_USER="root"
MYSQL_PASS="your_password"
DOMAIN="your-domain.com"

mkdir -p $BACKUP_DIR/$DATE

echo "=== Magento 备份开始 $(date) ==="

# 数据库备份
echo "备份数据库..."
mysqldump -u $MYSQL_USER -p$MYSQL_PASS magento --single-transaction --routines --triggers > "$BACKUP_DIR/$DATE/magento_db.sql"

# 文件备份
echo "备份文件..."
tar -czf "$BACKUP_DIR/$DATE/magento_files.tar.gz" -C /var/www magento --exclude="var/cache/*" --exclude="var/page_cache/*" --exclude="var/session/*"

# 配置文件备份
echo "备份配置文件..."
tar -czf "$BACKUP_DIR/$DATE/config_files.tar.gz" /etc/nginx /etc/php /etc/mysql /etc/ssl

# 压缩整个备份
echo "压缩备份..."
tar -czf "$BACKUP_DIR/magento_backup_$DATE.tar.gz" -C $BACKUP_DIR $DATE
rm -rf "$BACKUP_DIR/$DATE"

# 清理旧备份（保留 30 天）
find $BACKUP_DIR -name "magento_backup_*.tar.gz" -mtime +30 -delete

echo "备份完成: $BACKUP_DIR/magento_backup_$DATE.tar.gz"
```

### 恢复流程

```bash
#!/bin/bash
# magento_restore.sh

if [ $# -ne 1 ]; then
    echo "用法: $0 <备份文件>"
    exit 1
fi

BACKUP_FILE=$1
RESTORE_DIR="/tmp/restore_$(date +%Y%m%d_%H%M%S)"
MYSQL_USER="root"
MYSQL_PASS="your_password"

echo "=== Magento 恢复开始 $(date) ==="

# 创建恢复目录
mkdir -p $RESTORE_DIR
cd $RESTORE_DIR

# 解压备份
echo "解压备份文件..."
tar -xzf $BACKUP_FILE

# 恢复数据库
echo "恢复数据库..."
mysql -u $MYSQL_USER -p$MYSQL_PASS magento < */magento_db.sql

# 恢复文件
echo "恢复文件..."
tar -xzf */magento_files.tar.gz -C /var/www/

# 设置权限
echo "设置权限..."
chown -R magento:www-data /var/www/magento
find /var/www/magento -type f -exec chmod 644 {} \;
find /var/www/magento -type d -exec chmod 755 {} \;
chmod +x /var/www/magento/bin/magento

# 清理缓存
echo "清理缓存..."
cd /var/www/magento
sudo -u magento php bin/magento cache:flush
sudo -u magento php bin/magento cache:clean

echo "恢复完成"
```

## 📊 监控仪表板

### 创建监控脚本

```bash
#!/bin/bash
# monitoring_dashboard.sh

echo "=================================="
echo "Magento LEMP 监控仪表板"
echo "时间: $(date)"
echo "=================================="

# 系统信息
echo -e "\n🖥️  系统信息:"
uptime
echo "CPU 使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')%"
echo "内存使用率: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "磁盘使用率: $(df -h / | awk 'NR==2{print $5}')"

# 服务状态
echo -e "\n🔧 服务状态:"
for service in nginx php8.4-fpm mysql opensearch valkey rabbitmq-server; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: 运行中"
    else
        echo "❌ $service: 停止"
    fi
done

# Web 服务器状态
echo -e "\n🌐 Web 服务器:"
if curl -s http://localhost > /dev/null; then
    echo "✅ HTTP: 正常"
else
    echo "❌ HTTP: 异常"
fi

if curl -s https://localhost > /dev/null; then
    echo "✅ HTTPS: 正常"
else
    echo "❌ HTTPS: 异常"
fi

# 数据库状态
echo -e "\n🗄️  数据库:"
if mysqladmin ping -u root -p$MYSQL_ROOT_PASSWORD 2>/dev/null; then
    echo "✅ MySQL: 连接正常"
    CONNECTIONS=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW STATUS LIKE 'Threads_connected';" | awk 'NR==2{print $2}')
    echo "   当前连接数: $CONNECTIONS"
else
    echo "❌ MySQL: 连接失败"
fi

# Magento 状态
echo -e "\n🛒 Magento:"
if [ -f "/var/www/magento/bin/magento" ]; then
    cd /var/www/magento
    MODE=$(sudo -u magento php bin/magento deploy:mode:show 2>/dev/null | tail -1)
    echo "   运行模式: $MODE"
    
    # 检查缓存状态
    CACHE_STATUS=$(sudo -u magento php bin/magento cache:status 2>/dev/null | grep -c "enabled")
    echo "   启用缓存数: $CACHE_STATUS"
else
    echo "❌ Magento 未安装"
fi

echo -e "\n=================================="
```

## 🚨 告警设置

### 邮件告警脚本

```bash
#!/bin/bash
# alert_system.sh

ADMIN_EMAIL="admin@your-domain.com"
HOSTNAME=$(hostname)

# 检查磁盘空间
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "警告：$HOSTNAME 磁盘使用率达到 $DISK_USAGE%" | mail -s "磁盘空间告警" $ADMIN_EMAIL
fi

# 检查内存使用
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
if [ $MEMORY_USAGE -gt 90 ]; then
    echo "警告：$HOSTNAME 内存使用率达到 $MEMORY_USAGE%" | mail -s "内存使用告警" $ADMIN_EMAIL
fi

# 检查服务状态
for service in nginx php8.4-fpm mysql; do
    if ! systemctl is-active --quiet $service; then
        echo "警告：$HOSTNAME 上的 $service 服务已停止" | mail -s "服务状态告警" $ADMIN_EMAIL
    fi
done
```

---

定期执行这些维护任务将确保您的 Magento 2.4.8 LEMP 环境保持最佳性能和安全性。建议将这些脚本添加到 crontab 中自动执行。
