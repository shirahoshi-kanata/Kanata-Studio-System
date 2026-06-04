#!/bin/bash
set -e

echo "[INFO] Starting Robust KSS Entrypoint..."

# 1. RunPodの環境変数から公開鍵を受け取り、SSHログインを許可する（超重要）
if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "[INFO] SSH Public Key injected."
fi

# 2. SSHデーモンの起動（エラーが出てもスクリプトを止めないように `|| true` をつける）
/usr/sbin/sshd || true
echo "[INFO] SSH Daemon started."

# 3. バックグラウンドで必要な準備を走らせる（隔離スペース）
(
    echo "[INFO] Background setup is running..."
) > /workspace/boot_setup.log 2>&1 &

# 4. メインプロセス（PID 1）を永遠に眠らせる
echo "[INFO] Pod is now indestructible. Sleeping infinity."
sleep infinity
