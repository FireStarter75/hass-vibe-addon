#!/bin/bash
set -e

export HA_TOKEN="$SUPERVISOR_TOKEN"
export HA_URL="http://supervisor/core"

PERSIST_DIR=/homeassistant/.vibe
mkdir -p "$PERSIST_DIR" /root/.config

if [ ! -L /root/.vibe ]; then
    rm -rf /root/.vibe
    ln -s "$PERSIST_DIR" /root/.vibe
fi

FONT_SIZE=$(jq -r '.terminal_font_size // 14' /data/options.json)
THEME=$(jq -r '.terminal_theme // "dark"' /data/options.json)
SESSION_PERSIST=$(jq -r 'if .session_persistence == null then true else .session_persistence end' /data/options.json)
WORK_DIR=$(jq -r '.working_directory // "/homeassistant"' /data/options.json)
ENABLE_MCP=$(jq -r 'if .enable_mcp == null then true else .enable_mcp end' /data/options.json)
AUTO_UPDATE=$(jq -r '.auto_update_vibe // false' /data/options.json)
API_KEY=$(jq -r '.mistral_api_key // ""' /data/options.json)
ACTIVE_MODEL=$(jq -r '.active_model // ""' /data/options.json)
EXTRA_MODELS=$(jq -r '.extra_models // ""' /data/options.json)

if [ -n "$API_KEY" ]; then
    mkdir -p "$PERSIST_DIR"
    touch "$PERSIST_DIR/.env"
    if grep -q '^MISTRAL_API_KEY=' "$PERSIST_DIR/.env" 2>/dev/null; then
        sed -i "s|^MISTRAL_API_KEY=.*$|MISTRAL_API_KEY=$API_KEY|" "$PERSIST_DIR/.env"
    else
        printf 'MISTRAL_API_KEY=%s\n' "$API_KEY" >> "$PERSIST_DIR/.env"
    fi
    chmod 600 "$PERSIST_DIR/.env"
    echo '[INFO] Mistral API key saved to /homeassistant/.vibe/.env'
fi

if [ "$AUTO_UPDATE" = "true" ]; then
    echo "[WARN] auto_update_vibe=true; updating the CLI may install a version that was not verified at build time"
    pip3 install --break-system-packages --upgrade mistral-vibe \
        || echo "[WARN] Update failed; keeping the installed version"
fi

if timeout 30 vibe --version < /dev/null > /dev/null 2>&1; then
    VIBE_OK=true
    echo "[INFO] Vibe Code $(cat /etc/vibe-code-version 2>/dev/null || echo unknown) (verified at build time)"
else
    VIBE_OK=false
    echo "[ERROR] vibe CLI did not respond within 30s"
    echo "[ERROR] The terminal will still start so you can debug from inside the add-on"
fi

CONFIG_FILE=/root/.vibe/config.toml
mkdir -p /root/.vibe
if [ ! -f "$CONFIG_FILE" ]; then
    printf '' > "$CONFIG_FILE"
fi
if ! python3 -c "import tomllib; tomllib.load(open('$CONFIG_FILE','rb'))" 2>/dev/null; then
    echo '[ERROR] ~/.vibe/config.toml is invalid TOML; attempting repair from backup'
    if [ -f "$CONFIG_FILE.bak" ] && python3 -c "import tomllib; tomllib.load(open('$CONFIG_FILE.bak','rb'))" 2>/dev/null; then
        cp "$CONFIG_FILE.bak" "$CONFIG_FILE"
        echo '[INFO] Restored config.toml from the last known-good backup'
    else
        mv "$CONFIG_FILE" "$CONFIG_FILE.corrupt" 2>/dev/null || true
        printf '' > "$CONFIG_FILE"
        echo '[WARN] No valid backup found; the corrupt file was moved to config.toml.corrupt and a fresh one was created'
    fi
fi
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
if [ "$VIBE_OK" = "true" ] && [ "$ENABLE_MCP" = "true" ]; then
    HA_MCP_CONFIGURED=false
    if grep -q 'name = "homeassistant"' "$CONFIG_FILE" 2>/dev/null; then
        HA_MCP_CONFIGURED=true
    elif grep -qE '^(mcp_servers)[[:space:]]*=' "$CONFIG_FILE" 2>/dev/null; then
        echo '[WARN] An inline mcp_servers array exists in ~/.vibe/config.toml; add the homeassistant server there manually instead of the add-on appending one'
    else
        cat >> "$CONFIG_FILE" << 'EOF'

