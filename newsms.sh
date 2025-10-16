#!/bin/bash

TS=$(date +%s)
echo "[$TS] This is mockup send sms script"
echo "Phone: $NEWSMS_PHONE"
echo "SMSTEXT: $NEWSMS_SMSTEXT"

# run curl_cli to real provider here and use variables $NEWSMS_PHONE and $NEWSMS_SMSTEXT

echo "SMS sent (mockup)"

curl_cli -k -v -m2 -d '{"phone":"'"$NEWSMS_PHONE"'","message":"'"$NEWSMS_SMSTEXT"'"}' \
-u sms:vpn123 -H "Content-Type: application/json" \
https://nanuc-1.buru-gamma.ts.net/webhook/3e462382-59dc-4a38-9b92-1776c441dc45
echo ""


exit 0