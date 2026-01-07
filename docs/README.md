# Documentation

This folder contains planning and documentation for the Adhan Prayer Clock app.

## Project Evolution

This project started as a simple web app (`index.html` + `app.js`) designed to run on iPad Safari. Due to unreliable audio playback caused by iOS Safari's restrictions, we're converting to a native SwiftUI iOS app.

## Planning Documents

| Document | Description |
|----------|-------------|
| [00-implementation-roadmap.md](planning/00-implementation-roadmap.md) | Master plan with phases, tasks, validation, and timeline |
| [01-architecture-overview.md](planning/01-architecture-overview.md) | Technical architecture, code examples, and design decisions |
| [02-team-structure.md](planning/02-team-structure.md) | Development team (subagent) definitions and interfaces |

## Quick Reference

### Key Decisions
- **Framework**: SwiftUI (native iOS)
- **iOS Target**: iOS 15.0 (supports iPads from 2014+)
- **Scope**: Kiosk mode only, iPad landscape
- **Distribution**: Free Apple ID for personal testing (no $99 account needed)

### Development Phases
1. **Phase 0**: Project Foundation (Xcode setup)
2. **Phase 1**: Data Layer (API integration)
3. **Phase 2**: Audio System (AVAudioSession)
4. **Phase 3**: Core Logic (prayer tracking)
5. **Phase 4**: Location Service
6. **Phase 5**: User Interface
7. **Phase 6**: Kiosk Instructions
8. **Phase 7**: Integration & Polish

### Critical Success Test
> Can the adhan audio play when the iPad screen is locked?

If Phase 2 passes this test, the native app approach is validated.

## Original Web App

The original web app files remain in the repository root:
- `index.html` - Web UI
- `app.js` - Web logic
- `adhan.mp3` - Audio file (will be reused in native app)
- `mosque.jpg` - Background image (will be reused in native app)

The web app continues to work at https://jwarwani.github.io/adhan/ but has unreliable audio.
