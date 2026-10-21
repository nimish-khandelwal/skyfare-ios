# SkyFare

[![CI](https://github.com/nimish-khandelwal/skyfare-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/nimish-khandelwal/skyfare-ios/actions/workflows/ci.yml)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)
![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![Coverage](https://img.shields.io/badge/coverage-94%25-success.svg)

A flight booking app for iOS. Search a route, compare flights, sort and filter them —
built the way a real airline app works, in Swift 6 and SwiftUI.

| Search | Autocomplete | Travellers | Results | Filters |
| --- | --- | --- | --- | --- |
| ![](docs/screenshots/01-search.png) | ![](docs/screenshots/02-autocomplete.png) | ![](docs/screenshots/03-travellers.png) | ![](docs/screenshots/04-results.png) | ![](docs/screenshots/05-filters.png) |

## Try it

```bash
git clone https://github.com/nimish-khandelwal/skyfare-ios.git
cd skyfare-ios
brew install xcodegen && xcodegen generate
open SkyFare.xcodeproj
```

Hit run. It works straight away — no API key, no signup.

## What works

- Airport search that waits until you stop typing before hitting the network
- One-way and round trip, cabin class, traveller counts with the real airline rules
  (an infant can't fly without an adult, nine seats max)
- Results you can sort by price, duration or departure time
- Filters for stops, airline, departure window and whether a checked bag is included
- 144 tests, 94% coverage, no compiler warnings
- CI on every push

## What's next

Fare families · seat map in UIKit · passenger details · baggage and meals ·
payment · offline trips · push notifications · deep links · Arabic with RTL

## A note on the data

I started this on the Amadeus Self-Service API. Amadeus shut that free tier down in
July 2026, a few months in, so I moved the app over to [Duffel](https://duffel.com).

That turned out to be the useful part. Swapping provider meant rewriting three files
and deleting a fourth — nothing in the UI, the view models or the domain models knows
or cares where a flight comes from. The migration is in the git history if you want to
see the diff.

Without a token the app runs on bundled sample flights, which is how the screenshots
above were taken. To use real data, grab a free test token at
[app.duffel.com/join](https://app.duffel.com/join) (no card needed) and drop it in:

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# paste your duffel_test_... token into the new file
```

That file is git-ignored. Duffel's test mode returns a fictional airline rather than
real schedules, which is fine — it exercises the same code path.

The app only accepts a `duffel_test_` token. Hand it a live one and it ignores it and
stays on sample data, so there is no way for this project to reach real inventory or
run up a bill. There's a test that holds that guarantee in place.

## How it's built

MVVM, with a coordinator owning navigation and repositories behind protocols so
everything can be tested without a network.

A few decisions worth explaining:

**View models are `@MainActor`, everything below them is `Sendable`.** The UI is
single-threaded by construction, the rest is concurrency-safe by contract. The whole
project compiles under Swift 6 strict concurrency with zero warnings.

**Combine only where it earns its place.** Airport autocomplete is a debounce pipeline,
so typing "dubai" fires one request instead of five. Form validation is a second
pipeline feeding `canSearch`. Everything below the view model is plain async/await.

**The API payload and the app's own models are separate types.** Flight APIs return
awkward JSON — prices as strings, durations as `PT03H05M`, local departure times with
no timezone, baggage buried per passenger per segment. A mapper absorbs all of that in
one place, so the rest of the app stays clean. It's also what made changing provider a
one-afternoon job instead of a rewrite.

**Validation lives in a plain struct** with no Combine or UIKit in it, which makes the
rules easy to test directly.

## Tests

```bash
bundle install
bundle exec fastlane test
```

137 unit tests and 7 UI tests. The unit tests run against recorded API responses, so
they're fast and don't need a network. The UI tests drive the real app and also capture
the screenshots above.

## Notes

Xcode 27 locally, Xcode 16.4 on CI, so it's verified on two toolchains. The `.xcodeproj`
is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen) and
isn't committed — no merge conflicts in project files.

A personal learning project, not affiliated with any airline.
