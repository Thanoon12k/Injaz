# إنجاز — Injaz

A beautiful offline task manager with daily task tracking, checklists, priorities, tags, and a teal animated UI.
Comes as a **Python desktop app** and a **Flutter mobile app** (Android) that also includes **Fikra — فِكْرة**, the ideas notebook.

## 📱 Mobile app (Flutter)

One calm app for your day and your ideas — tasks and ideas live together on a single screen.

- **One capture bar** — type, pick **Task** or **Idea**, send. The ⚙ button opens the full form
  (time, priority, checklist for tasks; photos, voice note and details for ideas).
- **Today** — only today's tasks. Tap the ring to finish a task, hold it to set *Doing*, tap the row
  for details and steps, swipe to delete (with undo). Ring colour = priority. Unfinished tasks from earlier
  days show as one line you can open.
- **Ideas** — your latest ideas under today's tasks; links are clickable, Arabic is right-aligned automatically,
  pin the important ones, and **Do it today** turns an idea into a task.
- Everything else (all tasks, all ideas, settings) is behind your avatar.
- Light and dark themes follow the phone.

**Sign in with Google** to back up and sync across devices (or use it without an account).
Data is saved on the phone first and syncs automatically on launch, on return to the app, a couple of
seconds after each change and every 45 s. Photos and voice notes go to a private storage bucket; each
account only sees its own rows (row-level security). Google sign-in returns to the app via
`com.thanoon.injaz://login-callback`, which must be listed in Supabase → Authentication → URL Configuration → Redirect URLs.

Supabase tables: `injaz_tasks`, `fikra_ideas`, bucket `fikra-media` (see `lib/store.dart` for the sync logic).

```bash
flutter pub get
flutter run                     # debug on a device
flutter build apk --release     # release APK in build/app/outputs/flutter-apk/
flutter test
```

Release builds are signed with `android/app/upload.jks` when that file exists, otherwise with debug keys.

## 🖥️ Desktop app (Python)

### Features
- 📋 **Today View** — daily tasks with quick-add bar and animated teal background
- ✅ **Checklists** — expandable subtask checklist per task
- 🏷️ **Tags & Priority** — low / medium / high / urgent with color-coded bars
- 📅 **Past Tasks** — import uncompleted tasks from previous days to today
- ⚙️ **Settings** — profile photo, name, bio, and task statistics
- 💾 **100% Offline** — SQLite local database, no internet required

### Requirements
```
pip install PyQt5 Pillow
```

### Run
```
python main.py
```

### Build Executable
```
pyinstaller --onefile --windowed --add-data "ui;ui" --add-data "assets;assets" --icon=assets/icon.ico main.py
```

The `.exe` will be in `dist/`. The `injaz.db` database is saved next to the executable.
