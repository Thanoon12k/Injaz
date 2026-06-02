import sys
import os
import shutil
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QLineEdit, QTextEdit, QFileDialog,
    QFrame, QMessageBox
)
from PyQt5.QtCore import Qt, pyqtSignal, QSize
from PyQt5.QtGui import QPixmap, QPainter, QBrush, QColor, QPainterPath

import styles

if getattr(sys, 'frozen', False):
    _BASE = os.path.dirname(sys.executable)
else:
    _BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ASSETS_DIR = os.path.join(_BASE, 'assets')


def _round_pixmap(path: str, size: int) -> QPixmap:
    """Return a circular-cropped pixmap."""
    src = QPixmap(path).scaled(size, size, Qt.KeepAspectRatioByExpanding, Qt.SmoothTransformation)
    out = QPixmap(size, size); out.fill(Qt.transparent)
    p = QPainter(out); p.setRenderHint(QPainter.Antialiasing)
    path_obj = QPainterPath(); path_obj.addEllipse(0, 0, size, size)
    p.setClipPath(path_obj); p.drawPixmap(0, 0, src); p.end()
    return out


class SettingsView(QWidget):
    profile_updated = pyqtSignal()

    def __init__(self, db, parent=None):
        super().__init__(parent)
        self.db = db
        self._image_path = ''
        self.setStyleSheet("background:#F0FAFA;")
        self._build()
        self._load()

    def _build(self):
        root = QVBoxLayout(self)
        root.setContentsMargins(32, 32, 32, 32)
        root.setSpacing(24)

        # title
        ttl = QLabel("Settings")
        ttl.setStyleSheet(f"font-size:26px; font-weight:700; color:{styles.TEXT_DARK};")
        root.addWidget(ttl)

        # ── profile card ──────────────────────────────────────────
        card = QFrame()
        card.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 16px;
            }
        """)
        card_lay = QVBoxLayout(card)
        card_lay.setContentsMargins(28, 28, 28, 28)
        card_lay.setSpacing(20)

        sec = QLabel("Profile")
        sec.setStyleSheet(f"font-size:18px; font-weight:700; color:{styles.TEXT_DARK};")
        card_lay.addWidget(sec)

        # avatar row
        av_row = QHBoxLayout(); av_row.setSpacing(20)

        self._avatar = QLabel()
        self._avatar.setFixedSize(90, 90)
        self._avatar.setAlignment(Qt.AlignCenter)
        self._avatar.setStyleSheet(f"""
            background: {styles.PRIMARY_LIGHT};
            border-radius: 45px;
            font-size: 36px;
        """)
        self._avatar.setText("👤")
        av_row.addWidget(self._avatar)

        av_col = QVBoxLayout(); av_col.setSpacing(8)
        change_btn = QPushButton("Change Photo")
        change_btn.setStyleSheet(styles.BTN_PRIMARY)
        change_btn.setFixedWidth(140)
        change_btn.clicked.connect(self._pick_image)
        av_col.addWidget(change_btn)

        remove_btn = QPushButton("Remove Photo")
        remove_btn.setStyleSheet(styles.BTN_SECONDARY)
        remove_btn.setFixedWidth(140)
        remove_btn.clicked.connect(self._remove_image)
        av_col.addWidget(remove_btn)
        av_col.addStretch()
        av_row.addLayout(av_col)
        av_row.addStretch()
        card_lay.addLayout(av_row)

        # name
        card_lay.addWidget(self._field_label("Name"))
        self._name = QLineEdit()
        self._name.setStyleSheet(styles.FIELD)
        card_lay.addWidget(self._name)

        # bio
        card_lay.addWidget(self._field_label("Bio"))
        self._bio = QTextEdit()
        self._bio.setFixedHeight(80)
        self._bio.setStyleSheet(styles.FIELD)
        card_lay.addWidget(self._bio)

        # save button
        save_row = QHBoxLayout(); save_row.addStretch()
        save_btn = QPushButton("Save Changes")
        save_btn.setStyleSheet(styles.BTN_PRIMARY)
        save_btn.clicked.connect(self._save)
        save_row.addWidget(save_btn)
        card_lay.addLayout(save_row)

        root.addWidget(card)

        # ── stats card ───────────────────────────────────────────
        stats_card = QFrame()
        stats_card.setStyleSheet("QFrame { background:white; border-radius:16px; }")
        stats_lay = QHBoxLayout(stats_card)
        stats_lay.setContentsMargins(28, 20, 28, 20)
        stats_lay.setSpacing(0)

        self._stat_labels = {}
        for key, icon, label in [
            ('total',     '📋', 'Total Tasks'),
            ('completed', '✅', 'Completed'),
            ('pending',   '⏳', 'Pending'),
        ]:
            col = QVBoxLayout(); col.setAlignment(Qt.AlignCenter)
            val = QLabel("0")
            val.setAlignment(Qt.AlignCenter)
            val.setStyleSheet(f"font-size:32px; font-weight:700; color:{styles.PRIMARY};")
            col.addWidget(val)
            lbl = QLabel(f"{icon}  {label}")
            lbl.setAlignment(Qt.AlignCenter)
            lbl.setStyleSheet(f"font-size:14px; color:{styles.TEXT_GREY};")
            col.addWidget(lbl)
            stats_lay.addLayout(col)
            stats_lay.addStretch()
            self._stat_labels[key] = val

        root.addWidget(stats_card)
        root.addStretch()

    @staticmethod
    def _field_label(text):
        l = QLabel(text)
        l.setStyleSheet(f"color:{styles.TEXT_GREY}; font-size:12px; font-weight:600;")
        return l

    # ── Load / Save ───────────────────────────────────────────────
    def _load(self):
        p = self.db.get_profile()
        self._name.setText(p.get('name', ''))
        self._bio.setPlainText(p.get('bio', ''))
        self._image_path = p.get('image_path', '')
        self._refresh_avatar()
        self._refresh_stats()

    def _refresh_avatar(self):
        if self._image_path and os.path.exists(self._image_path):
            px = _round_pixmap(self._image_path, 90)
            self._avatar.setPixmap(px)
            self._avatar.setText('')
        else:
            self._avatar.setPixmap(QPixmap())
            self._avatar.setText("👤")

    def _refresh_stats(self):
        all_tasks = self.db.get_all_tasks()
        total     = len(all_tasks)
        completed = sum(1 for t in all_tasks if t['status'] == 'completed')
        pending   = sum(1 for t in all_tasks if t['status'] == 'pending')
        self._stat_labels['total'].setText(str(total))
        self._stat_labels['completed'].setText(str(completed))
        self._stat_labels['pending'].setText(str(pending))

    def _pick_image(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Select Profile Photo", "",
            "Images (*.png *.jpg *.jpeg *.bmp *.gif)"
        )
        if not path:
            return
        os.makedirs(ASSETS_DIR, exist_ok=True)
        dest = os.path.join(ASSETS_DIR, 'profile' + os.path.splitext(path)[1])
        shutil.copy2(path, dest)
        self._image_path = dest
        self._refresh_avatar()

    def _remove_image(self):
        self._image_path = ''
        self._refresh_avatar()

    def _save(self):
        name = self._name.text().strip() or 'User'
        bio  = self._bio.toPlainText().strip()
        self.db.update_profile(name, bio, self._image_path)
        QMessageBox.information(self, "Saved", "Profile saved successfully!")
        self.profile_updated.emit()

    def refresh(self):
        self._load()
