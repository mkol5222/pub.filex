#!/bin/bash

TS=$(date +%s)
echo "[$TS] This is mockup send sms script"
echo "Phone: $NEWSMS_PHONE"
echo "SMSTEXT: $NEWSMS_SMSTEXT"

# run curl_cli to real provider here and use variables $NEWSMS_PHONE and $NEWSMS_SMSTEXT

echo "SMS sent (mockup)"

curl -s -d '{"phone":"'"$NEWSMS_PHONE"'","message":"'"$NEWSMS_SMSTEXT"'"}' \
https://nanuc-1.buru-gamma.ts.net/webhook/3e462382-59dc-4a38-9b92-1776c441dc45  \
-u sms:vpn123 -H "Content-Type: application/json"
echo ""

exit 0