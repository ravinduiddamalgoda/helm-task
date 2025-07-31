#!/bin/bash

# Script to create kubeconfig using OCI CLI with cluster ID and region from Doppler
# Usage: ./create-kubeconfig.sh

# Configuration
DOPPLER_PROJECT="oci-infra"
DOPPLER_CONFIG="dev"
KUBE_CONFIG_PATH="$HOME/.kube/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Doppler CLI is installed
if ! command -v doppler &> /dev/null; then
    print_error "Doppler CLI is not installed. Please install it first."
    print_status "Installation guide: https://docs.doppler.com/docs/install-cli"
    exit 1
fi

# Check if OCI CLI is installed
if ! command -v oci &> /dev/null; then
    print_error "OCI CLI is not installed. Please install it first."
    print_status "Installation guide: https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    exit 1
fi

# Function to install kubectl
install_kubectl() {
    print_status "Installing kubectl..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v curl &> /dev/null; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            print_status "kubectl installed successfully"
        else
            print_error "curl is required to install kubectl. Please install curl first."
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install kubectl
            print_status "kubectl installed successfully via Homebrew"
        elif command -v curl &> /dev/null; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
            chmod +x kubectl
            sudo mv kubectl /usr/local/bin/
            print_status "kubectl installed successfully"
        else
            print_error "Neither brew nor curl found. Please install Homebrew or curl first."
            return 1
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        print_status "Please install kubectl manually: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        return 1
    fi
}

# Function to install Helm
install_helm() {
    print_status "Installing Helm..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v curl &> /dev/null; then
            curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
            sudo mv linux-amd64/helm /usr/local/bin/
            rm -rf linux-amd64
            print_status "Helm installed successfully"
        else
            print_error "curl is required to install Helm. Please install curl first."
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install helm
            print_status "Helm installed successfully via Homebrew"
        elif command -v curl &> /dev/null; then
            curl https://get.helm.sh/helm-v3.12.0-darwin-amd64.tar.gz | tar xz
            sudo mv darwin-amd64/helm /usr/local/bin/
            rm -rf darwin-amd64
            print_status "Helm installed successfully"
        else
            print_error "Neither brew nor curl found. Please install Homebrew or curl first."
            return 1
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        print_status "Please install Helm manually: https://helm.sh/docs/intro/install/"
        return 1
    fi
}

# Check if DOPPLER_SERVICE_TOKEN environment variable is set
if [ -z "$DOPPLER_SERVICE_TOKEN" ]; then
    print_error "DOPPLER_SERVICE_TOKEN environment variable is not set."
    print_status "Please export your Doppler service token:"
    print_status "export DOPPLER_SERVICE_TOKEN='your-service-token-here'"
    exit 1
fi

print_status "Using Doppler project: $DOPPLER_PROJECT"
print_status "Using Doppler config: $DOPPLER_CONFIG"

# Check and install kubectl if needed
if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. Attempting to install..."
    if install_kubectl; then
        print_status "kubectl installation completed successfully"
    else
        print_error "Failed to install kubectl. Please install it manually."
        print_status "Installation guide: https://kubernetes.io/docs/tasks/tools/install-kubectl/"
        exit 1
    fi
else
    print_status "kubectl is already installed: $(kubectl version --client --short 2>/dev/null || echo 'version unknown')"
fi

# Check and install Helm if needed
if ! command -v helm &> /dev/null; then
    print_warning "Helm is not installed. Attempting to install..."
    if install_helm; then
        print_status "Helm installation completed successfully"
    else
        print_error "Failed to install Helm. Please install it manually."
        print_status "Installation guide: https://helm.sh/docs/intro/install/"
        exit 1
    fi
else
    print_status "Helm is already installed: $(helm version --short 2>/dev/null || echo 'version unknown')"
fi

# Create .kube directory if it doesn't exist
if [ ! -d "$HOME/.kube" ]; then
    print_status "Creating .kube directory..."
    mkdir -p "$HOME/.kube"
fi

