# Changelog

## 1.0.0

- Initial release.
- Mistral Vibe CLI in a web terminal (ttyd) with HA Ingress panel.
- Persistent credentials and config in `/homeassistant/.vibe`.
- Optional `hass-mcp` MCP server integration.
- tmux session persistence, dark/light theme, font size and auto-update options.

## 1.2.0

- Added `vibe-stats` command: aggregated token usage and estimated costs across all logged Vibe sessions.

## 1.2.1

- Fixed a startup bug where appending the `homeassistant` MCP server could produce an invalid `~/.vibe/config.toml` (TOML conflict with an existing `mcp_servers` key), crashing `vibe` with a `TOMLDecodeError`. The add-on now detects inline `mcp_servers` arrays, validates the file after appending, and rolls back on failure.

## 1.3.0

- Added automatic `config.toml` repair: a backup (`config.toml.bak`) is kept of the last known-good state, refreshed at every add-on start and after every successful modification.
- If `config.toml` is invalid at startup, the add-on restores the backup; without a valid backup the corrupt file is moved to `config.toml.corrupt` and a fresh config is created.
