#!/bin/bash
set -e
echo "=========================================="
echo " KSS AI Pipeline - Fast Boot Entrypoint"
echo "=========================================="

echo "[INFO] Configuring Rclone for Cloudflare R2..."
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[r2]
type = s3
provider = Cloudflare
access_key_id = f4541e83ebc10be90f4a7aed8b9a8977
secret_access_key = 28da6cd8950e088696d158593b4596879afbd5cdb4859738db858e7928b6f84d
endpoint = https://b1726c7e40c73181a9d4f4447c9ee2f0.r2.cloudflarestorage.com
acl = private
EOF
echo "[INFO] Rclone configured successfully."

# モデルのR2直付けマウントとWebUI起動
if [ "$RUN_MODEL" = "HiDream" ]; then
    echo "[INFO] Mounting HiDream model..."
    mkdir -p /workspace/HiDream-O1/models
    rclone mount r2:kss-storage/hidream /workspace/HiDream-O1/models --vfs-cache-mode full --daemon
    
    echo "[INFO] Starting HiDream WebUI..."
    cd /workspace/HiDream-O1
    export HIDREAM_HOST=0.0.0.0
    export HIDREAM_PORT=7860
    export HIDREAM_MODEL_TYPE=dev
    python app.py &

elif [ "$RUN_MODEL" = "Lance" ]; then
    echo "[INFO] Mounting Lance model..."
    mkdir -p /workspace/Lance/models
    rclone mount r2:kss-storage/lance /workspace/Lance/models --vfs-cache-mode full --daemon
    
    echo "[INFO] Starting Lance WebUI..."
    cd /workspace/Lance
    python lance_gradio.py &

elif [ "$RUN_MODEL" = "AceStep" ]; then
    echo "[INFO] Mounting AceStep model..."
    mkdir -p /workspace/ComfyUI/models/checkpoints
    rclone mount r2:kss-storage/acestep /workspace/ComfyUI/models/checkpoints --vfs-cache-mode full --daemon
    
    echo "[INFO] Starting ComfyUI for AceStep..."
    cd /workspace/ComfyUI
    python main.py --port 6006 &

elif [ "$RUN_MODEL" = "ALL" ]; then
    echo "[INFO] Mounting ALL models..."
    mkdir -p /workspace/models
    rclone mount r2:kss-storage /workspace/models --vfs-cache-mode full --daemon
fi

echo "[INFO] System initialization complete. Handing over to CMD."
echo "=========================================="
exec "$@"
