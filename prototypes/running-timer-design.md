# Running timer in the closed notch: approved design

Approved by the owner on 2026-11-05 ("perfect."). Mockup: `running-timer.prototype.html` (open in a browser).

## When it shows
- Whenever a timer is running, with no hover needed.
- Hovering opens the hover panel below (approved 2026-11-06).
- With more than one timer running, the closed island (icon, time, progress line and glow) shows the timer that ends soonest. Owner's words, 2026-11-05: "the progress bar when minimized … should reflect the timer ending soonest".
- It replaces the current closed-notch timer display (`DynamicIsland/ContentView.swift` around line 1140).

## Shape
- Black island 283 × 34 pt: the 179 pt camera notch plus 52 pt on each side.
- Bottom corner radius 12 pt; the top corners flare into the screen edge with a 6 pt concave curve.

## Left and right
- Left: Apple's `stopwatch` SF Symbol at 12 pt, in the preset's colour, 14 pt from the left edge. Not the `timer` symbol: the owner said it looks like a power button.
- Right: time left, system font (SF Pro), 11.5 pt, medium weight, tabular digits, in the preset's colour, 13 pt from the right edge. Format `18:42`, or `1:01:59` over an hour.

## Progress line
- 2 pt line, in the preset's colour, drawn flush inside the island's outline, with no gap.
- The path starts at the top-left where the island meets the screen edge, follows the curve down the left side, crosses the bottom, climbs the right side, and ends at the top-right screen edge. 0% to 100% is that whole path.
- Drawn only from the start to the current progress. Nothing past the tip: no track, no rim.
- Round end cap.

## Glow on the tip
- Soft round haze, 12 pt across, centred on the tip of the line.
- Colour: white at 80% in the centre, the preset's colour at 45% at 30% out, transparent at 70%; blurred by 1 pt.
- Not a dome above the line (tried and rejected).

## Colours used in the mockup
- Superseded on 2026-11-06: see "Colours" below (lavender, mint, peach). In the app these come from each preset's own colour.

## Build notes
- SwiftUI: draw the outline as a `Shape`, then `.trim(from: 0, to: progress)` with `.stroke(lineWidth: 2, lineCap: .round)`; place the glow at the trimmed end point.
- Build waits on the SanDisk SSD (`/Volumes/SandiskSSD/notch-build`).

## Hover panel (approved 2026-11-06; replaces the 396 pt row and the A/B/C panels)
Mockup: `hover-panel.prototype.html` (all three modes, idle and running). One panel for idle and running.
- Black panel 283 x 124 pt, the same width as the closed island, so hover only grows the notch downward. Bottom corner radius 22 pt. Every mode is the same height.
- Top 34 pt in the centre is the camera; nothing is drawn under it.
- Left column: mode switcher, vertical. Capsule 28 pt wide, 8 pt from the panel's side, top and bottom (so its ends are concentric with the 22 pt corner: 22 - 8 = 14 pt radius). Three round 24 pt buttons spread over the full height: Timer (stopwatch), Until (clock), Pomodoro (circular arrow). Current mode has a 16% white fill.
- Right column, same capsule and position:
  - Idle: one tall play button filling the whole column (28 x 108 pt), in the mode's colour, black play glyph.
  - Running: three round 24 pt buttons spread over the full height: pause (filled with the mode's colour) on top, restart in the middle, stop at the bottom.
- Middle (between the columns, centred):
  - Timer idle: big time (SF Pro Rounded 32 pt medium, focus colour) over a draggable ruler; preset dots and labels on the ruler (Break, Focus, "Deep"). Clicking the time lets you type ("90", "1h30").
  - Until idle: a time of day in white over a ruler with 5-minute ticks; the label under the needle says how far away it is ("in 1 h 32 m"). Until uses white as its colour.
  - Pomodoro idle: three tinted chips (focus minutes, break minutes, "x4" rounds; tint is the colour at 20%) over a plan bar (focus blocks and break blocks, 4 pt tall).
  - Running: the countdown over a 4 pt progress bar. Until adds "until 3:30 PM" under the countdown. Pomodoro's plan bar fills block by block.

## Colours (approved 2026-11-06)
- Focus: lavender `#8e8cff`. Break: mint `#5ee6b8` (owner rejected the muted `#7fd6b5`). Deep Work: peach `#f4b28a`.
- These are the default preset colours. A preset's own colour, set in settings, still wins.
- The closed island follows the running timer's colour, so it becomes lavender during Focus (it was orange in the first mockup).

Decided (owner's yes, 2026-11-09):
- The left and right columns spread over the full panel height, as the mockup shows.
- Running several timers at once is dropped for now. It comes back later as its own job.
- In Pomodoro, restart goes back to the start of the current round.
- While a timer runs, the other mode icons are dimmed and locked.
- Pomodoro starts the next round by itself, with a chime between rounds.
- No long break after the last round, for now.
- "Until" means counting down to a time of day.
- The cup (Keep Awake) and gear (Settings) icons are off by default in the open notch header (owner yes, 2026-11-09). Settings stays reachable from the menu bar icon.

Engineering note: the app holds only one timer today (`DynamicIsland/managers/TimerManager.swift:31-40`). Several at once means TimerManager holds a list, plus updates to `LockScreenTimerWidgetManager.swift` and `SystemTimerBridge.swift`.
