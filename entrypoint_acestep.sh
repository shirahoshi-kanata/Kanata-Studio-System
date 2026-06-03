#!/bin/bash
# Inject RunPod SSH Public Key
if [[ -n "$PUBLIC_KEY" ]]; then
    mkdir -p /root/.ssh
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
fi
/usr/sbin/sshd
echo "[INFO] Starting Robust KSS Entrypoint"

(
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
) > /workspace/boot_setup.log 2>&1 &

echo "[INFO] Boot setup is running in background. Check /workspace/boot_setup.log for details."
sleep infinity
