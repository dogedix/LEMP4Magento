#!/bin/bash

# Magento 2.4.8 LEMP Stack Deployment Script
# Usage: ./deploy.sh [target_server_ip] [target_server_user] [domain_name]

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

# Default values
TARGET_IP="${1:-localhost}"
TARGET_USER="${2:-root}"
DOMAIN_NAME="${3:-magento.local}"
SSH_KEY="${SSH_KEY_PATH:-~/.ssh/id_rsa}"

print_status "Starting Magento 2.4.8 LEMP Stack Deployment"
print_status "Target Server: $TARGET_USER@$TARGET_IP"
print_status "Domain: $DOMAIN_NAME"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    print_error "Ansible is not installed. Please install Ansible first."
    print_status "Installation command: sudo apt update && sudo apt install ansible"
    exit 1
fi

# Check if required collections are installed
print_status "Installing required Ansible collections..."
ansible-galaxy collection install -r requirements.yml --force

# Encrypt vault file if not already encrypted
if [ -f "group_vars/vault.yml" ] && ! grep -q "\$ANSIBLE_VAULT" group_vars/vault.yml; then
    print_warning "Vault file is not encrypted. Encrypting now..."
    ansible-vault encrypt group_vars/vault.yml
fi

# Create inventory with provided parameters
print_status "Creating dynamic inventory..."
cat > inventory/hosts.yml << EOF
---
all:
  children:
    magento_servers:
      hosts:
        magento-server:
          ansible_host: "${TARGET_IP}"
          ansible_user: "${TARGET_USER}"
          ansible_ssh_private_key_file: "${SSH_KEY}"
      vars:
        ansible_python_interpreter: /usr/bin/python3
        magento_domain: "${DOMAIN_NAME}"
        admin_email_address: "admin@${DOMAIN_NAME}"
EOF

# Test connection
print_status "Testing connection to target server..."
if ansible magento_servers -m ping; then
    print_success "Connection successful!"
else
    print_error "Failed to connect to target server. Please check:"
    print_error "1. Server IP/hostname: $TARGET_IP"
    print_error "2. SSH user: $TARGET_USER"
    print_error "3. SSH key: $SSH_KEY"
    print_error "4. SSH access permissions"
    exit 1
fi

# Run syntax check
print_status "Checking playbook syntax..."
if ansible-playbook site.yml --syntax-check; then
    print_success "Playbook syntax is valid!"
else
    print_error "Playbook syntax check failed. Please fix the errors."
    exit 1
fi

# Run the playbook
print_status "Starting deployment..."
print_warning "This may take 30-60 minutes depending on server performance and network speed."

# Ask for vault password and run playbook
if ansible-playbook site.yml --ask-vault-pass -v; then
    print_success "Deployment completed successfully!"
    
    echo ""
    print_status "=== POST-DEPLOYMENT INFORMATION ==="
    echo ""
    print_success "LEMP stack has been installed with the following components:"
    echo "  - Nginx 1.27 with ModSecurity"
    echo "  - PHP 8.4/8.3 with all Magento extensions"
    echo "  - Percona MySQL 8.4"
    echo "  - OpenSearch 2.19"
    echo "  - Valkey 8 (Redis compatible)"
    echo "  - RabbitMQ 4.1"
    echo "  - Varnish 7.6"
    echo "  - Composer 2.8"
    echo "  - Security tools (Fail2ban, Certbot)"
    echo "  - Admin tools (Webmin, phpMyAdmin)"
    echo ""
    print_status "Next Steps:"
    echo "1. Install Magento 2.4.8:"
    echo "   ssh $TARGET_USER@$TARGET_IP"
    echo "   cd /var/www && composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition magento"
    echo "   # All files will be owned by doge user with www-data group"
    echo ""
    echo "2. Configure SSL certificate:"
    echo "   certbot --nginx -d $DOMAIN_NAME"
    echo ""
    echo "3. Access admin interfaces:"
    echo "   - Webmin: https://$TARGET_IP:10000"
    echo "   - phpMyAdmin: https://$DOMAIN_NAME/phpmyadmin"
    echo ""
    echo "4. Monitor services:"
    echo "   systemctl status nginx php8.4-fpm mysql opensearch valkey rabbitmq-server varnish"
    echo ""
    print_success "Deployment completed! Your Magento 2.4.8 LEMP stack is ready!"
    
else
    print_error "Deployment failed. Please check the logs above for details."
    exit 1
fi
