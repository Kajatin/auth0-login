#!/bin/bash

# Function to get input values
get_input() {
  local name="$1"
  local required="$2"
  local value="${!name}"

  if [[ -z "$value" && "$required" == "true" ]]; then
    echo "Input $name is required" >&2
    exit 1
  fi

  echo "$value"
}

# Function to send request to Auth0 and get the access token
auth0_login() {
  local tenant_url="$1"
  local client_id="$2"
  local client_secret="$3"
  local audience="$4"
  local grant_type="$5"

  local auth0_url="${tenant_url%/}/oauth/token"

  local request_body=$(jq -n \
    --arg client_id "$client_id" \
    --arg client_secret "$client_secret" \
    --arg grant_type "$grant_type" \
    --arg audience "$audience" \
    '{
      client_id: $client_id,
      client_secret: $client_secret,
      grant_type: $grant_type,
      audience: $audience
    } | del(.audience | select(. == ""))')

  local response=$(curl -s -X POST "$auth0_url" \
    -H "Content-Type: application/json" \
    -d "$request_body")

  local http_status=$(echo "$response" | jq -r '.error // empty')

  if [[ -n "$http_status" ]]; then
    echo "Failed to authenticate with Auth0: $response" >&2
    exit 1
  fi

  local access_token=$(echo "$response" | jq -r '.access_token')

  if [[ -z "$access_token" ]]; then
    echo "Failed to retrieve access token from Auth0 response" >&2
    exit 1
  fi

  echo "$access_token"
}

# Main function
main() {
  tenant_url=$(get_input "tenant_url" true)
  client_id=$(get_input "client_id" true)
  client_secret=$(get_input "client_secret" true)
  audience=$(get_input "audience" false)
  grant_type=$(get_input "grant_type" false)

  if [[ -z "$grant_type" ]]; then
    grant_type="client_credentials"
  fi

  access_token=$(auth0_login "$tenant_url" "$client_id" "$client_secret" "$audience" "$grant_type")

  # Set output
  echo "::add-mask::$access_token"
  echo "::set-output name=access-token::$access_token"

  echo "Successfully authenticated with Auth0"
}

# Execute main function
main
