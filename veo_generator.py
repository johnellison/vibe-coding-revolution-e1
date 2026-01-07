#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Run with: source venv/bin/activate && python veo_generator.py
"""
Veo 3.1 Video Generator for JE Show E1
======================================

SETUP - Choose ONE method:

METHOD 1: Vertex AI (Google Cloud - recommended, higher quotas)
  1. Install gcloud: brew install google-cloud-sdk
  2. Authenticate: gcloud auth application-default login
  3. Set variables:
     export GOOGLE_CLOUD_PROJECT=your-project-id
     export GOOGLE_GENAI_USE_VERTEXAI=True

METHOD 2: Gemini API (AI Ultra subscription)
  1. Get API key from: https://aistudio.google.com/apikey
  2. Set variable:
     export GOOGLE_API_KEY=your-api-key-here

PRICING (Vertex AI):
- Veo 3.1: $0.20/second
- Veo 3.1 Fast: $0.15/second
- This script's 57 clips: ~$60-80

USAGE:
  python veo_generator.py --list              # List all prompts
  python veo_generator.py -p H01_data_flow_neural  # Generate one clip
  python veo_generator.py --batch --section HOOK   # Generate section
  python veo_generator.py --batch             # Generate all clips
"""

import time
import os
import argparse
from pathlib import Path

