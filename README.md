# Enterprise Softphone Solution - Asterisk PBX

A complete enterprise phone system using softphones (computer-based phones) deployed with Docker, Incus, and OpenTofu.

## 🎯 What This Does

Replace your traditional desk phones with **softphones on employee computers**:

- ✅ **Keep your existing phone numbers** - Port them to a SIP trunk provider
- ✅ **Employees use computers as phones** - Windows, macOS, Linux supported
- ✅ **Full PBX features** - Voicemail, conference calls, call transfer, etc.
- ✅ **Easy to scale** - Add users with a simple script
- ✅ **Cost-effective** - No expensive desk phones needed
- ✅ **Infrastructure as Code** - Deploy and manage with OpenTofu

## 💡 Perfect For

- **Small to medium enterprises** (10-100 employees)
- **Remote/hybrid teams** - Employees work from anywhere
- **Cost-conscious businesses** - Eliminate desk phone costs
- **Modern workplaces** - Employees already use computers with headsets

## 🚀 Quick Start (5 Minutes)

### Step 1: Deploy Asterisk Server

```bash
# Install prerequisites
sudo apt install incus
# Install OpenTofu from https://opentofu.org/

# Initialize Incus
sudo incus admin init

# Deploy Asterisk
./deploy.sh
```

### Step 2: Set Up Test Clients

**On Computer 1:**
1. Download Zoiper: https://www.zoiper.com/
2. Configure:
   - Domain: `10.100.100.10`
   - Username: `1000`
   - Password: `TestPass1000`

**On Computer 2:**
1. Download Zoiper
2. Configure:
   - Domain: `10.100.100.10`
   - Username: `1001`
   - Password: `TestPass1001`

### Step 3: Test

- From Computer 1, dial `1001` → should ring Computer 2
- Dial `*43` for echo test
- Dial `8000` for conference room

**See [TEST_CREDENTIALS.md](TEST_CREDENTIALS.md) for complete test setup**

## 📁 Project Structure

```
Asterisk-POC/
├── deploy.sh                    # One-command deployment
├── TEST_CREDENTIALS.md          # Test user credentials
│
├── terraform/                   # Infrastructure as Code
│   ├── main.tf                  # Asterisk + Nginx containers
│   ├── variables.tf             # Configuration
│   └── outputs.tf               # Connection info
│
├── asterisk/                    # Asterisk configuration
│   ├── pjsip.conf              # SIP users/trunk config
│   ├── extensions.conf         # Call routing
│   ├── voicemail.conf          # Voicemail boxes
│   └── rtp.conf                # Voice media settings
│
├── scripts/
│   └── add-extension.sh        # Add new users
│
└── docs/
    ├── SETUP.md                # Detailed setup guide
    ├── SOFTPHONE_SETUP.md      # Employee softphone guide
    └── SIP_TRUNK_SETUP.md      # Connect your phone numbers
```

## ✨ Features

### Phone System Features

- ✅ **Internal calling** - Call between employees (extensions 1000-1049)
- ✅ **Voicemail** - With email notification
- ✅ **Conference calls** - Multi-party meetings (with optional PIN)
- ✅ **Call transfer** - Forward calls to colleagues
- ✅ **Call parking** - Put calls on hold and retrieve from any phone
- ✅ **Do Not Disturb** - Control availability
- ✅ **External calling** - Connect to PSTN via SIP trunk
- ✅ **Keep your numbers** - Port existing company phone numbers

### Softphone Support

- ✅ **Windows** - Zoiper, MicroSIP, Linphone
- ✅ **macOS** - Zoiper, Linphone
- ✅ **Linux** - Zoiper, Linphone
- ✅ **Mobile** - iOS and Android apps available

### Infrastructure

- ✅ **Docker-based** - Official Asterisk images
- ✅ **Infrastructure as Code** - OpenTofu/Terraform
- ✅ **Fast deployment** - Up and running in 5 minutes
- ✅ **Easy scaling** - Add users with one command
- ✅ **Secure** - TLS/SRTP encryption support

## 📖 Documentation

- **[TEST_CREDENTIALS.md](TEST_CREDENTIALS.md)** - Ready-to-use test credentials
- **[SETUP.md](docs/SETUP.md)** - Complete deployment guide
- **[SOFTPHONE_SETUP.md](docs/SOFTPHONE_SETUP.md)** - Employee softphone setup
- **[SIP_TRUNK_SETUP.md](docs/SIP_TRUNK_SETUP.md)** - Connect your phone numbers

## 🔧 Configuration

### Default Settings

- **Asterisk Server**: 10.100.100.10
- **SIP Port**: 5060
- **Extensions**: 1000-1049 (50 users pre-configured)
- **Test Users**: 1000 (TestPass1000), 1001 (TestPass1001)
- **Docker Image**: andrius/asterisk:latest (production-optimized)

### Connect Your Phone Numbers

To receive calls from external numbers (like your mobile phone):

1. **Sign up with SIP trunk provider** (Twilio recommended)
2. **Port your existing numbers** to the provider
3. **Configure trunk** in `asterisk/pjsip.conf`
4. **Set up routing** in `asterisk/extensions.conf`

