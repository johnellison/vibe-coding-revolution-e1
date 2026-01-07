#!/bin/bash
# Script to crop/scale videos from 1920x1088 to proper 1080p (1920x1080)
# Usage: ./crop_to_1080p.sh input_video.mp4

INPUT="$1"

if [ -z "$INPUT" ]; then
    echo "Usage: $0 <input_video.mp4>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: File '$INPUT' not found"
    exit 1
fi

# Get filename without extension
FILENAME=$(basename "$INPUT" .mp4)

# Check if this is a 4K video - warn before processing
if [[ "$FILENAME" =~ _4K_ ]]; then
    echo "⚠️  WARNING: This appears to be a 4K video!"
    echo "Are you sure you want to crop it to 1080p? This will downscale it."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

OUTPUT="${FILENAME}_1080p.mp4"

echo "Processing: $INPUT"
echo "Output: $OUTPUT"

# Crop from center: 1920x1088 -> 1920x1080 (remove 4 pixels from top and bottom)
ffmpeg -i "$INPUT" \
    -vf "crop=1920:1080:0:4" \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -c:a copy \
    "$OUTPUT"

if [ $? -eq 0 ]; then
    echo "✓ Successfully created: $OUTPUT"
else
    echo "✗ Error processing video"
    exit 1
fi
