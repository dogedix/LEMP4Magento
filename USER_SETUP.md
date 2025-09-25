# 🧑‍💻 用户配置说明

## 👤 默认用户配置

此项目已配置为使用 **doge** 用户进行所有 Magento 开发工作，而不是创建单独的 `magento` 用户。

### ⚙️ 用户配置详情

```yaml
# 系统用户配置
system_user: "doge"           # 使用现有的 doge 用户
system_group: "doge"          # doge 用户组  
web_group: "www-data"         # Web 服务器组
```

### 🔧 自动配置内容

部署完成后，`doge` 用户将具备以下配置：

#### 1. 用户组配置
```bash
# doge 用户被添加到 www-data 组
usermod -a -G www-data doge
```

#### 2. 目录权限
```bash
# Web 目录配置
/var/www/
├── 所有者: doge
├── 用户组: www-data  
└── 权限: 755
```

#### 3. PHP-FPM 池配置
```ini
# /etc/php/8.4/fpm/pool.d/doge.conf
[doge]
user = doge
group = www-data
listen = /run/php/php8.4-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
```

#### 4. Composer 配置
```bash
# Composer 目录
/home/doge/.composer/
├── 所有者: doge
├── 用户组: doge
└── 权限: 755
```

## 🚀 Magento 安装流程

### 方法 1: 使用 doge 用户直接安装

```bash
# 1. 进入 Web 目录
cd /var/www

# 2. 创建 Magento 项目
composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition \
    magento-site1

# 3. 设置权限
cd magento-site1
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chmod u+x bin/magento
```

### 方法 2: 多站点支持

您可以在 `/var/www` 下安装多个 Magento 站点：

```bash
cd /var/www

# 站点 1
composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition \
    site1.example.com

# 站点 2  
composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition \
    site2.example.com

# 站点 3
composer create-project \
    --repository-url=https://repo.magento.com/ \
    magento/project-community-edition \
    site3.example.com
```

## 📁 推荐目录结构

```
/var/www/
├── site1.example.com/          # 第一个 Magento 站点
│   ├── app/
│   ├── bin/
│   ├── pub/
│   └── var/
├── site2.example.com/          # 第二个 Magento 站点
│   ├── app/
│   ├── bin/
│   ├── pub/
│   └── var/
├── shared/                     # 共享资源
│   ├── media/                  # 共享媒体文件
│   └── logs/                   # 集中日志
└── phpmyadmin/                 # 数据库管理界面
```

## 🔐 安全权限设置

### Magento 推荐权限

```bash
# 进入 Magento 目录
cd /var/www/your-magento-site

# 设置基础权限
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

# 设置特殊权限
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

# 设置可执行权限
chmod u+x bin/magento
```

### 自动权限脚本

创建权限设置脚本：

```bash
#!/bin/bash
# /var/www/set-magento-permissions.sh

if [ $# -eq 0 ]; then
    echo "用法: $0 <magento-directory>"
    exit 1
fi

MAGENTO_DIR=$1

if [ ! -d "$MAGENTO_DIR" ]; then
    echo "错误: 目录 $MAGENTO_DIR 不存在"
    exit 1
fi

cd "$MAGENTO_DIR"

echo "设置 Magento 权限: $MAGENTO_DIR"

# 基础权限
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;

# 可写权限
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +

# 可执行权限
chmod u+x bin/magento

echo "权限设置完成！"
```

## 🗄️ 数据库配置

每个 Magento 站点使用独立数据库：

```sql
-- 为每个站点创建独立数据库
CREATE DATABASE magento_site1;
CREATE DATABASE magento_site2;
CREATE DATABASE magento_site3;

-- 使用相同的数据库用户
GRANT ALL PRIVILEGES ON magento_site1.* TO 'magento_user'@'localhost';
GRANT ALL PRIVILEGES ON magento_site2.* TO 'magento_user'@'localhost';
GRANT ALL PRIVILEGES ON magento_site3.* TO 'magento_user'@'localhost';
```

## 🎯 优势总结

使用 `doge` 用户的优势：

1. **🔧 简化管理**: 无需切换用户，直接使用主用户
2. **📁 统一权限**: 所有项目文件归属明确
3. **🚀 快速部署**: 减少用户管理复杂性
4. **🔄 多站点支持**: 轻松管理多个 Magento 站点
5. **🛠️ 开发友好**: IDE 和工具直接访问文件

---

**注意**: 确保 `doge` 用户具有足够的系统权限来管理 Web 文件和运行 Composer。
