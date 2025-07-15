# SSH Key Management with Doppler

This directory contains scripts and documentation for automatic SSH key generation and management using Doppler, eliminating the need for manual SSH key management in your OCI infrastructure.

## Overview

The SSH key management system automatically:
- ✅ Generates ED25519 SSH key pairs
- ✅ Stores keys securely in Doppler
- ✅ Creates local SSH key files with correct permissions
- ✅ Sets environment variables for Terragrunt/Terraform
- ✅ Regenerates keys when needed (expiry/security)
- ✅ Verifies key integrity and functionality


### How It Works  ### Retrieving SSH Keys from Doppler

1. **Doppler Integration**: The `root.hcl` file reads SSH keys from Doppler
2. **Bastion Configuration**: The bastion terragrunt file uses the keys from root configuration
3. **Automatic Access**: No manual SSH key management required


## Quick Start

### 1. Prerequisites

Install Doppler CLI:

# Linux
curl -Ls https://cli.doppler.com/install.sh | sh


### 2. Set Up Authentication

```bash
# Set your Doppler service token
export DOPPLER_SERVICE_TOKEN="dp.st.dev.your-actual-token-here"


### 3. Run Setup
# Navigate to script directory
cd koci

# Make scripts executable
chmod +x setup-ssh-keys-doppler.sh

# Run setup
./setup-ssh-keys-doppler.sh



## Scripts

### `setup-ssh-keys-doppler.sh`

**Purpose**: Main setup script that handles SSH key generation and management.

**Features**:
- Checks Doppler CLI and authentication
- Generates new SSH keys if they don't exist
- Stores keys in Doppler (`oci-infra/dev` project)
- Creates local SSH key files
- Sets environment variables
- Verifies key functionality

**Usage**: 
RUN :
 ./setup-ssh-keys-doppler.sh


**Configuration** (at the top of the script):
```bash
DOPPLER_PROJECT="oci-infra"
DOPPLER_CONFIG="dev"
SSH_KEY_NAME="BASTION_SSH_PRIVATE_KEY"
SSH_PUBLIC_KEY_NAME="BASTION_SSH_PUBLIC_KEY"
SSH_KEY_EXPIRY_DAYS=90
```


### After (Automated Management)
- ✅ Automatic SSH key generation
- ✅ Secure storage in Doppler
- ✅ Automatic local file creation
- ✅ Automatic key rotation
- ✅ Secure key handling

