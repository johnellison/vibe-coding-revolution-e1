# The Vibe Coding Revolution - Episode 1

Automated video processing pipeline for producing "The Vibe Coding Revolution" podcast/show.

## 🎬 What This Does

This repository contains automation scripts for processing AI-generated video content:

1. **Auto-crop videos** from Google Flow's 1920x1088 to proper 1080p (1920x1080)
2. **Upscale to 4K** using Fal.ai's API
3. **Convert screenshots** to WebP format with 60-96% file size reduction
4. **Organize assets** automatically

## 🚀 Quick Start

### Video Processing

```bash
# Process all videos in a folder (crop → 4K upscale → organize)
cd Assets/B-Roll/AI-Generated
./auto_process_and_upscale.sh
```

### Screenshot Conversion

```bash
# Convert all screenshots on Desktop to WebP
cd ~/Desktop
./convert_screenshots_to_webp.sh

# Or watch for new screenshots (auto-convert)
./watch_screenshots.sh &
```

## 📦 Scripts

### Video Processing
- **`auto_process_and_upscale.sh`** - Full pipeline: crop → upscale → organize
- **`crop_to_1080p.sh`** - Manual 1080p cropping
- **`upscale_to_4k.py`** - 4K upscaling via Fal.ai
- **`auto_process_videos.sh`** - Watch folder for new videos

### Utilities
- **`screen_recorder.py`** - Screen recording utility
- **`veo_generator.py`** - Video generation helper
- **`convert_screenshots_to_webp.sh`** - Screenshot optimizer (on Desktop)
- **`watch_screenshots.sh`** - Auto-watch for new screenshots (on Desktop)

## 🛠️ Setup

### Prerequisites

```bash
# Install FFmpeg
brew install ffmpeg

# Install fswatch (for auto-watch modes)
brew install fswatch

# Install WebP tools
brew install webp

# Install Python dependencies
pip install fal-client python-dotenv
```

### Environment Variables

Create `.env.local` with your Fal.ai API key:

```
FAL_API_KEY=your-api-key-here
```

## 📊 Results

### Video Processing
- **33 videos** upscaled to 4K (3840x2160)
- ~4 minutes per video
- Automatic organization into `4K/` and `_original/` folders

### Screenshot Conversion
- **1,533 screenshots** converted to WebP
- **60-96% file size reduction**
- Original quality maintained

## 📖 Documentation

- **`VIDEO_WORKFLOW.md`** - Complete video processing guide
- **`E1-PRODUCTION-GUIDE.md`** - Episode 1 production guide
- **`SCRIPT-WITH-BROLL.md`** - Episode script with B-roll notes
- **`FLOW-PROMPTS-CINEMATIC.md`** - Cinematic prompt templates
- **`VEO-PROMPTS-FOR-FLOW.md`** - Video generation prompts

## 🎯 Workflow

1. **Generate videos** with Google Flow (outputs 1920x1088)
2. **Drop videos** in `Assets/B-Roll/AI-Generated/`
3. **Run processor**: `./auto_process_and_upscale.sh`
4. **Get 4K videos** in `4K/` folder
5. **Originals archived** in `_original/` folder

## 💰 Cost

Using Fal.ai Bytedance upscaler:
- **$0.0288/second** for 4K upscaling
- ~$0.23 per 8-second clip
- Example: 33 videos × 8 sec = **~$7.60**

## 🔗 Links

- [Fal.ai Video Upscaler](https://fal.ai/models/fal-ai/bytedance-upscaler/upscale/video)
- [Google Flow](https://labs.google.com/flow)

---

🤖 Automated with **Claude Code** by Anthropic
