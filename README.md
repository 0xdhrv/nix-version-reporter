# NixOS Search Version Reporter

Automated tracking of version information from the [NixOS Search](https://github.com/NixOS/nixos-search) project and NixOS stable channels.

## What This Tracks

This repository automatically tracks and reports:

### NixOS Search
- **Frontend Version**: The Elasticsearch index version used by the NixOS Search UI
- **Channel Version**: The NixOS system state version (e.g., 25.05)

### NixOS Stable Channels
Automatically discovers and tracks available NixOS stable releases from the last ~2 years:
- **Channel**: The channel version number (e.g., 25.05, 24.11, 24.05)
- **Name**: Full channel name (e.g., nixos-24.11)
- **Revision**: Git commit hash of the nixpkgs revision
- **Release**: Full release identifier (e.g., nixos-24.11.719113.50ab793786d9)

The script dynamically detects which channels exist, so it will automatically pick up new NixOS releases without manual updates.

## Output Format

The versions are exported to `versions.json` in the following format:

```json
{
  "nixos_search": {
    "frontend_version": "44",
    "channel_version": "25.05"
  },
  "nixos_channels": [
    {
      "channel": "25.05",
      "name": "nixos-25.05",
      "revision": "3acb677ea67d",
      "release": "nixos-25.05.812778.3acb677ea67d"
    },
    {
      "channel": "24.11",
      "name": "nixos-24.11",
      "revision": "50ab793786d9",
      "release": "nixos-24.11.719113.50ab793786d9"
    },
    {
      "channel": "24.05",
      "name": "nixos-24.05",
      "revision": "b134951a4c9f",
      "release": "nixos-24.05.7376.b134951a4c9f"
    },
    {
      "channel": "23.11",
      "name": "nixos-23.11",
      "revision": "205fd4226592",
      "release": "nixos-23.11.7870.205fd4226592"
    },
    {
      "channel": "23.05",
      "name": "nixos-23.05",
      "revision": "70bdadeb94ff",
      "release": "nixos-23.05.5533.70bdadeb94ff"
    }
  ],
  "last_updated": "2025-11-18T04:03:57Z",
  "sources": {
    "nixos_search": "https://github.com/NixOS/nixos-search",
    "nixos_channels": "https://channels.nixos.org"
  }
}
```

## Automation

The GitHub Action runs automatically:
- **Every 6 hours** via cron schedule (`0 */6 * * *`)
- **On push** to the main branch
- **Manually** via workflow dispatch

When version changes are detected, the workflow commits and pushes the updated `versions.json` file.

## Manual Usage

You can also run the version check locally:

```bash
./update-versions.sh
```

This will fetch the current versions and generate `versions.json` in the current directory.

## Requirements

- `curl` for fetching remote files
- `sed` for text processing
- `bash` 4.0+ for array support
- `git` for version control operations (in CI/CD)
- `jq` for JSON parsing (in CI/CD workflow)

## Using the Version Data

You can fetch the latest version information directly from this repository:

```bash
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json
```

Or use it in your scripts:

```bash
# Get NixOS Search frontend version
FRONTEND_VERSION=$(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.nixos_search.frontend_version')

# Get NixOS Search channel version
SEARCH_CHANNEL=$(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.nixos_search.channel_version')

# Get latest stable channel (24.11) revision
NIXOS_24_11_REV=$(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.nixos_channels[] | select(.channel == "24.11") | .revision')

# Get all channel revisions
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.nixos_channels[] | "\(.channel): \(.revision)"'
```

## Channel Discovery

The script automatically discovers available NixOS stable channels by:
1. Generating a list of potential channels based on NixOS's release schedule (May and November releases)
2. Checking the last ~2 years of potential releases
3. Testing each channel URL to verify it exists
4. Only including channels that are actually available

This means:
- **New releases are automatically detected** without updating the script
- **Old EOL releases automatically drop off** after 2 years
- **No manual configuration needed**

If you want to adjust the time window, you can modify the `year_offset` range in the `generate_potential_channels()` function in `update-versions.sh`. For example, to track 3 years instead of 2:

```bash
# Change this line in generate_potential_channels():
for year_offset in 0 1 2; do
# To:
for year_offset in 0 1 2 3; do
```

## License

This is a utility repository for tracking public version information from NixOS Search.
