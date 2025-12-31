# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a standalone web application designed to run on an iPad in landscape mode as a dedicated Islamic prayer clock. It displays prayer times, plays the adhan (call to prayer), and provides a beautiful, serene interface inspired by Islamic aesthetics.

**Technology Stack:** Pure vanilla JavaScript, HTML5, and CSS3. No build system, package manager, or frameworks.

## Key Architecture

### Prayer Time Data Flow

1. **Geolocation → API Fetch → Schedule Building**
   - On startup, the app requests geolocation permission (app.js:46-67)
   - Falls back to Queens, NY if geolocation fails or is denied
   - Fetches prayer times from AlAdhan API using either lat/lon or city name (app.js:74-134)
   - Builds a daily schedule array with 5 prayers: Fajr, Dhuhr, Asr, Maghrib, Isha

2. **Day Rollover Logic**
   - After Isha prayer (the last of the day), the app automatically fetches the next day's prayer times (app.js:189-194)
   - A daily refresh is scheduled for midnight + 1 minute to refresh data (app.js:259-272)
   - The app uses the device's local timezone for all time calculations

3. **Adhan Audio Playback**
   - iOS Safari requires user interaction before audio can play (app.js:36-43)
   - A startup overlay prompts the user to tap "Start" to initialize audio
   - Audio is primed on initialization to enable later autoplay
   - Adhan plays automatically when prayer time arrives, tracked via `playedPrayers` Set to prevent replays

### Main Loop Architecture

The app runs a 1-second interval loop (app.js:204-228) that:
- Updates the current time display in 24-hour format
- Checks if the next prayer time has been reached
- Triggers adhan playback when prayer time arrives
- Advances to the next prayer in the schedule

### API Integration

**AlAdhan Prayer Times API:**
- Endpoint with geolocation: `https://api.aladhan.com/v1/timings/{timestamp}` with lat/lon params
- Endpoint with city: `https://api.aladhan.com/v1/timingsByCity` with city/state/country params
- Uses calculation method 2 (ISNA) and Hanafi school (school=1)
- Always passes the device timezone to ensure correct local times

**OpenStreetMap Reverse Geocoding:**
- Used to display city/country from lat/lon coordinates (app.js:140-155)
- Purely for display purposes in the location indicator

## Development Workflow

### Running the Application

This is a static web application with no build process:

1. **Local Development:** Open `index.html` directly in a web browser, or use any static file server:
   ```bash
   python3 -m http.server 8000
   # Then open http://localhost:8000
   ```

2. **iPad Deployment:**
   - Host the files on any web server (currently deployed via GitHub Pages)
   - Access the URL on iPad Safari
   - Add to Home Screen for fullscreen kiosk mode (removes Safari UI)
   - Enable Guided Access in iOS Settings to prevent exiting the app

### Testing Prayer Time Logic

To test different prayer scenarios without waiting:
- Modify prayer times in the API response or hardcode test times in `prayerSchedule`
- Adjust the system clock to simulate different times of day
- Check browser console for geolocation errors, API failures, or audio playback issues

### Key Files

- **index.html** - DOM structure, CSS styling, Google Fonts integration
- **app.js** - All application logic (no modules or bundling)
- **adhan.mp3** - Audio file played at prayer times
- **mosque.jpg** - Background image

## Important Constraints

### iOS Safari Audio Limitations

Audio autoplay is blocked on iOS Safari unless:
1. The AudioContext is created in response to a user gesture
2. The audio element has been played at least once via user interaction

This is why the startup overlay with the "Start" button is critical for the app to function.

### Timezone Handling

The app relies on the device's local timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`) and passes it to the API. This ensures prayer times are always correct for the user's current location, even if the device is moved to a different timezone.

### Date Calculation at Midnight

When fetching prayer times via lat/lon, the app constructs a timestamp for midnight + 1 minute of the target day (app.js:85-86). This is necessary because the API expects a Unix timestamp and we need to ensure we're getting the correct day's data.

## Git Deployment

The repository is deployed to GitHub Pages. To deploy changes:

```bash
git add .
git commit -m "Description of changes"
git push origin main
```

Changes will automatically appear at https://jwarwani.github.io/adhan/

## Design Philosophy

This app was intentionally built with ChatGPT assistance as a simple, self-contained solution. The codebase prioritizes:
- **Zero dependencies:** No npm, no build tools, no frameworks
- **Readability:** Single JavaScript file with clear section comments
- **Resilience:** Fallback location if geolocation fails, error handling for API calls
- **iOS compatibility:** Careful handling of audio autoplay restrictions

When making changes, maintain this simplicity. Avoid introducing build tools, package managers, or framework dependencies unless absolutely necessary.
