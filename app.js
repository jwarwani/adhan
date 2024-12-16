// DOM elements
const prayerTimesContainer = document.getElementById('prayerTimesContainer');
const nextPrayerLabel = document.getElementById('nextPrayerLabel');
const countdownElem = document.getElementById('countdown');
const dateInfoElem = document.getElementById('dateInfo');
const adhanAudio = document.getElementById('adhanAudio');
const startupOverlay = document.getElementById('startupOverlay');

// Data holders
let prayerSchedule = []; // Each item: { name, time, timestamp }
let nextPrayerTimeouts = [];
let nextPrayerData = null; // To store the upcoming prayer info for countdown

function initAudio() {
  startupOverlay.style.display = 'none';

  // Try playing silently to prime audio playback
  adhanAudio.play().then(() => {
    adhanAudio.pause();
    console.log('Audio primed');
  }).catch(err => console.log('Audio play error:', err));

  fetchPrayerData();
}

async function fetchPrayerData() {
  try {
    // Example: AlAdhan API for Mecca, Saudi Arabia with method=2
    const url = `https://api.aladhan.com/v1/timingsByCity?city=Queens&state=NY&country=USA&method=2&school=1`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code !== 200) throw new Error('API error');
    
    // Extract timings
    const { timings } = data.data;
    timings['Dhuhr'] = '09:50';
    // We'll also extract the date info
    const { date } = data.data; 
    // date.gregorian.month.en, date.gregorian.day, date.gregorian.year
    // date.hijri.month.en, date.hijri.day, date.hijri.year

    const dailyPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const now = new Date();

    prayerSchedule = dailyPrayers.map(prayerName => {
      const timeStr = timings[prayerName]; // e.g. "05:30"
      const [hours, minutes] = timeStr.split(':').map(Number);
      const prayerDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), hours, minutes, 0);
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

function updateUI(dateObj) {
  // DATE DISPLAY: Gregorian + Hijri
  // Example from AlAdhan:
  // dateObj.gregorian.month.en => "November"
  // dateObj.gregorian.day => "09"
  // dateObj.gregorian.year => "2024"
  // dateObj.hijri.month.en => "Rabi Al-Thani"
  // dateObj.hijri.day => "25"
  // dateObj.hijri.year => "1446"
  
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
    // No upcoming prayers for today
    nextPrayerLabel.textContent = `All prayers finished for today.`;
    countdownElem.textContent = '';
    nextPrayerData = null;
    return;
  }

  const nextP = upcoming[0];
  nextPrayerLabel.textContent = `${nextP.name} @ ${nextP.time}`;
  nextPrayerData = nextP;
}

function scheduleAdhans() {
  // Clear old timeouts
  nextPrayerTimeouts.forEach(timeout => clearTimeout(timeout));
  nextPrayerTimeouts = [];

  const now = Date.now();
  prayerSchedule.forEach(prayer => {
    if (prayer.timestamp > now) {
      const diff = prayer.timestamp - now;
      const tID = setTimeout(() => {
        playAdhan();
        displayNextPrayer(); 
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

// Re-fetch times at midnight
function scheduleDailyRefresh() {
  const now = new Date();
  const midnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0);
  const diff = midnight - now;

  setTimeout(() => {
    fetchPrayerData();    // re-fetch new day’s data
    scheduleDailyRefresh(); 
  }, diff);
}
scheduleDailyRefresh();
