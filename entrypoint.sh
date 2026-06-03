#!/bin/bash
set -e

echo "[INFO] KSS Fast-Boot Entrypoint Started"

# 1. R2の認証情報セットアップ
if [ -n "$RCLONE_CONF_B64" ]; then
    echo "[INFO] Decoding RCLONE_CONF_B64..."
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONF_B64" | base64 -d > ~/.config/rclone/rclone.conf
else
    echo "[WARNING] RCLONE_CONF_B64 is not set!"
fi

# 2. 実行モデルごとのマウントおよび起動処理
if [ "$RUN_MODEL" = "AceStep" ]; then
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
    
elif [ "$RUN_MODEL" = "HiDream" ]; then
    echo "[INFO] Mounting HiDream model..."
    mkdir -p /workspace/HiDream-O1/models
    rclone mount r2:kss-storage/hidream /workspace/HiDream-O1/models --vfs-cache-mode full --daemon
    
    echo "[INFO] Starting HiDream WebUI..."
    cd /workspace/HiDream-O1
    python webui.py --port 7860 &
    
elif [ "$RUN_MODEL" = "Lance" ]; then
    echo "[INFO] Mounting Lance model..."
    mkdir -p /workspace/Lance/models
    rclone mount r2:kss-storage/lance /workspace/Lance/models --vfs-cache-mode full --daemon
    
    echo "[INFO] Starting Lance WebUI..."
    cd /workspace/Lance
    python app.py --port 8000 &
    
else
    echo "[WARNING] Unknown or missing RUN_MODEL variable. Sleeping."
fi

# コンテナが終了しないよう待機
echo "[INFO] Setup complete. Waiting indefinitely..."
sleep infinity
