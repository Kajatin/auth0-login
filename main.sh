#!/bin/bash


# Prepare request body
REQUEST_BODY=$(jq -n --arg client_id "$CLIENT_ID" --arg client_secret "$CLIENT_SECRET" --arg grant_type "$GRANT_TYPE" \
    '{client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type}')

if [ -n "$AUDIENCE" ]; then
    REQUEST_BODY=$(echo "$REQUEST_BODY" | jq --arg audience "$AUDIENCE" '.audience = $audience')
fi

# Prepare Auth0 URL
AUTH0_URL="${TENANT_URL%/}/oauth/token"

# Make the request
RESPONSE=$(curl -s -X POST "$AUTH0_URL" -H "Content-Type: application/json" -d "$REQUEST_BODY")

# Check for response status
if ! echo "$RESPONSE" | jq -e .access_token > /dev/null; then
    echo "Failed to authenticate with Auth0: $(echo "$RESPONSE" | jq -r .error_description)" >&2
    exit 1
fi

# Extract access token
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r .access_token)

# Set outputs
echo "access-token=$ACCESS_TOKEN" >> "$GITHUB_OUTPUT"
