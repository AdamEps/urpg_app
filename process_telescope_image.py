#!/usr/bin/env python3
"""
Script to process navigation icons by removing background and inverting to white
Usage: python3 process_telescope_image.py [icon_type]
Icon types: locationview, zoomoutmaps, starsystem, multisystems
"""

from PIL import Image, ImageOps
import sys
import os

def remove_background_and_invert(input_path, output_path, description="icon"):
    """
    Remove background from image and invert colors to white
    Args:
        input_path: Path to input image
        output_path: Output filename (without extension)
        description: Description for logging
    """
    try:
        # Open the image
        img = Image.open(input_path)

        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Create a new image with transparent background
        # For simplicity, we'll use a basic approach: remove white/light backgrounds
        # This assumes the icon is the main dark object on a light background
        datas = img.getdata()

        new_data = []
        for item in datas:
            # Remove white or very light pixels (adjust threshold as needed)
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                # Make this pixel transparent
                new_data.append((255, 255, 255, 0))
            else:
                new_data.append(item)

        img.putdata(new_data)

        # Always invert colors to make the icon white
        inverted_img = Image.new('RGBA', img.size, (0, 0, 0, 0))

        for x in range(img.width):
            for y in range(img.height):
                r, g, b, a = img.getpixel((x, y))
                if a > 0:  # Only invert non-transparent pixels
                    # Invert RGB values and keep them bright (towards white)
                    inverted_r = 255 - r
                    inverted_g = 255 - g
                    inverted_b = 255 - b
                    # Make sure the result is bright/white
                    max_val = max(inverted_r, inverted_g, inverted_b)
                    if max_val > 0:
                        inverted_r = int((inverted_r / max_val) * 255)
                        inverted_g = int((inverted_g / max_val) * 255)
                        inverted_b = int((inverted_b / max_val) * 255)
                    inverted_img.putpixel((x, y), (inverted_r, inverted_g, inverted_b, a))
                else:
                    inverted_img.putpixel((x, y), (0, 0, 0, 0))

        img = inverted_img

        # Crop to content bounds to remove excess transparent space
        # Get bounding box of non-transparent pixels
        bbox = ImageOps.invert(img.convert('RGB')).getbbox()
        if bbox:
            img = img.crop(bbox)

        # Add some padding
        width, height = img.size
        padding = 20
        img = ImageOps.expand(img, border=padding, fill=(0, 0, 0, 0))

        # Resize to a reasonable size for UI use (adjust as needed)
        max_size = 200
        if width > max_size or height > max_size:
            img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)

        # Save to Locations folder
        os.makedirs('/Users/adamepstein/Desktop/urpg_app/Locations', exist_ok=True)
        output_full_path = os.path.join('/Users/adamepstein/Desktop/urpg_app/Locations', output_path)
        img.save(output_full_path, 'PNG')

        print(f"✅ Successfully processed {description}!")
        print(f"📁 Saved to: {output_full_path}")
        print(f"📏 Final size: {img.size}")
        print("⚪ Icon has been inverted to white for use in navigation bar")

        return True

    except Exception as e:
        print(f"❌ Error processing image: {e}")
        return False

def process_icon(icon_type):
    """Process a specific icon type"""
    icon_config = {
        'locationview': {
            'input': 'Icons/In Game/locationView.png',
            'output': 'LocationView.png',
            'description': 'location view icon'
        },
        'zoomoutmaps': {
            'input': 'Icons/In Game/zoomOutMaps.jpg',
            'output': 'ZoomOutMaps.png',
            'description': 'zoom out maps icon'
        },
        'starsystem': {
            'input': 'Icons/In Game/starSystem.png',
            'output': 'StarSystem.png',
            'description': 'star system icon'
        },
        'multisystems': {
            'input': 'Icons/In Game/multiSystems.png',
            'output': 'MultiSystems.png',
            'description': 'multi systems icon'
        }
    }

    if icon_type not in icon_config:
        print(f"❌ Unknown icon type: {icon_type}")
        print("Available types: locationview, zoomoutmaps, starsystem, multisystems")
        return False

    config = icon_config[icon_type]
    input_path = os.path.join('/Users/adamepstein/Desktop/urpg_app', config['input'])

    if not os.path.exists(input_path):
        print(f"❌ Input file not found: {input_path}")
        return False

    return remove_background_and_invert(input_path, config['output'], config['description'])

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ['-h', '--help', 'help']:
        print("Usage:")
        print("  python3 process_telescope_image.py [icon_type]")
        print("  python3 process_telescope_image.py all")
        print("\nIcon types:")
        print("  locationview  - Process locationView.png")
        print("  zoomoutmaps   - Process zoomOutMaps.jpg")
        print("  starsystem    - Process starSystem.png")
        print("  multisystems  - Process multiSystems.png")
        print("  all           - Process all icons")
        print("\nThis script will:")
        print("1. Remove the background from your image")
        print("2. Save it to the Locations folder")
        print("3. Optimize the size for UI use")
        print("4. Invert colors to white for navigation bar")
        return

    icon_type = sys.argv[1]

    if icon_type == 'all':
        print("🚀 Processing all navigation icons...")
        success_count = 0
        for type_name in ['locationview', 'zoomoutmaps', 'starsystem', 'multisystems']:
            print(f"\n--- Processing {type_name} ---")
            if process_icon(type_name):
                success_count += 1

        print(f"\n🎉 Processing complete! {success_count}/4 icons processed successfully.")
    else:
        success = process_icon(icon_type)
        if success:
            print("\n🎉 Processing complete! You can now use the icon in your app.")
            print("💡 Tip: You may want to manually adjust the background removal if needed.")

if __name__ == "__main__":
    main()
