# Softphone Setup Guide

This guide shows how to set up softphones on Windows, macOS, and Linux computers for your employees.

## What is a Softphone?

A softphone is software that turns your computer into a phone. Your employees can:
- Make and receive calls using their computer
- Use a headset or computer speakers/microphone
- Access all PBX features (voicemail, conference, transfer, etc.)

## Recommended Softphone: Zoiper

**Zoiper** is the best choice because:
- ✅ Works on Windows, macOS, Linux
- ✅ Free version available
- ✅ Easy to configure
- ✅ Reliable and well-supported

**Download**: https://www.zoiper.com/en/voip-softphone/download/current

## Installation

### Windows

1. Download **Zoiper5** from https://www.zoiper.com/
2. Run the installer
3. Choose "Free version" (sufficient for most users)
4. Complete installation

### macOS

1. Download **Zoiper5** for Mac
2. Open the .dmg file
3. Drag Zoiper to Applications folder
4. Open Zoiper (may need to allow in Security & Privacy settings)

### Linux

```bash
# Ubuntu/Debian
wget https://www.zoiper.com/en/voip-softphone/download/zoiper5/for/linux-deb
sudo dpkg -i zoiper5*.deb

# Or use Snap
sudo snap install zoiper5
```

## Configuration

### Step 1: Launch Zoiper

1. Open Zoiper
2. Click "Settings" or "Add Account"

### Step 2: Add SIP Account

**Account Settings:**
- **Account name**: Your Name (e.g., "John Doe - Ext 1000")
- **Domain**: `10.100.100.10` (your Asterisk server IP)
- **Username**: `1000` (your extension number)
- **Password**: `SecurePass123` (from pjsip.conf)

**Advanced Settings:**
- **Transport**: UDP
- **Port**: 5060
- **Authentication user**: Same as username (`1000`)

### Step 3: Audio Settings

1. Go to Settings → Audio
2. Select your headset or speakers/microphone
3. Test audio levels
4. Enable echo cancellation

### Step 4: Test

1. Dial `*43` - Echo test (you should hear yourself back)
2. Dial `*60` - Speaking clock
3. Dial another extension (e.g., `1001`) to test calling

## Quick Setup for Multiple Users

### For IT Admin: Prepare User Accounts

1. Edit `asterisk/pjsip.conf` - Set unique passwords for each extension
2. Create a spreadsheet with user credentials:

| Employee | Extension | Password | Email |
|----------|-----------|----------|-------|
| John Doe | 1000 | Pass1000! | john@company.com |
| Jane Smith | 1001 | Pass1001! | jane@company.com |

3. Send each employee their credentials

### For Employees: Self-Setup

Send employees this simple guide:

```
=== Your Phone Setup ===

1. Download Zoiper: https://www.zoiper.com/
2. Install and open Zoiper
3. Click "Add Account"
4. Enter these details:
   - Domain: 10.100.100.10
   - Username: [YOUR_EXTENSION]
   - Password: [YOUR_PASSWORD]
5. Click Save
6. Test by dialing *43 (echo test)

Need help? Contact IT support.
```

## Alternative Softphones

### MicroSIP (Windows only)

**Pros**: Lightweight, simple  
**Cons**: Windows only

**Download**: https://www.microsip.org/

**Configuration**:
- SIP Server: `10.100.100.10`
- SIP User: `1000`
- Password: `SecurePass123`

### Linphone (All platforms)

**Pros**: Open source, free  
**Cons**: Less polished UI

**Download**: https://www.linphone.org/

**Configuration**:
- Username: `1000`
- SIP Domain: `10.100.100.10`
- Password: `SecurePass123`

### Bria (Enterprise option)

**Pros**: Professional features, support  
**Cons**: Paid ($50-100/user)

**Download**: https://www.counterpath.com/bria-solo/

## Mobile Softphones

For employees who need mobile access:

### iOS
- **Zoiper** (Free/Paid)
- **Linphone** (Free)
- **Bria Mobile** (Paid)

### Android
- **Zoiper** (Free/Paid)
- **Linphone** (Free)
- **Grandstream Wave** (Free)

**Configuration**: Same as desktop (use Asterisk server IP)

## Features Guide

### Voicemail

- **Check voicemail**: Dial `*97`
- **Check someone else's**: Dial `*98` + extension
- **Configure**: Dial `*97` → follow prompts

### Conference Calls

- **Join conference**: Dial `8000` (public) or `8001` (PIN protected)
- **Invite others**: Give them the conference number

### Call Transfer

- **Blind transfer**: During call, press `#` + extension + `#`
- **Attended transfer**: Put call on hold, dial extension, announce, hang up

### Call Parking

- **Park call**: Transfer to `700`
- **Retrieve**: Dial the announced parking spot (701-720)

## Troubleshooting

### Can't Register

**Check**:
1. Is Asterisk server running? `incus list`
2. Can you ping the server? `ping 10.100.100.10`
3. Is the password correct?
4. Check Asterisk logs: `incus exec asterisk-server -- tail -f /var/log/asterisk/messages`

### No Audio

**Check**:
1. Firewall allows RTP ports (10000-20000)
2. Correct audio device selected in Zoiper
3. Headset/speakers working
4. Try different codec (Settings → Codecs → Enable ulaw, alaw)

### Poor Audio Quality

**Solutions**:
1. Use wired network (not WiFi)
2. Enable QoS on network
3. Use G.722 codec for better quality
4. Close bandwidth-heavy applications

### Can't Call External Numbers

**Check**:
1. SIP trunk configured? (See SIP_TRUNK_SETUP.md)
2. Dial `9` before the number
3. Check outbound calling permissions

## Best Practices

### For Employees

- ✅ Use a good quality USB headset
- ✅ Close Zoiper when not in use (saves battery)
- ✅ Set status (Available/Away/DND)
- ✅ Check voicemail daily

### For IT Admins

- ✅ Use strong passwords for each extension
- ✅ Document extension assignments
- ✅ Test new accounts before giving to users
- ✅ Monitor call quality and adjust as needed
- ✅ Keep Asterisk updated

## Scaling Up

### Adding New Users

```bash
# Use the add-extension script
cd scripts
./add-extension.sh 1010 SecurePass1010 "New Employee" new@company.com

# Reload Asterisk
incus exec asterisk-server -- asterisk -rx "pjsip reload"
incus exec asterisk-server -- asterisk -rx "voicemail reload"
```

### Bulk User Creation

Create a CSV file `users.csv`:
```
extension,password,name,email
1010,Pass1010,Alice Johnson,alice@company.com
1011,Pass1011,Bob Wilson,bob@company.com
1012,Pass1012,Carol Davis,carol@company.com
```

Then use the add-extension script in a loop:
```bash
while IFS=, read -r ext pass name email; do
    ./add-extension.sh "$ext" "$pass" "$name" "$email"
done < users.csv
```

## Support Resources

- **Zoiper Documentation**: https://www.zoiper.com/en/support/home
- **Asterisk Community**: https://community.asterisk.org/
- **This POC**: See README.md and SETUP.md

