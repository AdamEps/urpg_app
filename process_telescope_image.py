#!/usr/bin/env python3
"""
Script to process telescope image by removing background and saving to Locations folder
Usage: python3 process_telescope_image.py input_image.png
"""

from PIL import Image, ImageOps
import sys
import os

def remove_background_and_save(input_path, output_path, is_saturn=False):
    """
    Remove background from image and save to Locations folder
    Args:
        input_path: Path to input image
        output_path: Output filename (without extension)
        is_saturn: If True, invert colors to make the icon white
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

        # If this is the Saturn icon, invert colors to make it white
        if is_saturn:
            # Create a new image for inversion
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
        output_full_path = os.path.join('/Users/adamepstein/Desktop/urpg_app/Locations', output_filename)
        img.save(output_full_path, 'PNG')

        if is_saturn:
            print(f"✅ Successfully processed Saturn location icon!")
            print(f"📁 Saved to: {output_full_path}")
            print(f"📏 Final size: {img.size}")
            print("🌍 Icon has been inverted to white for use in navigation bar")
        else:
            print(f"✅ Successfully processed telescope image!")
            print(f"📁 Saved to: {output_full_path}")
            print(f"📏 Final size: {img.size}")

        return True

    except Exception as e:
        print(f"❌ Error processing image: {e}")
        return False

def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3 or sys.argv[1] in ['-h', '--help', 'help']:
        print("Usage:")
        print("  python3 process_telescope_image.py input_image.png              # For telescope")
        print("  python3 process_telescope_image.py input_image.png --saturn     # For Saturn location icon")
        print("\nThis script will:")
        print("1. Remove the background from your image")
        print("2. Save it to the Locations folder")
        print("3. Optimize the size for UI use")
        print("4. For Saturn icon: invert colors to white for navigation bar")
        return

    input_path = sys.argv[1]
    is_saturn = len(sys.argv) > 2 and sys.argv[2] == '--saturn'

    if not os.path.exists(input_path):
        print(f"❌ Input file not found: {input_path}")
        return

    # Determine output filename
    output_filename = 'SaturnLocation.png' if is_saturn else 'Telescope.png'

    success = remove_background_and_save(input_path, output_filename, is_saturn)

    if success:
        if is_saturn:
            print("\n🎉 Processing complete! You can now use SaturnLocation.png in your app.")
            print("💡 The icon has been inverted to white for the navigation bar.")
        else:
            print("\n🎉 Processing complete! You can now use Telescope.png in your app.")
            print("💡 Tip: You may want to manually adjust the background removal if needed.")

if __name__ == "__main__":
    main()
