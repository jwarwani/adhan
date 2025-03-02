/***********************************
 * DOM Elements & Global Variables
 ***********************************/
const prayerTimesContainer = document.getElementById('prayerTimesContainer');
const nextPrayerLabel = document.getElementById('nextPrayerLabel');
const countdownElem = document.getElementById('countdown');
const dateInfoElem = document.getElementById('dateInfo');
const adhanAudio = document.getElementById('adhanAudio');
const startupOverlay = document.getElementById('startupOverlay');

const locationIndicator = document.createElement('div');
locationIndicator.id = 'locationIndicator';
document.body.appendChild(locationIndicator);
locationIndicator.style.position = 'absolute';
locationIndicator.style.right = '10px';
locationIndicator.style.bottom = '10px';
locationIndicator.style.fontSize = '0.9rem';
locationIndicator.style.color = '#ccc';

// Data structures
let prayerSchedule = [];       // Array of { name, time, timestamp }
let nextPrayerData = null;     // Current upcoming prayer object
let playedPrayers = new Set(); // Track prayers whose Adhan has already been played

let userLat = null;
let userLon = null;

const FALLBACK_CITY = 'Queens';
const FALLBACK_STATE = 'NY';
const FALLBACK_COUNTRY = 'USA';


/***********************************
 * Initialization & Audio Priming
 ***********************************/
function initAudio() {
  startupOverlay.style.display = 'none';

  // Prime the adhan audio (iOS requires user interaction + immediate play/pause)
  adhanAudio.play().then(() => {
    adhanAudio.pause();
    console.log('Audio primed for iOS autoplay');
  }).catch(err => console.log('Audio play error:', err));

  // Attempt to get geolocation
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        userLat = pos.coords.latitude;
        userLon = pos.coords.longitude;
        fetchPrayerData(0);  
        updateLocationIndicator(userLat, userLon);
      },
      (error) => {
        console.warn('Geolocation error:', error);
        userLat = null;
        userLon = null;
        fetchPrayerData(0);
        locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  } else {
    console.warn('Geolocation not supported. Using fallback city.');
    fetchPrayerData(0);
    locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
  }
}


/***********************************
 * Fetching Prayer Data
 ***********************************/
async function fetchPrayerData(offsetDays = 0) {
  try {
    const now = new Date();
    now.setDate(now.getDate() + offsetDays);

    let responseData, dateObj;
    const dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    // 1) Build the user’s local time zone string
    // e.g. "America/New_York"
    const userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;

    if (userLat !== null && userLon !== null) {
      // --- Lat/Long approach with AlAdhan "timings/{timestamp}?timezonestring=xxx" ---
      const targetMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      const unixTimestamp = Math.floor(targetMidnight.valueOf() / 1000);

      const url = `https://api.aladhan.com/v1/timings/${unixTimestamp}`
                + `?latitude=${userLat}&longitude=${userLon}`
                + `&method=2&school=1`
                + `&timezonestring=${encodeURIComponent(userTimeZone)}`;

      const response = await fetch(url);
      const data = await response.json();
      if (data.code !== 200) throw new Error('API error (lat/lon)');
      responseData = data.data;
      dateObj = data.data.date;

    } else {
      // --- Fallback city approach with "timingsByCity?timezonestring=xxx" ---
      const day = String(now.getDate()).padStart(2, '0');
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const year = now.getFullYear();
      const dateParam = `${day}-${month}-${year}`;

      const cityURL = `https://api.aladhan.com/v1/timingsByCity`
                    + `?city=${FALLBACK_CITY}&state=${FALLBACK_STATE}&country=${FALLBACK_COUNTRY}`
                    + `&method=2&school=1`
                    + `&date=${dateParam}`
                    + `&timezonestring=${encodeURIComponent(userTimeZone)}`;

      const response = await fetch(cityURL);
      const data = await response.json();
      if (data.code !== 200) throw new Error('API error (city fallback)');
      responseData = data.data;
      dateObj = data.data.date;
    }

    const timings = responseData.timings;
    const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    prayerSchedule = dailyPrayers.map((prayerName) => {
      const timeStr = timings[prayerName];  // e.g. "05:30"
      const [hours, minutes] = timeStr.split(':').map(Number);
      const prayerDate = new Date(
        baseDate.getFullYear(),
        baseDate.getMonth(),
        baseDate.getDate(),
        hours,
        minutes,
        0
      );
      return {
        name: prayerName,
        time: timeStr,
        timestamp: prayerDate.getTime(),
      };
    });

    // Reset the set of played prayers, so we can play them again for the new day
    playedPrayers.clear();

    updateUI(dateObj); 
    scheduleDailyRefresh();
  } catch (err) {
    console.error('Error fetching prayer data:', err);
    nextPrayerLabel.textContent = 'Failed to load prayer data.';
  }
}


