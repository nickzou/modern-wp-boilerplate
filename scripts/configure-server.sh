#!/bin/bash
# tf-to-ansible.sh - Extract Terraform outputs and configure Ansible inventory and variables

# Set error handling
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
TF_DIR="infrastructure/terraform"
ANSIBLE_DIR="infrastructure/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory"
GROUP_VARS_FILE="$ANSIBLE_DIR/group_vars/web_servers.yml"
ENV_FILE=".env"

# Function to print colored status messages
print_status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if Terraform directory exists
if [ ! -d "$TF_DIR" ]; then
    print_error "Terraform directory $TF_DIR not found. Please verify the path."
    exit 1
fi

# Check if Ansible directory exists, create if not
if [ ! -d "$ANSIBLE_DIR" ]; then
    print_warning "Ansible directory $ANSIBLE_DIR not found. Creating directory structure..."
    mkdir -p "$ANSIBLE_DIR"
    mkdir -p "$ANSIBLE_DIR/group_vars"
fi

# Ensure group_vars directory exists
mkdir -p "$(dirname "$GROUP_VARS_FILE")"

# Change to the Terraform directory
print_status "Changing to Terraform directory: $TF_DIR"
cd "$TF_DIR"

# Check if Terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -d ".terraform" ]; then
    print_error "No Terraform state found. Please run terraform apply first."
    exit 1
fi

print_status "Extracting Terraform outputs..."

# Extract outputs using terraform output -json
if ! terraform_outputs=$(terraform output -json 2>/dev/null); then
    print_error "Failed to extract Terraform outputs. Make sure Terraform has been applied successfully."
    exit 1
fi

# Parse JSON outputs using jq (or fallback to basic parsing)
if command -v jq &> /dev/null; then
    server_ip=$(echo "$terraform_outputs" | jq -r '.server_ip.value // empty')
    wordpress_url=$(echo "$terraform_outputs" | jq -r '.wordpress_url.value // empty')
    wordpress_admin=$(echo "$terraform_outputs" | jq -r '.wordpress_admin.value // empty')
    staging_url=$(echo "$terraform_outputs" | jq -r '.staging_url.value // empty')
    ssh_command=$(echo "$terraform_outputs" | jq -r '.ssh_command.value // empty')
    domain_name=$(echo "$terraform_outputs" | jq -r '.domain_name.value // empty')
    ssl_email=$(echo "$terraform_outputs" | jq -r '.ssl_email.value // empty')
else
    print_warning "jq not found. Using basic parsing method."
    # Fallback parsing (less robust but works without jq)
    server_ip=$(terraform output -raw server_ip 2>/dev/null || echo "")
    wordpress_url=$(terraform output -raw wordpress_url 2>/dev/null || echo "")
    wordpress_admin=$(terraform output -raw wordpress_admin 2>/dev/null || echo "")
    staging_url=$(terraform output -raw staging_url 2>/dev/null || echo "")
    ssh_command=$(terraform output -raw ssh_command 2>/dev/null || echo "")
    domain_name=$(terraform output -raw domain_name 2>/dev/null || echo "")
    ssl_email=$(terraform output -raw ssl_email 2>/dev/null || echo "")
fi

# Return to original directory
cd - > /dev/null

# Validate required outputs
if [ -z "$server_ip" ]; then
    print_error "server_ip output not found or empty. Cannot proceed."
    exit 1
fi

print_status "Found server IP: $server_ip"

# Create Ansible inventory file
print_status "Creating Ansible inventory file: $INVENTORY_FILE"
cat > "$INVENTORY_FILE" << EOF
[web_servers]
root@$server_ip

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

print_status "Inventory file created successfully."

# Parse .env file for ANS_ prefixed variables
print_status "Scanning .env file for ANS_ prefixed variables..."
env_vars=""
if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check if line starts with ANS_
        if [[ "$line" =~ ^ANS_[A-Za-z0-9_]+=.*$ ]]; then
            # Extract variable name and value
            var_name=$(echo "$line" | cut -d'=' -f1)
            var_value=$(echo "$line" | cut -d'=' -f2- | sed 's/^"//;s/"$//')
            
            # Convert ANS_VAR_NAME to ansible_var_name format
            ansible_var_name=$(echo "${var_name#ANS_}" | tr '[:upper:]' '[:lower:]')
            
            # Add to env_vars string
            env_vars="${env_vars}${ansible_var_name}: \"${var_value}\"\n"
            print_status "Found environment variable: $var_name -> $ansible_var_name"
        fi
    done < "$ENV_FILE"
else
    print_warning ".env file not found. Skipping environment variable parsing."
fi

# Create group_vars file
print_status "Creating Ansible group variables file: $GROUP_VARS_FILE"
cat > "$GROUP_VARS_FILE" << EOF
---
# Terraform outputs for Ansible configuration
# Generated automatically by tf-to-ansible.sh

# Server information
server_ip: "$server_ip"

# WordPress URLs
wordpress_url: "$wordpress_url"
wordpress_admin: "$wordpress_admin"
staging_url: "$staging_url"

# SSH configuration
ssh_command: "$ssh_command"

# Domain and SSL configuration
domain_name: "$domain_name"
ssl_email: "$ssl_email"

# Additional Ansible configuration
ansible_user: root
ansible_ssh_private_key_file: "{{ lookup('env', 'SSH_PRIVATE_KEY_PATH') | default('~/.ssh/id_rsa') }}"

# Environment variables from .env file (ANS_ prefixed)
EOF

# Add environment variables if any were found
if [ -n "$env_vars" ]; then
    echo -e "$env_vars" >> "$GROUP_VARS_FILE"
else
    echo "# No ANS_ prefixed environment variables found" >> "$GROUP_VARS_FILE"
fi

print_status "Group variables file created successfully."

# Display summary
print_status "Configuration Summary:"
echo "  Server IP: $server_ip"
echo "  Domain: $domain_name"
echo "  WordPress URL: $wordpress_url"
echo "  Staging URL: $staging_url"
echo ""
print_status "Files created:"
echo "  Inventory: $INVENTORY_FILE"
echo "  Variables: $GROUP_VARS_FILE"
echo ""
print_status "You can now run Ansible playbooks with:"
echo "  ansible-playbook -i $INVENTORY_FILE your-playbook.yml"
echo ""

# Optional: Test connectivity
read -p "Do you want to test SSH connectivity to the server? (y/n): " test_ssh
if [[ $test_ssh == [yY] || $test_ssh == [yY][eE][sS] ]]; then
    print_status "Testing SSH connectivity..."
    if ansible all -i "$INVENTORY_FILE" -m ping 2>/dev/null; then
        print_status "SSH connectivity test successful!"
    else
        print_warning "SSH connectivity test failed. Please check your SSH key configuration."
        print_status "You can test manually with: $ssh_command"
    fi
fi

print_status "Done."
