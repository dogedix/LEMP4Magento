#!/bin/bash

# Magento 2.4.8 LEMP Stack Local Installation Script
# 本地安装脚本 - 无需任何参数

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "======================================="
print_status "Magento 2.4.8 LEMP 本地环境安装"
print_status "======================================="
print_status "用户: doge"
print_status "安装位置: 本地服务器"
print_status "Web目录: /var/www"

# Check if running as root or with sudo access
if [[ $EUID -eq 0 ]]; then
    print_error "请不要以 root 用户运行此脚本"
    print_status "正确用法: ./install-local.sh"
    exit 1
fi

# Check if user has sudo access
if ! sudo -n true 2>/dev/null; then
    print_error "当前用户需要 sudo 权限"
    print_status "请确保 doge 用户有 sudo 权限"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    print_warning "Ansible 未安装，正在安装..."
    sudo apt update
    sudo apt install -y ansible
fi

# Check if required collections are installed
print_status "安装必需的 Ansible 集合..."
ansible-galaxy collection install -r requirements.yml --force

# Encrypt vault file if not already encrypted
if [ -f "group_vars/vault.yml" ] && ! grep -q "\$ANSIBLE_VAULT" group_vars/vault.yml; then
    print_warning "加密敏感配置文件..."
    ansible-vault encrypt group_vars/vault.yml
fi

# Run syntax check
print_status "检查配置语法..."
if ansible-playbook site.yml --syntax-check; then
    print_success "配置语法正确！"
else
    print_error "配置语法检查失败，请修复错误。"
    exit 1
fi

# Run the playbook
print_status "开始安装 LEMP 环境..."
print_warning "安装过程可能需要 30-60 分钟，请耐心等待..."

# Ask for vault password and run playbook
if ansible-playbook site.yml --ask-vault-pass -v; then
    print_success "LEMP 环境安装完成！"
    
    echo ""
    print_status "=== 安装完成信息 ==="
    echo ""
    print_success "已安装的组件："
    echo "  ✅ Nginx 1.27 + ModSecurity"
    echo "  ✅ PHP 8.4/8.3 + 所有 Magento 扩展"
    echo "  ✅ Percona MySQL 8.4"
    echo "  ✅ OpenSearch 2.19"
    echo "  ✅ Valkey 8 (Redis 兼容)"
    echo "  ✅ RabbitMQ 4.1"
    echo "  ✅ Varnish 7.6"
    echo "  ✅ Composer 2.8"
    echo "  ✅ 安全工具 (Fail2ban, UFW)"
    echo "  ✅ 管理工具 (Webmin, phpMyAdmin)"
    echo ""
    print_status "下一步操作："
    echo ""
    echo "1. 🛒 安装 Magento 2.4.8:"
    echo "   cd /var/www"
    echo "   composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition magento"
    echo ""
    echo "2. 🌐 访问您的网站:"
    echo "   http://localhost (Nginx 默认页面)"
    echo "   http://localhost/magento (安装 Magento 后)"
    echo ""
    echo "3. 🛠️ 管理界面:"
    echo "   Webmin: http://localhost:10000"
    echo "   phpMyAdmin: http://localhost/phpmyadmin"
    echo ""
    echo "4. 📊 服务状态检查:"
    echo "   sudo systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server varnish"
    echo ""
    echo "5. 📁 文件权限设置 (Magento 安装后):"
    echo "   cd /var/www/magento"
    echo "   find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +"
    echo "   find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"
    echo "   chmod u+x bin/magento"
    echo ""
    print_success "🎉 本地 Magento 2.4.8 LEMP 环境已就绪！"
    print_status "所有服务已启动并配置完成，可以开始安装 Magento 了！"
    
else
    print_error "安装失败，请检查上面的错误信息。"
    exit 1
fi
