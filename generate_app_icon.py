#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(version="2.0.6", size=1024):
    """
    Create a black app icon with white bold URPG text and version number
    """
    # Create a black background
    img = Image.new('RGB', (size, size), color='black')
    draw = ImageDraw.Draw(img)
    
    # Try to use a system font, fallback to default if not available
    try:
        # Try to use a bold system font
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.25))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.08))
    except:
        try:
            # Fallback to Arial Bold
            font_large = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", int(size * 0.25))
            font_small = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", int(size * 0.08))
        except:
            # Use default font
            font_large = ImageFont.load_default()
            font_small = ImageFont.load_default()
    
    # Get text dimensions for centering
    text_urpg = "URPG"
    text_version = f"v{version}"
    
    # Calculate text positions (centered)
    bbox_urpg = draw.textbbox((0, 0), text_urpg, font=font_large)
    bbox_version = draw.textbbox((0, 0), text_version, font=font_small)
    
    urpg_width = bbox_urpg[2] - bbox_urpg[0]
    urpg_height = bbox_urpg[3] - bbox_urpg[1]
    version_width = bbox_version[2] - bbox_version[0]
    version_height = bbox_version[3] - bbox_version[1]
    
    # Position URPG text (centered horizontally, slightly above center vertically)
    urpg_x = (size - urpg_width) // 2
    urpg_y = (size - urpg_height - version_height - 20) // 2
    
    # Position version text (centered horizontally, below URPG)
    version_x = (size - version_width) // 2
    version_y = urpg_y + urpg_height + 20
    
    # Draw the text in white
    draw.text((urpg_x, urpg_y), text_urpg, fill='white', font=font_large)
    draw.text((version_x, version_y), text_version, fill='white', font=font_small)
    
    return img

def main():
    version = "2.0.9"  # Default version (will be overridden by update script)
    
    # Create the app icon
    print(f"Creating app icon for version {version}...")
    icon = create_app_icon(version)
    
    # Save the icon
    icon_path = "/Users/adamepstein/Desktop/urpg_app/UniverseRPG/UniverseRPG/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    icon.save(icon_path, "PNG")
    print(f"App icon saved to: {icon_path}")
    
    # Also create a preview version
    preview_path = "/Users/adamepstein/Desktop/urpg_app/app_icon_preview.png"
    icon.save(preview_path, "PNG")
    print(f"Preview saved to: {preview_path}")
    
    print("✅ App icon generated successfully!")

if __name__ == "__main__":
    main()
