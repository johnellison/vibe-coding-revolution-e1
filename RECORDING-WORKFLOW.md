# Screen Recording Workflow

Quick reference for recording b-roll footage for Episode 1.

## Quick Start

```bash
cd "/Users/iamjohndass/Documents/John Ellison Show/E1 - The Vibe Coding Revolution/Claude E1"
./record_helper.sh
```

## What Gets Recorded

### 1. App Demos (Web Apps)
- **Pravos.xyz** - Focus music app (45-60s)
- **Vibrana.ai** - AI capabilities (45-60s)
- **Mrktr** - Marketing tool (30-45s)

### 2. Development Footage
- **Claude Code** - Terminal session building something (60-90s)
- **VS Code/Cursor** - Code editing with AI (30-45s)
- **Generic B-Roll** - Typing, terminal commands, git operations (30s clips)

## Recording Settings

**Use macOS Native Screen Recorder (Cmd+Shift+5)**

- **Resolution:** Highest available (4K preferred)
- **Frame Rate:** 30fps
- **Format:** MOV (ProRes if available)
- **Capture:** Select "Record Selected Window" for clean edges
- **Audio:** Not needed (will be replaced)

## Pre-Recording Checklist

- [ ] Enable Do Not Disturb (no notifications!)
- [ ] Clean desktop (hide personal files)
- [ ] Hide browser bookmarks bar
- [ ] Use dark theme for code editors
- [ ] Close unnecessary apps/windows
- [ ] 4K display if available

## Recording Tips

### For Web Apps:
1. Open app in browser
2. Hide bookmarks bar (Cmd+Shift+B in Chrome)
3. Go fullscreen or clean window
4. Use smooth scrolling
5. Show key features naturally

### For Code/Terminal:
1. Use a nice color theme (Dracula, One Dark, Nord)
2. Increase font size for visibility
3. Show real work, not fake demos
4. Terminal should be ~16-18pt font
5. Dark theme with good contrast

### Recording Process:
1. **Setup** - Open app/tool, position windows
2. **Cmd+Shift+5** - Open screen recorder
3. **Select window** - Choose specific window to record
4. **Record** - Click record button
5. **Perform actions** - Navigate app smoothly
6. **Stop** - Click stop in menu bar
7. **Save** - Save to `Assets/B-Roll/Screen-Recordings/`

## File Naming Convention

```
[app-name]_[date]_[time].mov

Examples:
- pravos_20260107_143022.mov
- vibrana_20260107_143523.mov
- claude_code_20260107_144012.mov
- coding_broll_typing_20260107_144512.mov
```

## After Recording

Files are saved to:
```
Assets/B-Roll/Screen-Recordings/
```

### Post-Processing:
1. Trim dead space at start/end
2. Speed up boring parts (2x-4x for installs, builds)
3. Color grade if needed
4. Export to editing-friendly format

## Advanced: Using screen_recorder.py

For automated scrolling/actions:

```bash
# List available demos
python screen_recorder.py --list

# Record with guided actions
python screen_recorder.py --demo pravos

# Simple timed recording
python screen_recorder.py --record-only 60
```

## Troubleshooting

**Recording not starting?**
- Check Screen Recording permissions in System Preferences > Privacy

**Low quality output?**
- Ensure display is set to native resolution
- Use MOV format instead of MP4

**File too large?**
- Normal for high-quality recordings
- Will compress during final export
- ProRes files are large but edit better

---

## Shot List Reference

See `Assets/SCREEN-RECORDING-SHOT-LIST.md` for detailed shot descriptions.

## Tools

- **macOS Screen Recorder** - Built-in (Cmd+Shift+5)
- **record_helper.sh** - Interactive menu for systematic recording
- **screen_recorder.py** - Automated demo runner (advanced)

---

*Last updated: 2026-01-07*
