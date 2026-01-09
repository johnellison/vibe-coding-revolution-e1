#!/bin/bash
# Fully automated video processor: Crop to 1080p -> Upscale to 4K -> Move to 4K folder
# Usage: ./auto_process_and_upscale.sh

WATCH_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUR_K_DIR="$WATCH_DIR/4K"
VENV_PATH="/Users/iamjohndass/Documents/John Ellison Show/E1 - The Vibe Coding Revolution/Claude E1/venv"
UPSCALE_SCRIPT="/Users/iamjohndass/Documents/John Ellison Show/E1 - The Vibe Coding Revolution/Claude E1/upscale_to_4k.py"
LOG_FILE="$WATCH_DIR/auto_process.log"

# Create 4K directory if it doesn't exist
mkdir -p "$FOUR_K_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

process_video() {
    local INPUT="$1"
    local FILENAME=$(basename "$INPUT" .mp4)
    local TEMP_1080P="${WATCH_DIR}/${FILENAME}_1080p_temp.mp4"
    local FINAL_4K="${FOUR_K_DIR}/${FILENAME}_4K.mp4"

    # Skip if it's already a processed file
    if [[ "$FILENAME" =~ _1080p_temp$ ]] || [[ "$FILENAME" =~ _4K$ ]] || [[ "$FILENAME" =~ _1080p$ ]]; then
        return 0
    fi

    # Skip if ANY 4K version already exists (check all naming patterns)
    local EXISTING_4K=$(find "$FOUR_K_DIR" -maxdepth 1 -name "${FILENAME}*4K*.mp4" -o -name "${FILENAME}*4k*.mp4" 2>/dev/null | head -1)
    if [ -n "$EXISTING_4K" ]; then
        log "⏭️  Skipping (already in 4K): $FILENAME -> $(basename "$EXISTING_4K")"
        return 0
    fi

    log "🎬 Processing: $FILENAME"

    # Step 1: Crop to 1080p
    log "  📐 Cropping to 1080p..."
    ffmpeg -i "$INPUT" \
        -vf "crop=1920:1080:0:4" \
        -c:v libx264 \
        -preset fast \
        -crf 18 \
        -c:a copy \
        "$TEMP_1080P" \
        -y &>/dev/null

    if [ $? -ne 0 ]; then
        log "  ❌ Error cropping: $FILENAME"
        rm -f "$TEMP_1080P"
        return 1
    fi

    log "  ✅ Cropped to 1080p"

    # Step 2: Upscale to 4K using Fal.ai
    log "  🚀 Upscaling to 4K (this may take 1-3 minutes)..."

    source "$VENV_PATH/bin/activate"
    python3 "$UPSCALE_SCRIPT" "$TEMP_1080P" bytedance >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        # Check if 4K file was created in the 4K folder
        local EXPECTED_4K="${FOUR_K_DIR}/${FILENAME}_1080p_temp_4K_bytedance.mp4"
        if [ -f "$EXPECTED_4K" ]; then
            # Rename to final name
            mv "$EXPECTED_4K" "$FINAL_4K"
            log "  ✅ Upscaled to 4K: ${FILENAME}_4K.mp4"

            # Clean up temp 1080p file
            rm -f "$TEMP_1080P"

            # Move original to _original folder
            local ORIGINAL_DIR="${WATCH_DIR}/_original"
            mkdir -p "$ORIGINAL_DIR"
            if [ -f "$INPUT" ]; then
                mv "$INPUT" "$ORIGINAL_DIR/"
                log "  📦 Moved original to _original/"
            fi

            log "✨ COMPLETE: $FILENAME -> ${FILENAME}_4K.mp4"
            return 0
        else
            log "  ⚠️  4K file not found at expected location"
            rm -f "$TEMP_1080P"
            return 1
        fi
    else
        log "  ❌ Error upscaling: $FILENAME"
        rm -f "$TEMP_1080P"
        return 1
    fi
}

# Process all existing videos first
log "=========================================="
log "🎥 Starting automated video processor"
log "Watching: $WATCH_DIR"
log "Output: $FOUR_K_DIR"
log "=========================================="

log "📂 Scanning for videos to process..."

# Find all mp4 files that aren't already processed
for video in "$WATCH_DIR"/*.mp4; do
    if [ -f "$video" ]; then
        process_video "$video"
    fi
done

log "=========================================="
log "✅ All videos processed!"
log "=========================================="
