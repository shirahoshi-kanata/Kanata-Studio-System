#!/bin/bash
set -e
echo "[INFO] KSS Fast-Boot Entrypoint Started (AceStep)"
echo "[INFO] Mounting AceStep model..."
mkdir -p /workspace/ComfyUI/models/checkpoints
rclone mount r2:kss-storage/acestep /workspace/ComfyUI/models/checkpoints --vfs-cache-mode full --daemon
echo "[INFO] Starting ComfyUI backend on port 6006..."
cd /workspace/ComfyUI
nohup python main.py --port 6006 > /workspace/comfyui_backend.log 2>&1 &
echo "[INFO] Waiting for ComfyUI to become ready..."
for i in {1..30}; do
    if curl -s http://localhost:6006 > /dev/null; then
        echo "[INFO] ComfyUI ready! Starting Kanata Studio UI (Gradio)..."
        nohup python /workspace/kanata_studio_ui.py > /workspace/acestep_ui.log 2>&1 &
        break
    fi
    sleep 5
done
echo "[INFO] Setup complete. Waiting indefinitely..."
sleep infinity
