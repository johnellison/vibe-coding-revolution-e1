#!/usr/bin/env python3
"""
Screen Recording Automation for JE Show E1
==========================================

Automates screen recordings of your apps for b-roll footage.
Uses macOS native tools for recording and AppleScript for automation.

REQUIREMENTS:
- macOS (uses native screencapture and osascript)
- Chrome or Safari for web app demos
- Optional: cliclick (brew install cliclick) for precise mouse control

USAGE:
  python screen_recorder.py --list              # List available demos
  python screen_recorder.py --demo pravos       # Run Pravos demo
  python screen_recorder.py --demo all          # Run all demos
  python screen_recorder.py --record-only 30    # Just record screen for 30s

OUTPUT:
  Recordings saved to: Assets/B-Roll/Screen-Recordings/
"""

import subprocess
import time
import os
import argparse
from pathlib import Path
from datetime import datetime

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "Assets" / "B-Roll" / "Screen-Recordings"

# Demo configurations
DEMOS = {
    "pravos": {
        "name": "Pravos.xyz",
        "url": "http://localhost:3000",  # Or production URL
        "description": "Focus music app demo - dashboard, player, playlists",
        "duration": 45,
        "actions": [
            {"type": "wait", "seconds": 3},
            {"type": "scroll", "direction": "down", "amount": 300, "duration": 2},
            {"type": "wait", "seconds": 2},
            {"type": "scroll", "direction": "down", "amount": 300, "duration": 2},
            {"type": "wait", "seconds": 3},
            {"type": "scroll", "direction": "up", "amount": 600, "duration": 3},
            {"type": "wait", "seconds": 2},
        ]
    },
    "vibrana": {
        "name": "Vibrana.ai",
        "url": "http://localhost:3000",
        "description": "AI app demo - main interface and features",
        "duration": 45,
        "actions": [
            {"type": "wait", "seconds": 3},
            {"type": "scroll", "direction": "down", "amount": 400, "duration": 3},
            {"type": "wait", "seconds": 3},
            {"type": "scroll", "direction": "up", "amount": 400, "duration": 3},
        ]
    },
    "mrktr": {
        "name": "Mrktr",
        "url": "http://localhost:3000",
        "description": "Marketing tool demo - dashboard and analytics",
        "duration": 40,
        "actions": [
            {"type": "wait", "seconds": 3},
            {"type": "scroll", "direction": "down", "amount": 500, "duration": 4},
            {"type": "wait", "seconds": 2},
        ]
    },
    "claude_code": {
        "name": "Claude Code Terminal",
        "type": "terminal",
        "description": "Claude Code in action - terminal session",
        "duration": 60,
        "commands": [
            "# This is a placeholder - run Claude Code manually",
            "# Record yourself using Claude Code for authentic footage",
        ]
    },
    "vscode_coding": {
        "name": "VS Code / Cursor",
        "type": "app",
        "app_name": "Cursor",  # or "Visual Studio Code"
        "description": "Code editor with AI assistance",
        "duration": 45,
        "actions": [
            {"type": "wait", "seconds": 5},
            # Scroll through code
            {"type": "key", "key": "cmd+end"},  # Go to end
            {"type": "wait", "seconds": 2},
            {"type": "key", "key": "cmd+home"},  # Go to start
        ]
    }
}

# Screen recording settings
RECORDING_SETTINGS = {
    "format": "mov",  # mov for ProRes, mp4 for H.264
    "fps": 30,
    "quality": "high",  # high, medium, low
}


def run_applescript(script: str) -> str:
    """Execute AppleScript and return output."""
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()


def open_url_in_chrome(url: str):
    """Open URL in Chrome."""
    script = f'''
    tell application "Google Chrome"
        activate
        if (count every window) = 0 then
            make new window
        end if
        set URL of active tab of front window to "{url}"
    end tell
    '''
    run_applescript(script)


def open_url_in_safari(url: str):
    """Open URL in Safari."""
    script = f'''
    tell application "Safari"
        activate
        if (count every window) = 0 then
            make new document
        end if
        set URL of front document to "{url}"
    end tell
    '''
    run_applescript(script)


def scroll_browser(direction: str = "down", amount: int = 300, duration: float = 1.0):
    """Scroll in the active browser window."""
    # Using AppleScript to send scroll events
    scroll_amount = amount if direction == "down" else -amount
    steps = int(duration * 10)  # 10 steps per second
    per_step = scroll_amount / steps

    for _ in range(steps):
        script = f'''
        tell application "System Events"
            scroll area 1 of process "Google Chrome" ¬
                scroll by {{0, {int(per_step)}}}
        end tell
        '''
        # Alternative: use cliclick if available
        subprocess.run(
            ["osascript", "-e", f'tell application "System Events" to scroll area 1'],
            capture_output=True
        )
        time.sleep(0.1)


