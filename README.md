# إنجاز — Injaz

A beautiful offline task manager with daily task tracking, checklists, priorities, tags, and a teal animated UI.
Comes as a **Python desktop app** and a **Flutter mobile app** (Android) that also includes **Fikra — فِكْرة**, the ideas notebook.

## 📱 Mobile app (Flutter)

Two modes, switched from the pill at the top of the screen:

- **✓ Injaz** — today's tasks only: quick-add bar, tap the circle to move a task
  pending → in progress → done, tap a card for details and its checklist, swipe to delete (with undo).
  Finished tasks fold into a "Completed" row; unfinished tasks from earlier days show as one small chip.
- **💡 Fikra** — "What are you thinking?": capture an idea in one line, or add details, photos and a
  voice note. URLs in descriptions are clickable. Pin ideas to keep them on top. Arabic text is right-aligned automatically.

Everything else (all tasks, unfinished from earlier, settings, account) lives in the ☰ menu.

**Offline-first sync.** Data is saved on the phone first and works with no internet. Sign in (Settings & sync)
with an email and password to back it up to Supabase and sync across devices automatically — on launch,
on return to the app, a couple of seconds after each change and every 45 s. Photos and voice notes go to a private
storage bucket. Each account only sees its own rows (row-level security).

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
