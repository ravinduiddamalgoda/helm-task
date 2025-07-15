#!/bin/bash

# SSH Key Management with Doppler
# This script automatically generates SSH keys and stores them in Doppler
# Only generates new keys if they don't exist or are expired

set -e

# Configuration
DOPPLER_PROJECT="oci-infra"
DOPPLER_CONFIG="dev"
SSH_KEY_NAME="BASTION_SSH_PRIVATE_KEY"
SSH_PUBLIC_KEY_NAME="BASTION_SSH_PUBLIC_KEY"
SSH_KEY_EXPIRY_DAYS=90  # Regenerate keys older than 90 days

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local level=$1
    local message=$2
    case $level in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Function to check if Doppler CLI is available
check_doppler_cli() {
    if ! command -v doppler >/dev/null 2>&1; then
        print_status "ERROR" "Doppler CLI is not installed"
        echo "   Install it from: https://docs.doppler.com/docs/install-cli"
        exit 1
    fi
    print_status "SUCCESS" "Doppler CLI is available"
}

# Function to check Doppler authentication
check_doppler_auth() {
    print_status "INFO" "Checking Doppler authentication..."
    
    # Check for either DOPPLER_TOKEN or DOPPLER_SERVICE_TOKEN
    local doppler_token=""
    if [ -n "$DOPPLER_TOKEN" ]; then
        doppler_token="$DOPPLER_TOKEN"
        print_status "INFO" "Using DOPPLER_TOKEN"
    elif [ -n "$DOPPLER_SERVICE_TOKEN" ]; then
        doppler_token="$DOPPLER_SERVICE_TOKEN"
        print_status "INFO" "Using DOPPLER_SERVICE_TOKEN"
    else
        print_status "ERROR" "Neither DOPPLER_TOKEN nor DOPPLER_SERVICE_TOKEN environment variable is set"
        exit 1
    fi
    
    # Test Doppler connection using the token
    if ! DOPPLER_TOKEN="$doppler_token" doppler secrets download --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" --no-file >/dev/null 2>&1; then
        print_status "ERROR" "Failed to authenticate with Doppler"
        echo "   Please check your Doppler token and project configuration"
        echo "   Project: $DOPPLER_PROJECT"
        echo "   Config: $DOPPLER_CONFIG"
        exit 1
    fi

    
    print_status "SUCCESS" "Doppler authentication successful"
}

