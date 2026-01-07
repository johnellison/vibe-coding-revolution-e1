#!/usr/bin/env python3
"""
Upscale videos to 4K using Fal.ai
Supports multiple upscaling models with different quality/cost tradeoffs
"""

import os
import sys
import time
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env.local')

try:
    import fal_client
except ImportError:
    print("Installing fal_client...")
    os.system("pip install fal-client")
    import fal_client

# Available models and their pricing
MODELS = {
    "bytedance": {
        "name": "fal-ai/bytedance-upscaler/upscale/video",
        "cost": "$0.0288/second for 4K",
        "description": "Fast and reliable, best for most use cases"
    },
    "seedvr2": {
        "name": "fal-ai/seedvr2/upscale/video",
        "cost": "~$0.001/megapixel (most affordable)",
        "description": "Cost-effective, great quality for 4K"
    },
    "topaz": {
        "name": "fal-ai/topaz/upscale/video",
        "cost": "$0.08/second for >1080p",
        "description": "Premium quality, removes noise/compression artifacts"
    },
    "flashvsr": {
        "name": "fal-ai/flashvsr/upscale/video",
        "cost": "Varies",
        "description": "Fastest upscaling speeds"
    }
}

def upload_video_to_fal(video_path):
    """Upload video file to Fal.ai and return URL"""
    print(f"Uploading {video_path}...")
    url = fal_client.upload_file(video_path)
    print(f"✓ Uploaded: {url}")
    return url

def upscale_video(video_path, model="bytedance", target_resolution="4k"):
    """
    Upscale video to 4K using selected Fal.ai model

    Args:
        video_path: Path to input video
        model: One of: bytedance (default), seedvr2, topaz, flashvsr
        target_resolution: Target resolution (default: 4k)
    """
    if not os.path.exists(video_path):
        print(f"Error: File not found: {video_path}")
        return None

    if model not in MODELS:
        print(f"Error: Unknown model '{model}'. Choose from: {', '.join(MODELS.keys())}")
        return None

    # Configure API key - Fal.ai expects FAL_KEY environment variable
    api_key = os.getenv('FAL_API_KEY')
    if not api_key:
        print("Error: FAL_API_KEY not found in .env.local")
        return None

    # Set FAL_KEY for fal_client
    os.environ['FAL_KEY'] = api_key

    model_info = MODELS[model]
    print(f"\n{'='*60}")
    print(f"Upscaling with: {model_info['description']}")
    print(f"Model: {model_info['name']}")
    print(f"Cost: {model_info['cost']}")
    print(f"{'='*60}\n")

    try:
        # Upload video
        video_url = upload_video_to_fal(video_path)

        # Prepare arguments based on model
        arguments = {
            "video_url": video_url,
        }

        # Add model-specific parameters
        if model == "bytedance":
            arguments["target_resolution"] = "4k"  # Options: 1080p, 2k, 4k
            arguments["target_fps"] = "30fps"  # Options: 30fps, 60fps
        elif model == "seedvr2":
            arguments["scale"] = 4
            arguments["variant"] = "7b"  # Higher quality variant
        elif model == "topaz":
            arguments["enhancement_amount"] = 0.75
            arguments["output_format"] = "mp4"

        # Submit upscaling job
        print(f"Submitting upscaling job...")
        handler = fal_client.submit(
            model_info['name'],
            arguments=arguments
        )

        print(f"Job ID: {handler.request_id}")
        print("Processing... (this may take a few minutes)")

        # Wait for result with progress updates
        start_time = time.time()
        result = handler.get()
        elapsed = time.time() - start_time

        print(f"\n✓ Upscaling complete! ({elapsed:.1f} seconds)")

        # Download result
        if 'video' in result:
            output_url = result['video']['url']
        elif 'output_url' in result:
            output_url = result['output_url']
        else:
            print("Result structure:")
            print(result)
            output_url = result.get('url', None)

        if output_url:
            # Generate output filename in 4K subfolder
            input_path = Path(video_path)
            output_dir = input_path.parent / "4K"
            output_dir.mkdir(exist_ok=True)
            output_path = output_dir / f"{input_path.stem}_4K_{model}.mp4"

            print(f"Downloading to: {output_path}")

            # Download using curl
            os.system(f'curl -o "{output_path}" "{output_url}"')

            print(f"\n{'='*60}")
            print(f"✓ 4K video saved: {output_path}")
            print(f"Processing time: {elapsed:.1f} seconds")
            print(f"{'='*60}\n")

            return str(output_path)
        else:
            print("Error: No output URL in result")
            print(result)
            return None

    except Exception as e:
        print(f"Error during upscaling: {e}")
        import traceback
        traceback.print_exc()
        return None

def batch_upscale(input_dir, model="bytedance"):
    """Upscale all 1080p videos in a directory"""
    input_path = Path(input_dir)

    if not input_path.exists():
        print(f"Error: Directory not found: {input_dir}")
        return

    # Find all 1080p videos
    videos = list(input_path.glob("*_1080p.mp4"))

    if not videos:
        print(f"No *_1080p.mp4 videos found in {input_dir}")
        return

    print(f"Found {len(videos)} video(s) to upscale")
    print(f"Model: {model}")
    print()

    for i, video in enumerate(videos, 1):
        print(f"\n[{i}/{len(videos)}] Processing: {video.name}")
        result = upscale_video(str(video), model=model)
        if result:
            print(f"✓ Completed: {Path(result).name}")
        else:
            print(f"✗ Failed: {video.name}")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Single video:  python upscale_to_4k.py <video.mp4> [model]")
        print("  Batch process: python upscale_to_4k.py --batch <directory> [model]")
        print()
        print("Available models:")
        for name, info in MODELS.items():
            print(f"  {name:12} - {info['description']} ({info['cost']})")
        print()
        print("Examples:")
        print("  python upscale_to_4k.py video_1080p.mp4")
        print("  python upscale_to_4k.py video_1080p.mp4 seedvr2")
        print("  python upscale_to_4k.py --batch ./processed_1080p")
        sys.exit(1)

    if sys.argv[1] == "--batch":
        directory = sys.argv[2] if len(sys.argv) > 2 else "./processed_1080p"
        model = sys.argv[3] if len(sys.argv) > 3 else "bytedance"
        batch_upscale(directory, model)
    else:
        video_path = sys.argv[1]
        model = sys.argv[2] if len(sys.argv) > 2 else "bytedance"
        upscale_video(video_path, model)

if __name__ == "__main__":
    main()
