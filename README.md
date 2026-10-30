# Vibe Code Home Assistant Add-on

Run the [Mistral Vibe Code](https://github.com/mistralai/mistral-vibe) CLI inside Home Assistant, with a web terminal (sidebar panel), access to your Home Assistant configuration, and optional Home Assistant MCP integration.

Based on the [Claude Code add-on](https://github.com/robsonfelix/robsonfelix-hass-addons) by Robson Felix.

## Installation

1. Settings → Add-ons → Add-on Store → ⋮ → Repositories, add: `https://github.com/FireStarter75/hass-vibe-addon`
2. Install **Vibe Code** from the store.
3. Start the add-on and open the web UI from the sidebar.
4. In the terminal, run `vibe --setup` once and log in with your Mistral account (subscription) or paste an API key. Credentials are stored persistently in `/homeassistant/.vibe`.

## Features

- Full Vibe Code CLI in a browser terminal (ttyd), reachable from the HA sidebar
- Working directory is `/homeassistant` (your HA config), so Vibe can read and edit your configuration, automations and dashboards
- Session persistence via tmux (terminal survives browser refresh)
- Optional `hass-mcp` MCP server so Vibe can query entities, states and automations through the Home Assistant API
- Configurable font size, terminal theme and auto-update of the CLI

## Add-on configuration

| Option | Default | Description |
|---|---|---|
| `enable_mcp` | `true` | Register the `homeassistant` MCP server with Vibe |
| `terminal_font_size` | `14` | Web terminal font size (10–24) |
| `terminal_theme` | `dark` | `dark` or `light` |
| `working_directory` | `/homeassistant` | Directory Vibe starts in |
| `session_persistence` | `true` | Keep the session alive in tmux |
| `auto_update_vibe` | `false` | Update the CLI at add-on startup |

## Path mapping

Inside the add-on `/homeassistant` is your HA configuration directory (equivalent to `/config` in HA Core).

## Disclaimer

Vibe can run shell commands and edit your configuration. Always keep backups before letting an AI agent make changes.
