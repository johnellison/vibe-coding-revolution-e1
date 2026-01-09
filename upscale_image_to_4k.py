#!/usr/bin/env python3
"""
Upscale images to 4K using Fal.ai
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

# Available models for image upscaling
MODELS = {
    "creative": {
        "name": "fal-ai/creative-upscaler",
        "cost": "~$0.04/image",
        "description": "AI-enhanced upscaling with detail generation"
    },
    "clarity": {
        "name": "fal-ai/clarity-upscaler",
        "cost": "~$0.02/image",
        "description": "High quality upscaling, preserves original look"
    },
    "esrgan": {
        "name": "fal-ai/real-esrgan",
        "cost": "~$0.01/image",
        "description": "Fast and affordable, good for most images"
    }
}

# Target 4K dimensions
TARGET_4K_WIDTH = 3840
TARGET_4K_HEIGHT = 2160

def upload_image_to_fal(image_path):
    """Upload image file to Fal.ai and return URL"""
    print(f"Uploading {image_path}...")
    url = fal_client.upload_file(image_path)
    print(f"✓ Uploaded: {url}")
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

def calculate_scale_for_4k(width, height):
    """Calculate scale factor needed to reach 4K"""
    scale_w = TARGET_4K_WIDTH / width
    scale_h = TARGET_4K_HEIGHT / height
    # Use the larger scale to ensure we reach 4K on the smaller dimension
    return max(scale_w, scale_h)

def upscale_image(image_path, model="clarity", output_dir=None):
    """
    Upscale image to 4K using selected Fal.ai model

    Args:
        image_path: Path to input image
        model: One of: creative, clarity, esrgan
        output_dir: Optional output directory (default: 4K subfolder)
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

    # Get current dimensions and calculate scale
    width, height = get_image_dimensions(image_path)
    scale = calculate_scale_for_4k(width, height)

    model_info = MODELS[model]
    print(f"\n{'='*60}")
    print(f"Image: {Path(image_path).name}")
    print(f"Current size: {width}x{height}")
    print(f"Scale factor: {scale:.2f}x")
    print(f"Target size: ~{int(width*scale)}x{int(height*scale)}")
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

        if model == "creative":
            arguments["scale"] = min(int(scale) + 1, 4)  # Max 4x for creative
            arguments["creativity"] = 0.3  # Lower = more faithful to original
        elif model == "clarity":
            arguments["scale"] = min(int(scale) + 1, 4)
        elif model == "esrgan":
            arguments["scale"] = min(int(scale) + 1, 4)

        # Submit upscaling job
        print(f"Submitting upscaling job...")
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

        print(f"\n✓ Upscaling complete! ({elapsed:.1f} seconds)")

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
                out_dir = input_path.parent / "4K"
            out_dir.mkdir(exist_ok=True)

            # Download to temp file first
            temp_path = out_dir / f"{input_path.stem}_4K_temp"
            print(f"Downloading...")
            os.system(f'curl -sS -o "{temp_path}" "{output_url}"')

            # Detect actual format and convert to desired format if needed
            import subprocess
            result = subprocess.run(['file', str(temp_path)], capture_output=True, text=True)
            actual_format = result.stdout.lower()

            # Determine desired extension (prefer original, but use jpg for compatibility)
            desired_ext = input_path.suffix.lower()
            if desired_ext not in ['.jpg', '.jpeg', '.png', '.webp']:
                desired_ext = '.jpg'

            output_path = out_dir / f"{input_path.stem}_4K{desired_ext}"

            # Convert if format doesn't match extension
            if 'png' in actual_format and desired_ext in ['.jpg', '.jpeg']:
                print(f"Converting PNG to JPEG for compatibility...")
                os.system(f'sips -s format jpeg "{temp_path}" --out "{output_path}"')
                os.remove(temp_path)
            elif 'jpeg' in actual_format and desired_ext == '.png':
                print(f"Converting JPEG to PNG...")
                os.system(f'sips -s format png "{temp_path}" --out "{output_path}"')
                os.remove(temp_path)
            else:
                # Format matches, just rename
                os.rename(temp_path, output_path)

            # Verify and show new dimensions
            new_width, new_height = get_image_dimensions(str(output_path))

            print(f"\n{'='*60}")
            print(f"✓ 4K image saved: {output_path}")
            print(f"Final size: {new_width}x{new_height}")
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

def batch_upscale(input_dir, model="clarity", extensions=None):
    """Upscale all images in a directory"""
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

    # Filter out already upscaled images
    images = [img for img in images if '_4K' not in img.stem]

    if not images:
        print(f"No images found in {input_dir}")
        return

    print(f"Found {len(images)} image(s) to upscale")
    print(f"Model: {model}")
    print()

    for i, image in enumerate(images, 1):
        print(f"\n[{i}/{len(images)}] Processing: {image.name}")
        result = upscale_image(str(image), model=model)
        if result:
            print(f"✓ Completed: {Path(result).name}")
        else:
            print(f"✗ Failed: {image.name}")

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Single image: python upscale_image_to_4k.py <image.jpg> [model]")
        print("  Batch process: python upscale_image_to_4k.py --batch <directory> [model]")
        print()
        print("Available models:")
        for name, info in MODELS.items():
            print(f"  {name:12} - {info['description']} ({info['cost']})")
        print()
        print("Examples:")
        print("  python upscale_image_to_4k.py photo.jpg")
        print("  python upscale_image_to_4k.py photo.jpg creative")
        print("  python upscale_image_to_4k.py --batch ./photos clarity")
        sys.exit(1)

    if sys.argv[1] == "--batch":
        directory = sys.argv[2] if len(sys.argv) > 2 else "."
        model = sys.argv[3] if len(sys.argv) > 3 else "clarity"
        batch_upscale(directory, model)
    else:
        image_path = sys.argv[1]
        model = sys.argv[2] if len(sys.argv) > 2 else "clarity"
        upscale_image(image_path, model)

if __name__ == "__main__":
    main()
