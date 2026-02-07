#!/bin/bash
#============================ Add Extension Script ============================
# This script adds a new extension to Asterisk configuration
# Usage: ./add-extension.sh <extension> <password> <display_name> <email>

set -e

if [ $# -lt 4 ]; then
    echo "Usage: $0 <extension> <password> <display_name> <email>"
    echo "Example: $0 1050 SecurePass123 'Jane Smith' jane@company.local"
    exit 1
fi

EXTENSION=$1
PASSWORD=$2
DISPLAY_NAME=$3
EMAIL=$4

PJSIP_CONF="/etc/asterisk/pjsip.conf"
VOICEMAIL_CONF="/etc/asterisk/voicemail.conf"

echo "Adding extension $EXTENSION ($DISPLAY_NAME)..."

# Check if extension already exists
if grep -q "^\[$EXTENSION\]" "$PJSIP_CONF"; then
    echo "Error: Extension $EXTENSION already exists in pjsip.conf"
    exit 1
fi

# Add to pjsip.conf
echo "" >> "$PJSIP_CONF"
echo "; Extension $EXTENSION - $DISPLAY_NAME" >> "$PJSIP_CONF"
echo "[$EXTENSION](endpoint-internal)" >> "$PJSIP_CONF"
echo "auth=$EXTENSION" >> "$PJSIP_CONF"
echo "aors=$EXTENSION" >> "$PJSIP_CONF"
echo "callerid=\"$DISPLAY_NAME\" <$EXTENSION>" >> "$PJSIP_CONF"
echo "" >> "$PJSIP_CONF"
echo "[$EXTENSION](auth-userpass)" >> "$PJSIP_CONF"
echo "username=$EXTENSION" >> "$PJSIP_CONF"
echo "password=$PASSWORD" >> "$PJSIP_CONF"
echo "" >> "$PJSIP_CONF"
echo "[$EXTENSION](aor-single)" >> "$PJSIP_CONF"

echo "Added to pjsip.conf"

# Add to voicemail.conf
if ! grep -q "^$EXTENSION =>" "$VOICEMAIL_CONF"; then
    # Find the [default] section and add the extension
    sed -i "/^\[default\]/a $EXTENSION => 1234,$DISPLAY_NAME,$EMAIL,,attach=yes|tz=central" "$VOICEMAIL_CONF"
    echo "Added to voicemail.conf"
else
    echo "Extension already exists in voicemail.conf, skipping"
fi

# Reload Asterisk
echo "Reloading Asterisk configuration..."
asterisk -rx "pjsip reload"
asterisk -rx "voicemail reload"

echo ""
echo "Extension $EXTENSION added successfully!"
echo ""
echo "Details:"
echo "  Extension: $EXTENSION"
echo "  Password: $PASSWORD"
echo "  Display Name: $DISPLAY_NAME"
echo "  Email: $EMAIL"
echo "  Voicemail PIN: 1234 (change via *97)"
echo ""
echo "Verify with: asterisk -rx 'pjsip show endpoint $EXTENSION'"

