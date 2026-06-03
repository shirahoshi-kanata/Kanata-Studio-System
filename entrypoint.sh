#!/bin/bash
set -e
echo "=========================================="
echo " KSS AI Pipeline - Docker Container Start"
echo "=========================================="
# 1. Generate rclone configuration dynamically
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
# 2. Dynamic Model Pulling (zero egress cost from R2 to RunPod)
# Depending on the RUN_MODEL environment variable, we pull the specific model.
# If RUN_MODEL is not set, we skip to save time.
if [ "$RUN_MODEL" = "HiDream" ]; then
    echo "[INFO] Mounting HiDream model from R2..."
    rclone mount r2:kss-storage/HiDream /workspace/models/HiDream --vfs-cache-mode full --daemon
elif [ "$RUN_MODEL" = "Lance" ]; then
    echo "[INFO] Mounting Lance model from R2..."
    rclone mount r2:kss-storage/lance /workspace/models/Lance --vfs-cache-mode full --daemon
elif [ "$RUN_MODEL" = "AceStep" ]; then
    echo "[INFO] Mounting AceStep model from R2..."
    rclone mount r2:kss-storage/acestep /workspace/models/AceStep --vfs-cache-mode full --daemon
elif [ "$RUN_MODEL" = "ALL" ]; then
    echo "[INFO] Mounting ALL models from R2..."
    rclone mount r2:kss-storage /workspace/models --vfs-cache-mode full --daemon
else
    echo "[INFO] RUN_MODEL not specified or set to None. Skipping model mount."
fi
echo "[INFO] System initialization complete. Handing over to CMD."
echo "=========================================="
# Execute the CMD passed to the container (e.g. sleep infinity, jupyter, etc.)
exec "$@"
