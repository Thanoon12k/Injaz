from PyQt5.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QScrollArea, QFrame, QWidget
)
from PyQt5.QtCore import Qt
from .task_card import TaskCard
import styles


class PastTasksDialog(QDialog):
    """Shows uncompleted past tasks; lets user move them to today."""

    def __init__(self, db, parent=None):
        super().__init__(parent)
        self.db = db
        self.setWindowTitle("Uncompleted Past Tasks")
        self.setMinimumSize(500, 500)
        self.setModal(True)
        self._build()
        self._load()

    def _build(self):
        self.setStyleSheet("background: white;")
        vlay = QVBoxLayout(self)
        vlay.setContentsMargins(24, 20, 24, 20)
        vlay.setSpacing(14)

        hdr = QLabel("📅  Past Uncompleted Tasks")
        hdr.setStyleSheet("font-size:17px; font-weight:700; color:#212121;")
        vlay.addWidget(hdr)

        sub = QLabel("Right-click a card → Move to Today, or use the button below.")
        sub.setStyleSheet("color:#9E9E9E; font-size:12px;")
        vlay.addWidget(sub)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        self._inner = QWidget(); self._inner.setStyleSheet("background:white;")
        self._vl = QVBoxLayout(self._inner)
        self._vl.setSpacing(8)
        self._vl.addStretch()
        scroll.setWidget(self._inner)
        vlay.addWidget(scroll)

        # move-all button
        row = QHBoxLayout(); row.addStretch()
        move_all = QPushButton("Move All to Today")
        move_all.setStyleSheet(styles.BTN_PRIMARY)
        move_all.clicked.connect(self._move_all)
        row.addWidget(move_all)

        close_btn = QPushButton("Close")
        close_btn.setStyleSheet(styles.BTN_SECONDARY)
        close_btn.clicked.connect(self.accept)
        row.addWidget(close_btn)
        vlay.addLayout(row)

        self._empty = QLabel("🎉  All caught up — no uncompleted past tasks!")
        self._empty.setAlignment(Qt.AlignCenter)
        self._empty.setStyleSheet("color:#9E9E9E; font-size:14px;")
        vlay.addWidget(self._empty)

    def _load(self):
        while self._vl.count() > 1:
            item = self._vl.takeAt(0)
            if item.widget(): item.widget().deleteLater()

        tasks = self.db.get_uncompleted_past_tasks()
        self._empty.setVisible(len(tasks) == 0)

        for t in tasks:
            card = TaskCard(t, self.db, show_date=True, parent=self)
            card.move_today_requested.connect(self._move_one)
            card.delete_requested.connect(self._delete_one)
            self._vl.insertWidget(self._vl.count() - 1, card)

    def _move_one(self, task_id):
        self.db.move_to_today(task_id)
        self._load()

    def _delete_one(self, task_id):
        self.db.delete_task(task_id)
        self._load()

    def _move_all(self):
        for t in self.db.get_uncompleted_past_tasks():
            self.db.move_to_today(t['id'])
        self._load()
