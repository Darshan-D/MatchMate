# MatchMate — Post-Mortem Review

Analysis of the submitted solution against the take-home brief (`iOS Technical Assignment.pdf`),
written to understand why the submission was not selected and how to get closer to what was asked.

## TL;DR

The app almost certainly **works** and passes most of the "quick checklist." The rejection was
not about missing features — it was about the signals the rubric weights: *how* status sync was
solved, whether the engineering matched the stated scope, framework fluency (SwiftData), and
concurrency. The fixes below are the same scope built the way the framework wants, with depth
concentrated on the two categories worth 50% of the grade.

## Grading rubric (from the PDF)

| Area | Weight |
|---|---|
| Architecture / boundaries | 25% |
| Offline + DB + status across list & detail | 25% |
| Pagination + list/detail UX | 15% |
| Code quality | 15% |
| Unit tests | 15% |
| README & commit history | 5% |

---

## 1. Biggest issue: fought SwiftData instead of using it

The "Important — status must stay consistent everywhere" section is 25% of the grade and is the
heart of the assignment. SwiftData provides this for free; the submission opted out.

**What the submission does:**
- List and Detail each get their own `ProfileRepositoryImpl` + `SwiftDataLocalDataSource`.
- They only share the underlying `mainContext`.
- Sync happens because `MatchListView`'s inner `ScrollView` has
  `.onAppear { Task { await viewModel.refreshFromCache() } }`, which re-reads the whole table
  and diffs it (`if self.profiles != cached`).

**What was likely expected:**
```swift
// MatchListView
@Query(sort: \ProfileEntity.sortIndex) private var profiles: [ProfileEntity]

// MatchDetailView
@Query private var matches: [ProfileEntity]   // filtered by id
```
With `@Query`, a write on detail propagates to the list instantly and automatically — even with
both visible on iPad — no `.onAppear`, no diffing, no "known gap."

The README itself documents the self-inflicted weakness:
> No live/reactive sync — List and Detail wouldn't self-correct if both were visible at once…
> since sync relies on `.onAppear`, not a live binding.

Documenting a self-inflicted gap does not neutralize it when the chosen framework eliminates it.

**Clean-architecture counter-argument** (expected to be addressed): `@Query` in the View couples
the View to SwiftData. The mature answer is a repository exposing an `AsyncStream<[Profile]>` /
publisher backed by a `@ModelActor` or a fetch-results observer, so the ViewModel stays testable
*and* sync is live.

---

## 2. Over-engineering vs. "keep the scope tight"

The PDF says it three times: "We're not looking for a huge app," "Keep the scope tight,"
"code you'd be comfortable putting up for review on a real team."

- **5 use-case files**, each ~10 lines, each a pure pass-through
  (`DefaultFetchProfilesUseCase.execute(page:)` → `repository.loadPage(page)`). Zero logic.
- Triple model mapping: `ProfileDTO` → `Profile` → `ProfileEntity` → `Profile`, with a `+Mapping`
  file per direction.
- Protocols on every type: both data sources, the repository, and all 5 use cases.
- `AppComposition` rebuilds the whole graph (`remote`, `local`, `repo`) separately for the list VM
  and for *every* detail VM.

For a two-screen app, MVVM + a repository protocol + a SwiftData store is enough. On a real PR
someone would ask to delete the use-case layer. This is shop-dependent (some teams like a
use-case layer), but combined with the scope instructions it reads as poor calibration.

If a use-case layer is kept, it must earn its place — e.g. a `LoadNextPageUseCase` that owns the
resume-page logic, page increment, and offline-fallback decision currently scattered across the
ViewModel and repository.

---

## 3. Concurrency: everything is on the main thread

`@MainActor` is on `RandomUserRemoteDataSource`, `ProfileRepositoryImpl`,
`SwiftDataLocalDataSource`, every use case, and both ViewModels.

Consequences:
- `URLSession.data(from:)` **and `JSONDecoder().decode`** run on the main actor.
- Every SwiftData `fetch`/`save` blocks the main thread.

README acknowledges it:
> Everything is pinned to `@MainActor`… A dedicated `ModelActor` for writes would fix this.

Fixes:
- Remote data source: drop `@MainActor`; decode off-main (already `async`).
- SwiftData writes: a `@ModelActor` actor owning its own `ModelContext`.
- ViewModels stay `@MainActor` (correct); repository bridges.

---

## 4. Network / connectivity handling is thin (rubric names it explicitly)

Rubric: "Error handling for API calls, database operations, **and network connectivity**."

1. **HTTP status codes ignored.** `let (data, _) = try await session.data(from: url)` discards
   the response. Random User **rate-limits (HTTP 429)** and returns HTML. Code then hits
   `JSONDecoder`, throws `.decoding`, and `ProfileRepositoryImpl` does **not** offline-fallback on
   `.decoding` — so a rate-limited user with a full cache gets an error banner instead of cache.
   Need `(response as? HTTPURLResponse)?.statusCode` handling and explicit non-2xx mapping.
2. **No `NWPathMonitor`.** Every offline action eats a ~60s URLSession timeout before falling back.
   Listed as a known gap, but "network connectivity" is a named grading line. Inject a
   `NetworkMonitor` into the repository: skip the request when offline, drive the empty-state /
   banner reactively.
