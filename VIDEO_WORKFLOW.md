# Video Processing Workflow

Automated workflow for processing Google Flow videos → 1080p → 4K upscaling

## 🎯 Quick Start

### Option 1: Process Videos One-by-One
```bash
# 1. Crop to proper 1080p
./crop_to_1080p.sh Scene_intensely_bright_1080p_20260107140.mp4

# 2. Upscale to 4K
python upscale_to_4k.py Scene_intensely_bright_1080p_20260107140_1080p.mp4
```

### Option 2: Automated Watch Mode
```bash
# Install fswatch (one-time setup)
brew install fswatch

# Start auto-processor (watches for new videos)
./auto_process_videos.sh

# Just drop MP4 files in this folder - they'll auto-process!
```

### Option 3: Batch Process Everything
```bash
# Process all videos in folder to 1080p
for f in *.mp4; do ./crop_to_1080p.sh "$f"; done

# Upscale all 1080p videos to 4K
python upscale_to_4k.py --batch ./processed_1080p
```

---

## 📂 Folder Structure

```
Claude E1/Assets/B-Roll/AI-Generated/
├── Scene_*.mp4                    # Raw videos from Google Flow (1920x1088)
├── Scene_*_1080p.mp4             # Proper 1080p videos (cropped)
└── 4K/                           # ✨ 4K upscaled videos
    └── Scene_*_1080p_4K_bytedance.mp4

Claude E1/
├── crop_to_1080p.sh              # Manual 1080p conversion
├── auto_process_videos.sh        # Auto-watch mode (skips 4K videos!)
├── upscale_to_4k.py              # 4K upscaling (saves to 4K subfolder)
└── video_processing.log          # Processing log
```

---

## 🎬 Workflow Steps

### Step 1: Fix Google Flow Videos (1920x1088 → 1920x1080)

Google Flow outputs 1920x1088 instead of standard 1080p (1920x1080). The scripts crop 4 pixels from top and bottom.

**Manual mode:**
```bash
./crop_to_1080p.sh your_video.mp4
```

**Auto mode:**
```bash
./auto_process_videos.sh
# Leave running, drop files in folder
```

### Step 2: Upscale to 4K with Fal.ai

**All 4K videos are automatically saved to a `4K/` subfolder to keep things organized.**

Choose your upscaling model based on needs:

| Model | Cost | Best For |
|-------|------|----------|
| **bytedance** (default) | $0.0288/sec | Fast, reliable, general use |
| **seedvr2** | ~$0.001/MP | Most affordable, great quality |
| **topaz** | $0.08/sec | Premium quality, noise removal |
| **flashvsr** | Varies | Fastest speeds |

**Single video:**
```bash
python upscale_to_4k.py video_1080p.mp4              # bytedance (default)
python upscale_to_4k.py video_1080p.mp4 seedvr2      # cheapest
python upscale_to_4k.py video_1080p.mp4 topaz        # best quality
```

**Batch upscale:**
```bash
python upscale_to_4k.py --batch ./processed_1080p bytedance
```

---

## 💰 Cost Estimates

### Example: 10-second video

| Model | 1080p→4K Cost | Quality | Speed |
|-------|---------------|---------|-------|
| SeedVR2 | ~$0.08 | ⭐⭐⭐⭐ | Medium |
| Bytedance | $0.29 | ⭐⭐⭐⭐ | Fast |
| Topaz | $0.80 | ⭐⭐⭐⭐⭐ | Slower |

**Recommendation:** Start with `seedvr2` for best value, upgrade to `topaz` if you need premium quality.

---

## 🔧 Technical Details

### FFmpeg Crop Filter
```bash
crop=1920:1080:0:4
# Format: crop=width:height:x:y
# Crops from (0,4) = removes 4px from top, 4px from bottom
```

### Quality Settings
- **CRF 18**: Near-lossless quality (lower = better, 18 is high quality)
- **Preset slow**: Better compression (for initial crop)
- **Preset medium**: Faster processing (for auto mode)

### File Naming Convention
- Input: `Scene_name_1080p_timestamp.mp4` (from Google Flow)
- After crop: `Scene_name_1080p_timestamp_1080p.mp4` (proper 1080p)
- After upscale: `Scene_name_1080p_timestamp_1080p_4K_bytedance.mp4`

---

## 🚀 Recommended Workflow

### For Regular Use:

1. **Start auto-processor in background:**
   ```bash
   ./auto_process_videos.sh &
   ```

2. **Export from Google Flow** → Drop files in `Claude E1` folder

3. **Videos auto-process to 1080p** → Saved in `processed_1080p/`

4. **Batch upscale to 4K:**
   ```bash
   python upscale_to_4k.py --batch ./processed_1080p seedvr2
   ```

### For Quick Single Videos:

```bash
./crop_to_1080p.sh Scene_video.mp4 && \
python upscale_to_4k.py Scene_video_1080p.mp4 seedvr2
```

---

## 📝 Troubleshooting

### "ffmpeg: command not found"
```bash
brew install ffmpeg
```

### "fswatch: command not found" (for auto mode)
```bash
brew install fswatch
```

### "fal_client module not found"
```bash
pip install fal-client
# or: python -m pip install fal-client
```

### Check API key
```bash
cat .env.local  # Should show FAL_API_KEY
```

### Monitor processing
```bash
tail -f video_processing.log
```

---

## 🎨 Integration with Your Setup

Your current `.env.local` has:
- ✅ `FAL_API_KEY` configured
- ✅ `CONTEXT7_API_KEY` configured

All scripts ready to use! Just drop your Google Flow videos and run.

---

## 📊 Performance Tips

1. **Batch processing is more efficient** than one-by-one
2. **SeedVR2 offers best price/quality ratio** for most content
3. **Use Topaz for high-ISO footage** (removes noise)
4. **Process overnight** for large batches (upscaling takes time)
5. **Keep original files** until you verify 4K quality

---

## 🔗 API Documentation

- [Fal.ai Video Upscaler](https://fal.ai/models/fal-ai/video-upscaler)
- [Bytedance Upscaler](https://fal.ai/models/fal-ai/bytedance-upscaler/upscale/video)
- [Topaz Video Upscale](https://fal.ai/models/fal-ai/topaz/upscale/video)
- [SeedVR2 Guide](https://adam.holter.com/seedvr2-on-fal-ai-cheap-10k-image-and-4k-video-upscaling-with-a-catch/)
