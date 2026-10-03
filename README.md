# Psst

A quiet "where's my phone?" for iPhone and Apple Watch. Tap the Psst button in
your watch's Control Center and your iPhone chirps softly at a high pitch you
pick. Tap it again to stop.

## How it behaves

| Time | iPhone does |
|---|---|
| 0–20 s | Soft chirps at your tuned pitch, every 2 seconds |
| 20–40 s | Louder, every 1.2 seconds |
| 40–60 s | Full volume, every 0.8 seconds, with a lower 2 kHz tone added |
| 60 s | Stops, and posts a notification (which reaches your watch) |

It also stops when you:
- tap the watch button again,
- pick the phone up (can be turned off in the iPhone app),
- tap the "Psst is chirping" notification or its **Stop** action.

Chirps play even when the iPhone is on silent, but never louder than the
iPhone's media volume.

## Setup (on your Mac)

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen), which turns
   `project.yml` into the Xcode project:
   ```sh
   brew install xcodegen
   ```
2. In this folder, generate and open the project:
   ```sh
   xcodegen && open Psst.xcodeproj
   ```
   Re-run `xcodegen` whenever files are added or `project.yml` changes.
3. For each of the three targets (**Psst**, **PsstWatch**,
   **PsstWatchControls**), open *Signing & Capabilities* and choose your team.
   Xcode registers the IDs and the `group.com.morganthall.psst` App Group.
   (Or put your Team ID in `DEVELOPMENT_TEAM` in `project.yml` once.)
4. Pick the **Psst** scheme, choose your iPhone, and run. This installs the
   watch app too.
5. Open Psst on the iPhone once, allow notifications, and tune the pitch with
   **Listen** on.
6. On the watch, open Control Center, tap **Edit**, and add the **Psst**
   button.

Requires iOS 26 and watchOS 26.

## Layout

| Folder | Target | What's in it |
|---|---|---|
| `Shared/` | all | Message keys and constants |
| `iOS/` | Psst | Tone generator, escalation, pickup detection, notifications, settings UI |
| `Watch/` | PsstWatch | Watch app with a big start/stop button |
| `WatchShared/` | PsstWatch, PsstWatchControls | Watch↔iPhone link, shared state, the start/stop intent |
| `WatchControls/` | PsstWatchControls | The Control Center button |

## Things to check on real devices

This was written without building it, so expect a round of compile fixes in
Xcode. Things that can only be confirmed on hardware:

- **Control Center button opens the watch app.** Only the watch app can talk
  to the iPhone, so the button opens it (`openAppWhenRun`) and the app sends
  the command. If watchOS turns out to allow it from Control Center directly,
  that flag can be removed.
- **Waking the iPhone app.** The watch's message wakes Psst on the iPhone in
  the background, even if it isn't running. If a start fails while the iPhone
  is locked, check the message reaches `PhoneLink`.
- **Pickup sensitivity.** `PickupDetector.threshold` (0.25 g) may need
  adjusting if it stops too easily or not easily enough.
