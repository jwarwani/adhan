# adhan
Webapp to display adhan times and play the adhan

- Uses [AlAdhan Prayer Times API](https://aladhan.com/prayer-times-api)
- Background photo by [Ali Arif Soydaş](https://unsplash.com/photos/two-mosque-minarets-under-calm-sky-uwzPks8CE3k?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash)
- Deployed [here](https://github.com/jwarwani/adhan)

## ChatGPT Prompts

Initial Prompt:
I have an old ipad that I want to use as a prayer clock for the five daily prayers. The ipad will be placed in landscape mode and should display, at the top, the next prayer and its time. Below this, it should show the time for each of the five prayers for that day. When it is time for the prayer, it should play the full adhan out loud to alert me that it is time to pray. I want the UI to look beautiful, peaceful, serene, and to embody the values of islam. What are my options?

Prompt to generate code:
Let's go with option 2b (build your own minimal web app). Guide me through it

Additional requirements #1:
- The ipad will be up on a bookshelf, so visibility from a distance is important
- The most visible thing should be the next prayer time
- Underneath the next prayer time, there should be a small countdown to the next prayer time
- It would be good to display the date (in Gregorian and Islamic calendars) on the page somewhere

Additional requirements #2:
- Display the date using the written-out month in english. I believe this is also included in the API response (data.date.hijri.month.en for example)
- Create a separate block for the next prayer, make it visually distinct from the rest of the display, and make the font 10x larger
- Choose nice fonts to make it visually appealing
- Create a subtle background image and pattern and incorporate that

Additional requirements #3: 
- There should be no background for the date at the top. It should simply overlay the image
- The next prayer block doesn't need to extend all the way to the edge of the screen
- Choose a nicer color palette. I've uploaded the image I am using as the background for your context

Additional requirements #4: 
- Modify the code so that it fetches the next day's data after the Isha prayer, and after the isha prayer, displays the time for Fajr the following day.

Additional requirements #5:
- How can I make the sizing dynamic so that the nextPrayerLabel always shows in one line?

Additional requirements #6:
- Can I get the location from the ipad and use that to get the correct prayer times?

Additional requirements #7:
- I want to use geolocation to fetch the correct prayer times, and any time the prayer times get refreshed, it should use geolocation without reprompting the user to allow geolocation. I also want to display the city and country in the bottom right corner in small text as an indicator of the location used so that the user can validate that the prayer times are for the correct location

## ChatGPT Summary of Requirements

Prompt: Summarize the requirements for this app so that I can give them to an LLM and get a fully functioning webapp with the same capabilities and look

Response:

**Summarized Requirements (Based Only on User-Provided Specifications)**

1. **Device & Purpose**:  
   - The app will run on an old iPad as a dedicated prayer clock display.

2. **Display & Layout**:  
   - At the top, show "Bismillāhir Raḥmānir Raḥīm" in Arabic calligraphy.
   - Directly beneath that, display today’s date in both the Gregorian and Islamic (Hijri) calendars.
   - Prominently feature the next upcoming prayer time in very large, easily visible text, ensuring it always fits on a single line.
   - Below the next prayer, show a countdown timer to that next prayer.
   - Further below, list all five daily prayer times for the current day.
   - Display the user’s city and country in the bottom-right corner so the user can confirm the correct location is being used.

3. **Functionality**:  
   - Use geolocation to automatically determine the user’s location and fetch accurate daily prayer times.
   - If geolocation is unavailable or fails, default to a specified fallback location (e.g., Queens, NY, USA).
   - When the prayer time arrives, play the full adhan out loud.
   - After the last prayer of the day (Isha), automatically fetch and display the following day’s prayer times, so that the schedule rolls over seamlessly.
   - Refresh the prayer times daily at midnight (or after Isha) to ensure the schedule is always up-to-date.

4. **Aesthetic Requirements**:  
   - The UI must be beautiful, peaceful, and serene, reflecting Islamic values.
   - Use Islamic-inspired fonts (e.g., Arabic calligraphy for headings) and calming colors.
   - Include a subtle background image or pattern that does not distract from the text.
   - Ensure all text is readable from a distance.

5. **Kiosk Mode**:  
   - The app should run in a fullscreen mode on the iPad without showing Safari’s UI elements.
   - Once set up, the screen should remain on continuously, displaying prayer times and updating automatically.

