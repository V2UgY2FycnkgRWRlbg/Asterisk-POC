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

# Check if Docker remote is configured
if ! incus remote list | grep -q "oci-docker"; then
    echo "⚠️  Docker remote (oci-docker) not configured"
    echo "Adding Docker remote..."
    incus remote add oci-docker https://docker.io --protocol=oci --public
    echo "✓ Docker remote added"
fi

echo "✓ Prerequisites OK"
echo ""

# Check for terraform.tfvars
echo "[2/4] Checking configuration..."

cd terraform

# Always recreate terraform.tfvars to avoid duplicates
if [ -f "terraform.tfvars" ]; then
    echo "Removing old terraform.tfvars..."
    rm terraform.tfvars
fi

echo "Creating terraform.tfvars from example..."
cp terraform.tfvars.example terraform.tfvars

# Ask about Incus project
echo ""
echo "========================================="
echo "Incus Project Configuration"
echo "========================================="
echo ""
echo "Available Incus projects:"
incus project list -c n -f compact
echo ""
echo "Which Incus project do you want to use?"
echo ""
read -p "Project name [default: default]: " INCUS_PROJECT
INCUS_PROJECT=${INCUS_PROJECT:-default}

# Validate project exists (extract just the project name, ignoring (current) marker)
if ! incus project list -c n -f compact | awk '{print $1}' | grep -q "^${INCUS_PROJECT}$"; then
    echo ""
    echo "⚠️  Project '${INCUS_PROJECT}' does not exist."
    read -p "Create it now? (yes/no): " CREATE_PROJECT
    if [ "$CREATE_PROJECT" = "yes" ]; then
        incus project create "${INCUS_PROJECT}"
        echo "✓ Project '${INCUS_PROJECT}' created"
    else
        echo "Error: Project '${INCUS_PROJECT}' does not exist. Aborting."
        exit 1
    fi
fi

echo "✓ Using project: ${INCUS_PROJECT}"
echo ""

# Check if resources already exist in this project
echo "Checking for existing resources in project '${INCUS_PROJECT}'..."

# Check for instances
EXISTING_INSTANCES=$(incus list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -E "^asterisk-" | wc -l)
# Check for network
EXISTING_NETWORK=$(incus network list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -c "^asterisk-net$" || echo 0)
# Check for storage
EXISTING_STORAGE=$(incus storage list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -c "^asterisk-storage$" || echo 0)

TOTAL_EXISTING=$((EXISTING_INSTANCES + EXISTING_NETWORK + EXISTING_STORAGE))

if [ "$TOTAL_EXISTING" -gt 0 ]; then
    echo ""
    echo "⚠️  Found existing Asterisk resources in project '${INCUS_PROJECT}':"

    if [ "$EXISTING_INSTANCES" -gt 0 ]; then
        echo ""
        echo "Instances:"
        incus list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep "^asterisk-" | sed 's/^/  - /'
    fi

    if [ "$EXISTING_NETWORK" -gt 0 ]; then
        echo ""
        echo "Network:"
        echo "  - asterisk-net"
    fi

    if [ "$EXISTING_STORAGE" -gt 0 ]; then
        echo ""
        echo "Storage:"
        echo "  - asterisk-storage"
    fi

    echo ""
    echo "Options:"
    echo "  1. Delete ALL existing resources and redeploy (RECOMMENDED - clean slate)"
    echo "  2. Cancel deployment"
    echo ""
    read -p "Choose option (1/2) [default: 1]: " CLEANUP_OPTION
    CLEANUP_OPTION=${CLEANUP_OPTION:-1}

    case $CLEANUP_OPTION in
        1)
            echo ""
            echo "🗑️  Deleting existing resources..."

            # Delete instances first (they depend on network and storage)
            if [ "$EXISTING_INSTANCES" -gt 0 ]; then
                echo ""
                echo "Deleting instances..."
                incus list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep "^asterisk-" | while read instance; do
                    if [ -n "$instance" ]; then
                        echo "  → Deleting: $instance"
                        if incus delete "$instance" --force --project="${INCUS_PROJECT}"; then
                            echo "    ✓ Deleted successfully"
                        else
                            echo "    ⚠️  Failed to delete (may not exist or be in use)"
                        fi
                    fi
                done
                # Wait a bit for instances to be fully deleted
                echo "  Waiting for instances to be fully removed..."
                sleep 3
            fi

            # Delete network
            if [ "$EXISTING_NETWORK" -gt 0 ]; then
                echo ""
                echo "Deleting network..."
                echo "  → Deleting: asterisk-net"
                if incus network delete asterisk-net --project="${INCUS_PROJECT}"; then
                    echo "    ✓ Network deleted successfully"
                else
                    echo "    ⚠️  Failed to delete network"
                    echo "    You may need to delete it manually: incus network delete asterisk-net --project=${INCUS_PROJECT}"
                fi
                sleep 1
            fi

            # Delete storage pool
            if [ "$EXISTING_STORAGE" -gt 0 ]; then
                echo ""
                echo "Deleting storage pool..."
                echo "  → Deleting: asterisk-storage"
                if incus storage delete asterisk-storage --project="${INCUS_PROJECT}"; then
                    echo "    ✓ Storage pool deleted successfully"
                else
                    echo "    ⚠️  Failed to delete storage pool"
                    echo "    You may need to delete it manually: incus storage delete asterisk-storage --project=${INCUS_PROJECT}"
                fi
                sleep 1
            fi

            # Verify cleanup
            echo ""
            echo "Verifying cleanup..."
            REMAINING_INSTANCES=$(incus list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -c "^asterisk-" || echo 0)
            REMAINING_NETWORK=$(incus network list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -c "^asterisk-net$" || echo 0)
            REMAINING_STORAGE=$(incus storage list --project="${INCUS_PROJECT}" -c n -f compact 2>/dev/null | grep -c "^asterisk-storage$" || echo 0)

            if [ "$REMAINING_INSTANCES" -gt 0 ] || [ "$REMAINING_NETWORK" -gt 0 ] || [ "$REMAINING_STORAGE" -gt 0 ]; then
                echo "⚠️  Warning: Some resources could not be deleted:"
                [ "$REMAINING_INSTANCES" -gt 0 ] && echo "  - $REMAINING_INSTANCES instance(s) still exist"
                [ "$REMAINING_NETWORK" -gt 0 ] && echo "  - Network 'asterisk-net' still exists"
                [ "$REMAINING_STORAGE" -gt 0 ] && echo "  - Storage pool 'asterisk-storage' still exists"
                echo ""
                read -p "Continue anyway? (yes/no): " CONTINUE_ANYWAY
                if [ "$CONTINUE_ANYWAY" != "yes" ]; then
                    echo "Deployment cancelled. Please clean up manually."
                    exit 1
                fi
            else
                echo "✓ All resources successfully removed"
            fi

            echo ""
            echo "✓ Cleanup complete"
            echo ""
            ;;
        2)
            echo ""
            echo "Deployment cancelled."
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid option. Deployment cancelled."
            exit 1
            ;;
    esac