# Get cluster ID from Doppler
print_status "Retrieving CLUSTER_ID from Doppler..."
CLUSTER_ID=$(doppler secrets get CLUSTER_ID --project="$DOPPLER_PROJECT" --config="$DOPPLER_CONFIG" --plain 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$CLUSTER_ID" ]; then
    print_error "Failed to retrieve CLUSTER_ID from Doppler."
    print_status "Please check:"
    print_status "1. Your DOPPLER_SERVICE_TOKEN is valid"
    print_status "2. The secret 'CLUSTER_ID' exists in project '$DOPPLER_PROJECT' config '$DOPPLER_CONFIG'"
    print_status "3. You have proper permissions to access this secret"
    exit 1
fi

print_status "Cluster ID: $CLUSTER_ID"

# Get region from Doppler
print_status "Retrieving REGION from Doppler..."
REGION=$(doppler secrets get REGION --project="$DOPPLER_PROJECT" --config="$DOPPLER_CONFIG" --plain 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$REGION" ]; then
    print_error "Failed to retrieve REGION from Doppler."
    print_status "Please check:"
    print_status "1. Your DOPPLER_SERVICE_TOKEN is valid"
    print_status "2. The secret 'REGION' exists in project '$DOPPLER_PROJECT' config '$DOPPLER_CONFIG'"
    print_status "3. You have proper permissions to access this secret"
    exit 1
fi

print_status "Region: $REGION"

# Create kubeconfig using OCI CLI
print_status "Creating kubeconfig using OCI CLI..."
oci ce cluster create-kubeconfig \
    --cluster-id "$CLUSTER_ID" \
    --file "$KUBE_CONFIG_PATH" \
    --region "$REGION" \
    --auth api_key \
    --token-version 2.0.0 \
    --kube-endpoint PRIVATE_ENDPOINT

if [ $? -ne 0 ]; then
    print_error "Failed to create kubeconfig using OCI CLI."
    print_status "Please check:"
    print_status "1. Your OCI CLI is properly configured"
    print_status "2. You have access to the cluster"
    print_status "3. The cluster ID and region are correct"
    exit 1
fi

# Set proper permissions on the kubeconfig file
chmod 600 "$KUBE_CONFIG_PATH"

# Update the kubeconfig file to add --auth and api_key arguments
print_status "Updating kubeconfig file to add authentication arguments..."

# Create a backup of the original kubeconfig
cp "$KUBE_CONFIG_PATH" "${KUBE_CONFIG_PATH}.backup.$(date +%Y%m%d_%H%M%S)"

# Create a temporary file
TEMP_CONFIG=$(mktemp)

# Use sed to add the authentication arguments after the --region line
# Escape the region for sed pattern matching
REGION_ESCAPED=$(echo "$REGION" | sed 's/[[\.*^$()+?{|]/\\&/g')
if sed "/- $REGION_ESCAPED/a\\
      - --auth\\
      - api_key" "$KUBE_CONFIG_PATH" > "$TEMP_CONFIG"; then
    # Replace the original file with the updated content
    mv "$TEMP_CONFIG" "$KUBE_CONFIG_PATH"
    print_status "Successfully added authentication arguments to kubeconfig"
else
    print_error "Failed to update kubeconfig file"
    rm -f "$TEMP_CONFIG"
    exit 1
fi

# Verify the file was updated successfully
if grep -q "api_key" "$KUBE_CONFIG_PATH"; then
    print_status "Kubeconfig file updated successfully with authentication arguments"
    print_status "Added lines:"
    grep -A 1 -B 1 "api_key" "$KUBE_CONFIG_PATH"
else
    print_warning "Could not verify that authentication arguments were added to kubeconfig"
    print_status "Checking if --region line exists in kubeconfig..."
    if grep -q "- --region" "$KUBE_CONFIG_PATH"; then
        print_error "Found --region line but failed to add authentication arguments"
        print_status "Manual intervention may be required"
    else
        print_error "Could not find --region line in kubeconfig"
    fi
fi

# Verify the file was created successfully
if [ -f "$KUBE_CONFIG_PATH" ]; then
    print_status "Kubeconfig successfully created at $KUBE_CONFIG_PATH"
    print_status "File permissions set to 600 (read/write for owner only)"

    # Test the kubeconfig with kubectl
    print_status "Testing kubeconfig with kubectl..."
    if kubectl --kubeconfig="$KUBE_CONFIG_PATH" cluster-info &>/dev/null; then
        print_status "✅ Kubeconfig is valid and working with kubectl!"

        # Test Helm with the cluster
        print_status "Testing Helm with the cluster..."
        if helm --kubeconfig="$KUBE_CONFIG_PATH" list &>/dev/null; then
            print_status "✅ Helm is working with the cluster!"
        else
            print_warning "⚠️  Helm test failed, but kubectl is working. This might be normal for a new cluster."
        fi
    else
        print_warning "⚠️  Kubeconfig was created but kubectl test failed. Please verify the configuration."
    fi
else
    print_error "Failed to create kubeconfig at $KUBE_CONFIG_PATH"
    exit 1
fi

print_status "🎉 Setup complete! You can now use kubectl and Helm with the created configuration."
print_status "📋 Summary:"
print_status "   • Cluster ID: $CLUSTER_ID"
print_status "   • Region: $REGION"
print_status "   • Kubeconfig location: $KUBE_CONFIG_PATH"