# NixOS Search Version Reporter

Automated tracking of version information from the [NixOS Search](https://github.com/NixOS/nixos-search) project.

## What This Tracks

This repository automatically tracks and reports:
- **Frontend Version**: The Elasticsearch index version used by the NixOS Search UI
- **Channel Version**: The NixOS system state version (e.g., 25.05)

## Output Format

The versions are exported to `versions.json` in the following format:

```json
{
  "frontend_version": "44",
  "channel_version": "25.05",
  "last_updated": "2025-11-18T12:00:00Z",
  "source": "https://github.com/NixOS/nixos-search"
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
- `grep` with Perl regex support (`-P` flag)
- `git` for version control operations (in CI/CD)

## Using the Version Data

You can fetch the latest version information directly from this repository:

```bash
curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json
```

Or use it in your scripts:

```bash
# Get frontend version
FRONTEND_VERSION=$(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.frontend_version')

# Get channel version
CHANNEL_VERSION=$(curl -s https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/versions.json | jq -r '.channel_version')
```

## License

This is a utility repository for tracking public version information from NixOS Search.
