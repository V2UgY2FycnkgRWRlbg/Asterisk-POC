# Phone Number Porting Guide

This guide explains how to port existing phone numbers to your new Asterisk PBX system and manage the transition.

## Table of Contents

1. [Overview](#overview)
2. [Pre-Porting Checklist](#pre-porting-checklist)
3. [Porting Process](#porting-process)
4. [Transition Strategies](#transition-strategies)
5. [Post-Porting Configuration](#post-porting-configuration)
6. [Troubleshooting](#troubleshooting)

## Overview

**Number porting** (Local Number Portability - LNP) allows you to transfer existing phone numbers from your current carrier to a new SIP trunk provider that works with Asterisk.

### Key Points

- **Timeline**: 2-4 weeks typical (can be longer for toll-free numbers)
- **Cost**: Usually $5-25 per number
- **Requirements**: Account information from current carrier
- **Downtime**: Minimal if planned correctly (can be zero with proper strategy)

## Pre-Porting Checklist

### 1. Inventory Your Numbers

Create a list of all phone numbers to port:

```
Main Line:        +1 (555) 123-4567
Sales Direct:     +1 (555) 123-4568
Support Direct:   +1 (555) 123-4569
Fax Line:         +1 (555) 123-4570
Toll-Free:        +1 (800) 555-1234
```

### 2. Gather Current Carrier Information

You'll need:

- **Current carrier name** (e.g., AT&T, Verizon)
- **Account number** (call carrier to get this)
- **Account holder name** (must match exactly)
- **Service address** (billing address)
- **Authorized contact** (person who can approve the port)
- **PIN/Password** (if applicable)
- **Recent bill** (as proof of ownership)

### 3. Choose a SIP Trunk Provider

Popular providers that work well with Asterisk:

| Provider | Pros | Cons | Pricing |
|----------|------|------|---------|
| **Twilio** | Easy API, great docs | Higher cost | $1/mo + $0.0085/min |
| **Bandwidth** | Good pricing, reliable | More technical | $0.50/mo + $0.004/min |
| **Vonage Business** | Full-featured | Less flexible | $19.99/mo per line |
| **Flowroute** | Developer-friendly | Limited support | $0.39/mo + $0.012/min |
| **Telnyx** | Low cost, global | Newer company | $0.40/mo + $0.004/min |

**Recommendation for POC**: Start with **Twilio** or **Bandwidth** for ease of use.

### 4. Verify Number Portability

Not all numbers can be ported:

- ✅ **Can port**: Local numbers, toll-free, most business lines
- ❌ **Cannot port**: Some VoIP numbers, temporary numbers, certain prepaid numbers

Check with your new provider's porting tool or support.

## Porting Process

### Step 1: Sign Up with SIP Trunk Provider

1. Create account with chosen provider
2. Verify your identity (business documents may be required)
3. Add payment method

### Step 2: Submit Port Request

#### Example: Twilio Port Request

```bash
# Via Twilio Console:
1. Go to Phone Numbers → Port & Host
2. Click "Port a Number"
3. Enter numbers to port
4. Upload Letter of Authorization (LOA)
5. Submit request
```

#### Letter of Authorization (LOA)

Most providers require a signed LOA. It includes:

- Numbers to port
- Current carrier information
- Account details
- Authorized signature
- Date

**Template**: Providers usually provide their own LOA template.

### Step 3: Port Validation

The new carrier will:

1. **Validate information** with current carrier (1-3 days)
2. **Identify issues** (wrong account number, name mismatch, etc.)
3. **Request corrections** if needed

**Common rejection reasons**:
- Account number doesn't match
- Name on account doesn't match LOA
- Number is under contract
- Missing information

### Step 4: Port Scheduling

Once validated:

1. **FOC Date** (Firm Order Commitment) is set
2. **Port window** is assigned (usually business hours)
3. **Confirmation** sent to both carriers

**Timeline**:
- Local numbers: 7-10 business days
- Toll-free: 15-30 business days
- International: Varies by country

### Step 5: Port Completion

On the FOC date:

1. **Numbers transfer** to new carrier (usually takes 1-4 hours)
2. **Old service disconnects** automatically
3. **New service activates** on your SIP trunk
4. **Test immediately** to verify

## Transition Strategies

### Strategy 1: Direct Cutover (Recommended for Small Deployments)

**Best for**: 1-10 numbers, short downtime acceptable

```
Timeline:
Day 1:     Submit port request
Day 7-10:  Port completes
Day 10:    Configure Asterisk with ported numbers
```

**Pros**: Simple, clean break
**Cons**: Brief downtime during port window

### Strategy 2: Parallel Running (Recommended for Critical Numbers)

**Best for**: Main business lines, zero downtime required

```
Timeline:
Week 1:    Set up Asterisk with new temporary numbers
Week 2:    Test thoroughly with temporary numbers
Week 3:    Submit port request for real numbers
Week 4:    Port completes, switch to ported numbers
```

**Implementation**:

1. Get temporary numbers from SIP provider
2. Set up Asterisk with temporary numbers
3. Forward old numbers to temporary numbers
4. Test everything thoroughly
5. Port real numbers
6. Update Asterisk configuration
7. Remove temporary numbers

### Strategy 3: Staged Migration (Recommended for Large Deployments)

**Best for**: 10+ numbers, departments, multiple locations

```
Phase 1: Port non-critical numbers (test group)
Phase 2: Port department numbers
Phase 3: Port main lines
Phase 4: Port remaining numbers
```

**Example Schedule**:

| Week | Numbers | Purpose |
|------|---------|---------|
| 1-2 | IT department (2 numbers) | Test and validate |
| 3-4 | Sales department (5 numbers) | Expand rollout |
| 5-6 | Support department (5 numbers) | Continue rollout |
| 7-8 | Main lines (3 numbers) | Complete migration |

### Strategy 4: Call Forwarding Bridge

**Best for**: Maximum safety, can afford extra cost

```
Setup:
1. Keep old carrier active
2. Forward old numbers to new Asterisk numbers
3. Run parallel for 1-2 months
4. Port numbers when confident
5. Cancel old carrier
```

**Pros**: Zero risk, easy rollback
**Cons**: Pay for both services during transition

## Post-Porting Configuration

### Configure SIP Trunk in Asterisk

Edit `/etc/asterisk/pjsip.conf`:

```ini
[trunk-twilio]
type=registration
transport=transport-udp
outbound_auth=trunk-twilio-auth
server_uri=sip:yourcompany.pstn.twilio.com
client_uri=sip:yourcompany@yourcompany.pstn.twilio.com
retry_interval=60

[trunk-twilio-auth]
type=auth
auth_type=userpass
username=yourcompany
password=YOUR_TWILIO_PASSWORD

[trunk-twilio-endpoint]
type=endpoint
context=from-trunk
disallow=all
allow=ulaw
allow=alaw
transport=transport-udp
from_user=yourcompany
outbound_auth=trunk-twilio-auth
aors=trunk-twilio-aor

[trunk-twilio-aor]
type=aor
contact=sip:yourcompany.pstn.twilio.com

[trunk-twilio-identify]
type=identify
endpoint=trunk-twilio-endpoint
match=yourcompany.pstn.twilio.com
```

### Map DIDs to Extensions

Edit `/etc/asterisk/extensions.conf`:

```ini
[from-trunk]
; Main line -> Reception
exten => +15551234567,1,NoOp(Main line incoming)
 same => n,Dial(PJSIP/1000,30,tr)
 same => n,Goto(ivr-main,s,1)

; Sales direct -> Sales department
exten => +15551234568,1,NoOp(Sales line)
 same => n,Dial(PJSIP/1002,30,tr)
 same => n,VoiceMail(1002@default,u)
 same => n,Hangup()

; Support direct -> Support queue
exten => +15551234569,1,NoOp(Support line)
 same => n,Answer()
 same => n,Queue(support-queue)
 same => n,Hangup()

; Toll-free -> IVR
exten => +18005551234,1,NoOp(Toll-free incoming)
 same => n,Goto(ivr-main,s,1)
```

### Update Outbound Caller ID

```ini
[internal]
; Set outbound caller ID to main company number
exten => _1NXXNXXXXXX,1,NoOp(Outbound call)
 same => n,Set(CALLERID(num)=+15551234567)
 same => n,Dial(PJSIP/${EXTEN}@trunk-twilio-endpoint)
 same => n,Hangup()
```

### Reload Configuration

```bash
asterisk -rx "pjsip reload"
asterisk -rx "dialplan reload"
```

## Testing After Port

### Test Checklist

- [ ] **Inbound calls** to each ported number
- [ ] **Outbound calls** showing correct caller ID
- [ ] **Voicemail** on each line
- [ ] **Call forwarding** if configured
- [ ] **Emergency calls** (911) - verify callback number
- [ ] **Fax** if applicable (may need T.38 configuration)
- [ ] **After-hours routing** if configured

### Test Script

```bash
# Test inbound to main line
# Call +15551234567 from external phone
# Verify: Rings extension 1000

# Test outbound caller ID
# From extension 1000, call your mobile
# Verify: Shows +15551234567

# Test voicemail
# Call +15551234567, let it go to voicemail
# Leave message, check *97

# Test emergency
# From extension 1000, dial 911
# Verify: Connects, callback number correct
# IMPORTANT: Inform 911 operator this is a test!
```

## Troubleshooting

### Port Rejected

**Issue**: Port request rejected by current carrier

**Solutions**:
1. Verify account number is correct (call current carrier)
2. Ensure name on LOA matches account exactly
3. Check for outstanding balance
4. Verify number is not under contract
5. Confirm service address matches billing address

### Port Delayed

**Issue**: Port taking longer than expected

**Solutions**:
1. Contact new carrier for status update
2. Check for pending information requests
3. Verify FOC date hasn't changed
4. Escalate with carrier support if needed

### Numbers Not Working After Port

**Issue**: Calls to ported numbers fail

**Solutions**:
1. Check SIP trunk registration: `asterisk -rx "pjsip show registrations"`
2. Verify trunk credentials are correct
3. Check firewall allows SIP traffic from provider
4. Review Asterisk logs: `tail -f /var/log/asterisk/messages`
5. Test with provider's support team

### Caller ID Not Showing

**Issue**: Outbound calls show wrong number

**Solutions**:
1. Verify number is validated with SIP provider
2. Check `Set(CALLERID(num)=...)` in dialplan
3. Ensure number format matches provider requirements (+1 vs 1 vs no prefix)
4. Some carriers require CNAM registration

### Emergency Calls Not Working

**Issue**: 911 calls fail or show wrong location

**Solutions**:
1. Register E911 address with SIP provider (REQUIRED)
2. Verify callback number is configured
3. Test with provider support
4. Keep backup phone line until verified

## Best Practices

1. **Port in batches** - Don't port all numbers at once
2. **Test thoroughly** - Use temporary numbers first
3. **Document everything** - Keep records of account numbers, dates, contacts
4. **Communicate** - Inform staff of port dates and potential issues
5. **Have backup** - Keep old service active during testing if possible
6. **Monitor closely** - Watch for issues in first 48 hours after port
7. **Update listings** - Update online directories, business cards, etc.

## Emergency Rollback

If porting causes major issues:

1. **Contact SIP provider immediately** - Request port reversal (rare, difficult)
2. **Forward to old numbers** - If old service still active
3. **Use backup lines** - Switch to backup carrier
4. **Communicate** - Update voicemail, website with temporary numbers

**Note**: Port reversals are difficult and may not be possible. Prevention is key!

