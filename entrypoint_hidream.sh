#!/bin/bash
set -e
echo "[INFO] KSS Fast-Boot Entrypoint Started (HiDream)"
if [ -n "$RCLONE_CONF_B64" ]; then
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONF_B64" | base64 -d > ~/.config/rclone/rclone.conf
fi
echo "[INFO] Mounting HiDream model..."
mkdir -p /workspace/HiDream-O1/models
rclone mount r2:kss-storage/hidream /workspace/HiDream-O1/models --vfs-cache-mode full --daemon
echo "[INFO] Starting HiDream WebUI..."
cd /workspace/HiDream-O1
nohup python app.py --port 7860 > /workspace/hidream_ui.log 2>&1 &
echo "[INFO] Setup complete. Waiting indefinitely..."
sleep infinity
