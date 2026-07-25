# Essential English Words

A Flutter client for learning English vocabulary from the *Essential English Words* book
series — browse books and units, build a personal vocabulary list, search the whole corpus,
and drill words with a configurable quiz engine.

The app is a native (Android/iOS/Web) port of an existing React frontend. It talks to the
**unchanged** Node/Express REST backend, reuses the web app's translation bundles verbatim,
and reproduces its design tokens, so both clients stay visually and behaviourally in sync.

---

## Table of contents

- [Features](#features)
- [Architecture](#architecture)
- [Project layout](#project-layout)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Backend contract](#backend-contract)
- [Internationalization](#internationalization)
- [Theming](#theming)
- [Admin mode](#admin-mode)
- [Quality gates](#quality-gates)
- [Building releases](#building-releases)
- [Android networking](#android-networking)
- [Troubleshooting](#troubleshooting)

---

## Features

| Area | Description |
| --- | --- |
| **Library** | Books grid → unit tabs → paginated word list. |
| **Vocabulary** | A personal, user-owned book; new words are auto-assigned to a unit by the backend. |
| **Search** | Global paginated search, with book/unit provenance on every hit. |
| **Quiz** | Two modes (`topic`, `general`), two levels (`easy` multiple-choice, `hard` free-text), three general-mode scopes (`all`, `half`, `full`), switchable direction (UZ↔EN), IPA transcriptions, streak/tier cheers, and a result screen listing the missed words. |
| **Admin** | Password login, word create/edit/delete, drag-to-reorder within a unit, transcription backfill. |
| **i18n** | Uzbek, English, Russian — the same JSON bundles the web app ships. |
| **Theming** | Light/dark, driven by design tokens ported from the web Tailwind theme. |

Language, theme, and the admin token persist via `shared_preferences` — this app's
equivalent of the web client's `localStorage`.

---

## Architecture

```
UI        screens / components / widgets     Flutter + Material
   │      watch / read
State     Riverpod providers                 lib/state
   │
Domain    quiz scoring, DTOs                 lib/core/quiz_logic.dart, lib/models
   │
API       typed endpoint functions           lib/api/api.dart
   │
Transport Dio + interceptors                 lib/core/api_client.dart
   │
Backend   REST, { success, data | error } envelope
```

Key decisions:

- **Riverpod over a service locator.** The `FutureProvider`s in `lib/state/data.dart` mirror
  the web app's TanStack Query keys one-to-one and are intentionally *not* `autoDispose`, so
  results cache across navigation. Mutations call `ref.invalidate(...)`, matching the web
  client's `queryClient.invalidateQueries` behaviour.
- **One envelope-unwrapping transport.** `ApiClient` unwraps `{ success, data }`, converts
  any failure into an `ApiException` carrying the backend's already-localized message, and
  lets the UI render `e.message` directly — no per-call error plumbing.
- **`Session` as a synchronous bridge.** Dio interceptors must read the auth token and UI
  language on every request, but an interceptor has no access to a Riverpod container.
  `Session` is a small mutable singleton the notifiers keep in sync; the error interceptor
  also fans a `401` back out so `AuthController` can drop a stale token.
- **Typed endpoints, hand-written models.** No code generation: each endpoint in
  `lib/api/api.dart` is a single function returning a typed model, so the API surface stays
  greppable and the build has no codegen step.
- **Pure quiz logic.** Scoring, streaks, and cheer tiers live in `lib/core/quiz_logic.dart`
  with no Flutter imports — a direct port of the web app's `lib/quiz.ts`, testable without a
  widget harness.
- **Declarative routing.** `go_router` with a single `ShellRoute`, so the header/nav shell is
  built once and screens swap beneath it. Quiz configuration is held as an immutable
  in-memory snapshot rather than deep-linked query state.

### Dependencies

| Package | Role |
| --- | --- |
| `flutter_riverpod` | State management and async data caching |
| `dio` | HTTP client with request/error interceptors |
| `go_router` | Declarative, URL-based navigation |
| `shared_preferences` | Persisting language, theme, admin token |
| `flutter_launcher_icons`, `flutter_native_splash` | Native icon/splash generation (dev-only) |

---

## Project layout

```
lib/
├── main.dart                 # Bootstrap: prefs → i18n load → ProviderScope
├── router.dart               # go_router config (ShellRoute + 5 routes)
├── api/api.dart              # Typed endpoint functions
├── core/
│   ├── api_client.dart       # Dio wrapper, envelope unwrapping, ApiException
│   ├── config.dart           # kApiUrl / apiRoot (compile-time --dart-define)
│   ├── session.dart          # Sync token + language holder for interceptors
│   └── quiz_logic.dart       # Pure scoring, streaks, cheer tiers
├── i18n/i18n.dart            # Dotted-key lookup + {{param}} interpolation
├── models/                   # Book, Word, Quiz DTOs (hand-written fromJson)
├── state/
│   ├── app_state.dart        # locale / theme / auth controllers, ref.tr()
│   └── data.dart             # FutureProviders + invalidateWords()
└── ui/
    ├── app_shell.dart        # Persistent header/nav shell
    ├── theme.dart            # AppColors ThemeExtension (ported tokens)
    ├── screens/              # home, book, search, vocabulary, test/
    ├── components/           # books_grid, unit_tabs, words_table, word_form, …
    └── widgets/              # loader, confirm_dialog, shared primitives

assets/i18n/{uz,en,ru}.json   # Shared verbatim with the web app
test/widget_test.dart         # Mount smoke test (booksProvider overridden)
```

---

## Getting started

### Prerequisites

- Flutter **3.27+** / Dart **3.6+** (the theme uses `Color.withValues`). Verified on
  Flutter 3.44.6 stable.
- Android SDK (API 21+) and/or Xcode for the respective targets.
- A reachable backend — the deployed instance or a local Node/Express run.

The native `android/`, `ios/`, and `web/` folders are committed; no `flutter create .` step
is needed.

### Run

```bash
flutter pub get
flutter run                                  # uses the production backend by default
```

Point it at a local backend instead:

```bash
# Android emulator — 10.0.2.2 is the host machine's loopback as seen from the emulator
flutter run --dart-define=API_URL=http://10.0.2.2:3007

# iOS simulator — reaches the host's localhost directly
flutter run --dart-define=API_URL=http://localhost:3007
```

### Regenerating icons and splash

Only needed after changing `assets/icon/` or `assets/splash/`; both write into the
committed native folders:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Configuration

The only build-time knob is the backend base URL, read in `lib/core/config.dart`:

| Key | Default | Notes |
| --- | --- | --- |
| `API_URL` | `https://word-learner-qbx2.vercel.app` | A trailing slash is stripped by `apiRoot`. |

It is a `String.fromEnvironment` constant, baked in at compile time, so it must be passed to
*every* command that produces a binary:

```bash
flutter run   --dart-define=API_URL=…
flutter build --dart-define=API_URL=…
flutter test  --dart-define=API_URL=…
```

> The default deliberately points at the deployed backend. A release APK runs on a real
> device, where `10.0.2.2` and `localhost` resolve to nothing — defaulting to the emulator
> address would ship a build that silently fails every request.

---

## Backend contract

Every response is wrapped in `{ "success": true, "data": … }` or
`{ "success": false, "error": "<localized message>" }`. Every request carries
`Accept-Language: <uz|en|ru>`; admin requests add `Authorization: Bearer <token>`. Any `401`
clears the stored token and returns the app to read-only mode.

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/auth/login` | Exchange the admin password for a token |
| `GET` | `/books` | Book list with unit/word counts |
| `GET` | `/books/:id` | One book with its units |
| `GET` | `/vocabulary` | The personal vocabulary book |
| `POST` | `/vocabulary/words` | Add a word (the backend picks the unit) |
| `GET` | `/units/:id/words` | Paginated words (`page`, `pageSize`) |
| `POST` | `/units/:id/words` | Create a word *(admin)* |
| `PUT` | `/units/:id/words/order` | Reorder a unit via `orderedIds` *(admin)* |
| `PUT` | `/words/:id` | Update a word *(admin)* |
| `DELETE` | `/words/:id` | Delete a word *(admin)* |
| `GET` | `/words/search` | Global search (`q`, `page`, `pageSize`) |
| `GET` | `/words/quiz` | Questions + IPA map (`unitId` \| `fromUnitId`/`toUnitId`, `count`, `direction`, `level`) |
| `POST` | `/words/backfill-transcriptions` | Fill missing IPA transcriptions *(admin)* |

Null query parameters are stripped before the request is sent, so optional quiz filters can
be passed unconditionally.

---

## Internationalization

`I18nStore` loads all three JSON bundles at startup and resolves dotted keys with
`{{param}}` interpolation — the contract `i18next` provided on the web, minus pluralization
(unused by the source strings). A missing key falls back to Uzbek, then to the raw key.

Two accessors are exposed as a `WidgetRef` extension, and choosing the wrong one is the most
common mistake in this codebase:

```dart
Text(ref.tr('test.topic'));            // reactive — inside build(); rebuilds on language change
onPressed: () => ref.trs('test.topic') // non-reactive — inside callbacks and async code
```

`ref.tr` calls `watch`, which throws outside `build`. Use `ref.trs` everywhere else.

To add a string, add the key to **all three** files in `assets/i18n/`. They are asset
bundles, so picking up edits requires a hot restart, not a hot reload.

---

## Theming

`lib/ui/theme.dart` defines `AppColors`, a `ThemeExtension` whose light and dark palettes are
the web app's Tailwind `oklch` tokens converted to sRGB. Widgets read them via `context.c`
rather than `Theme.of(context).colorScheme`, which keeps both clients on one source of truth
for colour. `ThemeController` persists the choice and defaults to light.

---

## Admin mode

Admin affordances are gated on `isAdminProvider`, derived from the presence of a stored
token. Logging in (header → lock icon) enables inline editing, deletion, drag handles in the
words table, and the transcription backfill action.

This is presentation-level gating only: the backend validates every mutating request, and a
`401` reverts the client to read-only automatically.

---

## Quality gates

```bash
flutter analyze     # must be clean before any build
flutter test
```

Both currently pass:

```
Analyzing ess-words-flutter...
No issues found! (ran in 1.8s)

00:00 +1: All tests passed!
```

Lints come from `flutter_lints` plus `prefer_const_constructors` (see
`analysis_options.yaml`). Test coverage is currently one mount smoke test that overrides
`booksProvider` so no HTTP fires; `lib/core/quiz_logic.dart` is pure and is the natural next
target for unit tests.

---

## Building releases

```bash
flutter build apk --release       --dart-define=API_URL=https://word-learner-qbx2.vercel.app
flutter build appbundle --release --dart-define=API_URL=https://word-learner-qbx2.vercel.app
flutter build ipa --release       --dart-define=API_URL=https://word-learner-qbx2.vercel.app
flutter build web --release       --dart-define=API_URL=https://word-learner-qbx2.vercel.app
```

Two items to settle before public distribution: `android/app/build.gradle.kts` still signs
release builds with the debug config, and `applicationId` is still the scaffold default
`com.example.ess_words`.

---

## Android networking

`android/app/src/main/AndroidManifest.xml` declares `INTERNET` explicitly (Flutter adds it
only to the debug/profile manifests) and sets `android:usesCleartextTraffic="true"` so a
plain-HTTP local backend works.

For production, prefer scoping cleartext to dev hosts rather than allowing it globally.
Replace the attribute with `android:networkSecurityConfig="@xml/network_security_config"`
and add:

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
  <domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">10.0.2.2</domain>
    <domain includeSubdomains="true">localhost</domain>
  </domain-config>
</network-security-config>
```

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Every screen shows a network error | `API_URL` is unreachable from this target. Emulator → `10.0.2.2`, simulator → `localhost`, real device → a deployed HTTPS URL. |
| APK works on the emulator but not on a phone | The build baked in a loopback `API_URL`. Rebuild with the deployed URL. |
| `CLEARTEXT communication not permitted` | HTTP backend without the manifest flag or a network security config — see [Android networking](#android-networking). |
| Translations don't change after editing JSON | Assets are bundled at startup — hot **restart**, not hot reload. |
| `Bad state: … watch … outside build` | `ref.tr` used in a callback. Use `ref.trs`. |
| Admin controls disappear mid-session | The backend returned `401` and the token was cleared. Log in again. |
