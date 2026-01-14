# Xcode Project Setup Instructions

The iOS project is now a complete Xcode project in the git repo. Just clone/pull and open.

## Prerequisites

- Mac with Xcode 14+ installed (free from Mac App Store)
- Apple ID (free)
- iPad with iOS 15+ for device testing
- USB cable to connect iPad to Mac

---

## Step 1: Open the Project

1. Clone or pull the repo
2. Navigate to `ios/` folder
3. Double-click `AdhanApp.xcodeproj` to open in Xcode

That's it - the project is fully configured.

---

## Step 2: Configure Signing (One-Time)

1. In Xcode, click on **AdhanApp** in the left sidebar (blue project icon)
2. Select the **AdhanApp** target
3. Go to **Signing & Capabilities** tab
4. Under "Signing":
   - Check **Automatically manage signing**
   - Set **Team** to your Apple ID (click dropdown, select "Add Account" if needed)
5. The "Bundle Identifier" may need to be unique - change `com.adhan.app` to something like `com.yourname.adhan`

---

## Step 3: Build for Simulator (Validation)

1. At the top of Xcode, click the device selector
2. Select an iPad simulator (e.g., "iPad Pro 11-inch")
3. Press **⌘R** (or click the Play button)

**Expected Result**: App launches showing "Phase 2: Audio Validation" with Play/Stop buttons.

---

## Step 4: Deploy to Physical iPad

### Connect and Select Device

1. Connect your iPad to Mac via USB
2. On iPad: Tap "Trust" when prompted to trust this computer
3. In Xcode's device selector, choose your iPad (appears by name)

### First-Time Trust

1. Click **Run** (⌘R)
2. Build will succeed but app may not launch
3. On iPad: **Settings → General → VPN & Device Management**
4. Tap your Apple ID under "Developer App"
5. Tap **Trust "Apple Development: your@email.com"**
6. Return to Xcode and click **Run** again

---

## Step 5: Critical Audio Test

Once the app is running on your iPad:

1. **Verify** the screen shows a green checkmark: "adhan.mp3 found in bundle"
2. Tap **Play Adhan** - audio should start
3. **While audio is playing, lock the screen** (press power button)
4. **Listen for 10+ seconds**

### Results

- ✅ **Audio continues with screen locked** → Phase 2 passes, proceed with development
- ❌ **Audio stops when screen locked** → Report back for debugging

---

## Troubleshooting

### "adhan.mp3 NOT FOUND" (red X)

The audio file reference might be broken. In Xcode:
1. Right-click on **AdhanApp** folder in sidebar
2. Select "Add Files to AdhanApp"
3. Navigate to `adhan/adhan.mp3` (in repo root)
4. Ensure "Copy items if needed" is checked
5. Click Add

### Signing Error

- Make sure Team is set to your Apple ID
- Try changing Bundle Identifier to something unique

### App Won't Launch on Device

- Check Settings → General → VPN & Device Management
- Trust the developer certificate

### Build Errors

- Clean build: Product → Clean Build Folder (⇧⌘K)
- Close and reopen Xcode

---

## Project Structure

```
ios/
├── AdhanApp.xcodeproj/      # Xcode project (open this)
│   └── project.pbxproj      # Project configuration
└── AdhanApp/                # Source code
    ├── AdhanApp.swift       # App entry point
    ├── ContentView.swift    # Main view
    ├── Info.plist           # App configuration
    ├── AdhanApp.entitlements
    ├── Assets.xcassets/     # Images, colors
    ├── Models/              # Data models
    ├── Services/            # API, Audio, Location
    ├── ViewModels/          # State management
    └── Views/               # SwiftUI views
```

All changes you make in Xcode are saved directly to these files in the git repo.
