/***********************************
 * DOM Elements & Global Variables
 ***********************************/
const prayerTimesContainer = document.getElementById('prayerTimesContainer');
const currentTimeLabel     = document.getElementById('currentTimeLabel');
const nextPrayerLabel      = document.getElementById('nextPrayerTextDetails');
const dateInfoElem         = document.getElementById('dateInfo');
const adhanAudio           = document.getElementById('adhanAudio');
const startupOverlay       = document.getElementById('startupOverlay');

const locationIndicator = document.createElement('div');
locationIndicator.id = 'locationIndicator';
document.body.appendChild(locationIndicator);
locationIndicator.style.position = 'absolute';
locationIndicator.style.right = '10px';
locationIndicator.style.bottom = '10px';
locationIndicator.style.fontSize = '0.9rem';
locationIndicator.style.color = '#ccc';

// Prayer data and logic
let prayerSchedule = [];
let nextPrayerData = null;
let playedPrayers  = new Set();  // track adhan plays

// Geolocation / fallback
let userLat = null;
let userLon = null;
const FALLBACK_CITY     = 'Queens';
const FALLBACK_STATE    = 'NY';
const FALLBACK_COUNTRY  = 'USA';

// Wake lock
let wakeLock = null;


/***********************************
 * Debug Time Override
 * Usage in browser console:
 *   setDebugTime('2024-12-30 17:20:00')  // Set time (continues to advance)
 *   setDebugTime(null)                    // Disable debug mode
 ***********************************/
let debugTimeOffset = null;

function getCurrentTime() {
  if (debugTimeOffset !== null) {
    return new Date(Date.now() + debugTimeOffset);
  }
  return new Date();
}

function getCurrentTimestamp() {
  if (debugTimeOffset !== null) {
    return Date.now() + debugTimeOffset;
  }
  return Date.now();
}

window.setDebugTime = function(timeString) {
  if (timeString === null) {
    debugTimeOffset = null;
    console.log('Debug mode disabled');
    fetchPrayerData(0);
    return;
  }

  const targetTime = new Date(timeString);
  debugTimeOffset = targetTime.getTime() - Date.now();
  console.log(`Debug time set to: ${targetTime.toString()}`);
  console.log('Time will continue to advance from this point.');

  // Re-fetch prayer data for the new date and update UI
  fetchPrayerData(0);
};


/***********************************
 * Startup / Audio Init
 ***********************************/
function initAudio() {
  startupOverlay.style.display = 'none';

  // Prime iOS autoplay
  adhanAudio.play().then(() => {
    adhanAudio.pause();
    console.log('Audio primed');
  }).catch(err => console.log('Audio play error:', err));

  // Attempt geolocation
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        userLat = pos.coords.latitude;
        userLon = pos.coords.longitude;
        fetchPrayerData(0);
        updateLocationIndicator(userLat, userLon);
      },
      (err) => {
        console.warn('Geolocation error:', err);
        userLat = null;
        userLon = null;
        fetchPrayerData(0);
        locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  } else {
    console.warn('Geolocation not supported; using fallback city.');
    fetchPrayerData(0);
    locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
  }

  // Request wake lock to keep screen on
  requestWakeLock();
}


/***********************************
 * Wake Lock
 ***********************************/
async function requestWakeLock() {
  if ('wakeLock' in navigator) {
    try {
      wakeLock = await navigator.wakeLock.request('screen');
      console.log('Wake lock activated');

      // Re-acquire wake lock if page becomes visible again
      wakeLock.addEventListener('release', () => {
        console.log('Wake lock released');
      });

      document.addEventListener('visibilitychange', async () => {
        if (wakeLock !== null && document.visibilityState === 'visible') {
          wakeLock = await navigator.wakeLock.request('screen');
          console.log('Wake lock re-acquired');
        }
      });

    } catch (err) {
      console.warn('Wake lock error:', err);
    }
  } else {
    console.warn('Wake Lock API not supported. Please disable auto-lock in iOS settings.');
  }
}


/***********************************
 * Fetch Prayer Data
 ***********************************/