[[mcp_servers]]
name = "homeassistant"
transport = "stdio"
command = "hass-mcp"
EOF
        if python3 -c "import tomllib; tomllib.load(open('$CONFIG_FILE','rb'))" 2>/dev/null; then
            HA_MCP_CONFIGURED=true
            cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
            echo '[INFO] MCP configured with Home Assistant integration'
        else
            python3 - "$CONFIG_FILE" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    content = f.read()
marker = '\n[[mcp_servers]]\nname = "homeassistant"'
idx = content.find(marker)
if idx != -1:
    with open(path, 'w') as f:
        f.write(content[:idx].rstrip() + '\n')
PYEOF
            echo '[ERROR] Appending the homeassistant MCP server made config.toml invalid; rolled back. Add it manually.'
        fi
    fi
elif [ "$ENABLE_MCP" = "true" ]; then
    echo '[WARN] MCP is enabled but was skipped: the vibe CLI is not responding'
else
    echo '[INFO] MCP disabled'
fi

if [ "$VIBE_OK" = "true" ] && [ -n "$EXTRA_MODELS" ] && [ "$EXTRA_MODELS" != "null" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak" 2>/dev/null || true
    python3 - "$CONFIG_FILE" /data/options.json <<'PYEOF' && cp "$CONFIG_FILE" "$CONFIG_FILE.bak" \
        || { cp "$CONFIG_FILE.bak" "$CONFIG_FILE" 2>/dev/null || true; echo '[ERROR] The extra_models option produced invalid TOML; rolled back. Check your add-on configuration.'; }
import json, sys, tomllib, tomli_w
config_path, options_path = sys.argv[1], sys.argv[2]
with open(options_path) as f:
    options = json.load(f)
extras = options.get('extra_models') or []
if not isinstance(extras, list):
    extras = []
with open(config_path, 'rb') as f:
    data = tomllib.load(f)
existing = {(m.get('name'), m.get('alias')) for m in data.get('models', [])}
for m in extras:
    entry = {
        'name': str(m.get('name', '')),
        'provider': str(m.get('provider', 'mistral')),
        'alias': str(m.get('alias') or m.get('name', '')),
    }
    if 'input_price' in m:
        entry['input_price'] = m['input_price']
    if 'output_price' in m:
        entry['output_price'] = m['output_price']
    if m.get('thinking'):
        entry['thinking'] = str(m['thinking'])
    key = (entry['name'], entry['alias'])
    if key in existing:
        print(f"[INFO] Model '{entry['alias']}' already registered; skipping")
        continue
    data.setdefault('models', []).append(entry)
    existing.add(key)
if 'models' in data:
    data['models'] = sorted(data['models'], key=lambda m: m.get('alias', ''))
with open(config_path, 'wb') as f:
    tomli_w.dump(data, f)
print('[INFO] Extra models registered in ~/.vibe/config.toml')
PYEOF
fi
if [ "$VIBE_OK" = "true" ] && [ -n "$ACTIVE_MODEL" ] && [ "$ACTIVE_MODEL" != "null" ]; then
    if grep -q "^active_model[[:space:]]*=[[:space:]]*\"$ACTIVE_MODEL\"" "$CONFIG_FILE" 2>/dev/null; then
        echo "[INFO] Active model: $ACTIVE_MODEL"
    else
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak" 2>/dev/null || true
        if grep -q '^active_model' "$CONFIG_FILE" 2>/dev/null; then
            sed -i "s|^active_model[[:space:]]*=.*$|active_model = \"$ACTIVE_MODEL\"|" "$CONFIG_FILE"
        else
            sed -i "1i active_model = \"$ACTIVE_MODEL\"" "$CONFIG_FILE"
        fi
        if python3 -c "import tomllib; tomllib.load(open('$CONFIG_FILE','rb'))" 2>/dev/null; then
            cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
            echo "[INFO] Active model set to $ACTIVE_MODEL"
        else
            cp "$CONFIG_FILE.bak" "$CONFIG_FILE" 2>/dev/null || true
            echo '[ERROR] Could not set the active model; rolled back.'
        fi
    fi
fi


if [ "$THEME" = "dark" ]; then
    COLORS='background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc'
else
    COLORS='background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78'
fi

if [ "$SESSION_PERSIST" = "true" ]; then
    SHELL_CMD='tmux new-session -A -s vibe'
else
    SHELL_CMD='bash --login'
fi

if [ ! -d "$WORK_DIR" ]; then
    echo "[WARN] working_directory '$WORK_DIR' does not exist; falling back to /homeassistant"
    WORK_DIR=/homeassistant
fi

cd "$WORK_DIR"

exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
    -t fontSize="$FONT_SIZE" \
    -t fontFamily=Monaco,Consolas,monospace \
    -t scrollback=20000 \
    -t "theme=$COLORS" \
    $SHELL_CMD
