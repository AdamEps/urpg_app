#!/bin/bash

# Update App Icon Script
# Usage: ./update_app_icon.sh [version]
# Example: ./update_app_icon.sh 1.995

VERSION=${1:-"1.994"}

echo "🎨 Updating app icon for version $VERSION..."

# Update the Python script with the new version
sed -i '' "s/version = \".*\"/version = \"$VERSION\"/" generate_app_icon.py

# Generate the new icon
python3 generate_app_icon.py

echo "✅ App icon updated to version $VERSION!"
echo "📱 The new icon will appear after your next build."