async function fetchPrayerData(offsetDays = 0) {
  try {
    const now = getCurrentTime();
    now.setDate(now.getDate() + offsetDays);

    const userTimeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const dailyPrayers = ['Fajr','Dhuhr','Asr','Maghrib','Isha'];

    let responseData, dateObj;
    if (userLat !== null && userLon !== null) {
      // lat/lon approach
      const targetMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 1, 0);
      const unixTimestamp = Math.floor(targetMidnight.valueOf() / 1000);

      const url = `https://api.aladhan.com/v1/timings/${unixTimestamp}`
                + `?latitude=${userLat}&longitude=${userLon}`
                + `&method=2&school=1`
                + `&timezonestring=${encodeURIComponent(userTimeZone)}`;
      const resp = await fetch(url);
      const data = await resp.json();
      if (data.code !== 200) throw new Error('API error (lat/lon)');
      responseData = data.data;
      dateObj = data.data.date;
    } else {
      // city fallback
      const day = String(now.getDate()).padStart(2, '0');
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const year = now.getFullYear();
      const dateParam = `${day}-${month}-${year}`;

      const cityURL = `https://api.aladhan.com/v1/timingsByCity?city=${FALLBACK_CITY}`
                    + `&state=${FALLBACK_STATE}&country=${FALLBACK_COUNTRY}`
                    + `&method=2&school=1`
                    + `&date=${dateParam}`
                    + `&timezonestring=${encodeURIComponent(userTimeZone)}`;
      const resp = await fetch(cityURL);
      const data = await resp.json();
      if (data.code !== 200) throw new Error('API error (city fallback)');
      responseData = data.data;
      dateObj = data.data.date;
    }

    // Build schedule
    const timings = responseData.timings;
    const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    prayerSchedule = dailyPrayers.map(prayer => {
      const timeStr = timings[prayer];
      const [hh, mm] = timeStr.split(':').map(Number);
      const stamp = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), hh, mm, 0);
      return { name: prayer, time: timeStr, timestamp: stamp.getTime() };
    });

    playedPrayers.clear(); // reset for a new day
    updateUI(dateObj);
    scheduleDailyRefresh();

  } catch(err) {
    console.error('Error fetching prayer data:', err);
    nextPrayerLabel.textContent  = 'Error loading data';
  }
}


/***********************************
 * Location Indicator
 ***********************************/
