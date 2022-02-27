#!/bin/bash
# Author:       Björn Benouarets
# Version:      1.0
# Description:  This script is used to update your Cloudflare DNS record with your current IP address.

# Set variables
CF_EMAIL=""
CF_TOKEN=""
CF_ZONE_ID=""
CF_RECORD=""

# Get current IP address
IP=$(curl -s https://api.ipify.org)

# Show the current IP adress in bold
echo -e "🔎 Current IP: \033[1m$IP\033[0m"

# Don't show the curl output
echo -e "🔎 Verifying Cloudflare API token..."
RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json")    

# If in the result there is a "success" is true, then the token is valid
if [[ $RESULT == *"\"success\":true"* ]]; then
    echo -e "🔒 Token is valid!"
else
    echo -e "🔒 Token is invalid!"
    exit 1
fi

# Don't show the curl output
echo -e "🔎 Checking if record already up to date..."
RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$CF_RECORD" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json")

# Check if the current IP is already in the record
if [[ $RESULT == *"\"content\":\"$IP\""* ]]; then
    echo -e "🔒 Record is already up to date!"
    exit 0
else
    echo -e "🔒 Record is not up to date!"
fi

# Save the DNS record ID
CF_DNS_ID=$(echo $RESULT | grep -Po '"id":"\K[^"]*')

# Don't show the curl output
echo -e "🔎 Updating record..."
URL="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_DNS_ID"
echo -e "🚀 $URL"
RESULT=$(curl -s -X PUT "$URL" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"$CF_RECORD"'","content":"'"$IP"'","ttl":1,"proxied":true}')

# If in the result there is a "success" is true, then the record was updated
if [[ $RESULT == *"\"success\":true"* ]]; then
    echo -e "🔒 Record was updated!"
else
    echo -e "🔒 Record was not updated!"
    exit 1
fi