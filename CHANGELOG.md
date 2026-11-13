# Changelog

## 2.6.3.2

- Sign in and sign up have a Show/Hide button next to the password.
- Clearer messages when sign in or sign up fails (for example "Your email is not confirmed yet" instead of "Wrong email or password").

## 2.6.3.1

- Settings is reordered: sign in, currency, version, then backup and restore.
- New Back up now button (a JSON file of all your records), shown when you are signed in. Restore from a backup stays below it.
- The version shows as V2.6.3.1, without the description, and lists the key release notes instead.

## 2.6.2.0

- The Continue with Google button is hidden for now. Account sign in is Sign in and Sign up with email: name, surname, email and a password (at least 8 characters) are all required to create an account.

## 2.6.1.0

- Account sign in now has three options: Continue with Google, Sign in, and Sign up.
- Sign up asks for name, surname, email and a password (at least 8 characters); all four are required.
- Google sign in works in the web version. In the Android and iPhone apps, use email and password, because Google does not allow its sign-in page inside an app.

## 2.6.0.0

- Settings is tidier: one "Settings" title, a General section (account sign in, currency, restore from a backup) and an Updates section with the installed version at the bottom.
- The PDF report button and the "Download your records" buttons are no longer in Settings. The PDF report is still available from the main screen and from a closed task.

## 2.5.0.3

- Account sync: in Settings, sign in with your account and this device keeps its records in step with your other devices (phone, tablet and the desktop website). Records still stay on the device too, work offline, and send when you are back online. The most recent edit wins. If two devices create a task at the same time with the same number, one of them is renumbered.

## 2.4.3.3

- Desktop layout: on a wide screen (about 1100 px and up) the app now has a side menu, uses the full width, and shows the task list as a table (WO number, equipment, priority, started, status). Phones and narrow windows look exactly as before.
- New landing page for the project at /site/ on the web address, with screenshots, the feature list and download links.
- The offline copy in the home-screen app now only keeps the app itself, so other pages on the site can't replace it.

## 2.4.2.3

- The task header now shows the vehicle's number plate, or the equipment's serial number, next to the word TASK.
- A closed task opens for viewing only: the Close and Create follow-up buttons are gone (use the × at the top to leave). PDF report stays.
- New Attachments section at the bottom of a task. It lists the location photos and any PDF report made from the task. The report is kept on the task, and Save again hands you the same file.
- Closed tasks no longer show a green circle next to the status.
- The PDF report button on a closed task now makes a report for that one task.

## 2.4.1.3

- Every task now has a checklist. A button at the bottom of the task starts one for that WO number, and you add the steps. A task cannot be closed until the checklist has at least one step and every step is ticked.
- WO numbers now have a single dash, after WO: WO-V20260001. Older numbers display the same way.
- A closed task can no longer be re-opened or changed. You can still view it, make its PDF report and create a follow-up.
- Tasks tab: three filter buttons only, Open, Not started and Closed. Open means In progress or Further action. Statuses are now Not started, In progress, Further action and Closed.
- The task list shows the WO number, the equipment, the priority, and the date and time the task was started.

## 2.3.1.3

- Fix: the iPhone web app (Add to Home Screen) had no way to check for updates. Settings now has Check for updates and Update now, and the app checks quietly each time it opens. The saved copy is also refreshed properly instead of lagging a few minutes behind.
- Fix: in the iPhone app, Update now downloads the newest screens inside the app instead of opening the web page. Your records stay on the phone. Changes to the iPhone app itself still need a new install.

## 2.3.1.2

- "Asset" is now "Equipment" everywhere you see it: tabs, buttons, forms, the PDF report and the CSV export.
- Tasks get a new status, Further action, and the type Repair is now Corrective maintenance (older Repair tasks show as Corrective).
- At the bottom of every task: a tick box for "The equipment went to a garage, or a technician came over". Ticking it opens Name, Contact, Save current location and photo attachments for the location. The CSV export includes these.
- Corrective tasks with High priority get a red ! mark in the lists and on the task. If one is set to Further action and is still waiting 3 days later, the phone apps send a notification (Android and iPhone; the dashboard shows a Follow-up needed list in every version).
- Android: asks for notification and location permission only when you first use those features. Reminders survive a restart.
- iPhone and iPad app project (`ios/`) and the installable web app (`docs/`), see below.

- Installable web app (`docs/`, served by GitHub Pages): open the link in Safari, then Share > Add to Home Screen. It has its own icon, runs full screen and works offline. Records stay on the device, in IndexedDB.
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
