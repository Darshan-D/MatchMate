# MatchMate

An iOS app showing a paginated feed of profiles from the Random User API, with Accept/Decline actions and offline support. Built with SwiftUI, SwiftData, and Clean Architecture / MVVM.

## How to Run

1. Open `MatchMate.xcodeproj` in Xcode 15 or later.
2. Let Swift Package Manager resolve the **Kingfisher** dependency.
3. Pick an iOS 17+ simulator or device as the run target.
4. Build and run (`Cmd + R`).

No API key or config needed — the app calls `randomuser.me` with a fixed seed. To test offline mode: launch once with network on so a page or two caches, then enable Airplane Mode, kill the app, and relaunch.

## Architecture Sketch

Three layers, dependencies pointing inward, wired up in a composition root:

```
Presentation (SwiftUI Views, @Observable ViewModels)
        │  depends on protocols only
        ▼
Domain (Profile, MatchStatus, Use Cases)
        ▲  no knowledge of SwiftUI / SwiftData / URLSession
        │  implements
Data (URLSession + DTOs, SwiftData + @Model, ProfileRepositoryImpl)
```

- **Domain** — `Profile` (plain struct) and `MatchStatus` are the only types Presentation knows about. `UseCases` are thin wrappers that forward to `ProfileRepository`.
- **Data** — `RandomUserRemoteDataSource` fetches/decodes from the network; `SwiftDataLocalDataSource` reads/writes `ProfileEntity` via SwiftData. `ProfileRepositoryImpl` is the only place that knows about both, and decides network-vs-cache.
- **Presentation** — `MatchListViewModel` / `MatchDetailViewModel` hold UI state and call use cases only; no `URLSession` or `ModelContext` references.
- **`AppComposition`** builds the concrete graph (real data sources, repository, use cases) and hands ViewModels to the Views at app launch.

Everything touching SwiftData or DI is `@MainActor` isolated.

## Database Choice

**SwiftData**, over Core Data or a custom store — the `@Model` macro replaces `.xcdatamodeld`/`NSManagedObject` boilerplate with plain Swift, and it integrates directly with `async/await` so the local data source is just `throws` functions called from async use cases. `ProfileEntity` mirrors `Profile` but adds `pageFetched: Int`, which is what makes pagination resumable across launches. `MatchMateApp` also falls back to an in-memory store if the persistent one fails to load, so a corrupted store doesn't crash the app outright.

## Why Kingfisher

`AsyncImage` doesn't persist images to disk — it only holds them in `URLCache`'s session memory, which iOS evicts on app termination, so a relaunch means re-downloading every thumbnail. Since offline usability is a core requirement here, profile images needed to survive a cold, fully-offline relaunch too, not just the profile data. Kingfisher's `KFImage` caches to disk automatically, so images load instantly from cache on a subsequent offline launch instead of showing broken/placeholder states.

## Pagination + Status Sync

**Pagination:**

Loading more profiles happens automatically as the user scrolls — each row triggers a check, and when that row is the *last* one currently shown, the app loads the next page.

On launch, `loadInitial()` decides where to start:
- **Empty cache** (true first launch) → fetch page 1 from the network.
- **Cache has data** → show it immediately, no network wait, and resume from the last page that was ever saved (stored per-profile as `pageFetched`). So if a user quit the app on page 3, relaunching continues from page 4 instead of re-fetching pages 1–2.

Every page request tries the network first. If that fails, the app falls back to whatever is cached locally:
- If there's *no* cache at all (offline on a fresh install), the app shows a full-screen "you're offline" state.
- If the user scrolls past everything that was ever cached, it shows a smaller banner instead ("no more data offline") — the list itself stays visible.

If a page fetch fails for any reason, the app resets the current page number back to where it was, so a failed attempt doesn't leave pagination stuck on a page that never actually loaded.

**Status sync (List ↔ Detail):**

Tapping Accept/Decline updates the UI instantly — before the change is even saved. If saving fails, the change is undone and an error is shown. This makes the buttons feel responsive without ever showing a status that didn't actually persist.

The List and Detail screens don't share state directly — no shared ViewModel, no live database subscription. Each screen manages its own copy of the data. To stay in sync, the List screen simply re-reads the saved data every time it reappears on screen (e.g., when the user backs out of the Detail screen), and only redraws if something actually changed.

This keeps the two screens agreeing for normal back-and-forth navigation, but it's a "check when you reappear" approach rather than a live, always-in-sync connection — the two screens don't push updates to each other in real time. This was a deliberate trade-off to keep a clear separation of concerns; see Known Gaps for where it falls short.

## Known Gaps

- No live/reactive sync — List and Detail wouldn't self-correct if both were visible at once (e.g., iPad split-screen), since sync relies on `.onAppear`, not a live binding.
- Base URL, `resultsPerPage`, and the API seed are hardcoded in `ProfileRepositoryImpl` rather than injected config.
- No reachability pre-check — every offline page load pays for a timed-out request before falling back to cache.
- Everything is pinned to `@MainActor`; a very large pagination batch could cause frame drops on older devices. A dedicated `ModelActor` for writes would fix this.
- `upsert` intentionally never overwrites `status` on re-fetch (to preserve local decisions), so there's no path for status to ever be corrected by the server.

## Hours Spent

**Approximately** 9 hours

This app was built with help from several LLMs on their free tiers (Gemini, Claude, ChatGPT, DeepSeek). The total could likely have been lower with more generous usage limits, free-tier rate limits meant switching tools mid-task rather than working straight through with one. This is also why there are no `SKILLS.md` or `RULES.md` files for AI agents in this repo.

## Testing Details

Detailed testing results for the following test cases are available in this [Google Drive link](https://drive.google.com/drive/folders/15_QPq3KGBDeCac2FyycEQP_NjssuBXOA?usp=sharing).

### Test Cases

* **Test Case 1: Pagination** — Pagination works as expected using an infinite-scroll approach.
* **Test Case 2: UI Consistency** — The UI remains consistent between the main feed and the detailed profile view.
* **Test Case 3: Data Persistence** — Profile status is persisted correctly after the app is terminated and reopened.
* **Test Case 4: Airplane Mode** — The app displays cached data when the device is in Airplane Mode.
* **Test Case 5: Cold Start** — When the app is launched for the first time without an internet connection and no cached data is available, it displays an error screen with a **Retry** button.
* **Test Case 6: View Model Tests** — All ViewModel unit tests pass successfully.



