# 🚀 UniverseRPG App Launcher

Multiple ways to launch your UniverseRPG app:

## 🎯 Quick Launch Options

### 1. **Sweetpad Extension (Recommended)**
- Install Sweetpad extension in Cursor
- Press `Cmd+Shift+P` → "Sweetpad: Build & Run (Launch)"
- App will automatically build and launch on your iPhone

### 2. **VS Code Tasks**
- Press `Cmd+Shift+P` → "Tasks: Run Task"
- Choose from:
  - 🚀 **Launch UniverseRPG on iPhone** (build + install + launch)
  - 🔨 **Build UniverseRPG for iPhone** (build only)
  - 📱 **Install UniverseRPG on iPhone** (install only)
  - ▶️ **Start UniverseRPG on iPhone** (launch only)

### 3. **Terminal Scripts**
```bash
# Launch on iPhone
./launch_app.sh

# Launch on Simulator
./launch_simulator.sh
```

### 4. **Debug Panel**
- Go to Run and Debug panel (Cmd+Shift+D)
- Click the play button next to "🚀 Launch UniverseRPG on iPhone"

## 📱 Device Configuration

- **iPhone**: Adam's iPhone (00008140-00180CA80A53001C)
- **Simulator**: iPhone 16 (iOS 18.6)
- **Bundle ID**: com.universerpg.app.UniverseRPG

## 🔧 Troubleshooting

If the app fails to launch:
1. Make sure your iPhone is connected and trusted
2. Check that Xcode is signed in with your Apple ID
3. Try running the build task first, then install/launch separately

## 🎮 Happy Coding!

Your UniverseRPG app is ready to launch with just one click! 🎉
