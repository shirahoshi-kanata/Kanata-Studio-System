FROM runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04

# ==========================================================
# KSS (Kanata Studio System) Fast-Boot Docker Image
# ==========================================================

# 1. 依存関係のインストール
RUN apt-get update && apt-get install -y \
    wget curl git unzip ffmpeg libgl1-mesa-glx fuse3 \
    && rm -rf /var/lib/apt/lists/*

# 2. rcloneのインストール
RUN curl https://rclone.org/install.sh | bash

# 3. Pythonパッケージの更新
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir transformers diffusers accelerate gradio huggingface_hub

# 4. WebUIの事前焼き込み (Bake)
WORKDIR /workspace

# 4-1. ComfyUI & ACE-Step
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/Urabewe/ComfyUI-AudioTools.git && \
    git clone https://github.com/jeankassio/ComfyUI_MusicTools.git && \
    git clone https://github.com/billwuhao/ComfyUI_ACE-Step.git

# 4-2. HiDream
RUN git clone https://github.com/HiDream-ai/HiDream-O1-Image.git /workspace/HiDream-O1

# 4-3. Lance
RUN git clone https://github.com/bytedance/Lance.git /workspace/Lance

# 5. エントリポイントの設定
COPY kanata_studio_ui.py /workspace/kanata_studio_ui.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["sleep", "infinity"]