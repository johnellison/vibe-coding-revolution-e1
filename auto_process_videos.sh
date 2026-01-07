#!/bin/bash
# Auto-process videos dropped in this folder
# This script watches for new MP4 files and automatically crops them to 1080p

WATCH_DIR="$(dirname "$0")"
PROCESSED_DIR="$WATCH_DIR/processed_1080p"
LOG_FILE="$WATCH_DIR/video_processing.log"

# Create processed directory if it doesn't exist
mkdir -p "$PROCESSED_DIR"

echo "========================================" >> "$LOG_FILE"
echo "Starting video processor: $(date)" >> "$LOG_FILE"
echo "Watching directory: $WATCH_DIR" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

process_video() {
    local INPUT="$1"
    local FILENAME=$(basename "$INPUT" .mp4)
    local OUTPUT="$PROCESSED_DIR/${FILENAME}_1080p.mp4"

    # Skip if it's a 4K video
    if [[ "$FILENAME" =~ _4K_ ]]; then
        echo "[$(date)] Skipping (4K video): $FILENAME" | tee -a "$LOG_FILE"
        return
    fi

    # Skip if in 4K folder
    if [[ "$INPUT" =~ /4K/ ]]; then
        echo "[$(date)] Skipping (in 4K folder): $FILENAME" | tee -a "$LOG_FILE"
        return
    fi

    # Check if already processed
    if [ -f "$OUTPUT" ]; then
        echo "[$(date)] Skipping (already processed): $FILENAME" | tee -a "$LOG_FILE"
        return
    fi

    echo "[$(date)] Processing: $FILENAME" | tee -a "$LOG_FILE"

    # Crop from center: 1920x1088 -> 1920x1080
    ffmpeg -i "$INPUT" \
        -vf "crop=1920:1080:0:4" \
        -c:v libx264 \
        -preset medium \
        -crf 18 \
        -c:a copy \
        "$OUTPUT" 2>&1 | grep -E '(frame=|error|Error)' >> "$LOG_FILE"

    if [ $? -eq 0 ]; then
        echo "[$(date)] ✓ Successfully created: ${FILENAME}_1080p.mp4" | tee -a "$LOG_FILE"
    else
        echo "[$(date)] ✗ Error processing: $FILENAME" | tee -a "$LOG_FILE"
    fi
}

# Process any existing videos first
echo "Checking for existing videos to process..."
for video in "$WATCH_DIR"/*.mp4; do
    if [ -f "$video" ] && [[ ! "$video" =~ _1080p\.mp4$ ]] && [[ ! "$video" =~ _4K_ ]]; then
        process_video "$video"
    fi
done

echo ""
echo "========================================"
echo "Video processor is now running!"
echo "Drop MP4 files in this folder to auto-process them to 1080p"
echo "Processed videos will be saved to: $PROCESSED_DIR"
echo "Press Ctrl+C to stop"
echo "========================================"
echo ""

# Watch for new files (requires fswatch on macOS)
if command -v fswatch &> /dev/null; then
    fswatch -0 -e ".*" -i "\\.mp4$" "$WATCH_DIR" | while read -d "" file; do
        if [[ ! "$file" =~ _1080p\.mp4$ ]] && [[ ! "$file" =~ _4K_ ]] && [[ ! "$file" =~ /4K/ ]] && [ -f "$file" ]; then
            # Wait a bit to ensure file is fully copied
            sleep 2
            process_video "$file"
        fi
    done
else
    echo "⚠ fswatch not found. Install it with: brew install fswatch"
    echo "For now, manually run: ./crop_to_1080p.sh your_video.mp4"
fi
