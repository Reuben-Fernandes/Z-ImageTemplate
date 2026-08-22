# ── Base ─────────────────────────────────────────────────────────
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
ENV HF_XET_HIGH_PERFORMANCE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /workspace

# ── System Dependencies ──────────────────────────────────────────
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-dev \
        git \
        git-lfs \
        ffmpeg \
        curl \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/lib/python3.12/EXTERNALLY-MANAGED

# ── PyTorch (pinned to cu128) ─────────────────────────────────────
RUN pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128 \
    --quiet

# ── ComfyUI ──────────────────────────────────────────────────────
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
RUN pip install -r /workspace/ComfyUI/requirements.txt --quiet

# ── Python Dependencies ──────────────────────────────────────────
RUN pip install \
        "huggingface_hub[cli]" \
        --quiet

# ── Custom Nodes ─────────────────────────────────────────────────
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager && \
    git clone https://github.com/rgthree/rgthree-comfy && \
    git clone https://github.com/chrisgoringe/cg-use-everywhere
RUN for dir in /workspace/ComfyUI/custom_nodes/*/; do \
        if [ -f "$dir/requirements.txt" ]; then \
            pip install -r "$dir/requirements.txt" --quiet || true; \
        fi \
    done

# ── Ports ────────────────────────────────────────────────────────
EXPOSE 8188
EXPOSE 8888

# ── Start Script ─────────────────────────────────────────────────
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
