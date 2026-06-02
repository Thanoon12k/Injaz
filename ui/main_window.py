import os
from datetime import date
from PyQt5.QtWidgets import (
    QMainWindow, QWidget, QHBoxLayout, QVBoxLayout,
    QLabel, QPushButton, QStackedWidget, QFrame, QSizePolicy
)
from PyQt5.QtCore import Qt, QSize
from PyQt5.QtGui import QFont, QPixmap, QPainter, QPainterPath, QColor

from .today_view import TodayView
from .all_tasks_view import AllTasksView
from .settings_view import SettingsView
import styles

ASSETS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets')


def _round_pixmap(path: str, size: int) -> QPixmap:
    src = QPixmap(path).scaled(size, size, Qt.KeepAspectRatioByExpanding, Qt.SmoothTransformation)
    out = QPixmap(size, size); out.fill(Qt.transparent)
    p = QPainter(out); p.setRenderHint(QPainter.Antialiasing)
    pp = QPainterPath(); pp.addEllipse(0, 0, size, size)
    p.setClipPath(pp); p.drawPixmap(0, 0, src); p.end()
    return out


class NavButton(QPushButton):
    def __init__(self, icon: str, text: str, parent=None):
        super().__init__(f"  {icon}   {text}", parent)
        self.setCheckable(True)
        self.setFixedHeight(46)
        self.setStyleSheet("""
            QPushButton {
                background: transparent;
                color: rgba(255,255,255,0.80);
                border: none; border-radius: 10px;
                font-size: 17px; font-weight: 500;
                text-align: left; padding-left: 16px;
            }
            QPushButton:hover   { background: rgba(255,255,255,0.15); color: white; }
            QPushButton:checked { background: rgba(255,255,255,0.25); color: white; font-weight:700; }
        """)


class MainWindow(QMainWindow):
    def __init__(self, db):
        super().__init__()
        self.db = db
        self.setWindowTitle("Injaz  إنجاز")
        self.setMinimumSize(900, 600)
        self.resize(1100, 700)
        self._build()
        self._refresh_profile()

    def _build(self):
        central = QWidget()
        self.setCentralWidget(central)
        hlay = QHBoxLayout(central)
        hlay.setContentsMargins(0, 0, 0, 0)
        hlay.setSpacing(0)

        # ── Sidebar ───────────────────────────────────────────────
        self._sidebar = QFrame()
        self._sidebar.setFixedWidth(220)
        self._sidebar.setStyleSheet(f"""
            QFrame {{
                background: qlineargradient(
                    x1:0, y1:0, x2:0, y2:1,
                    stop:0 {styles.SIDEBAR_BG},
                    stop:1 {styles.PRIMARY_DARKER}
                );
            }}
        """)
        side_lay = QVBoxLayout(self._sidebar)
        side_lay.setContentsMargins(12, 24, 12, 24)
        side_lay.setSpacing(4)

        # app name
        app_name = QLabel("إنجاز  Injaz")
        app_name.setAlignment(Qt.AlignCenter)
        app_name.setStyleSheet("color:white; font-size:22px; font-weight:800; letter-spacing:1px;")
        side_lay.addWidget(app_name)

        # separator
        sep = QFrame(); sep.setFrameShape(QFrame.HLine)
        sep.setStyleSheet("color: rgba(255,255,255,0.2);")
        side_lay.addSpacing(8); side_lay.addWidget(sep); side_lay.addSpacing(16)

        # profile area
        self._profile_avatar = QLabel("👤")
        self._profile_avatar.setFixedSize(64, 64)
        self._profile_avatar.setAlignment(Qt.AlignCenter)
        self._profile_avatar.setStyleSheet(f"""
            background: rgba(255,255,255,0.2);
            border-radius: 32px; font-size: 28px;
        """)
        side_lay.addWidget(self._profile_avatar, alignment=Qt.AlignHCenter)

        self._profile_name = QLabel("User")
        self._profile_name.setAlignment(Qt.AlignCenter)
        self._profile_name.setStyleSheet("color:white; font-size:17px; font-weight:600;")
        side_lay.addWidget(self._profile_name)

        self._profile_bio = QLabel("")
        self._profile_bio.setAlignment(Qt.AlignCenter)
        self._profile_bio.setWordWrap(True)
        self._profile_bio.setStyleSheet("color:rgba(255,255,255,0.65); font-size:13px;")
        side_lay.addWidget(self._profile_bio)

        side_lay.addSpacing(20)

        # nav buttons
        self._nav_today    = NavButton("📋", "Today")
        self._nav_all      = NavButton("📅", "All Tasks")
        self._nav_settings = NavButton("⚙️",  "Settings")

        self._nav_today.setChecked(True)
        self._nav_today.clicked.connect(lambda: self._switch(0))
        self._nav_all.clicked.connect(lambda: self._switch(1))
        self._nav_settings.clicked.connect(lambda: self._switch(2))

        for btn in [self._nav_today, self._nav_all, self._nav_settings]:
            side_lay.addWidget(btn)

        side_lay.addStretch()

        # task counter badge at bottom
        self._counter = QLabel("0 tasks today")
        self._counter.setAlignment(Qt.AlignCenter)
        self._counter.setStyleSheet("color:rgba(255,255,255,0.6); font-size:13px;")
        side_lay.addWidget(self._counter)

        hlay.addWidget(self._sidebar)

        # ── Content stack ─────────────────────────────────────────
        self._stack = QStackedWidget()
        hlay.addWidget(self._stack)

        self._today_view    = TodayView(self.db)
        self._all_view      = AllTasksView(self.db)
        self._settings_view = SettingsView(self.db)

        self._stack.addWidget(self._today_view)     # 0
        self._stack.addWidget(self._all_view)       # 1
        self._stack.addWidget(self._settings_view)  # 2

        # signals
        self._today_view.tasks_changed.connect(self._on_tasks_changed)
        self._all_view.tasks_changed.connect(self._on_tasks_changed)
        self._settings_view.profile_updated.connect(self._refresh_profile)

        self._update_counter()

    def _switch(self, idx: int):
        self._stack.setCurrentIndex(idx)
        for i, btn in enumerate([self._nav_today, self._nav_all, self._nav_settings]):
            btn.setChecked(i == idx)
        if idx == 0: self._today_view.refresh()
        if idx == 1: self._all_view.refresh()
        if idx == 2: self._settings_view.refresh()

    def _on_tasks_changed(self):
        self._update_counter()
        self._all_view.refresh()

    def _update_counter(self):
        n = len(self.db.get_today_tasks())
        self._counter.setText(f"{n} task{'s' if n != 1 else ''} today")

    def _refresh_profile(self):
        p = self.db.get_profile()
        self._profile_name.setText(p.get('name', 'User'))
        self._profile_bio.setText(p.get('bio', ''))
        img = p.get('image_path', '')
        if img and os.path.exists(img):
            px = _round_pixmap(img, 64)
            self._profile_avatar.setPixmap(px)
            self._profile_avatar.setText('')
        else:
            self._profile_avatar.setPixmap(QPixmap())
            self._profile_avatar.setText("👤")
