#!/bin/bash
#============================ Asterisk POC Deployment Script ============================
# Quick deployment script for Asterisk POC using Docker images
# Usage: ./deploy.sh

set -e

echo "========================================="
echo "Asterisk POC Deployment (Docker-based)"
echo "========================================="
echo ""

# Check if running from project root
if [ ! -d "terraform" ]; then
    echo "Error: Please run this script from the project root directory"
    exit 1
fi

# Check prerequisites
echo "[1/4] Checking prerequisites..."

# Check and install Incus
if ! command -v incus &> /dev/null; then
    echo "⚠️  Incus is not installed"
    read -p "Install Incus now? (yes/no): " INSTALL_INCUS
    if [ "$INSTALL_INCUS" = "yes" ]; then
        echo "Installing Incus..."
        sudo apt update
        sudo apt install -y incus
        echo "✓ Incus installed"
        echo ""
        echo "⚠️  Please run 'sudo incus admin init' to initialize Incus, then run this script again"
        exit 0
    else
        echo "Error: Incus is required. Install with: sudo apt install incus"
        exit 1
    fi
fi

# Check and install OpenTofu
if ! command -v tofu &> /dev/null; then
    echo "⚠️  OpenTofu is not installed"
    read -p "Install OpenTofu now? (yes/no): " INSTALL_TOFU
    if [ "$INSTALL_TOFU" = "yes" ]; then
        echo "Installing OpenTofu..."

        # Install OpenTofu using official installation script
        curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
        chmod +x install-opentofu.sh
        sudo ./install-opentofu.sh --install-method deb
        rm install-opentofu.sh

        echo "✓ OpenTofu installed"
    else
        echo "Error: OpenTofu is required. Install from: https://opentofu.org/"
        exit 1
    fi
fi

echo "✓ Prerequisites OK"
echo ""

# Check Docker remote
echo "[2/4] Checking Docker remote..."

cd terraform

# Check if Docker remote is available
if ! incus remote list | grep -q "oci-docker"; then
    echo "Warning: oci-docker remote not found"
    echo "Adding Docker remote..."
    incus remote add oci-docker https://docker.io --protocol=oci --public
fi

echo "✓ Docker remote configured"
echo ""

# Pre-pull Docker images to avoid timeout issues
echo "[3/4] Pre-pulling Docker images (this may take a few minutes)..."
echo ""

echo "→ Pulling Asterisk image (andrius/asterisk:latest)..."
echo "  Using optimized production-ready Asterisk image"
echo "  This may take 2-5 minutes depending on your connection..."
incus image copy oci-docker:andrius/asterisk:latest local: --alias asterisk-latest 2>/dev/null || {
    echo "  ℹ️  Image already exists or will be pulled during deployment"
}

echo ""
echo "→ Pulling Nginx image (nginx:alpine)..."
incus image copy oci-docker:nginx:alpine local: --alias nginx-alpine 2>/dev/null || {
    echo "  ℹ️  Image already exists or will be pulled during deployment"
}

echo ""
echo "✓ Images ready"
echo ""

# Check for terraform.tfvars
echo "[4/5] Checking configuration..."

if [ ! -f "terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
fi

# Ask about test VMs
echo ""
echo "========================================="
echo "Test Client VMs Configuration"
echo "========================================="
echo ""
echo "Do you want to deploy test client VMs?"
echo ""
echo "This will create 2 Debian 12 VMs with:"
echo "  ✅ XFCE4 Desktop Environment"
echo "  ✅ Zoiper5 pre-installed and configured"
echo "  ✅ Extension 1000 (VM1) and 1001 (VM2)"
echo "  ✅ Ready to test immediately"
echo ""
echo "Resources per VM:"
echo "  - 2 CPU cores"
echo "  - 2GB RAM"
echo "  - ~5GB disk space"
echo ""
echo "Note: VMs take 5-10 minutes to fully provision"
echo ""
read -p "Deploy test VMs? (yes/no) [default: yes]: " DEPLOY_VMS
DEPLOY_VMS=${DEPLOY_VMS:-yes}

if [ "$DEPLOY_VMS" = "yes" ]; then
    echo "enable_test_vms = true" >> terraform.tfvars
    echo "✓ Test VMs will be deployed"
else
    echo "enable_test_vms = false" >> terraform.tfvars
    echo "✓ Test VMs will NOT be deployed"
fi

echo ""
echo "✓ Configuration ready"
echo ""

# Initialize Terraform
echo "[5/5] Initializing and deploying..."
echo ""

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing OpenTofu..."
    tofu init
    echo ""
fi

# Deploy
echo "This will create:"
echo "  - Asterisk container (andrius/asterisk:latest - optimized production image)"
echo "  - Nginx provisioning container (nginx:alpine)"
echo "  - Network (10.100.100.0/24)"
echo "  - Storage pool"
if [ "$DEPLOY_VMS" = "yes" ]; then
    echo "  - Test Client VM 1 (Debian 12 + XFCE4 + Zoiper - Extension 1000)"
    echo "  - Test Client VM 2 (Debian 12 + XFCE4 + Zoiper - Extension 1001)"
fi
echo ""

read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
tofu apply

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""

# Show outputs
tofu output

echo ""
echo "Next steps:"
echo "  1. Test with 2 softphones - see ../TEST_CREDENTIALS.md"
echo "  2. Set up SIP trunk for external calls - see ../docs/SIP_TRUNK_SETUP.md"
echo "  3. Add more users - see ../docs/SOFTPHONE_SETUP.md"
echo "  4. Connect to Asterisk: incus exec asterisk-server -- asterisk -rvvv"
echo ""
echo "Documentation:"
echo "  - Test Credentials: ../TEST_CREDENTIALS.md"
echo "  - Setup Guide: ../docs/SETUP.md"
echo "  - Softphone Setup: ../docs/SOFTPHONE_SETUP.md"
echo "  - SIP Trunk Setup: ../docs/SIP_TRUNK_SETUP.md"
echo ""
echo "========================================="