def smooth_scroll_js(direction: str = "down", amount: int = 300, duration: float = 2.0):
    """Use JavaScript for smooth scrolling in Chrome."""
    scroll_amount = amount if direction == "down" else -amount
    js_code = f"window.scrollBy({{top: {scroll_amount}, behavior: 'smooth'}})"

    script = f'''
    tell application "Google Chrome"
        execute active tab of front window javascript "{js_code}"
    end tell
    '''
    run_applescript(script)
    time.sleep(duration)


def start_screen_recording(output_path: str, duration: int = None):
    """Start screen recording using macOS screencapture."""
    # Create output directory if needed
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    # Build command
    cmd = ["screencapture", "-v"]  # -v for video mode

    if duration:
        # Use timeout to stop after duration
        cmd = ["timeout", str(duration)] + cmd

    cmd.append(output_path)

    print(f"🎬 Starting screen recording: {output_path}")
    print(f"   Press Ctrl+C or wait {duration}s to stop")

    # Start recording in background
    process = subprocess.Popen(cmd)
    return process


def stop_screen_recording():
    """Stop any running screen recording."""
    subprocess.run(["pkill", "-f", "screencapture"], capture_output=True)


def record_screen_region(output_path: str, x: int, y: int, width: int, height: int, duration: int):
    """Record a specific region of the screen."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    # Using screencapture with region
    cmd = [
        "screencapture",
        "-v",  # video
        "-R", f"{x},{y},{width},{height}",  # region
        output_path
    ]

    process = subprocess.Popen(cmd)
    time.sleep(duration)
    process.terminate()
    return output_path


def run_demo(demo_key: str, browser: str = "chrome"):
    """Run a demo and record it."""
    if demo_key not in DEMOS:
        print(f"❌ Unknown demo: {demo_key}")
        print(f"   Available: {', '.join(DEMOS.keys())}")
        return None

    demo = DEMOS[demo_key]
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = OUTPUT_DIR / f"{demo_key}_{timestamp}.mov"

    print(f"\n🎬 Running demo: {demo['name']}")
    print(f"   Description: {demo['description']}")
    print(f"   Duration: {demo['duration']}s")
    print(f"   Output: {output_file}")

    # Ensure output directory exists
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    demo_type = demo.get("type", "web")

    if demo_type == "web":
        # Open URL
        url = demo.get("url", "")
        if url:
            print(f"   Opening: {url}")
            if browser == "chrome":
                open_url_in_chrome(url)
            else:
                open_url_in_safari(url)
            time.sleep(2)  # Wait for page load

    elif demo_type == "terminal":
        print("\n   ⚠️  Terminal demo - manual recording recommended")
        print("   Open Terminal and start Claude Code, then use --record-only")
        return None

    elif demo_type == "app":
        app_name = demo.get("app_name", "")
        if app_name:
            script = f'tell application "{app_name}" to activate'
            run_applescript(script)
            time.sleep(2)

    # Start recording
    print("\n   🔴 Recording starting in 3 seconds...")
    print("   Press Cmd+Shift+5 to start macOS screen recording, then press Enter")
    input("   Press Enter when recording is active...")

    # Execute demo actions
    actions = demo.get("actions", [])
    for i, action in enumerate(actions):
        action_type = action.get("type")

        if action_type == "wait":
            seconds = action.get("seconds", 1)
            print(f"   ⏳ Waiting {seconds}s...")
            time.sleep(seconds)

        elif action_type == "scroll":
            direction = action.get("direction", "down")
            amount = action.get("amount", 300)
            duration = action.get("duration", 1)
            print(f"   📜 Scrolling {direction} ({amount}px over {duration}s)...")
            smooth_scroll_js(direction, amount, duration)

        elif action_type == "click":
            x = action.get("x", 0)
            y = action.get("y", 0)
            print(f"   🖱️ Clicking at ({x}, {y})...")
            subprocess.run(["cliclick", f"c:{x},{y}"], capture_output=True)

        elif action_type == "key":
            key = action.get("key", "")
            print(f"   ⌨️ Pressing {key}...")
            # Map to cliclick format
            if "cmd" in key.lower():
                subprocess.run(["cliclick", f"kd:cmd", f"t:{key.split('+')[-1]}", "ku:cmd"], capture_output=True)

    remaining = demo["duration"] - sum(
        a.get("seconds", 0) + a.get("duration", 0)
        for a in actions
    )
    if remaining > 0:
        print(f"   ⏳ Continuing for {remaining}s...")
        time.sleep(remaining)

    print("\n   🛑 Demo complete - stop your recording now")
    print(f"   Save recording to: {output_file}")

    return str(output_file)


def simple_record(duration: int):
    """Just record the screen for a set duration."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = OUTPUT_DIR / f"manual_recording_{timestamp}.mov"
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"\n🎬 Simple Screen Recording")
    print(f"   Duration: {duration}s")
    print(f"   Output: {output_file}")
    print(f"\n   Press Cmd+Shift+5 to start macOS screen recording")
    print(f"   Recording will auto-prompt to stop after {duration}s")

    input("\n   Press Enter when you've started recording...")

    for i in range(duration, 0, -1):
        print(f"   ⏱️ {i}s remaining...", end="\r")
        time.sleep(1)

    print(f"\n\n   🛑 Time's up! Stop your recording now.")
    print(f"   Save to: {output_file}")

    return str(output_file)


