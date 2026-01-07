# Native iOS Adhan App - Development Workflow

## Overview

This document defines the workflow between Claude (autonomous development) and the user (manual Xcode/device tasks).

---

## Role Division

### Claude Does Autonomously

| Task | Deliverable |
|------|-------------|
| Generate all Swift source files | .swift files ready to add to Xcode |
| Create Info.plist content | XML configuration |
| Design file/folder structure | Clear organization |
| Implement all business logic | Working code |
| Write UI views | SwiftUI views |
| Debug from error messages | Fixed code |
| Iterate based on test results | Improved code |

### User Must Do Manually

| Task | When | Instructions Provided |
|------|------|----------------------|
| Create Xcode project | After Phase 0 files generated | Step-by-step guide |
| Add files to Xcode | After each phase | Drag-and-drop instructions |
| Configure project settings | Once during setup | Exact settings to change |
| Connect iPad | Before device testing | Simple USB connection |
| Trust developer certificate | First run on device | iOS Settings path |
| Build and run | Each validation checkpoint | Click Run button |
| Physical testing | Critical validations | What to test and observe |
| Report results | After each test | What to tell Claude |

---

## Checkpoint Workflow

Each phase ends with a validation checkpoint:

```
┌─────────────────────┐
│  Claude generates   │
│  code files         │
├─────────────────────┤
│  Claude commits &   │
│  pushes to GitHub   │
├─────────────────────┤
│  Claude provides    │
│  setup instructions │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  USER: Add files    │
│  to Xcode project   │
├─────────────────────┤
│  USER: Build & run  │
│  on device          │
├─────────────────────┤
│  USER: Perform      │
│  validation test    │
├─────────────────────┤
│  USER: Report       │
│  results to Claude  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  If PASS: Continue  │
│  to next phase      │
├─────────────────────┤
│  If FAIL: Claude    │
│  debugs and fixes   │
└─────────────────────┘
```

---

## Phase-by-Phase Handoffs

### Phase 0: Project Foundation

**Claude delivers:**
- All Swift source files (placeholder implementations)
- Complete Info.plist content
- Asset requirements (image sizes, audio format)
- Step-by-step Xcode project creation guide

**User does:**
1. Create new Xcode project (iOS App, SwiftUI, iPad)
2. Configure project settings per guide
3. Add source files to project
4. Import assets (adhan.mp3, mosque.jpg)
5. Build and run on Simulator
6. Report: "Builds successfully" or error messages

---

### Phase 2: Audio System (Critical)

**Claude delivers:**
- AdhanAudioManager.swift with full implementation
- Test button in ContentView to trigger audio

**User does:**
1. Add new file to Xcode
2. Connect physical iPad via USB
3. Build and run on iPad
4. Tap test button, verify audio plays
5. Lock screen while audio is playing
6. **Critical test**: Does audio continue?
7. Report: "Audio works with screen locked" or "Audio stops when locked"

**If audio fails**: Claude will debug based on any error messages or behavior described.

---

### Phase 1: Data Layer

**Claude delivers:**
- Prayer.swift model
- AlAdhanResponse.swift model
- AlAdhanService.swift with networking

**User does:**
1. Add files to Xcode
2. Build and run
3. Check console output for prayer times
4. Report: "Shows 5 prayer times" or error messages

---

### Phase 3-6: Remaining Phases

Similar pattern:
- Claude generates code
- User adds to Xcode
- User tests specific functionality
- User reports results

---

## Communication Protocol

### When User Reports Success

Example:
> "Audio plays with screen locked. Tested for 2 minutes, no issues."

Claude response: Proceed to next phase.

### When User Reports Failure

Example:
> "Audio stops immediately when I lock the screen."

Claude response:
1. Ask clarifying questions if needed
2. Review code for issues
3. Generate fix
4. User retests

### When User Reports Error

Example:
> "Build failed with error: Cannot find 'AVAudioSession' in scope"

Claude response:
1. Identify missing import
2. Generate corrected file
3. User rebuilds

---

## Git Workflow

### Commit Strategy

Claude commits after completing each logical unit:
- After generating each phase's files
- After fixing bugs
- After making improvements based on feedback

### Branch Usage

All work happens on the designated feature branch. Claude pushes frequently so user can pull latest code.

### User Syncing

When Claude pushes updates:
```bash
cd /path/to/adhan
git pull origin claude/review-ios-conversion-plan-lf2wU
```

Then copy updated files from `ios/AdhanApp/` to Xcode project.

---

## File Organization in Repository

```
adhan/
├── index.html              # Existing web app
├── app.js                  # Existing web app
├── adhan.mp3               # Shared audio file
├── mosque.jpg              # Shared image
├── docs/
│   └── planning/           # These planning docs
│       ├── 00-implementation-roadmap.md
│       ├── 01-architecture-overview.md
│       └── 02-development-workflow.md
└── ios/
    └── AdhanApp/           # iOS source files
        ├── AdhanApp.swift
        ├── ContentView.swift
        ├── Info.plist
        ├── Models/
        ├── Services/
        ├── ViewModels/
        └── Views/
```

The `ios/AdhanApp/` folder contains source files that user copies into their Xcode project. This separation keeps iOS code organized while preserving the existing web app.

---

## Estimated User Time Per Phase

| Phase | User Time | Activities |
|-------|-----------|------------|
| 0 | 15-20 min | Create Xcode project, configure settings |
| 1 | 5 min | Add files, verify API works |
| 2 | 10 min | Add file, test audio on device |
| 3 | 5 min | Add files, test auto-play |
| 4 | 5 min | Add file, test location |
| 5 | 10 min | Add files, review UI |
| 6 | 5 min | Add file, test instructions |
| 7 | 30 min | Extended testing |

**Total estimated user time**: ~1.5 hours spread across all phases

Most of Claude's work is autonomous code generation. User involvement is primarily validation and the Xcode tasks that require the GUI.
