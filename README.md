# MatchMate

A robust, offline-first iOS application displaying matrimonial-style profiles fetched from the Random User API. Built natively for iOS 17 using SwiftUI and SwiftData, enforcing a strict Clean Architecture pattern and Swift 6 concurrency safety.

## 🌟 Project Highlights

*   **100% Offline Capable:** By replacing native `AsyncImage` with `Kingfisher` and intelligently syncing network payloads to a local SwiftData container, the app remains fully functional—including rendering profile pictures and allowing Match/Pass interactions—even in Airplane mode or after a cold app launch.
*   **Strict Clean Architecture:** The Domain layer contains pure Swift business logic with zero knowledge of `SwiftData`, `URLSession`, or `SwiftUI`. The Data and Presentation layers are strictly decoupled and depend entirely on injected protocols.
*   **Zero-Lag Optimistic UI:** When a user accepts or declines a profile, the ViewModels optimistically update the UI instantly, providing a snappy, tactile experience while the repository handles database persistence and network logic in the background.
*   **Flawless State Synchronization:** The List and Detail screens read from the exact same local source of truth. Without relying on messy `NotificationCenter` broadcasts, any status mutation on the Detail screen is instantly reflected on the List screen when the user navigates back.
*   **Modern, Interactive Design:** The UI moves beyond basic lists by utilizing vibrant gradients, frosted glass navigation bars, and immersive edge-to-edge hero images.
*   **Swift 6 Concurrency Safe:** The entire Domain and Data layer is explicitly isolated to the `@MainActor`, structurally eliminating data races and strict concurrency warnings.
*   **Testable by Design:** A complete suite of Unit and Integration tests proves the stability of the ViewModels without relying on any third-party mocking libraries.

---

## 🚀 How to Run

1. Open `MatchMate.xcodeproj` in Xcode 15+.
2. Wait for Swift Package Manager to resolve the `Kingfisher` dependency.
3. Select an iOS 17+ Simulator or physical device.
4. Press **Cmd + R** to build and run.
5. **To test offline mode:** Load the first page, trigger Airplane mode on your device/simulator, kill the app from the app switcher, and relaunch.

## 🏗 Architecture Sketch

The application is structured using **Clean Architecture + MVVM**, ensuring dependencies flow strictly inward. To guarantee Swift 6 strict concurrency safety, the Domain and Data layers are explicitly isolated to the `@MainActor`.

*   **Presentation Layer:** Contains declarative SwiftUI Views and `@Observable` ViewModels. ViewModels are completely decoupled from data-fetching implementations.
*   **Domain Layer:** Contains pure Swift business logic (`Profile`, `MatchStatus`, Use Cases). This layer has absolute zero knowledge of SwiftUI, SwiftData, or `URLSession`.
*   **Data Layer:** Handles network requests via DTOs and `URLSession`, as well as persistence via SwiftData and `@Model`. The `ProfileRepositoryImpl` orchestrates the single source of truth, managing merging, full-property upserts, and offline fallbacks.
*   **Dependency Injection:** Dependencies are injected using the **Composition Root** pattern via an `AppComposition` enum at the `@main` app entry point. Every dependency relies on protocols, making testing trivial without third-party mocking frameworks.

## 💾 Database Choice: SwiftData vs. Core Data

**SwiftData** was chosen over Core Data for this project for several modern architectural reasons:
*   **Native Integration:** It is designed specifically for Swift, eliminating the heavy `NSManagedObject` and `NSFetchedResultsController` boilerplate.
*   **Type Safety & Macros:** The `@Model` macro drastically simplifies mapping our pure Domain models to persistence entities without generating XML `.xcdatamodeld` files.
*   **Concurrency:** SwiftData integrates natively with modern Swift Concurrency (`async/await`), keeping background pagination merges smooth and thread-safe.

## 🔄 Pagination & Status Synchronization

### How Pagination Works
Pagination is handled via an infinite scroll mechanism. A `.task` modifier attached to the list items triggers the `MatchListViewModel` to fetch the next page when the user scrolls near the bottom. 
*   **Network Handling over Reachability Monitors:** Rather than relying on `NWPathMonitor` reachability checks (which are prone to lag and false negatives), the app always attempts the network request and leverages `URLSession`'s native failure states.
*   **Offline Fallback:** If the network request fails, the repository seamlessly falls back to the local cache. If the user attempts to scroll past the locally saved data while offline, it gracefully throws a `.offlineNoMoreData` error.
*   **Cold Start Empty State:** If the app is launched fully offline with an empty cache, it intercepts the state and presents a dedicated full-screen "Offline" view with a manual "Try Again" mechanism.

### How Status Sync Works (List ↔ Detail)
The app ensures that the list and detail views reflect the same data during standard navigation flows.

**The Architectural Trade-off:**
Rather than relying on SwiftData's native `@Query` for live change-observation, this app utilizes a manual re-fetch strategy (`.onAppear` triggering a cache read). This was a deliberate architectural choice made to preserve strict Clean Architecture boundaries. 

By avoiding `@Query`, the Presentation Layer (Views and ViewModels) remains entirely decoupled from the Data Layer (`ProfileEntity` and `ModelContext`), interacting only with pure Domain `Profile` structs. 

**Known Limitation:** 
Because this relies on view lifecycle events (`.onAppear` on pop) rather than a live reactive binding, it works perfectly for standard iPhone push/pop navigation but would not instantly self-correct in a simultaneous multi-window scenario (e.g., an iPad split-screen displaying both the list and detail views side-by-side).

## 🖼 Offline Image Caching

While native iOS provides `AsyncImage`, it does not persistently cache images to disk out-of-the-box; it relies on standard `URLCache` session memory, which the OS frequently evicts upon app termination. To satisfy the explicit requirement for robust offline survivability, the lightweight **Kingfisher** (`KFImage`) library was integrated. This ensures profile pictures are immediately cached to the physical disk, guaranteeing a 100% offline-capable experience.

## ⚠️ Known Gaps & Future Improvements

*   **Hardcoded Networking Details:** The base API URL, the `matchmate` seed, and the pagination limit (`resultsPerPage = 10`) are currently hardcoded inside `ProfileRepositoryImpl`. In a larger production app, these would be injected via an `AppConfiguration` environment file.
*   **Background Context Optimization:** While the app is thoroughly isolated to the `@MainActor` to strictly comply with Swift 6 concurrency safety, massive pagination background writes (e.g., hundreds of profiles) could theoretically cause frame drops on older devices. Moving the heavy upsert operations to a detached `ModelActor` would optimize this further.
*   **iPad Split-Screen Sync:** As noted in the Synchronization section, true live-binding would be required for simultaneous multi-window support.
