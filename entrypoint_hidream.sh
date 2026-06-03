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
echo "[INFO] KSS Fast-Boot Entrypoint Started (HiDream)"
echo "[INFO] Mounting HiDream model..."
mkdir -p /workspace/HiDream-O1/models
rclone mount r2:kss-storage/hidream /workspace/HiDream-O1/models --vfs-cache-mode full --daemon
echo "[INFO] Starting HiDream WebUI..."
cd /workspace/HiDream-O1
nohup python app.py --port 7860 > /workspace/hidream_ui.log 2>&1 &
echo "[INFO] Setup complete. Waiting indefinitely..."
) > /workspace/boot_setup.log 2>&1 &

echo "[INFO] Boot setup is running in background. Check /workspace/boot_setup.log for details."
sleep infinity