def list_demos():
    """List all available demos."""
    print("\n📋 Available Screen Recording Demos")
    print("=" * 50)

    for key, demo in DEMOS.items():
        demo_type = demo.get("type", "web")
        print(f"\n  🎬 {key}")
        print(f"     Name: {demo['name']}")
        print(f"     Type: {demo_type}")
        print(f"     Duration: {demo['duration']}s")
        print(f"     {demo['description']}")
        if demo_type == "web":
            print(f"     URL: {demo.get('url', 'N/A')}")

    print("\n" + "=" * 50)
    print("\n💡 Tips:")
    print("   1. Use Cmd+Shift+5 for macOS native screen recording")
    print("   2. Set recording to capture a window or region")
    print("   3. Use 4K display for best quality")
    print("   4. Hide bookmarks bar and clean up browser")
    print("   5. Use a dark theme for code editors")


def create_shot_list():
    """Create a markdown shot list for manual recording reference."""
    shot_list = """# Screen Recording Shot List for E1

## Setup Checklist
- [ ] 4K display resolution (3840x2160 or similar)
- [ ] Clean desktop (hide personal files)
- [ ] Browser: Hide bookmarks bar, clear tabs
- [ ] Code editor: Dark theme, clean project
- [ ] Terminal: Nice theme (Dracula, One Dark, etc.)
- [ ] Notifications: Do Not Disturb enabled

---

## Required Recordings

### 1. Pravos Demo (45-60s)
**Purpose:** Show your music app in action
- [ ] Dashboard overview
- [ ] Browse playlists/albums
- [ ] Player in action
- [ ] Any unique features

### 2. Vibrana.ai Demo (45-60s)
**Purpose:** Show AI capabilities
- [ ] Main interface
- [ ] AI interaction/generation
- [ ] Results/output

### 3. Mrktr Demo (30-45s)
**Purpose:** Show marketing tool
- [ ] Dashboard/analytics
- [ ] Key features

### 4. Claude Code Session (60-90s)
**Purpose:** "Building in public" footage
- [ ] Terminal with Claude Code running
- [ ] Code being generated
- [ ] Successful completion/deploy
- [ ] Maybe a small fix or feature

### 5. VS Code / Cursor (30-45s)
**Purpose:** Code editing footage
- [ ] Nice codebase open
- [ ] Scrolling through files
- [ ] AI assistance in action (if using Cursor)

### 6. Generic Coding B-Roll (30s each)
- [ ] Typing code (hands on keyboard)
- [ ] Terminal commands running
- [ ] Git commits/pushes
- [ ] npm/pnpm install running

---

## Recording Settings

**Resolution:** 4K (3840x2160) preferred, 1080p minimum
**Frame Rate:** 30fps
**Format:** ProRes or H.264
**Audio:** None needed (will be replaced)

## Post-Recording
1. Trim start/end dead space
2. Speed up boring parts (2x or 4x)
3. Color correct if needed
4. Export to ProRes for Premiere

---

*Generated by screen_recorder.py*
"""

    shot_list_path = OUTPUT_DIR.parent.parent / "SCREEN-RECORDING-SHOT-LIST.md"
    shot_list_path.parent.mkdir(parents=True, exist_ok=True)
    shot_list_path.write_text(shot_list)
    print(f"✅ Shot list created: {shot_list_path}")
    return str(shot_list_path)


def main():
    parser = argparse.ArgumentParser(description="Screen Recording Automation for JE Show E1")
    parser.add_argument("--demo", "-d", help="Run a specific demo (or 'all')")
    parser.add_argument("--list", "-l", action="store_true", help="List available demos")
    parser.add_argument("--record-only", "-r", type=int, help="Just record screen for N seconds")
    parser.add_argument("--browser", "-b", default="chrome", choices=["chrome", "safari"], help="Browser to use")
    parser.add_argument("--shot-list", "-s", action="store_true", help="Generate shot list markdown")

    args = parser.parse_args()

    if args.list:
        list_demos()
        return

    if args.shot_list:
        create_shot_list()
        return

    if args.record_only:
        simple_record(args.record_only)
        return

    if args.demo:
        if args.demo == "all":
            for key in DEMOS:
                run_demo(key, args.browser)
        else:
            run_demo(args.demo, args.browser)
        return

    parser.print_help()


if __name__ == "__main__":
    main()
