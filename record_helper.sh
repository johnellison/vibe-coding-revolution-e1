#!/bin/bash
# Screen Recording Helper for E1 - The Vibe Coding Revolution
# Makes it easy to record all required b-roll footage

RECORDINGS_DIR="Assets/B-Roll/Screen-Recordings"
SHOT_LIST="Assets/SCREEN-RECORDING-SHOT-LIST.md"
LOG_FILE="$RECORDINGS_DIR/recording_log.txt"

# Create directories
mkdir -p "$RECORDINGS_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

show_setup_checklist() {
    echo ""
    echo "=========================================="
    echo "🎬 SCREEN RECORDING SETUP CHECKLIST"
    echo "=========================================="
    echo ""
    echo "Before recording, ensure:"
    echo "  [ ] 4K display resolution (or highest available)"
    echo "  [ ] Clean desktop (hide personal files/icons)"
    echo "  [ ] Browser: Hide bookmarks bar, clear extra tabs"
    echo "  [ ] Code editor: Dark theme, clean workspace"
    echo "  [ ] Terminal: Nice color theme"
    echo "  [ ] Do Not Disturb: ENABLED (no notifications)"
    echo "  [ ] Hide menu bar (if possible)"
    echo ""
    read -p "Ready to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Come back when you're ready!"
        exit 0
    fi
}

record_app() {
    local APP_NAME="$1"
    local DESCRIPTION="$2"
    local DURATION="$3"
    local INSTRUCTIONS="$4"

    echo ""
    echo "=========================================="
    echo -e "${BLUE}🎬 Recording: $APP_NAME${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}Description:${NC} $DESCRIPTION"
    echo -e "${YELLOW}Duration:${NC} ~$DURATION seconds"
    echo ""
    echo -e "${YELLOW}Instructions:${NC}"
    echo "$INSTRUCTIONS"
    echo ""
    echo "=========================================="
    echo ""
    echo "Recording workflow:"
    echo "  1. Open/setup your app now"
    echo "  2. Press Cmd+Shift+5 to open Screen Recording"
    echo "  3. Select 'Record Selected Window' or 'Record Entire Screen'"
    echo "  4. Click 'Record' button"
    echo "  5. Perform the actions described above"
    echo "  6. Click Stop button in menu bar when done"
    echo ""
    echo "Suggested filename:"
    echo "  ${APP_NAME}_$(date '+%Y%m%d_%H%M%S').mov"
    echo ""
    echo "Save to: $(pwd)/$RECORDINGS_DIR/"
    echo ""

    read -p "Press Enter when you've completed this recording..."

    log "✅ Completed recording: $APP_NAME"
    echo -e "${GREEN}✅ Recording logged!${NC}"
    echo ""
}

show_progress() {
    echo ""
    echo "=========================================="
    echo "📊 RECORDING PROGRESS"
    echo "=========================================="

    local COUNT=$(ls -1 "$RECORDINGS_DIR"/*.mov 2>/dev/null | wc -l | tr -d ' ')
    echo "Recordings completed: $COUNT"

    echo ""
    echo "Files in recordings folder:"
    ls -lh "$RECORDINGS_DIR"/*.mov 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

    echo ""
    echo "Log file: $LOG_FILE"
    echo ""
}

menu() {
    while true; do
        echo ""
        echo "=========================================="
        echo "🎬 SCREEN RECORDING MENU"
        echo "=========================================="
        echo ""
        echo "1. Record Pravos.xyz Demo (45-60s)"
        echo "2. Record Vibrana.ai Demo (45-60s)"
        echo "3. Record Mrktr Demo (30-45s)"
        echo "4. Record Claude Code Session (60-90s)"
        echo "5. Record VS Code/Cursor (30-45s)"
        echo "6. Record Generic Coding B-Roll (30s)"
        echo "7. Show setup checklist"
        echo "8. Show progress"
        echo "9. Open recordings folder"
        echo "0. Exit"
        echo ""
        read -p "Choose recording: " choice

        case $choice in
            1)
                record_app \
                    "pravos" \
                    "Your focus music app in action" \
                    "45-60" \
                    "  - Show dashboard overview
  - Browse through playlists/albums
  - Show music player in action
  - Demonstrate any unique features
  - Smooth scrolling and navigation"
                ;;
            2)
                record_app \
                    "vibrana" \
                    "AI capabilities demo" \
                    "45-60" \
                    "  - Show main interface/dashboard
  - Demonstrate AI interaction or generation
  - Show the results/output
  - Highlight key features"
                ;;
            3)
                record_app \
                    "mrktr" \
                    "Marketing tool dashboard" \
                    "30-45" \
                    "  - Show dashboard with analytics
  - Navigate through key features
  - Display any charts or visualizations"
                ;;
            4)
                record_app \
                    "claude_code" \
                    "Claude Code building in public" \
                    "60-90" \
                    "  - Open Terminal and start Claude Code
  - Show code being generated in real-time
  - Complete a small task or fix
  - Show successful completion/deploy
  - Capture the conversational aspect"
                ;;
            5)
                record_app \
                    "vscode_cursor" \
                    "Code editor with AI assistance" \
                    "30-45" \
                    "  - Open a nice-looking codebase
  - Scroll through different files
  - Show code syntax highlighting
  - If using Cursor, show AI assistance
  - Navigate file tree"
                ;;
            6)
                record_app \
                    "coding_broll" \
                    "Generic coding footage" \
                    "30" \
                    "  - Typing code (show hands on keyboard if possible)
  - Terminal commands running (npm install, etc)
  - Git operations (status, commit, push)
  - Build processes running
  - Multiple short clips work well"
                ;;
            7)
                show_setup_checklist
                ;;
            8)
                show_progress
                ;;
            9)
                open "$RECORDINGS_DIR"
                log "Opened recordings folder"
                ;;
            0)
                echo ""
                echo "Done recording! Check progress:"
                show_progress
                exit 0
                ;;
            *)
                echo "Invalid choice. Try again."
                ;;
        esac
    done
}

# Main
clear
echo ""
echo "╔════════════════════════════════════════╗"
echo "║  Screen Recording Helper - E1          ║"
echo "║  The Vibe Coding Revolution            ║"
echo "╚════════════════════════════════════════╝"
echo ""

log "=========================================="
log "Recording session started"

# Show setup first
show_setup_checklist

# Start menu
menu
