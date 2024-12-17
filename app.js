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
locationIndicator.style.position = 'absolute';
locationIndicator.style.right = '10px';
locationIndicator.style.bottom = '10px';
locationIndicator.style.fontSize = '0.9rem';
locationIndicator.style.color = '#ccc';

let prayerSchedule = [];     // Each item: { name, time, timestamp }
let nextPrayerTimeouts = [];
let nextPrayerData = null;   // Next upcoming prayer for countdown

// Global lat/lon (if user grants location)
let userLat = null;
let userLon = null;

// 1. initAudio called from the "Start" button in the overlay
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
        fetchPrayerDataForDay(0);  // fetch today's times using geolocation
        updateLocationIndicator(userLat, userLon); // update city/country display
      },
      (error) => {
        console.warn('Geolocation error:', error);
        // fallback to city-based approach if geolocation fails/denied
        fetchPrayerDataCityForDay(0);
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 300000 }
    );
  } else {
    console.warn('Geolocation not supported. Using default city.');
    fetchPrayerDataCityForDay(0); // fallback
  }
}

// 2. fetchPrayerDataForDay using lat/lng and AlAdhan’s lat-lon endpoint
async function fetchPrayerDataForDay(offsetDays = 0) {
  try {
    if (!userLat || !userLon) {
      // No geolocation? fallback
      fetchPrayerDataCityForDay(offsetDays);
      return;
    }

    // We shift the date by offsetDays for tomorrow logic
    const now = new Date();
    now.setDate(now.getDate() + offsetDays);

    // AlAdhan lat/lon + a specific date is not as direct. 
    // The "timings" endpoint by lat/lng always returns "today" (unless we pass a timestamp).
    // So we can use the timestamp param => https://aladhan.com/prayer-times-api#GetTimings
    // We'll create a custom timestamp for "today + offsetDays" at midnight
    const targetDateMidnight = new Date(
      now.getFullYear(), now.getMonth(), now.getDate(), 
      0, 0, 0
    );
    const unixTimestamp = Math.floor(targetDateMidnight.valueOf() / 1000);

    const url = `https://api.aladhan.com/v1/timings/${unixTimestamp}?latitude=${userLat}&longitude=${userLon}&method=2&school=1`;
    const response = await fetch(url);
    const data = await response.json();
    if (data.code !== 200) throw new Error('API error (lat/lon)');

    const { timings } = data.data;
    const { date } = data.data;
    const dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    
    // Build schedule
    prayerSchedule = dailyPrayers.map(prayerName => {
      const timeStr = timings[prayerName];  // e.g. "05:30"
      const [hours, minutes] = timeStr.split(':').map(Number);
      const prayerDate = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate(),
        hours, minutes, 0
      );
      return {
        name: prayerName,
        time: timeStr,
        timestamp: prayerDate.getTime(),
      };
    });

    updateUI(date);
    scheduleAdhans();
    startCountdownUpdater();

  } catch (err) {
    console.error('Error fetching prayer times by coords:', err);
    nextPrayerLabel.textContent = 'Failed to load prayer data.';
  }
}

// Fallback approach using city "Queens, NY"
async function fetchPrayerDataCityForDay(offsetDays = 0) {
  try {
    const now = new Date();
    now.setDate(now.getDate() + offsetDays);
    const day = String(now.getDate()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const year = now.getFullYear();
    const dateParam = `${day}-${month}-${year}`;

    const url = `https://api.aladhan.com/v1/timingsByCity?city=Queens&state=NY&country=USA&method=2&school=1&date=${dateParam}`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code !== 200) throw new Error('API error (city fallback)');

    const { timings } = data.data;
    const { date } = data.data;
    const dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
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

    updateUI(date);
    scheduleAdhans();
    startCountdownUpdater();

    // Show fallback location in bottom-right
    locationIndicator.textContent = 'Queens, NY (fallback)';
  } catch (err) {
    console.error('Error fetching city fallback prayer times:', err);
    nextPrayerLabel.textContent = 'Failed to load prayer data.';
  }
}

// 3. Show city/country in bottom-right
async function updateLocationIndicator(lat, lon) {
  try {
    // Simple reverse geocoding request to a free service like Nominatim
    // e.g. https://nominatim.org/release-docs/latest/api/Reverse/
    // GET https://nominatim.openstreetmap.org/reverse?lat=...&lon=...&format=json

    const geoUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=json`;
    const res = await fetch(geoUrl);
    const locationData = await res.json();

    // Nominatim calls the city different keys (like address.city, address.town, etc.)
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

// 4. UI & Scheduling
function updateUI(dateObj) {
  const gregorian = dateObj.gregorian;
  const hijri = dateObj.hijri;
  const gregorianString = `${gregorian.day} ${gregorian.month.en} ${gregorian.year}`;
  const hijriString = `${hijri.day} ${hijri.month.en} ${hijri.year}`;
  dateInfoElem.textContent = `Today: ${gregorianString} | Hijri: ${hijriString}`;

  prayerSchedule.sort((a, b) => a.timestamp - b.timestamp);
  prayerTimesContainer.innerHTML = '';
  prayerSchedule.forEach(prayer => {
    const div = document.createElement('div');
    div.className = 'prayer';
    div.innerHTML = `
      <h2>${prayer.name}</h2>
      <p>${prayer.time}</p>
    `;
    prayerTimesContainer.appendChild(div);
  });

  displayNextPrayer();
}

function displayNextPrayer() {
  const now = Date.now();
  const upcoming = prayerSchedule.filter(p => p.timestamp > now);

  if (upcoming.length === 0) {
    // If no upcoming prayers, fetch tomorrow’s schedule
    fetchPrayerDataForDay(1);
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

        // If Isha triggers, fetch tomorrow’s schedule
        if (prayer.name === 'Isha') {
          // optional short delay to let adhan play 
          setTimeout(() => {
            fetchPrayerDataForDay(1);
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

// 5. Countdown updates every second
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

// 6. Daily refresh at midnight (optional, extra safety)
function scheduleDailyRefresh() {
  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate()+1, 0, 0, 0);
  const diff = midnight - now;
  setTimeout(() => {
    // Re-fetch tomorrow’s data at midnight
    // Using geolocation if available, otherwise fallback
    if (userLat && userLon) {
      fetchPrayerDataForDay(0);
      updateLocationIndicator(userLat, userLon);
    } else {
      fetchPrayerDataCityForDay(0);
    }
    scheduleDailyRefresh();
  }, diff);
}
scheduleDailyRefresh();
