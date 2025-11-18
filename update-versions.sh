#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Fetching NixOS Search version information...${NC}"

# Fetch frontend version from version.nix
echo "Fetching frontend version..."
FRONTEND_VERSION=$(curl -s https://raw.githubusercontent.com/NixOS/nixos-search/main/version.nix | sed -n 's/.*frontend = "\([^"]*\)".*/\1/p')

# Fetch channel version from flake.nix
echo "Fetching channel version..."
CHANNEL_VERSION=$(curl -s https://raw.githubusercontent.com/NixOS/nixos-search/main/flake.nix | sed -n 's/.*system\.stateVersion = "\([^"]*\)".*/\1/p')

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create JSON output
cat > versions.json << EOF
{
  "frontend_version": "$FRONTEND_VERSION",
  "channel_version": "$CHANNEL_VERSION",
  "last_updated": "$TIMESTAMP",
  "source": "https://github.com/NixOS/nixos-search"
}
EOF

echo -e "${GREEN}Successfully generated versions.json${NC}"
echo ""
cat versions.json
