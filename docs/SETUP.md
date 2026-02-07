# Asterisk POC Setup Guide

This guide will walk you through setting up an Asterisk PBX server using Docker images, Incus containers, and OpenTofu (Terraform).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Configuration](#configuration)
5. [Phone Setup](#phone-setup)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Incus** (or LXD) - Container runtime
- **OpenTofu** (or Terraform) - Infrastructure as Code tool
- **Linux host** - Ubuntu 22.04+ recommended

### Install Incus

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y incus

# Initialize Incus
sudo incus admin init
```

Follow the prompts:
- Storage backend: `dir` or `zfs` (recommended)
- Network bridge: `yes`
- IPv4 address: `auto`
- IPv6 address: `none` (or as needed)

### Add Docker Remote (for OCI images)

```bash
# Add Docker Hub as OCI remote (if not already present)
incus remote add oci-docker https://docker.io --protocol=oci --public

# Verify
incus remote list
```

### Install OpenTofu

```bash
# Download and install OpenTofu
curl -L https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip -o tofu.zip
unzip tofu.zip
sudo mv tofu /usr/local/bin/
sudo chmod +x /usr/local/bin/tofu

# Verify installation
tofu version
```

## Quick Start

### Using Automated Script (Recommended)

```bash
# Navigate to the project directory
cd /path/to/Asterisk-POC

# Run deployment script
./deploy.sh
```

### Manual Deployment

```bash
# 1. Clone or navigate to the project directory
cd /path/to/Asterisk-POC

# 2. Initialize OpenTofu
cd terraform
tofu init

# 3. Review the plan
tofu plan

# 4. Apply the configuration
tofu apply

# 5. Get connection information
tofu output
```

## Detailed Setup

### Step 1: Configure Variables

Copy the example variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize your setup:

```hcl
container_name   = "asterisk-server"
asterisk_ip      = "10.100.100.10"
network_subnet   = "10.100.100.1/24"
domain           = "yourcompany.local"
admin_email      = "admin@yourcompany.com"
```

### Step 2: Customize Asterisk Configuration

Before deploying, customize the Asterisk configuration files:

#### Update SIP Trunk Settings

Edit `../asterisk/pjsip.conf`:

```ini
[trunk-provider]
type=registration
server_uri=sip:sip.yourprovider.com
client_uri=sip:yourcompany@sip.yourprovider.com

[trunk-provider-auth]
username=yourcompany
password=YOUR_TRUNK_PASSWORD
```

#### Update Extension Passwords

**IMPORTANT**: Change default passwords in `pjsip.conf`:

```bash
# Generate secure passwords
openssl rand -base64 16

# Update each extension's password
[1000](auth-userpass)
username=1000
password=GENERATED_SECURE_PASSWORD
```

#### Update Company Information

Edit `../asterisk/extensions.conf`:

```ini
[globals]
COMPANY_NAME=Your Company Name
COMPANY_PHONE=+15551234567
```

### Step 3: Deploy with OpenTofu

```bash
cd terraform

# Initialize (first time only)
tofu init

# Validate configuration
tofu validate

# Preview changes
tofu plan

# Apply configuration
tofu apply
```

Type `yes` when prompted.

### Step 4: Verify Deployment

```bash
# Get container information
tofu output

# Connect to the container
incus exec asterisk-server -- /bin/bash

# Inside the container, check Asterisk status
asterisk -rvvv
```

In the Asterisk console:
```
core show version
pjsip show endpoints
pjsip show registrations
```

Press `Ctrl+C` to exit the console.

## Configuration

### Adding Extensions

Use the provided script to add new extensions:

```bash
# On the host
incus exec asterisk-server -- /bin/bash

# Inside the container
cd /root
./add-extension.sh 1050 SecurePass123 "Jane Smith" jane@company.local
```

Or manually edit `/etc/asterisk/pjsip.conf` and `/etc/asterisk/voicemail.conf`.

### Configuring SIP Trunk

1. Sign up with a SIP trunk provider (e.g., Twilio, Vonage, Bandwidth)
2. Get your credentials and server information
3. Update `/etc/asterisk/pjsip.conf` with trunk details
4. Reload Asterisk: `asterisk -rx "pjsip reload"`

### DID (Phone Number) Mapping

Map incoming phone numbers to extensions in `/etc/asterisk/extensions.conf`:

```ini
[from-trunk]
; Map +15551234567 to extension 1000
exten => +15551234567,1,Dial(PJSIP/1000,30,tr)
 same => n,VoiceMail(1000@default,u)
 same => n,Hangup()
```

## Phone Setup

### Auto-Provisioning

1. **Configure DHCP** to point phones to provisioning server
2. **Generate phone configs** using the script:

```bash
incus exec asterisk-server -- /bin/bash
cd /root
./generate-phone-config.sh yealink 0015651234ab 1000 SecurePass123 "John Doe"
```

3. **Reboot the phone** - it will auto-configure

### Manual Configuration

For manual setup, configure these settings on your phone:

- **SIP Server**: `10.100.100.10` (or your Asterisk IP)
- **SIP Port**: `5060`
- **Username**: Extension number (e.g., `1000`)
- **Auth ID**: Same as username
- **Password**: Extension password
- **Display Name**: User's name

### Supported Phone Brands

- Yealink (T4x, T5x series)
- Cisco (7940, 7960, 7941, 7961, 8841, 8861)
- Polycom (VVX series)
- Grandstream (GXP series)

See `asterisk/provisioning/README.md` for detailed provisioning instructions.

## Testing

### Test Internal Calls

1. Register two phones (e.g., extensions 1000 and 1001)
2. From 1000, dial `1001`
3. Answer on 1001
4. Verify two-way audio

### Test Voicemail

1. Dial `*97` from your extension
2. Follow prompts to set up voicemail
3. Have someone call you and leave a message
4. Dial `*97` again to retrieve messages

### Test Features

- **Echo Test**: Dial `*43`
- **Speaking Clock**: Dial `*60`
- **Conference**: Dial `8000`
- **Call Parking**: During a call, dial `700`

### Test External Calls

1. Configure SIP trunk (see Configuration section)
2. Dial an external number (e.g., `15551234567`)
3. Verify call connects and audio works

## Troubleshooting

### Phone Won't Register

```bash
# Check endpoint status
asterisk -rx "pjsip show endpoint 1000"

# Check for authentication failures
tail -f /var/log/asterisk/messages | grep NOTICE
```

Common issues:
- Wrong password in phone or pjsip.conf
- Firewall blocking port 5060
- Network connectivity issues

### No Audio on Calls

```bash
# Check RTP ports are open
ufw status | grep 10000:20000
```

Common issues:
- Firewall blocking RTP ports (10000-20000)
- NAT issues - set `direct_media=no` in pjsip.conf
- Codec mismatch - verify both endpoints support common codec

### Provisioning Not Working

```bash
# Check nginx is running
systemctl status nginx

# Check provisioning files exist
ls -la /srv/provisioning/

# Test HTTP access
curl http://10.100.100.10:8080/
```

### View Asterisk Logs

```bash
# Real-time messages
tail -f /var/log/asterisk/messages

# Full log
tail -f /var/log/asterisk/full

# Increase verbosity
asterisk -rx "core set verbose 5"
```

### Useful Asterisk Commands

```bash
# Show all endpoints
asterisk -rx "pjsip show endpoints"

# Show active calls
asterisk -rx "core show channels"

# Show registrations
asterisk -rx "pjsip show registrations"

# Reload configuration
asterisk -rx "pjsip reload"
asterisk -rx "dialplan reload"

# Show help
asterisk -rx "core show help"
```

## Next Steps

- See [NUMBER_PORTING.md](NUMBER_PORTING.md) for porting existing phone numbers
- Configure backup and high availability
- Set up call recording and CDR analysis
- Integrate with CRM systems
- Add queue management for call centers