else
    echo "✓ No existing resources found"
    echo ""
fi

# Add project to terraform.tfvars (at the beginning for clarity)
sed -i "s|^# incus_project = \"default\"|incus_project = \"${INCUS_PROJECT}\"|" terraform.tfvars

# Note about Docker images
echo "========================================="
echo "Docker Images"
echo "========================================="
echo ""
echo "ℹ️  Docker images will be pulled automatically by Incus during deployment"
echo "   - andrius/asterisk:latest (production-optimized, ~122MB)"
echo "   - nginx:alpine (lightweight web server, ~25MB)"
echo ""
echo "✓ Images will be fetched on-demand from Docker Hub"
echo ""

# Ask about test VMs
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

# Add the setting to terraform.tfvars (uncomment the line)
if [ "$DEPLOY_VMS" = "yes" ]; then
    sed -i "s|^# enable_test_vms = true|enable_test_vms = true|" terraform.tfvars
    echo "✓ Test VMs will be deployed"
else
    sed -i "s|^# enable_test_vms = true|enable_test_vms = false|" terraform.tfvars
    echo "✓ Test VMs will NOT be deployed"
fi

echo ""
echo "✓ Configuration ready"
echo ""

# Initialize Terraform
echo "[3/4] Initializing and deploying..."
echo ""

# Verify terraform.tfvars has the correct project
echo "Verifying configuration..."
if grep -q "^incus_project = \"${INCUS_PROJECT}\"" terraform.tfvars; then
    echo "✓ Incus project correctly set to: ${INCUS_PROJECT}"
else
    echo "⚠️  Warning: incus_project not found in terraform.tfvars"
    echo "   Adding it now..."
    echo "incus_project = \"${INCUS_PROJECT}\"" >> terraform.tfvars
fi
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
echo "📦 Incus Project: ${INCUS_PROJECT}"
echo ""

# Show outputs
tofu output

echo ""
echo "Next steps:"
echo "  1. Switch to project: incus project switch ${INCUS_PROJECT}"
echo "  2. List instances: incus ls"
echo "  3. Test with 2 softphones - see ../TEST_CREDENTIALS.md"
echo "  4. Set up SIP trunk for external calls - see ../docs/SIP_TRUNK_SETUP.md"
echo "  5. Add more users - see ../docs/SOFTPHONE_SETUP.md"
echo "  6. Connect to Asterisk: incus exec asterisk-server --project=${INCUS_PROJECT} -- asterisk -rvvv"
echo ""
echo "Documentation:"
echo "  - Test Credentials: ../TEST_CREDENTIALS.md"
echo "  - Setup Guide: ../docs/SETUP.md"
echo "  - Softphone Setup: ../docs/SOFTPHONE_SETUP.md"
echo "  - SIP Trunk Setup: ../docs/SIP_TRUNK_SETUP.md"
echo ""
echo "========================================="

