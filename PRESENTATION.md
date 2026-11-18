# SoundSpots: 4-Minute Presentation Script

**Before you present:** launch the app in the simulator, tap **⋯ › Load Demo Data**, and set a custom location (Features › Location › Custom Location → 37.77, -122.447). Have Xcode open on `ListenStore.swift`.

---

## 0:00–0:30 · The idea
> "You know how a song can take you right back to a place? SoundSpots remembers *where* you first heard your favorite songs, puts them on a map, and builds a playlist for each place from what you actually play there: your gym mix, your library mix, your car mix."

## 0:30–2:00 · Live demo (90 seconds)
1. **Map tab:** "Each pin is a place I've listened to music." Tap **The Gym** pin, show the callout with the top song, tap ⓘ.
2. **Gym playlist:** "Songs ranked by how often I play them *here*." Switch the sort to **Recent**, then **Firsts** ("songs I discovered at the gym"). Tap **Play #1** to play a 30-second preview, then stop it.
3. Tap **HUMBLE.**: "Here's when and where I first heard it, plus every place I've played it."
4. Back on the Map, tap **＋**, search *"levitating"*, and pick it. "It grabs my GPS location and suggests a name with reverse geocoding." Rename it to *"Coffee Shop"* and tap **Save**. The map jumps to the new pin.
5. **First Heard tab:** the new song is at the top. **Playlists tab:** the new "Coffee Shop Mix" appears.
6. (Optional) Quit and relaunch the app: everything is still there (UserDefaults).

## 2:00–3:20 · Code structure (80 seconds)
Show the folder tree (App / Models / Networking / Services / Persistence / Controllers / Views).
* **API:** `ITunesMusicService` uses URLSession with an **escaping completion handler**, decodes JSON with **Codable**, and returns `Result<[Song], NetworkError>`.
* **Protocols:** "The view controllers depend on the `MusicSearching` protocol, so when the network fails, the alert can swap in `MockMusicService` and nothing else changes." Mention `LogListenDelegate` too: "the modal sends the new listen back to the map through a delegate."
* **Enums:** `PlaylistSort` drives the segmented control *and* the sorting. `LocationSource` has an associated value.
* **Persistence:** `ListenStore` saves one Codable `ListeningHistory` struct to UserDefaults. Grouping listens within 150 m into the same place is a single `filter` + `min` on distances.
* **Storyboard:** show Main.storyboard with the tab bar → nav controllers → the modal flow, and the segues with identifiers.

## 3:20–4:00 · What I'd improve
* Auto-detect the song playing in Apple Music or Spotify instead of searching for it.
* Export a location's playlist to Apple Music or Spotify.
* Move to Core Data and add map clustering as the history grows.
* Add unit tests for the playlist ranking.

> "Thanks! Questions?"
