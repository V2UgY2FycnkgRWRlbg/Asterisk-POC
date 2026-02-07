terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.1"
    }
  }
  required_version = ">= 1.0"
}

provider "incus" {
  # Uses local Incus socket by default
  # For remote: set address, port, and credentials

  # Use specified project (configurable via variable)
  project = var.incus_project
}

# Create a storage volume for Asterisk data persistence
resource "incus_storage_pool" "asterisk_pool" {
  name   = "asterisk-storage"
  driver = "dir"
  # Don't specify source - let Incus create it automatically
}

# Create a network profile for Asterisk
resource "incus_network" "asterisk_network" {
  name = "asterisk-net"
  
  config = {
    "ipv4.address" = var.network_subnet
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    
    # DNS settings
    "dns.domain" = "asterisk.local"
    "dns.mode"   = "managed"
  }
}

# Asterisk server container using official Docker image
resource "incus_instance" "asterisk_server" {
  name  = var.container_name
  # Use official Asterisk Docker image from Docker Hub
  image = var.docker_image
  type  = "container"

  # Network configuration
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = incus_network.asterisk_network.name
      # Static IP for Asterisk server
      "ipv4.address" = var.asterisk_ip
    }
  }

  # Mount Asterisk configuration directory
  device {
    name = "asterisk-config"
    type = "disk"
    properties = {
      source = abspath("${path.module}/../asterisk")
      path   = "/etc/asterisk"
    }
  }

  # Auto-start on boot
  config = {
    "boot.autostart" = "true"

    # Resource limits
    "limits.cpu"    = var.cpu_limit
    "limits.memory" = var.memory_limit

    # Security settings
    "security.nesting"    = "false"
    "security.privileged" = "false"

    # Environment variables for Asterisk Docker container
    "environment.ASTERISK_UID" = "1000"
    "environment.ASTERISK_GID" = "1000"
  }
}

# Nginx container for phone provisioning (using Docker image)
resource "incus_instance" "provisioning_server" {
  name  = "${var.container_name}-provisioning"
  image = var.nginx_image
  type  = "container"

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = incus_network.asterisk_network.name
      "ipv4.address" = var.provisioning_ip
    }
  }

  # Mount provisioning files
  device {
    name = "www"
    type = "disk"
    properties = {
      source = abspath("${path.module}/../asterisk/provisioning")
      path   = "/usr/share/nginx/html"
    }
  }

  config = {
    "boot.autostart" = "true"

    # Resource limits
    "limits.cpu"    = "1"
    "limits.memory" = "512MB"
  }
}

# ============================================================================
# TEST CLIENT VMs - Debian 12 with XFCE4 Desktop and Zoiper
# ============================================================================

# Test VM 1 - Extension 1000
resource "incus_instance" "test_client_1" {
  count = var.enable_test_vms ? 1 : 0

  name  = "asterisk-test-client-1"
  image = var.test_vm_image
  type  = "virtual-machine"

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = incus_network.asterisk_network.name
      "ipv4.address" = var.test_vm1_ip
    }
  }

  config = {
    "boot.autostart" = "false"

    # Resource limits
    "limits.cpu"    = var.test_vm_cpu
    "limits.memory" = var.test_vm_memory

    # Enable GUI
    "security.secureboot" = "false"

    # Cloud-init configuration for XFCE4 and Zoiper
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      package_update: true
      package_upgrade: true

      packages:
        - xfce4
        - xfce4-goodies
        - lightdm
        - firefox-esr
        - pulseaudio
        - pavucontrol
        - alsa-utils
        - wget
        - curl
        - snapd

      runcmd:
        # Enable and start display manager
        - systemctl enable lightdm
        - systemctl set-default graphical.target

        # Create test user
        - useradd -m -s /bin/bash -G audio,video testuser
        - echo 'testuser:testpass' | chpasswd
        - usermod -aG sudo testuser

        # Install Zoiper via snap
        - snap install zoiper5

        # Create Zoiper config for extension 1000
        - mkdir -p /home/testuser/.Zoiper5
        - |
          cat > /home/testuser/.Zoiper5/config.xml <<EOF
          <?xml version="1.0"?>
          <options>
            <account>
              <username>1000</username>
              <password>TestPass1000</password>
              <domain>10.100.100.10</domain>
              <name>Extension 1000</name>
            </account>
          </options>
          EOF
        - chown -R testuser:testuser /home/testuser/.Zoiper5

        # Create desktop shortcut
        - mkdir -p /home/testuser/Desktop
        - |
          cat > /home/testuser/Desktop/zoiper.desktop <<EOF
          [Desktop Entry]
          Version=1.0
          Type=Application
          Name=Zoiper5
          Exec=zoiper5
          Icon=zoiper5
          Terminal=false
          EOF
        - chmod +x /home/testuser/Desktop/zoiper.desktop
        - chown testuser:testuser /home/testuser/Desktop/zoiper.desktop

        # Create README on desktop
        - |
          cat > /home/testuser/Desktop/README.txt <<EOF
          ========================================
          Asterisk Test Client 1
          ========================================

          Extension: 1000
          Password: TestPass1000
          Asterisk Server: 10.100.100.10

          Login:
          - Username: testuser
          - Password: testpass

          Zoiper is pre-configured!
          Just launch it from the desktop.

          Test calls:
          - Dial 1001 to call Test Client 2
          - Dial *43 for echo test
          - Dial *60 for speaking clock
          - Dial 8000 for conference room
          ========================================
          EOF
        - chown testuser:testuser /home/testuser/Desktop/README.txt

        # Reboot to apply all changes
        - reboot
    EOT
  }
}

