#!/bin/bash

# UniverseRPG Simulator Launcher Script
# This script builds and launches the UniverseRPG app on iPhone Simulator

echo "🚀 Building UniverseRPG for iPhone Simulator..."
xcodebuild -project UniverseRPG/UniverseRPG.xcodeproj -scheme UniverseRPG -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Installing app on simulator..."
    xcrun simctl install "iPhone 16" "/Users/adamepstein/Library/Developer/Xcode/DerivedData/UniverseRPG-ffqhybhqfhiiathcmlkhxgtlvrce/Build/Products/Debug-iphonesimulator/UniverseRPG.app"
    
    if [ $? -eq 0 ]; then
        echo "✅ App installed! Launching on simulator..."
        xcrun simctl launch "iPhone 16" com.universerpg.app.UniverseRPG
        echo "🎉 UniverseRPG is now running on iPhone Simulator!"
    else
        echo "❌ Failed to install app on simulator"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
