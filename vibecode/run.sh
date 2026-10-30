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
if [ "$VIBE_OK" = "true" ] && [ "$ENABLE_MCP" = "true" ]; then
    mkdir -p /root/.vibe
    if [ ! -f "$CONFIG_FILE" ]; then
        printf '' > "$CONFIG_FILE"
    fi
    if ! grep -q '^\[\[mcp_servers\]\]' "$CONFIG_FILE" || ! grep -q 'name = "homeassistant"' "$CONFIG_FILE"; then
        if grep -q '^\[\[mcp_servers\]\]' "$CONFIG_FILE"; then
            echo '[WARN] An MCP server entry already exists in ~/.vibe/config.toml; not appending homeassistant'
        fi
        cat >> "$CONFIG_FILE" << 'EOF'

[[mcp_servers]]
name = "homeassistant"
transport = "stdio"
command = "hass-mcp"
EOF
        echo '[INFO] MCP configured with Home Assistant integration'
    fi
elif [ "$ENABLE_MCP" = "true" ]; then
    echo '[WARN] MCP is enabled but was skipped: the vibe CLI is not responding'
else
    echo '[INFO] MCP disabled'
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
