# Test User Credentials

## Ready-to-Use Test Extensions

Two test extensions are pre-configured and ready to use:

### Test User 1
- **Extension**: 1000
- **Password**: TestPass1000
- **Display Name**: Test User 1
- **Asterisk Server**: 10.100.100.10
- **Port**: 5060

### Test User 2
- **Extension**: 1001
- **Password**: TestPass1001
- **Display Name**: Test User 2
- **Asterisk Server**: 10.100.100.10
- **Port**: 5060

## Quick Test Setup

### Option 1: Two Computers

1. **Computer 1**: Install Zoiper, configure with extension 1000
2. **Computer 2**: Install Zoiper, configure with extension 1001
3. From Computer 1, dial `1001` → should ring on Computer 2

### Option 2: One Computer (for testing)

1. Install Zoiper
2. Configure extension 1000
3. Test with `*43` (echo test)
4. Test with `*60` (speaking clock)

## Softphone Configuration

### Zoiper Settings

```
Account Name: Test User 1
Domain: 10.100.100.10
Username: 1000
Password: TestPass1000
Transport: UDP
Port: 5060
```

### MicroSIP Settings

```
SIP Server: 10.100.100.10
SIP User: 1000
Password: TestPass1000
```

## Testing Checklist

- [ ] Extension 1000 registers successfully
- [ ] Extension 1001 registers successfully
- [ ] Call from 1000 to 1001 works
- [ ] Call from 1001 to 1000 works
- [ ] Echo test (*43) works
- [ ] Voicemail (*97) works
- [ ] Conference (8000) works

## Calling from Your Mobile Phone

To receive calls from your mobile phone, you need to:

1. **Set up SIP trunk** (see docs/SIP_TRUNK_SETUP.md)
2. **Port your company number** to the SIP trunk provider
3. **Configure inbound routing** in extensions.conf

Example configuration in `asterisk/extensions.conf`:

```ini
[from-external]
; Route your company number to extension 1000
exten => +15551234567,1,NoOp(Incoming call from ${CALLERID(num)})
 same => n,Dial(PJSIP/1000,30)
 same => n,VoiceMail(1000@default,u)
 same => n,Hangup()
```

Replace `+15551234567` with your actual company phone number.

## Next Steps

1. ✅ **Deploy Asterisk**: `./deploy.sh`
   - Uses production-optimized `andrius/asterisk:latest` image
   - Smallest Asterisk Docker image available
   - Full PJSIP, WebRTC, and modern features
2. ✅ **Install Zoiper** on 2 computers
3. ✅ **Configure** with test credentials above
4. ✅ **Test** internal calling
5. ✅ **Set up SIP trunk** for external calls
6. ✅ **Add more users** as needed

## Adding More Users

```bash
cd scripts
./add-extension.sh 1002 TestPass1002 "Employee Name" employee@company.com

# Reload Asterisk
incus exec asterisk-server -- asterisk -rx "pjsip reload"
```

## Security Note

⚠️ **These are test passwords!** 

For production:
- Use strong, unique passwords for each extension
- Change passwords regularly
- Use TLS/SRTP for encrypted calls
- Enable fail2ban for brute-force protection