3. **`ISO8601DateFormatter` fallback to `Date()`** on parse failure silently writes wrong data
   (today's date) into the DB. Surface it or use a lenient decoding strategy.

---

## 5. Smaller correctness / data-handling issues

| Issue | Detail |
|---|---|
| **List uses `picture.large` for a 140×140 thumbnail** | PDF explicitly calls out `picture.large / medium`. `MatchCardView` and `MatchDetailView` both bind `profile.largePhotoURL`. List should use `thumbnailURL` (medium). Both URLs are stored; neither used correctly. |
| **List order not stable / doesn't match API** | `fetchAll()` sorts by `SortDescriptor(\.pageFetched)` only. Rows within a page have no secondary key, so order is undefined and can reshuffle between reads. Persist a `sortIndex` (page × pageSize + positionInPage). |
| **Once cached, the app never refreshes** | `loadInitial()` takes the `cached` branch whenever the DB is non-empty and never touches the network again for those pages. No pull-to-refresh. `upsert` never overwrites `status` and is never called for already-fetched pages. App is append-only after first run. Add `.refreshable`. |
| **Detail screen swallows errors** | `MatchDetailViewModel.error` is set on failure but `MatchDetailView` never renders it — no banner. A failed Accept on detail silently rolls back. Inconsistent with the list. |
| **Nested buttons inside `NavigationLink`** | The whole card (including Accept/Decline) is the `NavigationLink` label. Tap-target conflict between the buttons and the push is a known SwiftUI footgun — verify list-card actions fire reliably and don't also navigate. |
| **`@State var viewModel` in detail vs `@Bindable` in list** | Inconsistent `@Observable` ownership. `navigationDestination`'s closure can re-run; `@State` pins the first instance. Pick one pattern. |
| **No accessibility labels** | Icon-only buttons (`xmark`, `heart.fill`) have no `.accessibilityLabel`. |
| **`print()` logging with emoji everywhere** | Production code, every file. Use `os.Logger` / `OSLog` with categories. |

---

## 6. Tests (15%) — coverage is in the wrong place

- **`ProfileRepositoryImpl` has zero tests** — it holds the most complex, most bug-prone logic:
  network-first, offline fallback, the `page * resultsPerPage` heuristic in
  `handleOfflineFallback`, error mapping.
- **`MockProfileRepository` doesn't mirror the real implementation.** Its `cachedProfiles()` sorts
  by `firstName`; the real one sorts by `pageFetched`. Its `loadPage` offline branch has dead code
  (`if page > 1 && storage.isEmpty` right after a check that already returns when
  `storage.isEmpty`). Green tests don't exercise real ordering/pagination behavior.
- No test that pagination triggers **only** on the last item; none for the re-entrancy guard, the
  resume-page boundary, or `refreshFromCache` diffing.
- The list↔detail sync — the thing the assignment cares most about — is **untestable** in this
  design because it depends on `.onAppear`. That untestability is itself the tell. With a
  repository publisher: "detail calls `updateStatus`, assert the list VM's `profiles` reflects it"
  with no view involved.

---

## 7. README & commit history (5%)

The README is genuinely good — architecture sketch, DB rationale, pagination explanation, honest
"Known Gaps." Commit history is a reasonable incremental story (12 commits), though "fixed some
bugs" is vague.

**Real risk:** the paragraph foregrounding heavy multi-LLM reliance on free tiers and framing the
hours estimate around rate limits. Most teams are fine with AI assistance; few want a submission
that reads as low ownership of the code. It also primes a reviewer to scrutinize everything else
harder. Cut it — state hours, state what you'd do with more time.

---

## 8. Rebuild checklist to hit the brief

1. **Reactive sync via SwiftData.** Repository exposes an observed stream of `[Profile]`
   (ModelActor + change notifications, or `@Query` in the view with a documented trade-off).
   Delete `refreshFromCache` and every `.onAppear` sync hook. List↔detail consistency becomes
   structural, not best-effort.
2. **Collapse the layers.** ViewModel → `ProfileRepository` (protocol) → SwiftData store + API
   client. Drop the 5 pass-through use cases, or fold real logic into 1–2.
3. **Get off the main thread.** `@ModelActor` for persistence; decode off-main.
4. **`NetworkMonitor` (NWPathMonitor)** injected into the repository. Drives offline empty-state
   and banner reactively; short-circuits requests when offline.
5. **Real HTTP handling.** Check status codes; map 429/5xx; fall back to cache on any fetch
   failure when a cache exists.
6. **Persist a `sortIndex`** so list order matches the API and is stable.
7. **`medium` image in the list, `large` in detail.** Consider dropping Kingfisher for `URLCache`
   with disk capacity + `AsyncImage` (fewer deps in a small take-home), or keep it — the README
   reason is defensible.
8. **Error banner on detail too.** `.refreshable` on the list.
9. **Tests where the risk is:** repository offline-fallback matrix, pagination edge cases, and a
   sync test (`updateStatus` on one path → observed on the other). Make the mock behave like the
   real thing.
10. **`os.Logger`**, accessibility labels, resolve the NavigationLink/button nesting.

None of this is a bigger app — it is the same scope, built the way the framework wants, with the
depth on the two things worth 50% of the grade (boundaries; offline + DB + sync).
