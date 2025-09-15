#!/bin/bash

# Update App Icon Script
# Usage: ./update_app_icon.sh [version]
# Example: ./update_app_icon.sh 1.995
# If no version provided, auto-detect from git commit count

# Auto-detect version if not provided
if [ -z "$1" ]; then
    # Try to extract version from the latest commit message
    LATEST_COMMIT_MSG=$(git log -1 --pretty=%B)
    if echo "$LATEST_COMMIT_MSG" | grep -q "^v[0-9]\+\.[0-9]\+\.[0-9]\+"; then
        # Extract version from commit message like "v2.0.9: Add telescope navigation button"
        VERSION=$(echo "$LATEST_COMMIT_MSG" | grep -o "^v[0-9]\+\.[0-9]\+\.[0-9]\+" | sed 's/^v//')
        echo "🔍 Auto-detected version: $VERSION (from latest commit message)"
    else
        # Fallback to commit count if no version in commit message
        COMMIT_COUNT=$(git rev-list --count HEAD)
        VERSION="2.0.$COMMIT_COUNT"
        echo "🔍 Auto-detected version: $VERSION (fallback to commit count: $COMMIT_COUNT)"
    fi
else
    VERSION=$1
    echo "📝 Using provided version: $VERSION"
fi

echo "🎨 Updating app icon for version $VERSION..."

# Update the Python script with the new version
sed -i '' "s/version = \".*\"/version = \"$VERSION\"/" generate_app_icon.py

# Generate the new icon
python3 generate_app_icon.py

echo "✅ App icon updated to version $VERSION!"
echo "📱 The new icon will appear after your next build."
