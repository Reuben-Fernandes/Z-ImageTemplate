#!/bin/bash
#
# Z Image Turbo Pod start script
#

set -e

COMFYUI_DIR=/workspace/ComfyUI
MIRROR="ReubenF10/ComfyUI-Models"

echo ""
echo "########################################"
echo "#       Z Image Turbo - Starting      #"
echo "########################################"
echo ""

if [[ -z "$HF_TOKEN" ]]; then
    echo "ERROR: HF_TOKEN not set. Add it as a RunPod environment variable."
    exit 1
fi

export HF_TOKEN
export HF_XET_HIGH_PERFORMANCE=1

# ── Download Models ──────────────────────────────────────────────
echo "  → Checking models..."

python3 << PYEOF
import os, shutil
from huggingface_hub import hf_hub_download

token = os.environ["HF_TOKEN"]
mirror = "$MIRROR"
base = "$COMFYUI_DIR/models"

models = [
    ("diffusion_models/z_image_turbo_bf16.safetensors", "diffusion_models"),
    ("text_encoders/qwen_3_4b.safetensors", "text_encoders"),
    ("vae/ae.safetensors", "vae"),
]

for filename, dest_folder in models:
    save_name = filename.split("/")[-1]
    dest = os.path.join(base, dest_folder, save_name)
    if os.path.exists(dest):
        print(f"  ⏭ Already exists: {save_name}")
        continue
    os.makedirs(os.path.join(base, dest_folder), exist_ok=True)
    print(f"  → Downloading: {save_name}")
    path = hf_hub_download(
        repo_id=mirror,
        filename=filename,
        token=token,
        local_dir="/tmp/hf_dl",
        local_dir_use_symlinks=False
    )
    shutil.move(path, dest)
    print(f"  ✓ Saved: {save_name}")

print("")
print("✓ All models ready")
PYEOF

# ── Download Workflows ───────────────────────────────────────────
echo "  → Downloading workflows..."
mkdir -p "$COMFYUI_DIR/user/default/workflows"
curl -fsSL https://raw.githubusercontent.com/Reuben-Fernandes/ComfyUI-Workflows/main/Z_Image_Turbo_Generation.json \
    -o "$COMFYUI_DIR/user/default/workflows/Z_Image_Turbo_Generation.json" && echo "  ✓ Z_Image_Turbo_Generation.json" || true

# ── Launch ComfyUI ───────────────────────────────────────────────
echo "  → Launching ComfyUI on port 8188..."
echo ""
exec python3 "$COMFYUI_DIR/main.py" \
    --listen 0.0.0.0 \
    --port 8188 \
    --enable-cors-header
