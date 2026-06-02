import sys
import os
from PyQt5.QtWidgets import QApplication
from PyQt5.QtGui import QFont, QIcon
from database import Database
from ui.main_window import MainWindow


def _icon_path() -> str:
    """Return path to icon.png that works in both dev and PyInstaller bundle."""
    if getattr(sys, 'frozen', False):
        base = sys._MEIPASS          # bundled: extracted temp dir
    else:
        base = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base, 'assets', 'icon.png')


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Injaz")

    # App-wide icon (taskbar, alt-tab, window title bar)
    icon = QIcon(_icon_path())
    app.setWindowIcon(icon)

    # Use a clean system font
    font = QFont("Segoe UI", 15)
    app.setFont(font)

    db = Database()
    win = MainWindow(db)
    win.setWindowIcon(icon)
    win.show()

    ret = app.exec_()
    db.close()
    sys.exit(ret)


if __name__ == "__main__":
    main()