async function updateLocationIndicator(lat, lon) {
  try {
    const geoUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`;
    const res = await fetch(geoUrl);
    const data = await res.json();

    const city = data?.address?.city 
              || data?.address?.town 
              || data?.address?.village 
              || 'Unknown City';
    const country = data?.address?.country || 'Unknown Country';
    locationIndicator.textContent = `${city}, ${country}`;
  } catch {
    locationIndicator.textContent = '';
  }
}


/***********************************
 * UI & Display
 ***********************************/
function updateUI(dateObj) {
  // 1) Update date string with special date detection
  const gregorian = dateObj.gregorian;
  const hijri = dateObj.hijri;
  const gregorianString = `${gregorian.day} ${gregorian.month.en} ${gregorian.year}`;
  const hijriString = `${hijri.day} ${hijri.month.en} ${hijri.year}`;

  // Detect special Islamic dates
  const hijriMonth = parseInt(hijri.month.number);
  const hijriDay = parseInt(hijri.day);
  let specialIndicator = '';

  if (hijriMonth === 9) {
    // Entire month of Ramadan
    specialIndicator = ' ✦ Ramadan ✦';
  } else if (hijriMonth === 12 && hijriDay === 10) {
    // Eid al-Adha (10th of Dhul Hijjah)
    specialIndicator = ' ✦ Eid al-Adha ✦';
  }

  dateInfoElem.innerHTML = `Today: ${gregorianString} | Hijri: <span class="hijri-date${specialIndicator ? ' special-date' : ''}">${hijriString}${specialIndicator}</span>`;

  // 2) Sort & display prayer times
  prayerSchedule.sort((a,b) => a.timestamp - b.timestamp);
  prayerTimesContainer.innerHTML = '';
  for (const p of prayerSchedule) {
    const div = document.createElement('div');
    div.className = 'prayer';
    div.innerHTML = `<h2>${p.name}</h2><p>${p.time}</p>`;
    prayerTimesContainer.appendChild(div);
  }

  // 3) Find the next prayer
  findNextPrayer();
  // 4) Update background dimming based on time
  updateBackgroundDimming();
  // 5) Start the main loop that updates current time & checks prayer triggers
  startMainLoop();
}

/** Finds the next upcoming prayer & updates #nextPrayerLabel. */
function findNextPrayer() {
  const now = getCurrentTimestamp();
  const upcoming = prayerSchedule.filter(p => p.timestamp > now);
  if (upcoming.length === 0) {
    // no upcoming prayers => fetch tomorrow
    nextPrayerData = null;
    nextPrayerLabel.textContent = 'All prayers done for today';
    fetchPrayerData(1);
    return;
  }
  const newPrayer = upcoming[0];

  // Only animate if prayer actually changed
  if (!nextPrayerData || nextPrayerData.name !== newPrayer.name) {
    nextPrayerData = newPrayer;

    // Fade out before changing
    nextPrayerLabel.style.opacity = '0';

    setTimeout(() => {
      nextPrayerLabel.textContent = `${nextPrayerData.name} @ ${nextPrayerData.time}`;
      nextPrayerLabel.style.opacity = '1';
    }, 300);
  } else {
    nextPrayerData = newPrayer;
  }
}


/***********************************
 * Main Loop: Current Time & Adhan
 ***********************************/
function startMainLoop() {
  // Clear existing interval if any
  if (window._mainInterval) clearInterval(window._mainInterval);

  window._mainInterval = setInterval(() => {
    // 1) Update the current time label
    displayCurrentTime();

    // 2) Update prayer approaching indicator
    updatePrayerApproaching();

    // 3) Update background dimming every minute
    if (getCurrentTime().getSeconds() === 0) {
      updateBackgroundDimming();
    }

    // 4) Check if next prayer has passed and play adhan
    if (nextPrayerData) {
      const now = getCurrentTimestamp();
      if (now >= nextPrayerData.timestamp && !playedPrayers.has(nextPrayerData.name)) {
        // Prayer time reached - play adhan and schedule transition
        playAdhan();
        playedPrayers.add(nextPrayerData.name);

        // Schedule transition to next prayer after 1 minute
        setTimeout(() => {
          findNextPrayer();
        }, 60_000);
      }
    }
  }, 1000);
}

/** Displays local current time in #currentTimeLabel (24-hour format). */
function displayCurrentTime() {
  const now = getCurrentTime();
  let hours   = now.getHours();
  let minutes = now.getMinutes();
  let seconds = now.getSeconds();

  const hh = hours.toString().padStart(2, '0');
  const mm = minutes.toString().padStart(2, '0');
  const ss = seconds.toString().padStart(2, '0');

  currentTimeLabel.textContent = `${hh}:${mm}:${ss}`;
}


/***********************************
 * Play Adhan
 ***********************************/
function playAdhan() {
  adhanAudio.currentTime = 0;
  adhanAudio.play().catch(err => {
    console.error('Adhan play error:', err);
  });
}


/***********************************
 * Prayer Approaching Indicator
 ***********************************/
function updatePrayerApproaching() {
  const now = getCurrentTimestamp();
  const tenMinutes = 10 * 60 * 1000; // 10 minutes in milliseconds
  const indicator = document.getElementById('prayerApproachingIndicator');
  const indicatorText = indicator.querySelector('.indicator-text');
  const prayerEmoji = indicator.querySelector('.prayer-emoji');

  // Check if we're within 10 minutes before next prayer
  if (nextPrayerData) {
    const timeUntilPrayer = nextPrayerData.timestamp - now;

    if (timeUntilPrayer <= tenMinutes && timeUntilPrayer > 0) {
      // Prayer is approaching (within 10 min before)
      indicator.classList.add('show');
      prayerEmoji.textContent = '🌙';
      indicatorText.textContent = 'Prayer soon';
      return;
    }
  }

  // Check if we're within 10 minutes after any prayer time
  for (const prayer of prayerSchedule) {
    const timeSincePrayer = now - prayer.timestamp;

    if (timeSincePrayer >= 0 && timeSincePrayer <= tenMinutes) {
      // We're within 10 minutes after this prayer
      indicator.classList.add('show');
      prayerEmoji.textContent = '🕌';
      indicatorText.textContent = `${prayer.name} time`;
      return;
    }
  }

  // Not approaching or during any prayer time
  indicator.classList.remove('show');
}


/***********************************
 * Background Dimming
 ***********************************/
function updateBackgroundDimming() {
  const now = getCurrentTime();
  const overlay = document.getElementById('timeDimOverlay');

  // Find Isha and Fajr times from schedule
  const isha = prayerSchedule.find(p => p.name === 'Isha');
  const fajr = prayerSchedule.find(p => p.name === 'Fajr');

  if (!isha || !fajr) return;

  const currentTime = now.getTime();

  // Check if current time is after Isha OR before Fajr (nighttime)
  const isNightTime = currentTime >= isha.timestamp || currentTime < fajr.timestamp;

  if (isNightTime) {
    overlay.classList.add('night-mode');
  } else {
    overlay.classList.remove('night-mode');
  }
}


/***********************************
 * Daily Refresh at Midnight
 ***********************************/
function scheduleDailyRefresh() {
  if (window._dailyRefreshTimeout) {
    clearTimeout(window._dailyRefreshTimeout);
  }
  const now = getCurrentTime();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()+1, 0,1,0);
  const diff = midnight - now;
  window._dailyRefreshTimeout = setTimeout(() => {
    fetchPrayerData(0).then(() => {
      if (userLat && userLon) updateLocationIndicator(userLat, userLon);
      else locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
    });
  }, diff);
}
