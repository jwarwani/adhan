# Xcode Project Setup Instructions

Follow these steps to create the AdhanApp project in Xcode using the generated source files.

## Prerequisites

- Mac with Xcode 14+ installed (free from Mac App Store)
- Apple ID (free)
- iPad with iOS 15+ for device testing
- USB cable to connect iPad to Mac

---

## Step 1: Create New Xcode Project

1. Open Xcode
2. Click **"Create a new Xcode project"** (or File → New → Project)
3. Select **iOS** tab at the top
4. Select **App** and click **Next**
5. Fill in project details:
   - **Product Name**: `AdhanApp`
   - **Team**: Select your Apple ID (or "Add Account" if not logged in)
   - **Organization Identifier**: `com.yourname` (e.g., `com.jwarwani`)
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `None`
   - Uncheck "Include Tests" (optional, can leave checked)
6. Click **Next**
7. Choose a location to save the project (e.g., Desktop)
8. Click **Create**

---

## Step 2: Configure Project Settings

### Set iOS Deployment Target

1. Click on **AdhanApp** in the left sidebar (blue icon at top)
2. Select the **AdhanApp** target
3. Go to **General** tab
4. Under "Minimum Deployments", change iOS to **15.0**

### Set Device Orientation (iPad Landscape Only)

1. Still in **General** tab
2. Under "Deployment Info":
   - Uncheck **iPhone** (iPad only)
   - Uncheck **Portrait**
   - Check **Landscape Left** and **Landscape Right**

### Enable Background Audio

1. Go to **Signing & Capabilities** tab
2. Click **+ Capability** button (top left)
3. Search for **Background Modes** and double-click to add
4. Check **Audio, AirPlay, and Picture in Picture**

---

## Step 3: Configure Info.plist

1. In the left sidebar, find and click on **Info** (or Info.plist)
2. Add these entries by clicking the **+** button:

| Key | Type | Value |
|-----|------|-------|
| Privacy - Location When In Use Usage Description | String | Your location is used to calculate accurate prayer times for your area. |
| Requires full screen | Boolean | YES |
| Status bar is initially hidden | Boolean | YES |

**Note**: If Background Modes capability was added correctly, `UIBackgroundModes` with `audio` should already be there.

---

## Step 4: Replace Source Files

1. In Xcode's left sidebar, expand the **AdhanApp** folder (yellow folder icon)
2. You'll see default files: `AdhanAppApp.swift`, `ContentView.swift`

### Delete Default Files
1. Right-click on `AdhanAppApp.swift` → Delete → Move to Trash
2. Right-click on `ContentView.swift` → Delete → Move to Trash

### Add Generated Files

1. Right-click on the **AdhanApp** folder (yellow) → **Add Files to "AdhanApp"**
2. Navigate to where you cloned the repo: `adhan/ios/AdhanApp/`
3. Select **all files and folders**:
   - `AdhanApp.swift`
   - `ContentView.swift`
   - `Info.plist` (may conflict - see note below)
   - `Models/` folder
   - `Services/` folder
   - `ViewModels/` folder
   - `Views/` folder
4. Make sure these options are set:
   - ✅ Copy items if needed
   - ✅ Create groups
   - Target: ✅ AdhanApp
5. Click **Add**

**Note about Info.plist**: If Xcode already has an Info.plist, you can either:
- Manually add the entries from Step 3, or
- Replace the file entirely (may require updating Build Settings → Info.plist File path)

---

## Step 5: Add Assets

### Add Adhan Audio File

1. In Finder, locate `adhan.mp3` in your `adhan/` repo folder
2. Drag it directly into the Xcode project navigator (left sidebar), into the AdhanApp folder
3. Make sure:
   - ✅ Copy items if needed
   - Target: ✅ AdhanApp
4. Click **Finish**

### Add Background Image

1. In Finder, locate `mosque.jpg` in your `adhan/` repo folder
2. Drag it into Xcode the same way
3. Ensure it's added to the target

---

## Step 6: Build for Simulator

1. At the top of Xcode, click the device selector (shows iPhone name)
2. Select an iPad simulator (e.g., "iPad Pro 11-inch")
3. Press **⌘R** (Command+R) or click the **Play** button

**Expected Result**: App launches in Simulator showing:
- Black background
- "Adhan App" in white
- "Phase 0: Project Foundation" in gray
- "If you see this, the app builds and runs!" in green

---

## Step 7: Deploy to Physical iPad

### First Time Setup

1. Connect your iPad to your Mac via USB
2. On iPad: Trust this computer when prompted
3. In Xcode's device selector, choose your iPad (should appear with its name)
4. Click **Play** to build and run

### Signing Issues

If you see a signing error:
1. Go to **Signing & Capabilities** tab
2. Make sure **Team** is set to your Apple ID
3. If "Provisioning Profile" shows errors, click **Try Again** or select your team again

### Trust Developer on iPad

First time running on a device:
1. Build will succeed but app won't launch
2. On iPad: **Settings → General → VPN & Device Management**
3. Under "Developer App", tap your Apple ID
4. Tap **Trust "Apple Development: your@email.com"**
5. Tap **Trust** to confirm
6. Go back to Xcode and click **Play** again

---

## Validation Checkpoint

After completing these steps, you should see:

✅ App builds without errors
✅ App runs in Simulator showing placeholder text
✅ App runs on physical iPad
✅ Screen stays on (doesn't dim)

---

## Troubleshooting

### "Cannot find 'X' in scope"
- Make sure all source files are added to the target
- Check that files have the correct target membership (select file, check Inspector on right)

### "Signing for requires a development team"
- Go to Signing & Capabilities
- Select your Apple ID as the Team

### "Unable to install 'AdhanApp'"
- On iPad: Settings → General → Device Management → Trust the developer

### App crashes immediately
- Check console output (View → Debug Area → Activate Console)
- Look for error messages and report them

---

## Next Steps

Once Phase 0 validation passes:
1. Report success: "App builds and runs on iPad"
2. Proceed to Phase 2 (Audio) - the critical validation