/***********************************
 * Location Indicator
 ***********************************/
async function updateLocationIndicator(lat, lon) {
  try {
    const geoUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`;
    const res = await fetch(geoUrl);
    const locationData = await res.json();

    let city = locationData?.address?.city 
            || locationData?.address?.town 
            || locationData?.address?.village 
            || 'Unknown City';
    let country = locationData?.address?.country || 'Unknown Country';
    locationIndicator.textContent = `${city}, ${country}`;
  } catch (err) {
    console.error('Reverse geocoding error:', err);
    locationIndicator.textContent = '';
  }
}


/***********************************
 * UI & Display Logic
 ***********************************/
function updateUI(dateObj) {
  // 1) Update date display
  const gregorian = dateObj.gregorian;
  const hijri = dateObj.hijri;
  const gregorianString = `${gregorian.day} ${gregorian.month.en} ${gregorian.year}`;
  const hijriString = `${hijri.day} ${hijri.month.en} ${hijri.year}`;
  dateInfoElem.textContent = `Today: ${gregorianString} | Hijri: ${hijriString}`;

  // 2) Sort & display prayer times
  prayerSchedule.sort((a, b) => a.timestamp - b.timestamp);
  prayerTimesContainer.innerHTML = '';
  for (const prayer of prayerSchedule) {
    const div = document.createElement('div');
    div.className = 'prayer';
    div.innerHTML = `<h2>${prayer.name}</h2><p>${prayer.time}</p>`;
    prayerTimesContainer.appendChild(div);
  }

  // 3) Determine the next prayer
  displayNextPrayer();

  // 4) Start or restart the countdown loop
  startCountdownUpdater();
}

function displayNextPrayer() {
  const now = Date.now();
  const upcoming = prayerSchedule.filter(p => p.timestamp > now);

  if (upcoming.length === 0) {
    // No upcoming prayers => fetch tomorrow’s times
    // But keep the same date displayed until midnight
    fetchPrayerData(1); 
    nextPrayerLabel.textContent = 'All prayers done for today';
    nextPrayerData = null;
    return;
  }

  nextPrayerData = upcoming[0];
  nextPrayerLabel.textContent = `${nextPrayerData.name} ${nextPrayerData.time}`;
}


/***********************************
 * Countdown & Adhan Handling
 ***********************************/
function startCountdownUpdater() {
  // Clear any existing intervals before setting a new one
  if (window._countdownInterval) {
    clearInterval(window._countdownInterval);
  }

  window._countdownInterval = setInterval(() => {
    if (!nextPrayerData) {
      countdownElem.textContent = '';
      return;
    }

    const now = Date.now();
    const diff = nextPrayerData.timestamp - now;

    if (diff <= 0) {
      // It's prayer time or already past it
      // 1) If we haven't played Adhan yet for this prayer, do so
      if (!playedPrayers.has(nextPrayerData.name)) {
        playAdhan();
        playedPrayers.add(nextPrayerData.name);
      }

      // 2) Update countdown
      countdownElem.textContent = "It's time!";
      // 3) Force immediate re-check to move on to the next prayer
      //    so we don't stay stuck
      setTimeout(() => {
        displayNextPrayer(); 
      }, 60_000); 
      // ^ optionally wait 60s so the user sees "It's time!" for a bit 
      //   before switching, or set to 0 for immediate switch

      return;
    }

    // Normal countdown
    const totalSec = Math.floor(diff / 1000);
    const hours = Math.floor(totalSec / 3600);
    const mins = Math.floor((totalSec % 3600) / 60);
    const secs = totalSec % 60;

    const hh = hours.toString().padStart(2, '0');
    const mm = mins.toString().padStart(2, '0');
    const ss = secs.toString().padStart(2, '0');
    countdownElem.textContent = `${hh}:${mm}:${ss} until ${nextPrayerData.name}`;
  }, 1000);
}


function playAdhan() {
  adhanAudio.currentTime = 0;
  adhanAudio.play().catch(err => {
    console.error('Failed to play adhan:', err);
  });
}


/***********************************
 * Daily Refresh at Midnight
 ***********************************/
function scheduleDailyRefresh() {
  // Clear old refresh if any
  if (window._dailyRefreshTimeout) {
    clearTimeout(window._dailyRefreshTimeout);
  }

  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0);
  const diff = midnight - now;

  window._dailyRefreshTimeout = setTimeout(() => {
    // Actually fetch new "today" data after midnight 
    fetchPrayerData(0).then(() => {
      if (userLat && userLon) {
        updateLocationIndicator(userLat, userLon);
      } else {
        locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
      }
    });
  }, diff);
}
