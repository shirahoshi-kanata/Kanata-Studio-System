#!/bin/bash
set -e
echo "[INFO] KSS Fast-Boot Entrypoint Started (Lance)"
if [ -n "$RCLONE_CONF_B64" ]; then
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONF_B64" | base64 -d > ~/.config/rclone/rclone.conf
fi
echo "[INFO] Mounting Lance model..."
mkdir -p /workspace/Lance/models
rclone mount r2:kss-storage/lance /workspace/Lance/models --vfs-cache-mode full --daemon
echo "[INFO] Starting Lance WebUI..."
cd /workspace/Lance
# fallback between app.py and lance_gradio.py based on what exists
if [ -f "lance_gradio.py" ]; then
    nohup python lance_gradio.py > /workspace/lance_ui.log 2>&1 &
else
    nohup python app.py --port 8000 > /workspace/lance_ui.log 2>&1 &
fi
echo "[INFO] Setup complete. Waiting indefinitely..."
sleep infinity
