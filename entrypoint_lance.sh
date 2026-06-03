#!/bin/bash
# Inject RunPod SSH Public Key
if [[ -n "$PUBLIC_KEY" ]]; then
    mkdir -p /root/.ssh
    echo "$PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
fi
mkdir -p /var/run/sshd
service ssh start
echo "[INFO] Starting Robust KSS Entrypoint"

(
set -e
echo "[INFO] KSS Fast-Boot Entrypoint Started (Lance)"
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
) > /workspace/boot_setup.log 2>&1 &

echo "[INFO] Boot setup is running in background. Check /workspace/boot_setup.log for details."
sleep infinity
