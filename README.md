# Vibe Code for Home Assistant

Run the [Mistral Vibe Code](https://github.com/mistralai/mistral-vibe) CLI — Mistral's open-source AI coding agent — directly inside your Home Assistant installation. Get a full AI coding assistant in your browser that can read and edit your Home Assistant configuration, create automations, debug issues, and manage your smart home setup.

Inspired by the [Claude Code add-on](https://github.com/robsonfelix/robsonfelix-hass-addons) by Robson Felix.

## Features

- **Full Vibe Code CLI** running inside a web terminal (ttyd), reachable from the Home Assistant sidebar via Ingress
- **Smart home aware** — the working directory is your Home Assistant configuration (`/homeassistant`), so Vibe can read and edit `configuration.yaml`, automations, dashboards, scripts and more
- **Home Assistant MCP integration** — Vibe can query entities, states, automations and call services through the `hass-mcp` MCP server
- **Token usage & cost tracking** — the built-in `vibe-stats` command aggregates token usage and estimated costs across all your sessions
- **Persistent credentials** — your API key and Vibe configuration live in `/homeassistant/.vibe` and survive add-on restarts, rebuilds and reinstalls (and are included in HA backups)
- **Session persistence** — terminal sessions run inside tmux, so your Vibe session survives a browser refresh or closed tab
- **Configurable** — terminal theme, font size, working directory and auto-update options
- **Multi-arch** — builds for amd64, aarch64, armv7, armhf and i386

## Installation

### Step 1: Add the repository

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store**
2. Click the **⋮** menu (top right) → **Repositories**
3. Add: `https://github.com/FireStarter75/hass-vibe-addon`
4. Refresh the add-on store

### Step 2: Install the add-on

1. Find **Vibe Code** in the store and click it
2. Click **Install** (the image is built on HA's build infrastructure; this can take a few minutes)
3. Go to the **Configuration** tab and set your Mistral API key (see below)
4. **Save**, then **Start** the add-on
5. Enable **Show in sidebar** if you want quick access
6. Open **Vibe Code** from the sidebar and run `vibe`

### Step 3: Configure your API key

Get an API key from **[console.mistral.ai](https://console.mistral.ai)** (the same key works with a subscription, the free tier, or pay-as-you-go).

There are two ways to authenticate. To use your **Mistral subscription** (like the Claude Code add-on), run `vibe-login` in the add-on terminal:

1. Run `vibe-login` (alias: `login`)
2. It prints a sign-in URL — select it in the terminal, copy with **Ctrl+Shift+C**, and open it in any browser on your network
3. Sign in with your Mistral account and approve the Vibe CLI access
4. Back in the add-on terminal, the script detects the completed sign-in and stores the API key automatically

Alternatively, use an API key from **[console.mistral.ai](https://console.mistral.ai)** (works with a subscription, the free tier, or pay-as-you-go):

- Paste the key into the `mistral_api_key` option (Settings → Add-ons → Vibe Code → Configuration). The add-on stores it in `/homeassistant/.vibe/.env`, which the Vibe CLI loads automatically as its global environment file. The file is stored with restrictive permissions (`chmod 600`).
- Or run `vibe --setup` in the add-on terminal and use the API-key option there. Note that the built-in browser sign-in link cannot open a browser inside a container; use `vibe-login` instead for subscription login. Pasting in a web terminal uses **Ctrl+Shift+V** (or right-click), not Ctrl+V.

## Add-on configuration

| Option | Default | Description |
|---|---|---|
| `mistral_api_key` | `""` | Mistral API key; saved to `/homeassistant/.vibe/.env` at startup. Leave empty if you already logged in via `vibe --setup`. |
| `enable_mcp` | `true` | Register the `homeassistant` MCP server with Vibe so it can query entities, states and automations |
| `active_model` | `""` | Model alias to activate at startup (e.g. `glm-5.3`). Empty = keep the CLI default |
| `extra_models` | `[]` | Additional models to register, e.g. Z.ai GLM 5.3 (Mistral-hosted) |
| `terminal_font_size` | `14` | Web terminal font size (10–24) |
| `terminal_theme` | `dark` | `dark` or `light` terminal color scheme |
| `working_directory` | `/homeassistant` | Directory Vibe starts in |
| `session_persistence` | `true` | Keep the terminal session alive in tmux across browser refreshes |
| `auto_update_vibe` | `false` | Update the Vibe CLI to the latest release at add-on startup (the build-time version is verified, updates are not) |

## Usage

Open **Vibe Code** from the sidebar. You get a full terminal with the Vibe CLI ready to go.

### Examples

Ask Vibe to help with your smart home, straight from the terminal:

```text
vibe
> Look at my configuration.yaml and suggest how to restructure my automations
> Create an automation that turns off all lights when nobody is home
> Why is my binary_sensor.front_door not updating? Check the logs.
```

With the MCP integration enabled, Vibe can also inspect your running Home Assistant instance: list entities, read states, review automations and query history.

Useful shell aliases are pre-configured:

| Alias | Command | Description |
|---|---|---|
| `v` | `vibe` | Start (or resume) Vibe |
| `stats` | `vibe-stats` | Token usage and cost overview |
| `login` | `vibe-login` | Sign in with your Mistral subscription |
| `ha-config` | `cd /homeassistant` | Jump to the HA configuration directory |
| `ha-logs` | `ha core logs \| tail -100` | Show recent Home Assistant logs |

### Token usage and costs

Run `vibe-stats` (alias: `stats`) in the add-on terminal to see aggregated token usage and estimated costs across all logged Vibe sessions:

```
================================================================
VIBE CODE - TOKEN USAGE
================================================================
Sessions logged : 2
Input tokens    : 20,000
Output tokens   : 5,000
Total tokens    : 25,000
Est. total cost : $0.0750 (worst-case estimate)
----------------------------------------------------------------
Session                                      Tokens        Cost
----------------------------------------------------------------
Fix automations                              15,000     $0.0450
Debug sensor                                 10,000     $0.0300
----------------------------------------------------------------
Note: costs are worst-case estimates per session (no prompt-cache
discount). Account balance/credits: https://console.mistral.ai
```

The Vibe CLI logs every session's token counts and a worst-case cost estimate to `~/.vibe/logs/session/*/metadata.json`. Costs are estimates based on list prices without prompt-cache discounts. Your actual account balance, subscription usage and remaining credits are only visible in the [Mistral console](https://console.mistral.ai).

### Using other models (e.g. Z.ai GLM 5.3)

The Vibe CLI ships with Mistral's own coding models. You can register additional models — for example **Z.ai GLM 5.3**, hosted by Mistral on `api.mistral.ai` — through the `extra_models` option and activate one with `active_model`:

```json
{
  "active_model": "glm-5.3",
  "extra_models": [
    {
      "name": "zai-glm-5-3",
      "alias": "glm-5.3",
      "input_price": 1.4,
      "output_price": 4.4,
      "thinking": "high"
    }
  ]
}
```

- `name` is the model ID on the provider API (`zai-glm-5-3` for Mistral-hosted GLM 5.3)
- `alias` is the short name you use to select the model
- `input_price` / `output_price` (per million tokens) keep `vibe-stats` cost estimates accurate
- `thinking` sets the reasoning effort: `off`, `low`, `medium`, `high` or `max`
- `provider` defaults to `mistral`; use it for any OpenAI-compatible provider

Restart the add-on after changing models. You can also switch models inside a running session with the CLI's `/model` command.

## Path mapping

Inside the add-on container, paths differ from Home Assistant Core:

| Path | Description | Access |
|------|-------------|--------|
| `/homeassistant` | HA configuration directory (= `/config` in HA Core) | read-write |
| `/share` | Shared folder between add-ons | read-write |
| `/media` | Media files | read-write |
| `/ssl` | SSL certificates | read-only |
| `/backup` | Backups | read-only |
| `/data` | This add-on's own config (options) | read-write |

When prompts mention `/config/...`, translate to `/homeassistant/...`.

## File structure

```
hass-vibe-addon/
├── repository.yaml          # Add-on store repository manifest
├── README.md
└── vibecode/                # The Vibe Code add-on
    ├── config.yaml          # Add-on manifest (options, schema, ingress)
    ├── build.yaml           # Build images per architecture
    ├── Dockerfile           # Alpine + Python + Vibe CLI + ttyd + tmux + hass-mcp
    ├── run.sh               # Startup script: env, API key, MCP, ttyd
    ├── vibe-stats           # Token usage / cost aggregation command
    ├── CHANGELOG.md
    └── rootfs/root/         # Shell and tmux configuration
```

## Troubleshooting

- **`vibe` asks for login every restart** — make sure you either ran `vibe-login`, set `mistral_api_key` in the add-on configuration, or completed `vibe --setup`. All write to `/homeassistant/.vibe`, which persists across restarts.
- **Browser sign-in link inside `vibe --setup` does not work** — expected inside a container; use `vibe-login` instead, which prints the URL as copyable text.
- **Cannot paste the API key in the terminal** — use **Ctrl+Shift+V** or right-click → Paste. Ctrl+V does not work in web terminals.
- **Browser sign-in link does not work** — expected inside a container; use the API-key option in `vibe --setup` or the add-on option instead.
- **`ha` command not found** — the HA CLI is only published for amd64 and aarch64; on other architectures it is unavailable.
- **MCP not working** — check the add-on logs at start; the MCP server is registered in `~/.vibe/config.toml`. You can verify with `cat ~/.vibe/config.toml`.
- **`vibe` crashes with a TOML error** — the add-on keeps a backup of the last valid config at `~/.vibe/config.toml.bak` and restores it automatically at startup. If a corrupt file was quarantined, it is kept at `~/.vibe/config.toml.corrupt` for manual inspection.
- **Add-on logs** — Settings → Add-ons → Vibe Code → Log, or `ha-logs` inside the terminal for HA core logs.

## Support

- [Mistral Vibe CLI documentation](https://github.com/mistralai/mistral-vibe)
- [Vibe Code docs](https://docs.mistral.ai/vibe/code/cli/install-setup)
- [Home Assistant add-on development docs](https://developers.home-assistant.io/docs/add-ons/)

Bugs and feature requests: open an issue on [this repository](https://github.com/FireStarter75/hass-vibe-addon/issues).

## Disclaimer

Vibe Code is an AI agent that can read your configuration, write files and run shell commands inside the add-on container. Always keep Home Assistant backups enabled before letting an AI agent make changes to your configuration. The authors accept no liability for broken configurations.

## License

[MIT](LICENSE)
