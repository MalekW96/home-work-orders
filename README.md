# I Got This (home work orders)

A personal maintenance log for the house and the car. Every job is a numbered work order (`WO-2026-0001`, `WO-2026-0002`, ...) opened against an asset, with parts, labour and costs recorded on it.

The app is a single self-contained page, `home-work-orders.html`, published as a Claude artifact. Records live in the artifact's own database, not in this repo.

## What it does

- Assets: car, rooms, appliances, anything you maintain. Optional meter (km, mi or hours).
- Work orders: type, priority, status (Open, In progress, Completed, Cancelled), opened, due and completed dates, reading, who did the work, notes.
- Cost lines per order: parts (with part number and supplier), labour, other.
- Dashboard: open and overdue jobs, spend by asset, cost split.
- Parts & costs: every part used, searchable.
- Exports: work orders and cost lines as CSV, full backup as JSON (Settings).
- PDF report: period and asset choice, optional parts list. Built in the page with jsPDF.

## Numbering

A new work order takes the next number for the current year. The page takes a short lease on `meta/numbering`, reads the highest `seq` for that year, and writes `workorders/WO-<year>-<seq>`. Work orders cannot be deleted, only cancelled, so numbers are never reused.

## Data model

Collections in the artifact database:

| Path | Fields |
|---|---|
| `assets/{id}` | name, category, details, meterUnit (`""`, `km`, `mi`, `h`), notes, archived, createdAt, updatedAt |
| `workorders/{number}` | number, year, seq, title, assetId, type, priority, status, openedOn, dueOn, completedOn, meter, doneBy, description, notes, lines[], followUpOf, createdAt, updatedAt |
| `meta/settings` | currency (ISO code, default `SAR`) |
| `meta/numbering` | lease document used while a number is issued |

Each entry in `lines` is `{kind: part | labour | other, name, partNo, supplier, qty, unitCost}`. Dates are `YYYY-MM-DD` strings. Records created as examples carry `sample: true`.

## Publishing an update

1. Edit `home-work-orders.html`.
2. Republish it to the same artifact so the URL and the stored records are kept. In Claude: "update my Home Work Orders artifact from home-work-orders.html".
3. Keep the declared capabilities: `db`, `user`, `downloads`.

## Android app (APK)

`android/` is an Android Studio project that wraps the same page in a WebView. Records are stored on the phone only; the web version and the app do not sync. Move records between them with Settings > Full backup, then Settings > Restore from a backup.

Build it:

1. Open the `android/` folder in Android Studio and let Gradle sync (it downloads Gradle 8.9 and the Android Gradle Plugin 8.7.3; accept an upgrade prompt if offered).
2. Build > Build Bundle(s) / APK(s) > Build APK(s). The APK ends up in `android/app/build/outputs/apk/debug/`.
3. Copy it to the phone and install it. Android 10 or newer is required.

## Web app (Add to Home Screen)

`docs/` is an installable web version of the page, served by GitHub Pages at https://malekw96.github.io/home-work-orders/. On an iPhone open it in Safari, tap Share, then Add to Home Screen. Android Chrome: menu, Install app. It runs full screen, works offline after the first visit and updates itself when you open it online. Records stay on that device (IndexedDB) and are not synced with the other versions; use Settings > Full backup and Restore to move them. PDF and CSV files open the share sheet on iPhone.

`docs/` is generated: run `scripts/sync-web.sh` after changing the page, then commit and push.

## iPhone / iPad app

`ios/` is the same page in a WKWebView (Swift, iOS 15 or newer). Like the Android app, records stay on the device and are not synced with the web version; use Settings > Full backup and Restore to move them.

What differs from Android:

- PDF and CSV files open the iOS share sheet (Save to Files, AirDrop, Mail) instead of going straight to Downloads.
- Swiping in from the left edge works as Back.
- There is no in-app updater; Apple does not allow it. A new version is a new build you install over the old one.
- A second copy of the records is kept in the app's own storage and put back if iOS ever clears the web view's storage.

Building needs a Mac with Xcode, or the GitHub Actions workflow `iOS build` (Actions tab > iOS build > Run workflow), which compiles the app on a Mac runner and produces an unsigned `IGotThis-unsigned.ipa`. Sideloadly or AltStore (both run on Windows) can sign that with your own Apple ID and install it on an iPhone; a free Apple ID's signature lasts 7 days, a paid Apple Developer account's a year, and TestFlight or the App Store needs the paid account.

On a Mac: `brew install xcodegen`, then `cd ios && xcodegen generate && open IGotThis.xcodeproj`, pick your team under Signing & Capabilities and run.

`scripts/sync-web.sh` copies the page into `ios/IGotThis/Web/` as well, and checks that `MARKETING_VERSION` (first three parts of `APP_VERSION`) and `CURRENT_PROJECT_VERSION` (the fourth) in `ios/project.yml` match it.

## Versions and updates

The version lives in two places that must match: `APP_VERSION` in `home-work-orders.html` and `versionName` in `android/app/build.gradle.kts`. Raise `versionCode` by one for every new APK, otherwise Android refuses to install it over the old one.

To release a new version:

1. Change the page, then bump `APP_VERSION`, `versionName` and `versionCode`.
2. Run `scripts/sync-web.sh`. It checks that the two version numbers match and copies the page to `android/app/src/main/assets/index.html`.
3. Rebuild the APK in Android Studio, then create a GitHub release for the new version and attach the APK.

On the phone, Settings > About shows the installed version, and "Check for updates" opens this repo's Releases page. If the newest version there is higher, download its APK and install it over the old one. Records are kept as long as the new APK is signed with the same key, which Android Studio's debug key is on the same computer.

## Notes

- Libraries are loaded from cdnjs at pinned versions: jsPDF 2.5.1 and jspdf-autotable 3.8.2.
- The PDF uses built-in fonts, so text outside the Latin alphabet (for example Arabic) shows as `?` in the report. The app itself displays it fine.
- Dark and light themes follow the viewer's setting.

## Ideas for later

- Reminders that trigger on date or mileage.
- Restore from a JSON backup.
- Photos or receipts attached to a work order.
