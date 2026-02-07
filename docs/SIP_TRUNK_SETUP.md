# SIP Trunk Setup - Connect Your Enterprise Numbers

This guide shows how to connect your existing enterprise phone numbers to Asterisk so people can call you.

## What is a SIP Trunk?

A SIP trunk connects your Asterisk server to the public phone network (PSTN). It allows:
- **Inbound calls**: People calling your company numbers reach Asterisk
- **Outbound calls**: Your users can call external phone numbers
- **Keep existing numbers**: No need to change your published phone numbers

## Step 1: Choose a SIP Trunk Provider

Recommended providers:

| Provider | Best For | Pricing | Setup Difficulty |
|----------|----------|---------|------------------|
| **Twilio** | Easy setup, good docs | Pay-as-you-go | ⭐ Easy |
| **Bandwidth** | Enterprise, bulk | Monthly plans | ⭐⭐ Medium |
| **Flowroute** | Cost-effective | Low per-minute | ⭐⭐ Medium |
| **Telnyx** | Global coverage | Competitive | ⭐⭐ Medium |

**For this POC, we recommend Twilio** (easiest to set up).

## Step 2: Port Your Numbers to the Provider

### What You Need

1. **Current phone bill** - Shows you own the numbers
2. **Letter of Authorization (LOA)** - Provider will give you template
3. **Service address** - Where the numbers are registered
4. **Account number** - From current carrier

### Porting Process

1. **Sign up** with SIP trunk provider (e.g., Twilio)
2. **Request port** - Submit LOA and documentation
3. **Wait for approval** - Usually 2-4 weeks
4. **Confirm port date** - Provider schedules the switch
5. **Port completes** - Numbers now route through provider

**During porting**: Your numbers keep working with old carrier until port completes.

## Step 3: Configure Asterisk for Inbound Calls

### Example: Twilio Configuration

Edit `asterisk/pjsip.conf` and add:

```ini
;=== SIP Trunk Configuration ===

[twilio-trunk]
type=registration
outbound_auth=twilio-auth
server_uri=sip:yourcompany.pstn.twilio.com
client_uri=sip:youruser@yourcompany.pstn.twilio.com
retry_interval=60

[twilio-auth]
type=auth
auth_type=userpass
username=YOUR_TWILIO_USERNAME
password=YOUR_TWILIO_PASSWORD

[twilio]
type=endpoint
context=from-external
disallow=all
allow=ulaw
allow=alaw
aors=twilio
from_domain=yourcompany.pstn.twilio.com

[twilio]
type=aor
contact=sip:yourcompany.pstn.twilio.com

[twilio]
type=identify
endpoint=twilio
match=54.172.60.0/23
match=54.244.51.0/24
```

**Get these values from your Twilio account:**
- `yourcompany` - Your Twilio SIP domain
- `YOUR_TWILIO_USERNAME` - From Twilio Elastic SIP Trunking
- `YOUR_TWILIO_PASSWORD` - From Twilio Elastic SIP Trunking

### Configure Inbound Call Routing

Edit `asterisk/extensions.conf`:

```ini
[from-external]
; Main company number -> receptionist (extension 1000)
exten => +15551234567,1,NoOp(Incoming call to main line)
 same => n,Dial(PJSIP/1000,30)
 same => n,VoiceMail(1000@default,u)
 same => n,Hangup()

; Support line -> extension 1001
exten => +15559876543,1,NoOp(Incoming call to support)
 same => n,Dial(PJSIP/1001,30)
 same => n,VoiceMail(1001@default,u)
 same => n,Hangup()

; Sales line -> ring multiple extensions
exten => +15555555555,1,NoOp(Incoming call to sales)
 same => n,Dial(PJSIP/1002&PJSIP/1003&PJSIP/1004,30)
 same => n,VoiceMail(1002@default,u)
 same => n,Hangup()
```

**Replace** `+15551234567` with your actual phone numbers.

## Step 4: Configure Outbound Calling

Edit `asterisk/extensions.conf`:

```ini
[internal]
; Outbound calling - dial 9 + number
exten => _9NXXNXXXXXX,1,NoOp(Outbound call to ${EXTEN:1})
 same => n,Set(CALLERID(num)=YOUR_COMPANY_NUMBER)
 same => n,Dial(PJSIP/${EXTEN:1}@twilio)
 same => n,Hangup()

; International - dial 9 + 011 + country + number
exten => _9011.,1,NoOp(International call to ${EXTEN:1})
 same => n,Set(CALLERID(num)=YOUR_COMPANY_NUMBER)
 same => n,Dial(PJSIP/${EXTEN:1}@twilio)
 same => n,Hangup()
```

## Step 5: Apply Configuration

```bash
# Copy config to container
incus file push ../asterisk/pjsip.conf asterisk-server/etc/asterisk/
incus file push ../asterisk/extensions.conf asterisk-server/etc/asterisk/

# Reload Asterisk
incus exec asterisk-server -- asterisk -rx "pjsip reload"
incus exec asterisk-server -- asterisk -rx "dialplan reload"

# Verify trunk is registered
incus exec asterisk-server -- asterisk -rx "pjsip show registrations"
```

## Step 6: Test

### Test Inbound

1. Call your company number from your mobile phone
2. Should ring the configured extension
3. If no answer, should go to voicemail

### Test Outbound

1. From your softphone, dial: `9` + `1` + area code + number
2. Example: `915551234567`
3. Should connect to external number

## Firewall Configuration

Make sure these ports are open on your firewall:

```bash
# SIP signaling
5060/UDP (SIP)
5061/TCP (SIP TLS)

# RTP media (voice)
10000-20000/UDP

# If using firewall, forward these ports to: 10.100.100.10
```

## Troubleshooting

### Trunk Not Registering

```bash
# Check registration status
incus exec asterisk-server -- asterisk -rx "pjsip show registrations"

# Check logs
incus exec asterisk-server -- tail -f /var/log/asterisk/messages | grep twilio
```

### Inbound Calls Not Working

```bash
# Verify trunk endpoint
incus exec asterisk-server -- asterisk -rx "pjsip show endpoint twilio"

# Check if calls are reaching Asterisk
incus exec asterisk-server -- asterisk -rvvv
# Then call your number and watch console
```

### Outbound Calls Failing

```bash
# Check dialplan
incus exec asterisk-server -- asterisk -rx "dialplan show internal"

# Test dial
incus exec asterisk-server -- asterisk -rvvv
# From console: originate PJSIP/15551234567@twilio application echo
```

## Cost Estimates

**Twilio pricing example:**
- Phone number: $1/month per number
- Inbound calls: $0.0085/minute
- Outbound calls: $0.013/minute

**For 50 employees, ~1000 minutes/month:**
- Numbers (5): $5/month
- Inbound: ~$8.50/month
- Outbound: ~$13/month
- **Total: ~$26.50/month**

Much cheaper than traditional phone service!

## Next Steps

1. ✅ Sign up with SIP trunk provider
2. ✅ Port your numbers (or buy new test numbers)
3. ✅ Configure pjsip.conf with provider details
4. ✅ Configure extensions.conf for call routing
5. ✅ Test inbound and outbound calling
6. ✅ Add more users as needed

