# إنجاز — Injaz

A beautiful offline Python desktop task manager with daily task tracking, checklists, priorities, tags, and a teal animated UI.

## Features
- 📋 **Today View** — daily tasks with quick-add bar and animated teal background
- ✅ **Checklists** — expandable subtask checklist per task
- 🏷️ **Tags & Priority** — low / medium / high / urgent with color-coded bars
- 📅 **Past Tasks** — import uncompleted tasks from previous days to today
- ⚙️ **Settings** — profile photo, name, bio, and task statistics
- 💾 **100% Offline** — SQLite local database, no internet required

## Requirements
```
pip install PyQt5 Pillow
```

## Run
```
python main.py
```

## Build Executable
```
pyinstaller --onefile --windowed --add-data "ui;ui" --add-data "assets;assets" --icon=assets/icon.ico main.py
```

The `.exe` will be in `dist/`. The `injaz.db` database is saved next to the executable.