# Predefined prompts for E1 - The Vibe Coding Revolution
# Organized by section with both ABSTRACT and REALISTIC styles
PROMPTS = {
    # ═══════════════════════════════════════════════════════════════════
    # HOOK SECTION (0:00-0:45) - High energy, intriguing, urgent
    # ═══════════════════════════════════════════════════════════════════

    "H01_data_flow_neural": {
        "prompt": "Cinematic shot of glowing data streams flowing through a dark void, blue and purple light trails forming neural network patterns, 4K, futuristic aesthetic, slight camera movement tracking the flow, no text, no faces",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "H02_code_streaming": {
        "prompt": "Close-up of code scrolling rapidly on a dark screen, green and cyan syntax highlighting, reflections visible on a glass surface, cinematic depth of field, matrix-like but elegant and modern, no text overlays",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "H03_creator_laptop_night": {
        "prompt": "Cinematic close-up of hands typing on a glowing laptop keyboard in a dark room, screen light illuminating the scene, coffee cup nearby, authentic creative workspace not corporate, moody blue and warm accent lighting",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "H04_money_notifications": {
        "prompt": "Stylized visualization of digital notifications and numbers floating upward like particles, representing revenue and success, green accent colors on dark background, celebratory but not gaudy, modern minimal aesthetic",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "H05_extraction_vs_regeneration": {
        "prompt": "Split composition visual metaphor: left side shows cold blue corporate grid patterns converging to a central point representing extraction, right side shows warm organic golden light expanding outward like roots or mycelium representing regeneration, dark background, cinematic quality",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "H06_data_center_ominous": {
        "prompt": "Cinematic dolly shot through endless rows of server racks in a massive data center, blue LED lights blinking, steam or cold air visible, industrial scale, slightly ominous atmosphere, no people",
        "section": "HOOK",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # INTRO SECTION (0:45-2:00) - Confident, personal, authoritative
    # ═══════════════════════════════════════════════════════════════════

    "I01_startup_hustle": {
        "prompt": "Cinematic montage-style shot of a modern startup workspace, whiteboards with diagrams, multiple screens with code and data, energy and movement, natural lighting through windows, authentic not staged, no direct faces",
        "section": "INTRO",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "I02_transformation_paradigm": {
        "prompt": "Abstract visualization of transformation, particles of light reorganizing from chaos into ordered beautiful patterns, representing paradigm shift, dark background with vibrant blue and gold accent colors, cinematic quality, slow motion",
        "section": "INTRO",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "I03_chatgpt_moment": {
        "prompt": "A single bright point of light that pulses and creates expanding concentric waves of energy, each wave becoming more complex and structured, representing breakthrough moment, dark space background, epic scale",
        "section": "INTRO",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "I04_building_metaphor": {
        "prompt": "Timelapse-style visualization of digital architecture being constructed from light particles, structures forming and connecting, representing software being built, blue and white color scheme, satisfying construction visual",
        "section": "INTRO",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "I05_growth_chart_abstract": {
        "prompt": "Abstract visualization of exponential growth, a line of light that curves upward and accelerates, leaving trails of particles, representing rapid scaling, dark background with green and gold accents, cinematic",
        "section": "INTRO",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # MAIN 1 SECTION (2:00-7:00) - The Pattern & Hidden Cost
    # Analytical, myth-busting, slightly urgent/ominous
    # ═══════════════════════════════════════════════════════════════════

    "M1_01_retro_computer": {
        "prompt": "Nostalgic shot of a vintage 1990s computer setup, CRT monitor with green text, beige keyboard, old desk lamp, warm tungsten lighting, grainy film aesthetic, representing early internet era",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_02_dotcom_bubble": {
        "prompt": "Abstract visualization of a bubble forming from light particles, growing larger and more fragile, iridescent surface, tension building, representing dot-com bubble, dark background, slow motion",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_03_attention_converging": {
        "prompt": "Abstract visualization of countless small light particles being pulled toward a central gravitational point, representing attention and capital concentration, starts dispersed becomes intensely focused, dark void background",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_04_system_collapse": {
        "prompt": "Abstract geometric structure like a complex crystalline network slowly revealing hairline cracks, fragments beginning to drift apart, not violent but revealing underlying fragility, moody blue lighting, cinematic",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_05_mining_extraction": {
        "prompt": "Cinematic aerial shot of a massive open pit mine, terraced earth in geometric patterns, industrial scale of resource extraction, dust in the air, harsh daylight, documentary style but stylized",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_06_rare_earth_minerals": {
        "prompt": "Close-up macro shot of raw minerals and rare earth elements, metallic textures, crystalline structures, industrial lighting, representing the physical materials behind digital infrastructure",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_07_power_plant": {
        "prompt": "Cinematic wide shot of a power plant with cooling towers releasing steam into the sky, industrial landscape, dramatic clouds, representing energy infrastructure, moody atmospheric lighting",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_08_water_cooling": {
        "prompt": "Cinematic shot of water flowing through industrial cooling systems, pipes and infrastructure, blue tinted lighting, representing the hidden water cost of data centers, industrial beauty",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_09_server_farm_scale": {
        "prompt": "Dramatic drone-style shot pulling back to reveal the massive scale of a data center campus, multiple buildings, parking lots, industrial infrastructure as far as the eye can see, sunset lighting",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_10_power_concentration": {
        "prompt": "Six glowing orbs of different colors slowly orbiting and merging toward a central point, representing tech company consolidation, dark space background, ominous but beautiful, slow deliberate movement",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_11_corporate_towers": {
        "prompt": "Cinematic upward shot of sleek corporate skyscrapers made of glass and steel, reflections of clouds, imposing scale, representing concentrated corporate power, cool blue tones",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M1_12_profit_stark": {
        "prompt": "Minimalist abstract shot: a single gold coin or currency symbol slowly rotating in a dark void, cold lighting, stark and unsettling, representing profit as the sole metric",
        "section": "MAIN1",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # MAIN 2 SECTION (7:00-10:30) - Who This Is For
    # Inclusive, inspiring, defining the audience
    # ═══════════════════════════════════════════════════════════════════

    "M2_01_global_perspectives": {
        "prompt": "Cinematic montage of different global locations - a home office in a tropical setting, a cafe workspace, a modest apartment desk - representing diverse builders around the world, warm natural lighting, authentic spaces",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_02_hands_building": {
        "prompt": "Close-up of diverse hands working - typing on keyboard, writing in notebook, sketching on tablet - representing builders creating, warm lighting, intimate and human, no faces visible",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_03_privilege_choice": {
        "prompt": "Contemplative shot of a comfortable modern living space with large windows, morning light streaming in, laptop open on a table, representing the privilege of choice, peaceful and reflective",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_04_mind_expanding": {
        "prompt": "Abstract POV shot of consciousness expanding outward, starting from a single point and blooming into infinite fractal patterns of light, representing new perspective, warm golden and purple tones, transcendent feeling",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_05_amplification": {
        "prompt": "A human heartbeat pulse visualized as a wave of warm light that gets amplified and multiplied, each echo becoming larger and more powerful, representing AI amplification of human intent, organic to digital transition",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_06_crossroads_choice": {
        "prompt": "Aerial cinematic shot of a lone figure standing at a crossroads where two distinct paths diverge in a minimalist abstract landscape, one path glows cold blue, the other warm gold, golden hour lighting, contemplative mood",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M2_07_problem_solving": {
        "prompt": "Abstract visualization of a complex tangled knot of light slowly unraveling into an elegant solution, representing problem-solving, satisfying transformation, blue to gold color transition",
        "section": "MAIN2",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # MAIN 3 SECTION (10:30-15:00) - Life as Design Principle
    # Passionate, visionary, emotional peak
    # ═══════════════════════════════════════════════════════════════════

    "M3_01_climate_storms": {
        "prompt": "Dramatic cinematic shot of storm clouds gathering over a landscape, lightning in the distance, representing climate disruption, dark and ominous but beautiful, epic scale",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_02_biodiversity_life": {
        "prompt": "Stunning aerial shot of a vibrant rainforest canopy, mist rising, incredible density of green life, representing biodiversity, morning golden light, sense of abundance and interconnection",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_03_water_scarcity": {
        "prompt": "Cinematic shot of a dried riverbed or cracked earth, contrast between what was water and what remains, representing freshwater depletion, harsh sunlight, documentary style",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_04_soil_hands": {
        "prompt": "Close-up of hands holding rich dark soil, life teeming within, roots visible, representing soil health and regeneration, warm natural lighting, intimate and grounded",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_05_ecosystem_web": {
        "prompt": "Abstract visualization of an ecosystem as an interconnected web of light, nodes pulsing with life energy, showing relationships and dependencies, organic patterns, bioluminescent aesthetic",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_06_indigenous_land": {
        "prompt": "Respectful cinematic wide shot of ancestral lands - mountains, forests, rivers - representing indigenous territories, no people, golden hour lighting, sacred and timeless feeling",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_07_traditional_wisdom": {
        "prompt": "Close-up of hands working with natural materials - weaving, carving, tending plants - representing traditional knowledge and craftsmanship, warm lighting, dignity and skill, no faces",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_08_design_failure": {
        "prompt": "Complex interconnected network visualization slowly fragmenting and separating, nodes losing connections, representing systemic design failure, clinical white and red warning colors transitioning to darkness",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_09_revolution_dawn": {
        "prompt": "Dawn breaking over a digital landscape, first rays of golden light touching geometric crystalline forms that begin to glow and transform, sense of new era beginning, cinematic wide sweep, hopeful and epic tone",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_10_small_team_power": {
        "prompt": "Cinematic shot of a small group of people huddled around laptops in a modest space, energy and focus, screens glowing, representing small teams with big impact, warm intimate lighting, authentic not staged",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_11_individual_builder": {
        "prompt": "Silhouette of a single person at a desk with glowing screen, outside the window a vast landscape is visible, representing individual agency to create change, dramatic lighting contrast",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_12_values_code": {
        "prompt": "Abstract visualization of organic red heartbeat rhythm pulse transforming into flowing lines of elegant code, warm organic colors transitioning to cool tech blues while maintaining the organic pulse pattern throughout",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M3_13_intention_ripple": {
        "prompt": "A single drop of golden light falling into a dark void, creating expanding ripples that transform the darkness into patterns of life, representing intention creating change, beautiful and meditative",
        "section": "MAIN3",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # MAIN 4 SECTION (15:00-18:30) - Personal Truth & The How
    # Reflective, honest, instructive
    # ═══════════════════════════════════════════════════════════════════

    "M4_01_highs_lows_journey": {
        "prompt": "Abstract visualization of a journey - a path of light that rises and falls like a heartbeat or mountain range, representing the highs and lows of life, emotional color transitions from cool to warm",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_02_quiet_success": {
        "prompt": "Peaceful shot of morning light through a window, simple objects - a cup of tea, a book, a plant - representing quiet contentment beyond material success, warm and contemplative",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_03_purpose_light": {
        "prompt": "Single candle flame in darkness slowly revealing it's actually a beacon that illuminates a vast landscape, representing purpose illuminating life path, intimate to epic scale transition, warm golden light",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_04_service_to_life": {
        "prompt": "Beautiful shot of hands planting a seedling in rich soil, representing service to life, morning golden light, hopeful and grounded, close-up intimate perspective",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_05_watershed_restoration": {
        "prompt": "Cinematic aerial shot of a healthy watershed - river winding through green landscape, representing restoration work, vibrant colors, life abundant, sense of healing",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_06_building_in_public": {
        "prompt": "Over-the-shoulder shot of someone at a computer with code editor and terminal visible, cursor blinking, representing building in public, cozy workspace, authentic developer environment",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_07_practical_guide": {
        "prompt": "Clean visualization of a step-by-step process - abstract blocks or nodes lighting up in sequence, representing a practical guide or tutorial, minimal and clear, blue and white tones",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "M4_08_leverage_scale": {
        "prompt": "Abstract visualization of a small input creating a massive output - a tiny light triggering a cascade of larger and larger effects, representing leverage and scale, satisfying exponential visual",
        "section": "MAIN4",
        "duration": 4,
        "aspect_ratio": "16:9"
    },

    # ═══════════════════════════════════════════════════════════════════
    # CTA SECTION (18:30-20:00) - Invitation to Build
    # Direct, inspiring, actionable, forward-looking
    # ═══════════════════════════════════════════════════════════════════

    "C01_planetary_abundance": {
        "prompt": "Stunning view of Earth from space, not the cliche blue marble but a living breathing planet with visible weather systems and lights, representing planetary abundance, awe-inspiring, hopeful",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "C02_abundance_bloom": {
        "prompt": "Abstract visualization of abundance - golden light particles multiplying and spreading outward like seeds taking root, each one spawning more growth, regenerative pattern, hopeful and expansive feeling",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "C03_community_connect": {
        "prompt": "Abstract visualization of individual points of light finding each other and forming connections, building a network of community, warm colors, sense of belonging and movement",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "C04_forward_horizon": {
        "prompt": "Cinematic forward tracking shot moving toward a bright horizon where digital and natural elements merge harmoniously, representing hopeful future, sunrise colors, epic and inspiring, smooth camera movement",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "C05_new_day_dawn": {
        "prompt": "Beautiful timelapse-style shot of sun rising over mountains or ocean, new day beginning, golden light spreading across the landscape, representing new beginnings, cinematic and hopeful",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    },
    "C06_keep_building": {
        "prompt": "Final shot: hands on keyboard with warm light, screen reflecting in glasses or surface nearby, a sense of purpose and continuation, representing ongoing work, intimate and determined",
        "section": "CTA",
        "duration": 4,
        "aspect_ratio": "16:9"
    }
}


def get_auth_mode():
    """Determine which authentication mode to use."""
    use_vertex = os.environ.get('GOOGLE_GENAI_USE_VERTEXAI', '').lower() == 'true'
    project_id = os.environ.get('GOOGLE_CLOUD_PROJECT')
    api_key = os.environ.get('GOOGLE_API_KEY')

    if use_vertex and project_id:
        return 'vertex', project_id
    elif api_key:
        return 'gemini', api_key
    else:
        return None, None


def setup_check():
    """Check if environment is properly configured."""
    mode, credential = get_auth_mode()

    if mode == 'vertex':
        print(f"✅ Vertex AI mode (project: {credential})")
        print("   Using Google Cloud billing ($0.15-0.20/second)")
    elif mode == 'gemini':
        print(f"✅ Gemini API mode (key: {credential[:8]}...)")
        print("   Using AI Ultra credits")
    else:
        print("❌ No authentication configured")
        print("\nSetup Option 1 - Vertex AI (recommended):")
        print("  gcloud auth application-default login")
        print("  export GOOGLE_CLOUD_PROJECT=your-project-id")
        print("  export GOOGLE_GENAI_USE_VERTEXAI=True")
        print("\nSetup Option 2 - Gemini API:")
        print("  export GOOGLE_API_KEY=your-api-key-here")
        return False

    try:
        from google import genai
        print("✅ google-genai SDK installed")
    except ImportError:
        print("❌ google-genai SDK not installed")
        print("   Run: pip install --upgrade google-genai")
        return False

    return True


def generate_video(prompt_key: str, output_dir: str, use_fast: bool = False):
    """Generate a single video clip using Vertex AI or Gemini API."""
    from google import genai
    from google.genai.types import GenerateVideosConfig

    if prompt_key not in PROMPTS:
        print(f"❌ Unknown prompt key: {prompt_key}")
        print(f"   Available: {', '.join(PROMPTS.keys())}")
        return None

    prompt_data = PROMPTS[prompt_key]
    mode, credential = get_auth_mode()

    # Select model based on mode
    if mode == 'vertex':
        model = "veo-3.1-fast-generate-001" if use_fast else "veo-3.1-generate-001"
        cost_per_sec = 0.15 if use_fast else 0.20
        cost_estimate = prompt_data["duration"] * cost_per_sec
        cost_str = f"~${cost_estimate:.2f}"
    else:
        model = "veo-3.1-fast-generate-preview" if use_fast else "veo-3.1-generate-preview"
        cost_str = "~50-100 credits"

    print(f"\n🎬 Generating: {prompt_key}")
    print(f"   Section: {prompt_data['section']}")
    print(f"   Duration: {prompt_data['duration']}s")
    print(f"   Model: {model}")
    print(f"   Cost: {cost_str}")
    print(f"   Prompt: {prompt_data['prompt'][:80]}...")

    # Initialize client based on mode
    if mode == 'vertex':
        # Vertex AI uses application default credentials
        client = genai.Client(vertexai=True, project=credential, location="us-central1")
    else:
        # Gemini API uses API key
        client = genai.Client(api_key=credential)

    # Ensure output directory exists
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    output_file = output_path / f"{prompt_key}.mp4"

    try:
        operation = client.models.generate_videos(
            model=model,
            prompt=prompt_data["prompt"],
            config=GenerateVideosConfig(
                aspect_ratio=prompt_data["aspect_ratio"],
                resolution="1080p",
                number_of_videos=1,
            ),
        )

        print("   ⏳ Generating (this may take 2-5 minutes)...")

        while not operation.done:
            time.sleep(15)
            operation = client.operations.get(operation)
            print("   ⏳ Still processing...")

        if operation.response and operation.result.generated_videos:
            video = operation.result.generated_videos[0]

            # Try to save video to local file
            if hasattr(video, 'video') and hasattr(video.video, 'video_bytes') and video.video.video_bytes:
                with open(output_file, 'wb') as f:
                    f.write(video.video.video_bytes)
                print(f"   ✅ Saved to: {output_file}")
                return str(output_file)
            elif hasattr(video, 'video') and hasattr(video.video, 'uri') and video.video.uri:
                uri = video.video.uri
                print(f"   ✅ Complete! Video URI: {uri}")
                # Try to download from GCS if it's a gs:// URI
                if uri.startswith("gs://"):
                    print(f"   📥 Downloading from GCS...")
                    import subprocess
                    result = subprocess.run(
                        ["gsutil", "cp", uri, str(output_file)],
                        capture_output=True, text=True
                    )
                    if result.returncode == 0:
                        print(f"   ✅ Saved to: {output_file}")
                        return str(output_file)
                    else:
                        print(f"   ⚠️ gsutil download failed: {result.stderr}")
                        return uri
                return uri
            else:
                print(f"   ⚠️ Video generated but format unexpected")
                print(f"   Response: {video}")
                return str(video)
        else:
            print(f"   ❌ Generation failed or no videos returned")
            if hasattr(operation, 'error'):
                print(f"   Error: {operation.error}")
            return None

    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None


def generate_batch(output_dir: str, section: str = None, use_fast: bool = False):
    """Generate multiple videos, optionally filtered by section."""
    prompts_to_generate = PROMPTS

    if section:
        prompts_to_generate = {k: v for k, v in PROMPTS.items() if v["section"] == section.upper()}

    if not prompts_to_generate:
        print(f"❌ No prompts found for section: {section}")
        return

    # Calculate total credits estimate
    total_clips = len(prompts_to_generate)
    credits_per_clip = 50 if use_fast else 100
    total_credits = total_clips * credits_per_clip

    print(f"\n📦 Batch Generation")
    print(f"   Clips: {total_clips}")
    print(f"   Est. credits: ~{total_credits} (you have ~12,500/month with AI Ultra)")
    print(f"   Output: {output_dir}")

    confirm = input("\n   Continue? (y/n): ")
    if confirm.lower() != 'y':
        print("   Cancelled.")
        return

    results = {}
    for key in prompts_to_generate:
        result = generate_video(key, output_dir, use_fast)
        results[key] = result

    print("\n📊 Results:")
    for key, result in results.items():
        status = "✅" if result else "❌"
        print(f"   {status} {key}")

    return results


def list_prompts():
    """List all available prompts organized by section."""
    sections = {}
    for key, data in PROMPTS.items():
        section = data["section"]
        if section not in sections:
            sections[section] = []
        sections[section].append((key, data))

    total_seconds = 0
    total_cost_standard = 0
    total_cost_fast = 0

    section_labels = {
        "HOOK": "HOOK (0:00-0:45) - High energy opener",
        "INTRO": "INTRO (0:45-2:00) - Credibility & proof",
        "MAIN1": "MAIN 1 (2:00-7:00) - Pattern & hidden cost",
        "MAIN2": "MAIN 2 (7:00-10:30) - Who this is for",
        "MAIN3": "MAIN 3 (10:30-15:00) - Life as design principle",
        "MAIN4": "MAIN 4 (15:00-18:30) - Personal truth & how",
        "CTA": "CTA (18:30-20:00) - Invitation to build"
    }

    print("\n📋 Available Prompts for E1 - The Vibe Coding Revolution")
    print("=" * 60 + "\n")

    for section in ["HOOK", "INTRO", "MAIN1", "MAIN2", "MAIN3", "MAIN4", "CTA"]:
        if section not in sections:
            continue
        section_total = sum(d["duration"] for _, d in sections[section])
        print(f"═══ {section_labels.get(section, section)} ({len(sections[section])} clips, {section_total}s) ═══\n")
        for key, data in sections[section]:
            duration = data["duration"]
            total_seconds += duration
            total_cost_standard += duration * 0.20
            total_cost_fast += duration * 0.15
            print(f"  🎬 {key}")
            print(f"     {duration}s | {data['aspect_ratio']}")
            print(f"     {data['prompt'][:65]}...")
            print()

    print("=" * 60)
    print(f"📊 TOTALS")
    print(f"   Clips: {len(PROMPTS)}")
    print(f"   Total duration: {total_seconds}s ({total_seconds/60:.1f} min of footage)")
    print(f"   Cost (Veo 3.1 standard @ $0.20/s): ${total_cost_standard:.2f}")
    print(f"   Cost (Veo 3.1 Fast @ $0.15/s): ${total_cost_fast:.2f}")
    print("=" * 60)


def download_from_gcs(bucket_uri: str, local_dir: str):
    """Download generated videos from GCS to local directory."""
    import subprocess

    local_path = Path(local_dir)
    local_path.mkdir(parents=True, exist_ok=True)

    print(f"\n📥 Downloading from {bucket_uri} to {local_dir}")

    result = subprocess.run(
        ["gsutil", "-m", "cp", "-r", f"{bucket_uri}/*", str(local_path)],
        capture_output=True,
        text=True
    )

    if result.returncode == 0:
        print("✅ Download complete!")
        # List downloaded files
        for f in local_path.glob("**/*.mp4"):
            print(f"   📁 {f.name}")
    else:
        print(f"❌ Download failed: {result.stderr}")


def main():
    # Default output directory
    default_output = str(Path(__file__).parent.parent / "Assets" / "B-Roll" / "AI-Generated")

    parser = argparse.ArgumentParser(description="Veo 3.1 Video Generator for JE Show E1")
    parser.add_argument("--prompt", "-p", help="Generate specific prompt by key")
    parser.add_argument("--batch", "-b", action="store_true", help="Generate all prompts")
    parser.add_argument("--section", "-s", help="Filter by section (HOOK, INTRO, MAIN1, MAIN2, MAIN3, MAIN4, CTA)")
    parser.add_argument("--list", "-l", action="store_true", help="List all available prompts")
    parser.add_argument("--output", "-o", default=default_output, help="Output directory for videos")
    parser.add_argument("--fast", "-f", action="store_true", help="Use Veo 3.1 Fast (faster, fewer credits)")
    parser.add_argument("--check", "-c", action="store_true", help="Check setup/configuration")

    args = parser.parse_args()

    if args.check:
        setup_check()
        return

    if args.list:
        list_prompts()
        return

    if not setup_check():
        return

    if args.prompt:
        generate_video(args.prompt, args.output, args.fast)
    elif args.batch:
        generate_batch(args.output, args.section, args.fast)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
