#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Fetching NixOS Search version information...${NC}"

# Fetch frontend version from version.nix
echo "Fetching frontend version..."
FRONTEND_VERSION=$(curl -s https://raw.githubusercontent.com/NixOS/nixos-search/main/version.nix | sed -n 's/.*frontend = "\([^"]*\)".*/\1/p')

# Fetch channel version from flake.nix
echo "Fetching channel version..."
CHANNEL_VERSION=$(curl -s https://raw.githubusercontent.com/NixOS/nixos-search/main/flake.nix | sed -n 's/.*system\.stateVersion = "\([^"]*\)".*/\1/p')

echo -e "${BLUE}Discovering available NixOS stable channels...${NC}"

# Generate list of potential stable channels dynamically
# NixOS releases happen in May (05) and November (11) of each year
# We'll check the last 2 years worth of releases
generate_potential_channels() {
  local channels=()
  local current_year=$(date +%y)
  local current_month=$(date +%m)

  # Generate potential channels from last 2 years
  for year_offset in 0 1 2; do
    local year=$((current_year - year_offset))
    # Pad year with leading zero if needed
    year=$(printf "%02d" $year)

    for month in 11 05; do
      # Skip future releases
      if [ $year_offset -eq 0 ]; then
        if [ "$month" = "11" ] && [ "$current_month" -lt 11 ]; then
          continue
        fi
        if [ "$month" = "05" ] && [ "$current_month" -lt 05 ]; then
          continue
        fi
      fi

      channels+=("${year}.${month}")
    done
  done

  echo "${channels[@]}"
}

# Test if a channel exists by checking if we get a valid redirect
channel_exists() {
  local channel=$1
  local status=$(curl -sI "https://channels.nixos.org/nixos-${channel}" 2>/dev/null | head -1 | grep -oE '[0-9]{3}' | head -1)
  [ "$status" = "302" ] || [ "$status" = "200" ]
}

# Discover available stable channels
POTENTIAL_CHANNELS=($(generate_potential_channels))
STABLE_CHANNELS=()

echo "Testing channels for availability..."
for channel in "${POTENTIAL_CHANNELS[@]}"; do
  if channel_exists "$channel"; then
    echo "  ✓ nixos-${channel} is available"
    STABLE_CHANNELS+=("$channel")
  else
    echo "  ✗ nixos-${channel} not found"
  fi
done

if [ ${#STABLE_CHANNELS[@]} -eq 0 ]; then
  echo -e "${YELLOW}Warning: No stable channels found, falling back to default list${NC}"
  STABLE_CHANNELS=("24.11" "24.05" "23.11" "23.05")
fi

echo -e "${BLUE}Fetching version information for ${#STABLE_CHANNELS[@]} channels...${NC}"

# Function to fetch channel info
fetch_channel_info() {
  local channel=$1
  local channel_name="nixos-${channel}"

  echo -e "${YELLOW}  Fetching ${channel_name}...${NC}" >&2

  # Get the redirect URL which contains the revision info
  local redirect_url=$(curl -sI "https://channels.nixos.org/${channel_name}" | grep -i "^location:" | cut -d' ' -f2 | tr -d '\r')

  # Extract revision from the redirect URL (format: nixos-24.11.719113.50ab793786d9)
  local release_name=$(basename "$redirect_url" | tr -d '[:space:]')
  local revision=$(echo "$release_name" | rev | cut -d'.' -f1 | rev)

  # If revision extraction failed, mark as unknown
  if [ -z "$revision" ] || [ "$revision" = "$release_name" ]; then
    revision="unknown"
    release_name="unknown"
  fi

  echo "    {\"channel\": \"${channel}\", \"name\": \"${channel_name}\", \"revision\": \"${revision}\", \"release\": \"${release_name}\"}"
}

# Build channels array
CHANNELS_JSON="["
FIRST=true

for channel in "${STABLE_CHANNELS[@]}"; do
  if [ "$FIRST" = false ]; then
    CHANNELS_JSON+=","
  fi
  FIRST=false

  CHANNEL_INFO=$(fetch_channel_info "$channel")
  CHANNELS_JSON+="
    $CHANNEL_INFO"
done

CHANNELS_JSON+="
  ]"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create JSON output
cat > versions.json << EOF
{
  "nixos_search": {
    "frontend_version": "$FRONTEND_VERSION",
    "channel_version": "$CHANNEL_VERSION"
  },
  "nixos_channels": $CHANNELS_JSON,
  "last_updated": "$TIMESTAMP",
  "sources": {
    "nixos_search": "https://github.com/NixOS/nixos-search",
    "nixos_channels": "https://channels.nixos.org"
  }
}
EOF

echo -e "${GREEN}Successfully generated versions.json${NC}"
echo ""
cat versions.json
