# Vibe Code for Home Assistant

[English](README.md) | [Nederlands](README.nl.md)

Run the [Mistral Vibe Code](https://github.com/mistralai/mistral-vibe) CLI — Mistral's open-source AI coding agent — directly inside your Home Assistant installation. Get a full AI coding assistant in your browser that can read and edit your Home Assistant configuration, create automations, debug issues, and manage your smart home setup.

Inspired by the [Claude Code add-on](https://github.com/robsonfelix/robsonfelix-hass-addons) by Robson Felix.

## Features

- **Full Vibe Code CLI** running inside a web terminal (ttyd), reachable from the Home Assistant sidebar via Ingress
- **Smart home aware** — the working directory is your Home Assistant configuration (`/homeassistant`), so Vibe can read and edit `configuration.yaml`, automations, dashboards, scripts and more
- **Home Assistant MCP integration** — Vibe can query entities, states, automations and call services through the `hass-mcp` MCP server
- **Subscription login** — sign in with your Mistral account via `vibe-login`, no manual API keys needed
- **Automatic model discovery** — new Mistral-hosted models (like Z.ai GLM 5.3) are registered automatically at every start, or pick your own with the `models` menu
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
3. **Start** the add-on
4. Enable **Show in sidebar** if you want quick access

### Step 3: Sign in

See [Authentication](#authentication) below for the two ways to sign in (subscription or API key).

## Authentication

There are two ways to authenticate. Both store the key in `/homeassistant/.vibe/.env`, which persists across add-on restarts and is included in HA backups. You only do this once.

### Option A: Sign in with your Mistral subscription (recommended)

Use this to log in with your Mistral account — the same subscription you already pay for, like the Claude Code add-on.

1. Open the add-on web UI from the sidebar
2. Run `login` (or `vibe-login`) in the terminal
3. The script prints a sign-in URL — select it in the terminal and copy with **Ctrl+Shift+C**
4. Open the URL in any browser (on your phone or PC), sign in with your Mistral account and approve the Vibe CLI access
5. Back in the add-on terminal, the script detects the completed sign-in automatically and stores the key

> **Why not `vibe --setup`?** The built-in browser sign-in of `vibe --setup` cannot work inside a container (there is no browser). `vibe-login` runs the exact same Mistral sign-in flow, but prints the URL as copyable text instead of opening a browser.

### Option B: Use an API key

Works with a subscription, the free tier, or pay-as-you-go. Get a key from **[console.mistral.ai](https://console.mistral.ai)**.

- **Via the add-on configuration (easiest):** paste the key into the `mistral_api_key` option (Settings → Add-ons → Vibe Code → Configuration) and restart. The add-on stores it in `/homeassistant/.vibe/.env` with restrictive permissions (`chmod 600`).
- **Via the terminal:** run `vibe --setup` and choose the API-key option (not the browser link). Paste in a web terminal uses **Ctrl+Shift+V** (or right-click), not Ctrl+V.

## Models

### Automatic model discovery (default)

With the `auto_models` option enabled (default: `true`), the add-on fetches the live model list from the Mistral API at every start and registers new coding/agentic models automatically. When Mistral adds a new model (like Z.ai GLM 5.3), it appears in your `/model` picker after the next add-on restart — no manual steps needed.

### The `models` menu (manual selection)

Want full control? Run `models` (or `vibe-models`) in the add-on terminal:

```
$ models
============================================================
MISTRAL MODELS
============================================================

Already registered (available via /model):
  zai-glm-5-3 *
  mistral-vibe-cli-latest

Available on the API but not yet registered:
   1. devstral-small-latest *
   2. magistral-medium-latest
   ...

  * = recommended coding/agentic model

Numbers to add (comma-separated, 'a' = all, Enter = quit): 1
```

Pick numbers (e.g. `1,3`), `a` for all, or press Enter to quit. Registered models appear in the CLI's `/model` picker immediately (run `/reload` in an active session).

Other modes:

- `vibe-models --list` — print every model currently available on the API
- `vibe-models --sync` — non-interactive: register all new recommended coding models

### Setting the active model

- **Per session:** run `/model` inside the Vibe CLI and pick from the list
- **At startup:** set the `active_model` option in the add-on configuration to a model alias (e.g. `glm-5.3`)

### Registering models with full details (`extra_models`)

The `extra_models` option registers models with explicit settings — useful for prices (keeps `vibe-stats` accurate) or custom providers:

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

- `name` — the model ID on the provider API (`zai-glm-5-3` for Mistral-hosted GLM 5.3)
- `alias` — the short name used to select the model
- `input_price` / `output_price` — per million tokens, for cost estimates
- `thinking` — reasoning effort: `off`, `low`, `medium`, `high` or `max`
- `provider` — defaults to `mistral`; any OpenAI-compatible provider works

Restart the add-on after changing model options.

## Add-on configuration

| Option | Default | Description |
|---|---|---|
| `mistral_api_key` | `""` | Mistral API key; saved to `/homeassistant/.vibe/.env` at startup. Leave empty if you signed in with `vibe-login`. |
| `enable_mcp` | `true` | Register the `homeassistant` MCP server with Vibe so it can query entities, states and automations |
| `auto_models` | `true` | At startup, automatically register new Mistral-hosted coding models found on the API |
| `active_model` | `""` | Model alias to activate at startup (e.g. `glm-5.3`). Empty = keep the CLI default |
| `extra_models` | `[]` | Additional models to register with explicit settings (see [Models](#models)) |
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
| `login` | `vibe-login` | Sign in with your Mistral subscription |
| `models` | `vibe-models` | Interactive model picker |
| `stats` | `vibe-stats` | Token usage and cost overview |
| `ha-config` | `cd /homeassistant` | Jump to the HA configuration directory |
| `ha-logs` | `ha core logs \| tail -100` | Show recent Home Assistant logs |

### Token usage and costs

Run `stats` (or `vibe-stats`) in the add-on terminal to see aggregated token usage and estimated costs across all logged Vibe sessions:

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
├── README.md                # English documentation
├── README.nl.md             # Dutch documentation
└── vibecode/                # The Vibe Code add-on
    ├── config.yaml          # Add-on manifest (options, schema, ingress)
    ├── build.yaml           # Build images per architecture
    ├── Dockerfile           # Alpine + Python + Vibe CLI + ttyd + tmux + hass-mcp
    ├── run.sh               # Startup script: env, API key, models, MCP, ttyd
    ├── vibe-stats           # Token usage / cost aggregation command
    ├── vibe-login           # Subscription sign-in command
    ├── vibe-models          # Interactive model picker / sync command
    ├── CHANGELOG.md
    └── rootfs/root/         # Shell and tmux configuration
```

## Troubleshooting

**Login and authentication**

- **`vibe` asks for login every restart** — make sure you either ran `login`, set `mistral_api_key` in the add-on configuration, or completed `vibe --setup`. All write to `/homeassistant/.vibe`, which persists across restarts.
- **Browser sign-in link inside `vibe --setup` does not work** — expected inside a container; use `login` instead, which prints the URL as copyable text.
- **`login` prints a URL but nothing happens** — the URL is only valid for a few minutes. Copy it with Ctrl+Shift+C, open it in a browser, complete the sign-in, and wait for the script to confirm.
- **Cannot paste in the terminal** — use **Ctrl+Shift+V** or right-click → Paste. Ctrl+V does not work in web terminals.

**Models**

- **A new Mistral model is missing** — restart the add-on with `auto_models: true`, or run `models` to pick it manually. Check `vibe-models --list` to see everything the API offers.
- **Model costs show as $0.0000 in `stats`** — the price of that model is not known to the add-on. Add it to `extra_models` with `input_price`/`output_price`.
- **Switching models inside a session** — use the CLI's `/model` command; run `/reload` after registering new models.

**General**

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
