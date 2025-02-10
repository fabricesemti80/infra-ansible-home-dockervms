#!/bin/bash
# Log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}
# Validate required variables
if [[ -z "$CLOUDFLARE_API_TOKEN" || -z "$CLOUDFLARE_ZONE_ID" || -z "$DOMAIN" || -z "$TARGET" ]]; then
  log "❌ Error: Missing required environment variables."
  exit 1
fi
# Fetch existing DNS record
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?type=CNAME&name=$DOMAIN" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")
RECORD_ID=$(echo "$RESPONSE" | jq -r '.result[0].id')
CURRENT_TARGET=$(echo "$RESPONSE" | jq -r '.result[0].content')
if [[ "$RECORD_ID" != "null" ]]; then
  if [[ "$CURRENT_TARGET" == "$TARGET" ]]; then
    log "✅ DNS record already exists and matches: $DOMAIN → $TARGET"
  else
    # Update the existing record
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      -H "Content-Type: application/json" \
      --data '{"type":"CNAME","name":"'"$DOMAIN"'","content":"'"$TARGET"'","ttl":1,"proxied":true}')
    if echo "$RESPONSE" | grep -q '"success":true'; then
      log "⚠️ DNS record updated: $DOMAIN → $TARGET"
    else
      log "❌ Error updating DNS record: $(echo "$RESPONSE" | jq -r '.errors')"
      exit 1
    fi
  fi
else
  # Create a new record
  RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"CNAME","name":"'"$DOMAIN"'","content":"'"$TARGET"'","ttl":1,"proxied":true}')
  if echo "$RESPONSE" | grep -q '"success":true'; then
    log "🚀 DNS record created: $DOMAIN → $TARGET"
  else
    log "❌ Error creating DNS record: $(echo "$RESPONSE" | jq -r '.errors')"
    exit 1
  fi
fi
