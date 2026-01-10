#!/usr/bin/env python3
"""
Remove backgrounds from images using Fal.ai
Optimized for portrait photos with multiple model options
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

# Available models for background removal
MODELS = {
    "portrait": {
        "name": "fal-ai/birefnet",
        "model_type": "Portrait",
        "cost": "~$0.01/image",
        "description": "Optimized for portrait/people photos"
    },
    "general": {
        "name": "fal-ai/birefnet",
        "model_type": "General Use (Light)",
        "cost": "~$0.01/image",
        "description": "Fast general-purpose removal"
    },
    "heavy": {
        "name": "fal-ai/birefnet",
        "model_type": "General Use (Heavy)",
        "cost": "~$0.02/image",
        "description": "Slower but more accurate"
    },
    "bria": {
        "name": "fal-ai/bria/background/remove",
        "model_type": None,
        "cost": "~$0.01/image",
        "description": "Commercial-safe, trained on licensed data"
    }
}


def upload_image_to_fal(image_path):
    """Upload image file to Fal.ai and return URL"""
    print(f"Uploading {image_path}...")
    url = fal_client.upload_file(image_path)
    print(f"  Uploaded: {url}")
    return url


def get_image_dimensions(image_path):
    """Get image dimensions using sips (macOS)"""
    import subprocess
    result = subprocess.run(
        ['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', image_path],
        capture_output=True, text=True
    )
    lines = result.stdout.strip().split('\n')
    width = int([l for l in lines if 'pixelWidth' in l][0].split(':')[1].strip())
    height = int([l for l in lines if 'pixelHeight' in l][0].split(':')[1].strip())
    return width, height


def remove_background(image_path, model="portrait", output_dir=None):
    """
    Remove background from image using selected Fal.ai model

    Args:
        image_path: Path to input image
        model: One of: portrait, general, heavy, bria
        output_dir: Optional output directory (default: no_bg subfolder)
    """
    if not os.path.exists(image_path):
        print(f"Error: File not found: {image_path}")
        return None

    if model not in MODELS:
        print(f"Error: Unknown model '{model}'. Choose from: {', '.join(MODELS.keys())}")
        return None

    # Configure API key
    api_key = os.getenv('FAL_API_KEY')
    if not api_key:
        print("Error: FAL_API_KEY not found in .env.local")
        return None

    os.environ['FAL_KEY'] = api_key

    # Get current dimensions
    width, height = get_image_dimensions(image_path)

    model_info = MODELS[model]
    print(f"\n{'='*60}")
    print(f"Image: {Path(image_path).name}")
    print(f"Size: {width}x{height}")
    print(f"Model: {model_info['description']}")
    print(f"Cost: {model_info['cost']}")
    print(f"{'='*60}\n")

    try:
        # Upload image
        image_url = upload_image_to_fal(image_path)

        # Prepare arguments based on model
        arguments = {
            "image_url": image_url,
        }

        # Add model-specific parameters
        if model_info['model_type']:
            arguments["model"] = model_info['model_type']

        # Submit job
        print(f"Removing background...")
        handler = fal_client.submit(
            model_info['name'],
            arguments=arguments
        )

        print(f"Job ID: {handler.request_id}")
        print("Processing...")

        # Wait for result
        start_time = time.time()
        result = handler.get()
        elapsed = time.time() - start_time

        print(f"\n  Background removal complete! ({elapsed:.1f} seconds)")

        # Find output URL in result
        output_url = None
        if 'image' in result:
            output_url = result['image']['url']
        elif 'output' in result:
            output_url = result['output']['url'] if isinstance(result['output'], dict) else result['output']
        elif 'url' in result:
            output_url = result['url']
        else:
            # Try to find any URL in the result
            print("Result structure:")
            print(result)
            for key, value in result.items():
                if isinstance(value, str) and value.startswith('http'):
                    output_url = value
                    break
                elif isinstance(value, dict) and 'url' in value:
                    output_url = value['url']
                    break

        if output_url:
            # Generate output filename
            input_path = Path(image_path)
            if output_dir:
                out_dir = Path(output_dir)
            else:
                out_dir = input_path.parent / "no_bg"
            out_dir.mkdir(exist_ok=True)

            # Always save as PNG to preserve transparency
            output_path = out_dir / f"{input_path.stem}_no_bg.png"

            # Download
            print(f"Downloading...")
            os.system(f'curl -sS -o "{output_path}" "{output_url}"')

            # Verify dimensions
            new_width, new_height = get_image_dimensions(str(output_path))

            print(f"\n{'='*60}")
            print(f"  Saved: {output_path}")
            print(f"Size: {new_width}x{new_height}")
            print(f"Processing time: {elapsed:.1f} seconds")
            print(f"{'='*60}\n")

            return str(output_path)
        else:
            print("Error: No output URL in result")
            print(result)
            return None

    except Exception as e:
        print(f"Error during background removal: {e}")
        import traceback
        traceback.print_exc()
        return None


def batch_remove_background(input_dir, model="portrait", extensions=None):
    """Remove backgrounds from all images in a directory"""
    if extensions is None:
        extensions = ['.jpg', '.jpeg', '.png', '.webp']

    input_path = Path(input_dir)

    if not input_path.exists():
        print(f"Error: Directory not found: {input_dir}")
        return

    # Find all images
    images = []
    for ext in extensions:
        images.extend(input_path.glob(f"*{ext}"))
        images.extend(input_path.glob(f"*{ext.upper()}"))

    # Filter out already processed images
    images = [img for img in images if '_no_bg' not in img.stem]

    if not images:
        print(f"No images found in {input_dir}")
        return

    print(f"Found {len(images)} image(s) to process")
    print(f"Model: {model}")
    print()

    results = {"success": 0, "failed": 0}

    for i, image in enumerate(images, 1):
        print(f"\n[{i}/{len(images)}] Processing: {image.name}")
        result = remove_background(str(image), model=model)
        if result:
            print(f"  Completed: {Path(result).name}")
            results["success"] += 1
        else:
            print(f"  Failed: {image.name}")
            results["failed"] += 1

    print(f"\n{'='*60}")
    print(f"Batch complete: {results['success']} successful, {results['failed']} failed")
    print(f"{'='*60}")


def main():
    if len(sys.argv) < 2:
        print("Background Removal using Fal.ai")
        print("=" * 40)
        print()
        print("Usage:")
        print("  Single image: python remove_background.py <image.jpg> [model]")
        print("  Batch process: python remove_background.py --batch <directory> [model]")
        print()
        print("Available models:")
        for name, info in MODELS.items():
            marker = "(default)" if name == "portrait" else ""
            print(f"  {name:12} - {info['description']} ({info['cost']}) {marker}")
        print()
        print("Examples:")
        print("  python remove_background.py photo.jpg")
        print("  python remove_background.py photo.jpg portrait")
        print("  python remove_background.py --batch ./portraits")
        print("  python remove_background.py --batch ./photos general")
        print()
        print("Output: PNG files with transparent background in 'no_bg' subfolder")
        sys.exit(1)

    if sys.argv[1] == "--batch":
        directory = sys.argv[2] if len(sys.argv) > 2 else "."
        model = sys.argv[3] if len(sys.argv) > 3 else "portrait"
        batch_remove_background(directory, model)
    else:
        image_path = sys.argv[1]
        model = sys.argv[2] if len(sys.argv) > 2 else "portrait"
        remove_background(image_path, model)


if __name__ == "__main__":
    main()
