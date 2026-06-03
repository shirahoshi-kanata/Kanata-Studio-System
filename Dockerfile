FROM runpod/base:0.4.0-cuda11.8.0

# ==========================================================
# KSS (Kanata Studio System) Base Docker Image
# ==========================================================
# This image contains the necessary tools (rclone, python, ffmpeg)
# but DOES NOT contain the massive model weights.
# Models will be dynamically pulled from R2 upon container start.
# ==========================================================

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    unzip \
    ffmpeg \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Install rclone for R2/GDrive integration
RUN curl https://rclone.org/install.sh | bash

# Setup Python environment (RunPod base already has python, but let's ensure pip is updated)
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install required AI Python packages (e.g. for HiDream/Lance/AceStep)
# Note: Specific requirements can be loaded later, but common ones are here.
RUN pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    transformers \
    diffusers \
    accelerate \
    gradio \
    huggingface_hub

# Create workspace directory
WORKDIR /workspace

# Add our custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The entrypoint handles the dynamic pulling of models from R2
ENTRYPOINT ["/entrypoint.sh"]

# Default command (can be overridden by RunPod to start Jupyter or ComfyUI)
CMD ["sleep", "infinity"]