**See [SIP_TRUNK_SETUP.md](docs/SIP_TRUNK_SETUP.md) for complete guide**

## 🎯 Perfect For

### Remote/Hybrid Teams
- Employees work from home or office
- No desk phones needed
- Use existing computers and headsets
- Mobile apps for on-the-go

### Cost-Conscious Businesses
- Eliminate desk phone costs ($100-300 per phone)
- Pay-as-you-go SIP trunk pricing
- No expensive PBX hardware
- Easy to scale up or down

### Modern Workplaces
- Employees already use computers all day
- Integrate with existing IT infrastructure
- Easy deployment and management
- Infrastructure as Code for reproducibility

## 🔒 Security

- ✅ TLS/SRTP support for encrypted calls
- ✅ Strong password requirements
- ✅ Network isolation via Incus containers
- ✅ Fail2ban for brute-force protection (optional)
- ⚠️ **Change test passwords before production use!**

## 🧪 Testing

### Internal Testing (No SIP Trunk Needed)

**Set up 2 softphones:**
1. Computer 1: Extension 1000 (TestPass1000)
2. Computer 2: Extension 1001 (TestPass1001)
3. From 1000, dial `1001` → should ring
4. Test features:
   - `*43` - Echo test
   - `*60` - Speaking clock
   - `*97` - Voicemail
   - `8000` - Conference room

### External Testing (Requires SIP Trunk)

**To receive calls from your mobile phone:**
1. Set up SIP trunk (see [SIP_TRUNK_SETUP.md](docs/SIP_TRUNK_SETUP.md))
2. Port your company number to SIP provider
3. Configure inbound routing
4. Call your company number from mobile → should ring extension

**See [TEST_CREDENTIALS.md](TEST_CREDENTIALS.md) for complete testing guide**

## 📊 Monitoring

```bash
# Connect to Asterisk console
incus exec asterisk-server -- asterisk -rvvv

# View active calls
asterisk -rx "core show channels"

# View endpoints
asterisk -rx "pjsip show endpoints"

# View logs
incus exec asterisk-server -- tail -f /var/log/asterisk/messages
```

## 🛠️ Troubleshooting

### Softphone Won't Register

```bash
# Check if Asterisk is running
incus list

# Check endpoint status
incus exec asterisk-server -- asterisk -rx "pjsip show endpoint 1000"

# Check logs
incus exec asterisk-server -- tail -f /var/log/asterisk/messages
```

**Common issues:**
- Wrong password
- Can't reach server (check `ping 10.100.100.10`)
- Firewall blocking port 5060

### No Audio During Calls

- Firewall must allow RTP ports (10000-20000)
- Check audio device in softphone settings
- Try different codec (ulaw, alaw)

**See [SOFTPHONE_SETUP.md](docs/SOFTPHONE_SETUP.md) for detailed troubleshooting**

## 🚀 Adding More Users

### Add Single User

```bash
cd scripts
./add-extension.sh 1002 SecurePass1002 "Employee Name" employee@company.com

# Reload Asterisk
incus exec asterisk-server -- asterisk -rx "pjsip reload"
```

### Add Multiple Users

Create a CSV file with user details, then use the add-extension script in a loop.

**See [SOFTPHONE_SETUP.md](docs/SOFTPHONE_SETUP.md) for bulk user creation guide**

### Scaling Beyond 50 Users

- Current setup supports 50 extensions (1000-1049)
- To add more: Edit `asterisk/pjsip.conf` and add more extension templates
- For 100+ users: Consider Asterisk Realtime with database backend

## 📝 License

This is a proof-of-concept template. Customize as needed for your organization.

## 🤝 Contributing

This is a POC template. Feel free to adapt and extend for your needs.

## 📞 Support

For Asterisk-specific questions:
- [Asterisk Documentation](https://docs.asterisk.org/)
- [Asterisk Community](https://community.asterisk.org/)

For Incus questions:
- [Incus Documentation](https://linuxcontainers.org/incus/)

For OpenTofu questions:
- [OpenTofu Documentation](https://opentofu.org/docs/)

## ⚠️ Important Notes

1. **Test passwords included** - Change before production!
2. **SIP trunk required** for external calls - See [SIP_TRUNK_SETUP.md](docs/SIP_TRUNK_SETUP.md)
3. **Network access** - Employees must be able to reach 10.100.100.10 (VPN for remote workers)
4. **Headsets recommended** - Better audio quality than computer speakers
5. **Backup voicemail** - Important messages stored in container

## 📞 Next Steps

1. ✅ **Deploy**: Run `./deploy.sh`
2. ✅ **Test**: Set up 2 softphones with test credentials
3. ✅ **Connect numbers**: Set up SIP trunk for external calling
4. ✅ **Add users**: Use add-extension script
5. ✅ **Train employees**: Share [SOFTPHONE_SETUP.md](docs/SOFTPHONE_SETUP.md)

---

**Ready to start?** See [TEST_CREDENTIALS.md](TEST_CREDENTIALS.md) for quick testing!

