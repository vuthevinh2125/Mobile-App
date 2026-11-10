# Expense Tracker · User App (Flutter)

The user-side mobile app of an expense tracker built for COMP1786 (Mobile Application Design and Development) at the University of Greenwich. Staff use it to see every expense claim across all projects in real time and to submit new claims. The admin side backs project data up to **Firebase Realtime Database**; this app reads from and writes to that same database.

## Features

- **Live expense feed.** Streams the `CloudBackup` node and flattens every project's `expenses` into one list. New claims appear without a refresh. Handles expenses stored both as lists and as keyed maps.
- **Search.** Filters by claimant name or expense type as you type.
- **Favourites.** Tap the heart on any claim to keep it; favourites are saved on the device with `shared_preferences` and survive restarts. The heart in the app bar shows favourites only.
- **Add an expense.** A validated form (project, claimant, type, amount, date). The project dropdown is built from the database and shows each project's real name from `info.projectName`. The claim is written with `push()` under that project, timestamped as its id.
- **Clear states.** Loading spinner, "waiting for data sync from Admin" when the database is empty, "no matching results" when a search finds nothing, and readable errors in a snackbar.

## How the data is shaped

```
CloudBackup/
  project_3/
    info/        { projectName: "…" }
    expenses/    { <pushId>: { id, claimant, type, amount, date } … }
  project_4/
    …
```

## Project structure

```
lib/
  main.dart                     Firebase init, Material 3 theme
  models/project.dart           expense model + fromJson
  screens/home_screen.dart      live list, search, favourites
  screens/add_expense_screen.dart   new-claim form
```

## Run it

Requires the Flutter SDK (Dart ^3.11) and an Android or iOS device or emulator.

```bash
flutter pub get
flutter run
```

The app connects to the project's Firebase Realtime Database (region `asia-southeast1`) using the generated `lib/firebase_options.dart`. To point it at your own Firebase project, run `flutterfire configure` and update the `databaseURL` in `main.dart`.

## Stack

Flutter · Dart · Material 3 · Firebase Core · Firebase Realtime Database · shared_preferences
