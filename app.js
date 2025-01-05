// DOM elements
const prayerTimesContainer = document.getElementById('prayerTimesContainer');
const nextPrayerLabel = document.getElementById('nextPrayerLabel');
const countdownElem = document.getElementById('countdown');
const dateInfoElem = document.getElementById('dateInfo');
const adhanAudio = document.getElementById('adhanAudio');
const startupOverlay = document.getElementById('startupOverlay');
// New element for bottom-right location display
const locationIndicator = document.createElement('div');
locationIndicator.id = 'locationIndicator';
document.body.appendChild(locationIndicator);

// Some basic styling for the location text
locationIndicator.style.position = 'fixed';
locationIndicator.style.right = '10px';
locationIndicator.style.bottom = '10px';
locationIndicator.style.fontSize = '0.9rem';
locationIndicator.style.color = '#ccc';

let prayerSchedule = [];     
let nextPrayerTimeouts = [];
let nextPrayerData = null;  

// Global lat/lon (if user grants location)
let userLat = null;
let userLon = null;

// Constants for fallback location
const FALLBACK_CITY = 'Queens';
const FALLBACK_STATE = 'NY';
const FALLBACK_COUNTRY = 'USA';

function initAudio() {
  startupOverlay.style.display = 'none';

  // Prime audio
  adhanAudio.play().then(() => {
    adhanAudio.pause();
    console.log('Audio primed');
  }).catch(err => console.log('Audio play error:', err));

  // Attempt geolocation each time
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        userLat = pos.coords.latitude;
        userLon = pos.coords.longitude;
        // Consolidated approach: single function fetchPrayerData
        fetchPrayerData(0);  
        // Also update city/country display
        updateLocationIndicator(userLat, userLon);
      },
      (error) => {
        console.warn('Geolocation error:', error);
        // fallback to city-based approach if geolocation fails/denied
        userLat = null;
        userLon = null;
        fetchPrayerData(0); 
        locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  } else {
    console.warn('Geolocation not supported. Using default city.');
    fetchPrayerData(0); 
    locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
  }
}

/**
 * Consolidated function that fetches prayer data for either lat/lon or fallback city.
 * @param {number} offsetDays - 0 (today), 1 (tomorrow), etc.
 */
async function fetchPrayerData(offsetDays = 0, skipDateUI = false) {
  try {
    const now = new Date();
    now.setDate(now.getDate() + offsetDays);

    let responseData = null;
    let dateObj = null;         // To store .date from API
    let dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    if (userLat !== null && userLon !== null) {
      // ======== LAT/LON approach ========
      // Use AlAdhan "timings/{timestamp}" endpoint
      const targetMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0,0,0);
      const unixTimestamp = Math.floor(targetMidnight.valueOf() / 1000);
      const url = `https://api.aladhan.com/v1/timings/${unixTimestamp}?latitude=${userLat}&longitude=${userLon}&method=2&school=1`;
      
      const response = await fetch(url);
      const data = await response.json();
      if (data.code !== 200) throw new Error('API error (lat/lon)');

      responseData = data.data;  // {timings, date, etc.}
      dateObj = data.data.date;

    } else {
      // ======== CITY/STATE fallback approach ========
      const day = String(now.getDate()).padStart(2, '0');
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const year = now.getFullYear();
      const dateParam = `${day}-${month}-${year}`;
      const cityURL = `https://api.aladhan.com/v1/timingsByCity?city=${FALLBACK_CITY}&state=${FALLBACK_STATE}&country=${FALLBACK_COUNTRY}&method=2&school=1&date=${dateParam}`;
      
      const response = await fetch(cityURL);
      const data = await response.json();
      if (data.code !== 200) throw new Error('API error (city fallback)');
      
      responseData = data.data;
      dateObj = data.data.date;
    }

    const timings = responseData.timings;
    timings['Dhuhr'] = '12:19';
    // Build schedule
    const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    prayerSchedule = dailyPrayers.map(prayerName => {
      const timeStr = timings[prayerName];
      const [hours, minutes] = timeStr.split(':').map(Number);
      const prayerDate = new Date(baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(), hours, minutes, 0);
      return {
        name: prayerName,
        time: timeStr,
        timestamp: prayerDate.getTime()
      };
    });

    // Now update UI, schedule adhans, etc.
    if (!skipDateUI) {
      updateUI(dateObj);
    } else {
      updatePrayerTimesList();
    }
    scheduleAdhans();
    startCountdownUpdater();

  } catch (err) {
    console.error('Error fetching prayer data:', err);
    nextPrayerLabel.textContent = 'Failed to load prayer data.';
  }
}

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

// UI & Scheduling
function updateUI(dateObj) {
  const gregorian = dateObj.gregorian;
  const hijri = dateObj.hijri;
  const gregorianString = `${gregorian.day} ${gregorian.month.en} ${gregorian.year}`;
  const hijriString = `${hijri.day} ${hijri.month.en} ${hijri.year}`;
  dateInfoElem.textContent = `Today: ${gregorianString} | Hijri: ${hijriString}`;

  updatePrayerTimesList ();
}

function updatePrayerTimesList() {
  prayerSchedule.sort((a, b) => a.timestamp - b.timestamp);
  prayerTimesContainer.innerHTML = '';
  prayerSchedule.forEach(prayer => {
    const div = document.createElement('div');
    div.className = 'prayer';
    div.innerHTML = `<h2>${prayer.name}</h2><p>${prayer.time}</p>`;
    prayerTimesContainer.appendChild(div);
  });
  displayNextPrayer();
}

function displayNextPrayer() {
  const now = Date.now();
  const upcoming = prayerSchedule.filter(p => p.timestamp > now);

  if (upcoming.length === 0) {
    // If no upcoming prayers, fetch tomorrow’s schedule
    fetchPrayerData(1, true);
    return;
  }

  const nextP = upcoming[0];
  nextPrayerLabel.textContent = `${nextP.name} ${nextP.time}`;
  nextPrayerData = nextP;
}

function scheduleAdhans() {
  nextPrayerTimeouts.forEach(t => clearTimeout(t));
  nextPrayerTimeouts = [];

  const now = Date.now();
  prayerSchedule.forEach(prayer => {
    if (prayer.timestamp > now) {
      const diff = prayer.timestamp - now;
      const tID = setTimeout(() => {
        playAdhan();
        displayNextPrayer();
        if (prayer.name === 'Isha') {
          setTimeout(() => {
            fetchPrayerData(1);
          }, 0);
        }
      }, diff);
      nextPrayerTimeouts.push(tID);
    }
  });
}

function playAdhan() {
  adhanAudio.currentTime = 0;
  adhanAudio.play().catch(err => console.error('Failed to play adhan:', err));
}

// Countdown Updater: refresh every second
function startCountdownUpdater() {
  setInterval(() => {
    if (!nextPrayerData) {
      countdownElem.textContent = '';
      return;
    }
    const now = Date.now();
    const diff = nextPrayerData.timestamp - now;
    if (diff <= 0) {
      countdownElem.textContent = 'It’s time!';
      return;
    }
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

// Daily refresh at midnight
function scheduleDailyRefresh() {
  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()+1, 0, 0, 0);
  const diff = midnight - now;
  setTimeout(() => {
    if (userLat && userLon) {
      fetchPrayerData(0);
      updateLocationIndicator(userLat, userLon);
    } else {
      fetchPrayerData(0);
      locationIndicator.textContent = `${FALLBACK_CITY}, ${FALLBACK_STATE} (fallback)`;
    }
    scheduleDailyRefresh();
  }, diff);
}
scheduleDailyRefresh();
