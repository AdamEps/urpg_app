#!/bin/bash

# UniverseRPG App Launcher Script
# This script builds and launches the UniverseRPG app on your iPhone

echo "🚀 Building UniverseRPG for iPhone..."
xcodebuild -project UniverseRPG/UniverseRPG.xcodeproj -scheme UniverseRPG -destination "platform=iOS,id=00008140-00180CA80A53001C" build

if [ $? -eq 0 ]; then
    echo "✅ Build successful! Installing app on iPhone..."
    xcrun devicectl device install app --device 00008140-00180CA80A53001C "/Users/adamepstein/Library/Developer/Xcode/DerivedData/UniverseRPG-ffqhybhqfhiiathcmlkhxgtlvrce/Build/Products/Debug-iphoneos/UniverseRPG.app"
    
    if [ $? -eq 0 ]; then
        echo "✅ App installed! Launching on iPhone..."
        xcrun devicectl device process launch --device 00008140-00180CA80A53001C com.universerpg.app.UniverseRPG
        echo "🎉 UniverseRPG is now running on your iPhone!"
    else
        echo "❌ Failed to install app on device"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi
