from itertools import groupby
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QLineEdit, QComboBox, QScrollArea,
    QFrame, QMessageBox
)
from PyQt5.QtCore import Qt, pyqtSignal

from .task_card import TaskCard
from .add_task_dialog import AddTaskDialog
import styles


class AllTasksView(QWidget):
    tasks_changed = pyqtSignal()

    def __init__(self, db, parent=None):
        super().__init__(parent)
        self.db = db
        self.setStyleSheet(f"background: #F0FAFA;")
        self._build()
        self.refresh()

    def _build(self):
        root = QVBoxLayout(self)
        root.setContentsMargins(24, 24, 24, 16)
        root.setSpacing(14)

        # title
        ttl = QLabel("All Tasks")
        ttl.setStyleSheet(f"font-size:26px; font-weight:700; color:{styles.TEXT_DARK};")
        root.addWidget(ttl)

        # filter bar
        fbar = QHBoxLayout(); fbar.setSpacing(10)

        self._search = QLineEdit(); self._search.setPlaceholderText("🔍  Search…")
        self._search.setFixedHeight(42)
        self._search.setStyleSheet(styles.FIELD + "font-size:15px;")
        self._search.textChanged.connect(self.refresh)
        fbar.addWidget(self._search)

        self._status_cb = QComboBox();        self._status_cb.setFixedHeight(42)
        self._status_cb.setStyleSheet(styles.FIELD + "font-size:15px;")
        self._status_cb.addItem("All Statuses", "")
        for k, v in styles.STATUS_LABEL.items():
            self._status_cb.addItem(v, k)
        self._status_cb.currentIndexChanged.connect(self.refresh)
        fbar.addWidget(self._status_cb)

        self._pri_cb = QComboBox(); self._pri_cb.setFixedHeight(42)
        self._pri_cb.setStyleSheet(styles.FIELD + "font-size:15px;")
        self._pri_cb.addItem("All Priorities", "")
        for p in ['low', 'medium', 'high', 'urgent']:
            self._pri_cb.addItem(p.capitalize(), p)
        self._pri_cb.currentIndexChanged.connect(self.refresh)
        fbar.addWidget(self._pri_cb)

        root.addLayout(fbar)

        # scroll
        scroll = QScrollArea(); scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setStyleSheet("background: transparent;")
        scroll.verticalScrollBar().setStyleSheet("""
            QScrollBar:vertical { background:transparent; width:6px; }
            QScrollBar::handle:vertical { background:#B2EBF2; border-radius:3px; }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height:0; }
        """)

        self._inner = QWidget(); self._inner.setStyleSheet("background:transparent;")
        self._vl    = QVBoxLayout(self._inner)
        self._vl.setContentsMargins(0, 0, 0, 0)
        self._vl.setSpacing(6)
        scroll.setWidget(self._inner)
        root.addWidget(scroll)

        self._empty = QLabel("No tasks match your filters.")
        self._empty.setAlignment(Qt.AlignCenter)
        self._empty.setStyleSheet(f"color:{styles.TEXT_GREY}; font-size:17px;")
        root.addWidget(self._empty)

    def refresh(self):
        # clear
        while self._vl.count():
            item = self._vl.takeAt(0)
            if item.widget(): item.widget().deleteLater()

        tasks = self.db.get_all_tasks()

        # apply filters
        q    = self._search.text().lower()
        stat = self._status_cb.currentData()
        pri  = self._pri_cb.currentData()

        if q:    tasks = [t for t in tasks if q in t['title'].lower() or q in (t['description'] or '').lower()]
        if stat: tasks = [t for t in tasks if t['status']   == stat]
        if pri:  tasks = [t for t in tasks if t['priority'] == pri]

        self._empty.setVisible(len(tasks) == 0)

        # group by date
        for day, group in groupby(tasks, key=lambda t: t['date_assigned']):
            day_lbl = QLabel(day)
            day_lbl.setStyleSheet(f"color:{styles.PRIMARY_DARK}; font-size:15px; font-weight:700; padding-top:8px;")
            self._vl.addWidget(day_lbl)
            for t in group:
                card = TaskCard(t, self.db, show_date=False, parent=self)
                card.status_changed.connect(self._on_status)
                card.edit_requested.connect(self._on_edit)
                card.delete_requested.connect(self._on_delete)
                card.move_today_requested.connect(self._on_move)
                self._vl.addWidget(card)

        self._vl.addStretch()

    def _on_status(self, tid, status):
        self.db.set_status(tid, status)
        self.refresh(); self.tasks_changed.emit()

    def _on_edit(self, tid):
        task = next((t for t in self.db.get_all_tasks() if t['id'] == tid), None)
        if not task: return
        dlg = AddTaskDialog(self, task=task)
        if dlg.exec_() == dlg.Accepted:
            self.db.update_task(tid, **dlg.result_data())
            self.refresh(); self.tasks_changed.emit()

    def _on_delete(self, tid):
        if QMessageBox.question(self, "Delete", "Delete this task?",
                                QMessageBox.Yes | QMessageBox.No) == QMessageBox.Yes:
            self.db.delete_task(tid)
            self.refresh(); self.tasks_changed.emit()

    def _on_move(self, tid):
        self.db.move_to_today(tid)
        self.refresh(); self.tasks_changed.emit()
