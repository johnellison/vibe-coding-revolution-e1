#!/bin/bash
# Interactive organizer for screen recordings
# Helps rename and move recordings to proper folder

SOURCE_DIR="$HOME/Desktop"
DEST_DIR="Assets/B-Roll/Screen-Recordings"
LOG_FILE="$DEST_DIR/organization_log.txt"

# Create destination if needed
mkdir -p "$DEST_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Find today's recordings (or all .mov files from this week)
echo ""
echo "=========================================="
echo "🎬 SCREEN RECORDING ORGANIZER"
echo "=========================================="
echo ""
echo "Finding screen recordings from today..."

# Get recordings from today, sorted by time
RECORDINGS=($(ls -t "$SOURCE_DIR"/"Screen Recording 2026-01-07"*.mov 2>/dev/null))

if [ ${#RECORDINGS[@]} -eq 0 ]; then
    echo "No recordings found from today. Checking all recent .mov files..."
    RECORDINGS=($(ls -t "$SOURCE_DIR"/*.mov 2>/dev/null | head -20))
fi

TOTAL=${#RECORDINGS[@]}

if [ $TOTAL -eq 0 ]; then
    echo "❌ No .mov files found on Desktop!"
    exit 1
fi

echo "Found $TOTAL recordings to organize"
echo ""

ORGANIZED=0
SKIPPED=0

for i in "${!RECORDINGS[@]}"; do
    FILE="${RECORDINGS[$i]}"
    FILENAME=$(basename "$FILE")
    FILESIZE=$(ls -lh "$FILE" | awk '{print $5}')

    echo ""
    echo "=========================================="
    echo -e "${BLUE}Recording $((i+1)) of $TOTAL${NC}"
    echo "=========================================="
    echo ""
    echo "File: $FILENAME"
    echo "Size: $FILESIZE"
    echo ""
    echo "(Press 'p' below to preview this file)"
    echo ""

    # Ask what this recording is
    echo "What is this recording?"
    echo ""
    echo "  1) Pravos.xyz (music app demo)"
    echo "  2) Vibrana.ai (AI demo)"
    echo "  3) Mrktr (marketing tool)"
    echo "  4) Claude Code (terminal session)"
    echo "  5) VS Code / Cursor (code editor)"
    echo "  6) Generic coding b-roll (typing, terminal, git)"
    echo "  7) Other / Custom name"
    echo "  s) Skip this file"
    echo "  p) Preview in QuickTime first"
    echo "  q) Quit organizer"
    echo ""

    while true; do
        read -p "Choice: " choice

        case $choice in
            1)
                NEW_NAME="pravos_demo_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            2)
                NEW_NAME="vibrana_demo_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            3)
                NEW_NAME="mrktr_demo_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            4)
                NEW_NAME="claude_code_session_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            5)
                NEW_NAME="vscode_coding_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            6)
                echo "What kind of b-roll? (e.g., typing, terminal, git_commit):"
                read -p "Type: " broll_type
                NEW_NAME="broll_${broll_type}_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            7)
                echo "Enter custom name (without .mov):"
                read -p "Name: " custom_name
                NEW_NAME="${custom_name}_$(date -r "$FILE" '+%Y%m%d_%H%M%S').mov"
                break
                ;;
            p|P)
                echo "Opening preview..."
                open "$FILE"
                echo "Press Enter when ready to choose..."
                read
                continue
                ;;
            s|S)
                echo "⏭️  Skipping..."
                ((SKIPPED++))
                NEW_NAME=""
                break
                ;;
            q|Q)
                echo ""
                echo "Quitting organizer."
                echo "Organized: $ORGANIZED | Skipped: $SKIPPED"
                exit 0
                ;;
            *)
                echo "Invalid choice. Try again."
                continue
                ;;
        esac
    done

    # Skip if user chose to skip
    if [ -z "$NEW_NAME" ]; then
        continue
    fi

    # Move and rename
    DEST_PATH="$DEST_DIR/$NEW_NAME"

    echo ""
    echo "Moving: $FILENAME"
    echo "    To: $NEW_NAME"

    mv "$FILE" "$DEST_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Organized!${NC}"
        log "Organized: $FILENAME -> $NEW_NAME"
        ((ORGANIZED++))
    else
        echo "❌ Failed to move file"
        ((SKIPPED++))
    fi
done

echo ""
echo "=========================================="
echo "✅ ORGANIZATION COMPLETE!"
echo "=========================================="
echo ""
echo "Results:"
echo "  Organized: $ORGANIZED files"
echo "  Skipped: $SKIPPED files"
echo ""
echo "Recordings saved to:"
echo "  $DEST_DIR/"
echo ""
echo "View them:"
ls -lh "$DEST_DIR"/*.mov 2>/dev/null | tail -20 | awk '{print "  " $9 " (" $5 ")"}'
echo ""
log "=========================================="
log "Organization complete: $ORGANIZED organized, $SKIPPED skipped"
