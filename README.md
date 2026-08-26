# MatchMate

A robust, offline-first iOS application displaying matrimonial-style profiles fetched from the Random User API. Built natively for iOS 17 using SwiftUI and SwiftData, enforcing a strict Clean Architecture pattern.

## 🚀 How to Run

1. Open `MatchMate.xcodeproj` in Xcode 15+.


2. Wait for Swift Package Manager to resolve the `Kingfisher` dependency.


3. Select an iOS 17+ Simulator or physical device.


4. Press **Cmd + R** to build and run.


5. **To test offline mode:** Load the first page, trigger Airplane mode on your device/simulator, kill the app from the app switcher, and relaunch.



## 🏗 Architecture Sketch

The application is structured using **Clean Architecture + MVVM**, ensuring dependencies flow strictly inward.

* **Presentation Layer:** Contains declarative SwiftUI Views and `@Observable` ViewModels. ViewModels are completely decoupled from data-fetching implementations.


* **Domain Layer:** Contains pure Swift business logic (`Profile`, `MatchStatus`, Use Cases). This layer has absolute zero knowledge of SwiftUI, SwiftData, or `URLSession`.


* **Data Layer:** Handles network requests via DTOs and `URLSession`, as well as persistence via SwiftData and `@Model`. The `ProfileRepositoryImpl` orchestrates the single source of truth, managing merging, deduplication, and offline fallbacks.


* **Dependency Injection:** Dependencies are injected using the **Composition Root** pattern via an `AppComposition` enum at the `@main` app entry point. Every dependency relies on protocols, making testing trivial without third-party mocking frameworks.



## 💾 Database Choice: SwiftData vs. Core Data

**SwiftData** was chosen over Core Data for this project for several modern architectural reasons:

* **Native Integration:** It is designed specifically for Swift, eliminating the heavy `NSManagedObject` and `NSFetchedResultsController` boilerplate.


* **Type Safety & Macros:** The `@Model` macro drastically simplifies mapping our pure Domain models to persistence entities without generating XML `.xcdatamodeld` files.


* **Concurrency:** SwiftData integrates natively with modern Swift Concurrency (`async/await`), keeping background pagination merges smooth and thread-safe.



## 🔄 Pagination & Status Synchronization

### How Pagination Works

Pagination is handled via an infinite scroll mechanism. A `.task` modifier attached to the list items triggers the `MatchListViewModel` to fetch the next page when the user scrolls near the bottom.

* **Offline Handling:** If the user is offline, the repository checks the local cache. If the user attempts to scroll past the locally saved data, it gracefully throws a `.offlineNoMoreData` error.


* **Cold Start Empty State:** If the app is launched fully offline with an empty cache, it intercepts the state and presents a dedicated full-screen "Offline" view with a manual "Try Again" mechanism leveraging `URLSession`'s natural network restoration.

### How Status Sync Works

A strict requirement of this app is that the list and detail views must never disagree on a profile's match status.

1. When a status is mutated (via the detail view buttons), the ViewModel optimistically updates the UI and commands the Domain Use Case to persist the change.


2. The Repository saves the change directly into SwiftData's local container.


3. When the user navigates back, the `MatchListView` utilizes an `.onAppear` modifier to silently trigger `refreshFromCache()`.


4. Because both screens read from the exact same local database, state drift is impossible, and the UI remains perfectly synced without messy `NotificationCenter` event-bridging.



## 🖼 Offline Image Caching

The assignment strictly mandates that the app must show cached profiles and function offline after an app termination/relaunch.

While native iOS provides `AsyncImage`, it does not persistently cache images to disk out-of-the-box; it relies on standard `URLCache` session memory, which the OS frequently evicts upon app termination. To satisfy the explicit requirement for robust offline survivability, the lightweight **Kingfisher** (`KFImage`) library was integrated. This ensures profile pictures are immediately cached to the physical disk, guaranteeing a 100% offline-capable experience.

## ⚠️ Known Gaps & Future Improvements

* **Hardcoded Networking Details:** The base API URL, the `matchmate` seed, and the pagination limit (`resultsPerPage = 10`) are currently hardcoded inside `ProfileRepositoryImpl`. In a larger production app, these would be injected via an `AppConfiguration` environment file.


* **Background Context Optimization:** While the app is thoroughly isolated to the `@MainActor` to strictly comply with Swift 6 concurrency safety, massive pagination background writes (e.g., hundreds of profiles) could theoretically cause frame drops on older devices. Moving the heavy upsert operations to a detached `ModelActor` would optimize this further.
