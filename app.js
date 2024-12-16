// DOM elements
const prayerTimesContainer = document.getElementById('prayerTimesContainer');
const nextPrayerLabel = document.getElementById('nextPrayerLabel');
const countdownElem = document.getElementById('countdown');
const dateInfoElem = document.getElementById('dateInfo');
const adhanAudio = document.getElementById('adhanAudio');
const startupOverlay = document.getElementById('startupOverlay');

// Data holders
let prayerSchedule = [];     // Each item: { name, time, timestamp }
let nextPrayerTimeouts = [];
let nextPrayerData = null;   // Stores upcoming prayer info for countdown

function initAudio() {
  startupOverlay.style.display = 'none';

  // Prime audio playback
  adhanAudio.play().then(() => {
    adhanAudio.pause();
    console.log('Audio primed');
  }).catch(err => console.log('Audio play error:', err));

  // Fetch "today's" prayers by default
  fetchPrayerDataForDay(0);
}

// ---- REFACTORED FETCH FUNCTIONS ---- //

// Option A: A helper that fetches for “today + offsetDays”
async function fetchPrayerDataForDay(offsetDays = 0) {
  try {
    const now = new Date();
    now.setDate(now.getDate() + offsetDays); // offset for tomorrow if offsetDays=1

    // Format day-month-year for AlAdhan
    // AlAdhan supports a DD-MM-YYYY param if we use “timingsByCity?date=DD-MM-YYYY”
    const day = String(now.getDate()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const year = now.getFullYear();
    const dateParam = `${day}-${month}-${year}`;

    // Example: AlAdhan “timingsByCity” endpoint with a date param
    // https://aladhan.com/prayer-times-api#GetCalendarByCity
    // We'll use "timingsByCity?date=DD-MM-YYYY" rather than a timestamp
    const url = `https://api.aladhan.com/v1/timingsByCity?city=Queens&state=NY&country=USA&method=2&school=1&date=${dateParam}`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code !== 200) throw new Error('API error');

    const { timings } = data.data;
    const { date } = data.data; // has .gregorian, .hijri, etc.
    
    const dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const baseDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Build the schedule
    prayerSchedule = dailyPrayers.map(prayerName => {
      const timeStr = timings[prayerName];
      const [hours, minutes] = timeStr.split(':').map(Number);
      // Timestamp for that prayer on the chosen day
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

  } catch(err) {
    console.error('Error fetching prayer times:', err);
    nextPrayerLabel.textContent = 'Failed to load prayer data.';
  }
}

// Option B: Original “fetchPrayerData()” that just calls “fetchPrayerDataForDay(0)”
function fetchPrayerData() {
  return fetchPrayerDataForDay(0);
}

// ------------------------------------ //

function updateUI(dateObj) {
  // DATE DISPLAY: Gregorian + Hijri
  const gregorian = dateObj.gregorian;
  const hijri = dateObj.hijri;

  const gregorianString = `${gregorian.day} ${gregorian.month.en} ${gregorian.year}`;
  const hijriString = `${hijri.day} ${hijri.month.en} ${hijri.year}`;
  dateInfoElem.textContent = `Today: ${gregorianString} | Hijri: ${hijriString}`;

  // Sort prayers by time
  prayerSchedule.sort((a, b) => a.timestamp - b.timestamp);

  // Populate the prayer times
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
    // No upcoming prayers for this day
    nextPrayerLabel.textContent = `Alhamdulillah`;
    countdownElem.textContent = '';
    nextPrayerData = null;
    return;
  }

  const nextP = upcoming[0];
  nextPrayerLabel.textContent = `${nextP.name} ${nextP.time}`;
  nextPrayerData = nextP;
}

function scheduleAdhans() {
  // Clear old timeouts
  nextPrayerTimeouts.forEach(t => clearTimeout(t));
  nextPrayerTimeouts = [];

  const now = Date.now();
  prayerSchedule.forEach(prayer => {
    if (prayer.timestamp > now) {
      const diff = prayer.timestamp - now;
      const tID = setTimeout(() => {
        // Play adhan
        playAdhan();

        // Show next prayer
        displayNextPrayer();

        // If this was Isha, we fetch tomorrow’s data immediately
        if (prayer.name === 'Isha') {
          // Optionally wait a few seconds/minutes after Isha triggers 
          // so the user hears the full adhan before flipping to tomorrow:
          setTimeout(() => {
            fetchPrayerDataForDay(1); // fetch tomorrow’s times
          }, 0); 
          // ^ Wait 60 sec (1 min) so the Adhan can play. 
          // Or set to 0 if you want an immediate flip to tomorrow’s schedule.
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

    // Convert diff (ms) to HH:MM:SS
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

// We can optionally remove or modify scheduleDailyRefresh 
// because now after Isha triggers, we fetch the next day’s data anyway.
function scheduleDailyRefresh() {
  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0);
  const diff = midnight - now;

  setTimeout(() => {
    fetchPrayerDataForDay(0); // Re-fetch for the new day at midnight anyway
    scheduleDailyRefresh(); 
  }, diff);
}
scheduleDailyRefresh();