# Test VM 2 - Extension 1001
resource "incus_instance" "test_client_2" {
  count = var.enable_test_vms ? 1 : 0

  name  = "asterisk-test-client-2"
  image = var.test_vm_image
  type  = "virtual-machine"

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = incus_network.asterisk_network.name
      "ipv4.address" = var.test_vm2_ip
    }
  }

  config = {
    "boot.autostart" = "false"

    # Resource limits
    "limits.cpu"    = var.test_vm_cpu
    "limits.memory" = var.test_vm_memory

    # Enable GUI
    "security.secureboot" = "false"

    # Cloud-init configuration for XFCE4 and Zoiper
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      package_update: true
      package_upgrade: true

      packages:
        - xfce4
        - xfce4-goodies
        - lightdm
        - firefox-esr
        - pulseaudio
        - pavucontrol
        - alsa-utils
        - wget
        - curl
        - snapd

      runcmd:
        # Enable and start display manager
        - systemctl enable lightdm
        - systemctl set-default graphical.target

        # Create test user
        - useradd -m -s /bin/bash -G audio,video testuser
        - echo 'testuser:testpass' | chpasswd
        - usermod -aG sudo testuser

        # Install Zoiper via snap
        - snap install zoiper5

        # Create Zoiper config for extension 1001
        - mkdir -p /home/testuser/.Zoiper5
        - |
          cat > /home/testuser/.Zoiper5/config.xml <<EOF
          <?xml version="1.0"?>
          <options>
            <account>
              <username>1001</username>
              <password>TestPass1001</password>
              <domain>10.100.100.10</domain>
              <name>Extension 1001</name>
            </account>
          </options>
          EOF
        - chown -R testuser:testuser /home/testuser/.Zoiper5

        # Create desktop shortcut
        - mkdir -p /home/testuser/Desktop
        - |
          cat > /home/testuser/Desktop/zoiper.desktop <<EOF
          [Desktop Entry]
          Version=1.0
          Type=Application
          Name=Zoiper5
          Exec=zoiper5
          Terminal=false
          EOF
        - chmod +x /home/testuser/Desktop/zoiper.desktop
        - chown testuser:testuser /home/testuser/Desktop/zoiper.desktop

        # Create README on desktop
        - |
          cat > /home/testuser/Desktop/README.txt <<EOF
          ========================================
          Asterisk Test Client 2
          ========================================

          Extension: 1001
          Password: TestPass1001
          Asterisk Server: 10.100.100.10

          Login:
          - Username: testuser
          - Password: testpass

          Zoiper is pre-configured!
          Just launch it from the desktop.

          Test calls:
          - Dial 1000 to call Test Client 1
          - Dial *43 for echo test
          - Dial *60 for speaking clock
          - Dial 8000 for conference room
          ========================================
          EOF
        - chown testuser:testuser /home/testuser/Desktop/README.txt

        # Reboot to apply all changes
        - reboot
    EOT
  }
}

