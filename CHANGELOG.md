# Changelog

## Unreleased

- iOS app project added (`ios/`): the same page in a WKWebView, with the camera and photo library for attachments, the share sheet for saving PDF and CSV files, a swipe in from the left edge as Back, and a second copy of your records kept in the app's own storage. See the README for how to build it.

## 2.3.1.1

- "Work order" is now "Task" everywhere you see it: the tab, the + menu (Create new task), buttons, messages, the PDF and the CSV export. Task numbers still start with WO-, so existing numbers do not change.
- The PDF report is only available once at least one task is completed. Completed tasks also get a PDF report button of their own, which opens the report for that task's asset.

## 2.3.0.1

- One + button in the header, next to the settings gear. It opens a small menu: Add new asset or New work order.
- The Add new asset button on the Assets tab and the round + button at the bottom right are gone.

## 2.2.0.1

- Nothing is required any more when adding an asset, except a name or brand to call it by (and the parent, for an accessory).
- Photos are now Attachments: add as many as you like (up to 8), each with its own caption such as "Number plate" or "Car card". Existing photos move over with captions.
- Vehicles: make and model share one field, and the notes and meter fields are gone.

## 2.1.0.1

- Adding a vehicle now needs brand, make, model, colour, number plate, VIN, a photo of the plate and a photo of the car card. A photo of the car is optional.
- Other assets (AC, TV, console and so on) need a brand, model number and serial number, and can have up to four pictures.
- Parent and child assets: mark the main machine as the parent, and accessories such as a UPS as children of it.
- Work order numbers now start with a letter from the parent machine: WO-V-2026-0001 vehicle, C climate (air conditioner), E entertainment (TV, radio, console) and electrical, G everything else. Each letter counts up on its own. Older numbers are unchanged.
- The asset sheet now says "Add new asset" and the small "Asset" label above it is gone.
- In the phone app, adding a picture offers the camera as well as the gallery.

## 2.0.0.1

- New name: I Got This. It shows under the icon, in the header and on the PDF report.
- New app icon: a blue wrench with a green tick badge on a light tile.

## 2.0.0.0

Redesign. Same records, same numbering, a cleaner look.

- Slim header: logo, title and the settings gear. New work order is now a round + button at the bottom right on phones (the header buttons stay on wide screens).
- PDF report moved into Settings on phones.
- Dashboard: Spent is a large card; Open, Overdue and Assets sit in a small row. Overdue only turns red when something is late.
- Work orders: one search bar with a Filters button, and quick chips for Active, Open, In progress, Done and All. Asset and year filters are under Filters.
- Rows are soft cards with an icon for the asset type, a status dot and the amount.
- Rounder cards and buttons, press feedback, and a small illustration on empty screens.

## 1.0.0.5

- Fix: the top of the app was drawn under the camera and status bar. The page now sits inside a wrapper that carries the padding, because the web view ignores its own padding.

## 1.0.0.4

- Header sits lower again so the full title is clear of the camera.

## 1.0.0.3

- Update inside the app: when a newer release exists, Settings shows Download and install. The app downloads the APK, shows progress, and opens Android's installer. The first time, Android asks you to allow installs from this app.
- Needs the release list to be readable (public repository), and the APK attached to the release.

## 1.0.0.2

- Header sits about 0.5 cm lower so the camera cutout no longer covers it.

## 1.0.0.1

- Settings gear in the header. Settings now opens with the installed version and the update address.
- Check for updates: compares the installed version with the latest GitHub release and offers the APK download when a newer one exists. If the release list cannot be read (no release yet, or the repository is private) it says so and offers the releases page instead.
- Layouts for the Galaxy Z Fold 7: narrow cover screen, near-square inner screen and the sizes in between. Work order rows adapt to the width of their list, the dashboard goes to two columns only on wide screens, and the app does not restart when the phone is folded or unfolded.
- Stat figures on the dashboard scale to their box, so amounts no longer wrap.
- Dialogs no longer replay their opening animation every time their content changes.

## 1.0.0.0

- First version: assets, numbered work orders (WO-YYYY-NNNN), parts, labour and costs, dashboard, parts list, CSV and JSON export, restore from backup, PDF report, Android wrapper.
