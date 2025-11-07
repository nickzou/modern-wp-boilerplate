#!/bin/bash

# Set error handling
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Terraform directory
TF_DIR="infrastructure"

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

# Check if necessary files exist
if [ ! -f "$TF_DIR/terraform.tfvars" ]; then
    print_warning "terraform.tfvars file not found in $TF_DIR. Make sure to run env-to-tfvars.sh first."
fi

# Change to the Terraform directory
print_status "Changing to Terraform directory: $TF_DIR"
cd "$TF_DIR"

# Run terraform init
print_status "Initializing Terraform..."
terraform init

# Check if initialization was successful
if [ $? -ne 0 ]; then
    print_error "Terraform initialization failed."
    exit 1
fi

print_status "Terraform initialized successfully."

# Validate the configuration
print_status "Validating Terraform configuration..."
terraform validate

# Check if validation was successful
if [ $? -ne 0 ]; then
    print_error "Terraform validation failed."
    exit 1
fi

print_status "Terraform configuration is valid."

# Run terraform plan first
print_status "Running Terraform plan to check what will be created/modified..."
terraform plan

# Prompt for confirmation before applying
read -p "Do you want to continue with terraform apply? (y/n): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    print_warning "Terraform apply cancelled by user."
    cd - > /dev/null # Return to original directory
    exit 0
fi

# Run terraform apply
print_status "Applying Terraform configuration..."
terraform apply -auto-approve

# Check if apply was successful
if [ $? -ne 0 ]; then
    print_error "Terraform apply failed."
    cd - > /dev/null # Return to original directory
    exit 1
fi

print_status "Terraform apply completed successfully."
print_status "Infrastructure has been provisioned."

# Optionally show outputs
read -p "Do you want to see the outputs? (y/n): " show_outputs
if [[ $show_outputs == [yY] || $show_outputs == [yY][eE][sS] ]]; then
    print_status "Terraform outputs:"
    terraform output
fi

# Return to the original directory
cd - > /dev/null
print_status "Done."