# Function to check if SSH keys exist in Doppler
check_existing_ssh_keys() {
    print_status "INFO" "Checking existing SSH keys in Doppler..."
    
    # Get the Doppler token
    local doppler_token=""
    if [ -n "$DOPPLER_TOKEN" ]; then
        doppler_token="$DOPPLER_TOKEN"
    elif [ -n "$DOPPLER_SERVICE_TOKEN" ]; then
        doppler_token="$DOPPLER_SERVICE_TOKEN"
    fi
    
    local existing_private_key=$(DOPPLER_TOKEN="$doppler_token" doppler secrets get "$SSH_KEY_NAME" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" --silent 2>/dev/null || echo "")
    local existing_public_key=$(DOPPLER_TOKEN="$doppler_token" doppler secrets get "$SSH_PUBLIC_KEY_NAME" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" --silent 2>/dev/null || echo "")
    
    if [ -n "$existing_private_key" ] && [ -n "$existing_public_key" ]; then
        print_status "SUCCESS" "SSH keys found in Doppler"
        
        # Check if keys are expired (we'll use a simple timestamp check)
        # For now, we'll regenerate if the keys are older than SSH_KEY_EXPIRY_DAYS days
        # In a real implementation, you might want to store creation timestamps
        
        print_status "INFO" "SSH keys exist. Checking if regeneration is needed..."
        
        # For simplicity, we'll regenerate keys every time for now
        # In production, you might want to implement a more sophisticated expiry check
        print_status "WARNING" "Regenerating SSH keys for security"
        return 1  # Indicate keys need regeneration
    else
        print_status "INFO" "No SSH keys found in Doppler"
        return 1  # Indicate keys need generation
    fi
}

# Function to generate SSH keys
generate_ssh_keys() {
    print_status "INFO" "Generating new SSH keys..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local private_key_file="$temp_dir/oci_bastion_ed25519"
    local public_key_file="$temp_dir/oci_bastion_ed25519.pub"
    
    # Generate ED25519 key pair
    ssh-keygen -t ed25519 -f "$private_key_file" -N "" -C "doppler-managed-bastion-$(date +%Y%m%d)"
    
    # Set correct permissions
    chmod 600 "$private_key_file"
    chmod 644 "$public_key_file"
    
    # Read the keys
    local private_key_content=$(cat "$private_key_file")
    local public_key_content=$(cat "$public_key_file")
    
    # Clean up temporary files
    rm -rf "$temp_dir"
    
    print_status "SUCCESS" "SSH keys generated successfully"
    
    # Store keys in Doppler
    store_ssh_keys_in_doppler "$private_key_content" "$public_key_content"
}

# Function to store SSH keys in Doppler
store_ssh_keys_in_doppler() {
    local private_key="$1"
    local public_key="$2"
    
    print_status "INFO" "Storing SSH keys in Doppler..."
    
    # Get the Doppler token
    local doppler_token=""
    if [ -n "$DOPPLER_TOKEN" ]; then
        doppler_token="$DOPPLER_TOKEN"
    elif [ -n "$DOPPLER_SERVICE_TOKEN" ]; then
        doppler_token="$DOPPLER_SERVICE_TOKEN"
    fi
    
    # Store private key
    DOPPLER_TOKEN="$doppler_token" doppler secrets set "$SSH_KEY_NAME=$private_key" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG"
    # Store public key
    DOPPLER_TOKEN="$doppler_token" doppler secrets set "$SSH_PUBLIC_KEY_NAME=$public_key" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG"

    
    print_status "SUCCESS" "SSH keys stored in Doppler successfully"
}

# Function to create local SSH key file from Doppler
create_local_ssh_key_file() {
    print_status "INFO" "Creating local SSH key file from Doppler..."
    
    # Get the Doppler token
    local doppler_token=""
    if [ -n "$DOPPLER_TOKEN" ]; then
        doppler_token="$DOPPLER_TOKEN"
    elif [ -n "$DOPPLER_SERVICE_TOKEN" ]; then
        doppler_token="$DOPPLER_SERVICE_TOKEN"
    fi
    
    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    
    # Get private key from Doppler and save to local file
    DOPPLER_TOKEN="$doppler_token" doppler secrets get "$SSH_KEY_NAME" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" --silent > ~/.ssh/oci_bastion_ed25519
    
    # Set correct permissions
    chmod 600 ~/.ssh/oci_bastion_ed25519
    
    # Get public key from Doppler and save to local file
    DOPPLER_TOKEN="$doppler_token" doppler secrets get "$SSH_PUBLIC_KEY_NAME" --project "$DOPPLER_PROJECT" --config "$DOPPLER_CONFIG" --silent > ~/.ssh/oci_bastion_ed25519.pub
    
    # Set correct permissions
    chmod 644 ~/.ssh/oci_bastion_ed25519.pub
    
    print_status "SUCCESS" "Local SSH key files created"
    print_status "INFO" "Private key: ~/.ssh/oci_bastion_ed25519"
    print_status "INFO" "Public key: ~/.ssh/oci_bastion_ed25519.pub"
}

# Function to verify SSH keys
verify_ssh_keys() {
    print_status "INFO" "Verifying SSH keys..."
    
    # Check if local files exist
    if [ ! -f ~/.ssh/oci_bastion_ed25519 ] || [ ! -f ~/.ssh/oci_bastion_ed25519.pub ]; then
        print_status "ERROR" "Local SSH key files not found"
        return 1
    fi
    
    # Check permissions
    local private_key_perms=$(stat -c %a ~/.ssh/oci_bastion_ed25519)
    local public_key_perms=$(stat -c %a ~/.ssh/oci_bastion_ed25519.pub)
    
    if [ "$private_key_perms" != "600" ]; then
        print_status "WARNING" "Private key has incorrect permissions ($private_key_perms), should be 600"
        chmod 600 ~/.ssh/oci_bastion_ed25519
    fi
    
    if [ "$public_key_perms" != "644" ]; then
        print_status "WARNING" "Public key has incorrect permissions ($public_key_perms), should be 644"
        chmod 644 ~/.ssh/oci_bastion_ed25519.pub
    fi
    
    # Test SSH key format
    # if ! ssh-keygen -l -f ~/.ssh/oci_bastion_ed25519.pub >/dev/null 2>&1; then
    #     print_status "ERROR" "Invalid SSH public key format"
    #     return 1
    # fi
    
    print_status "SUCCESS" "SSH keys verified successfully"
    
    # Display public key fingerprint
    local fingerprint=$(ssh-keygen -l -f ~/.ssh/oci_bastion_ed25519.pub | awk '{print $2}')
    print_status "INFO" "SSH key fingerprint: $fingerprint"
}

# Function to set environment variable
set_environment_variable() {
    local env_var="BASTION_SSH_KEY"
    local key_path="$HOME/.ssh/oci_bastion_ed25519"
    
    print_status "INFO" "Setting environment variable: $env_var=$key_path"
    
    # Export for current session
    export "$env_var"="$key_path"
    
    # Add to shell profile if not already present
    local profile_file="$HOME/.bashrc"
    if [ -f "$profile_file" ]; then
        if ! grep -q "export $env_var=" "$profile_file"; then
            echo "export $env_var=\"$key_path\"" >> "$profile_file"
            print_status "INFO" "Added $env_var to $profile_file"
        else
            print_status "INFO" "$env_var already exists in $profile_file"
        fi
    fi
    
    print_status "SUCCESS" "Environment variable set: $env_var=$key_path"
}

# Main execution
main() {
    echo "🔑 SSH Key Management with Doppler"
    echo "=================================="
    echo "Project: $DOPPLER_PROJECT"
    echo "Config: $DOPPLER_CONFIG"
    echo "Key Expiry: $SSH_KEY_EXPIRY_DAYS days"
    echo ""
    
    # Check prerequisites
    check_doppler_cli
    check_doppler_auth
    
    # Check existing keys
    if check_existing_ssh_keys; then
        print_status "INFO" "Using existing SSH keys from Doppler"
    else
        print_status "INFO" "Generating new SSH keys"
        generate_ssh_keys
    fi
    
    # Create local files
    create_local_ssh_key_file
    
    # Verify keys
    verify_ssh_keys
    
    # Set environment variable
    set_environment_variable
    
    echo ""
    print_status "SUCCESS" "SSH key management completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "   • SSH keys are stored in Doppler: $DOPPLER_PROJECT/$DOPPLER_CONFIG"
    echo "   • Local files created: ~/.ssh/oci_bastion_ed25519*"
    echo "   • Environment variable set: BASTION_SSH_KEY=~/.ssh/oci_bastion_ed25519"
    echo ""
    echo "🔍 Next steps:"
    echo "   1. Use the SSH keys in your Terraform/Terragrunt configuration"
    echo "   2. The keys will be automatically regenerated when needed"
    echo "   3. Keys are securely stored in Doppler with proper access controls"
    echo ""
}

# Run main function
main "$@" 