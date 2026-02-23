# Adhan iOS App

SwiftUI iOS application for displaying Islamic prayer times and playing the adhan.

## Quick Start

1. **Install XcodeGen** (if not already installed):
   ```bash
   brew install xcodegen
   ```

2. **Generate the Xcode project**:
   ```bash
   cd ios
   xcodegen generate
   ```

3. **Open in Xcode**:
   ```bash
   open AdhanApp.xcodeproj
   ```

4. **Configure signing**: Select your development team in Xcode > Target > Signing & Capabilities

5. **Add audio files** to `AdhanApp/Resources/`:
   - `adhan.mp3` - Standard adhan audio
   - `adhan_fajr.mp3` - Fajr-specific adhan (optional, falls back to standard)

## Project Structure

```
ios/
├── project.yml           # XcodeGen configuration (source of truth)
├── AdhanApp.xcodeproj/   # Generated Xcode project (do not edit manually)
└── AdhanApp/
    ├── AdhanApp.swift    # App entry point
    ├── ContentView.swift # Main UI
    ├── Models/           # Data models & settings
    ├── Views/            # SwiftUI view components
    ├── ViewModels/       # State management
    ├── Services/         # API, location, audio services
    ├── Utilities/        # Logger, build environment
    ├── Extensions/       # Swift extensions
    ├── Resources/        # Audio files (mp3)
    └── Assets.xcassets/  # Images & colors
```

## XcodeGen Workflow

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`. This approach:

- Avoids merge conflicts in the `.xcodeproj` file
- Makes project configuration declarative and reviewable
- Automatically includes new Swift files when regenerated

### When to Regenerate

Run `xcodegen generate` when you:
- Add or remove Swift files
- Add or remove resource files
- Change project settings in `project.yml`

### Automatic Regeneration

Git hooks are configured to automatically regenerate the project after `git checkout` or `git pull`:

```bash
# Enable the hooks (run once after cloning)
git config core.hooksPath .githooks
```

### Manual Regeneration

```bash
cd ios
xcodegen generate
```

## Configuration

### Build Configurations

- **Debug**: Enables debug features (triple-tap debug panel)
- **Release**: Production build with optimizations

### Info.plist Settings

Key permissions and settings are configured in `project.yml`:
- Location permission for prayer time calculation
- Background audio mode for adhan playback

### App Settings

User-configurable settings (stored in `AppSettings.swift`):
- Calculation method (ISNA, MWL, Umm Al-Qura, etc.)
- Asr school (Standard/Shafi'i or Hanafi)
- Per-prayer alert mode (Adhan, Notification, or Silent)
- Manual location override

## Building for Release

1. Update version in `project.yml`:
   ```yaml
   MARKETING_VERSION: "1.1.0"
   CURRENT_PROJECT_VERSION: "2"
   ```

2. Regenerate project:
   ```bash
   xcodegen generate
   ```

3. Archive in Xcode: Product > Archive

## Troubleshooting

### "File not found" errors after pulling
Run `xcodegen generate` to add new files to the project.

### Audio not playing
1. Ensure audio files are in `AdhanApp/Resources/`
2. Regenerate the project so files are included
3. Check device is not in silent mode

### Location not working
Ensure "Location When In Use" permission is granted in device Settings.
