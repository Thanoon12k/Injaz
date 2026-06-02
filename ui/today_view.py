from datetime import date
from PyQt5.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QPushButton, QLineEdit, QScrollArea, QFrame,
    QSizePolicy, QMessageBox
)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QFont

from .gradient_widget import GradientWidget
from .task_card import TaskCard
from .add_task_dialog import AddTaskDialog
import styles


class TodayView(QWidget):
    """Today's tasks — main view matching the mockup."""

    tasks_changed = pyqtSignal()   # tells main window to refresh counters

    def __init__(self, db, parent=None):
        super().__init__(parent)
        self.db = db
        self._build()
        self.refresh()

    # ── Build UI ──────────────────────────────────────────────────
    def _build(self):
        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        # animated gradient fills the whole view
        self._bg = GradientWidget(self)
        root.addWidget(self._bg)

        # overlay layout on top of gradient
        overlay = QVBoxLayout(self._bg)
        overlay.setContentsMargins(20, 20, 20, 20)
        overlay.setSpacing(12)

        # ── header row ──
        hdr = QHBoxLayout()
        self._date_lbl = QLabel()
        self._date_lbl.setStyleSheet("color:white; font-size:17px;")
        today = date.today().strftime("%A, %d %B %Y")
        self._date_lbl.setText(today)
        hdr.addWidget(self._date_lbl)
        hdr.addStretch()

        # import past tasks button
        import_btn = QPushButton("📥 Past Tasks")
        import_btn.setStyleSheet("""
            QPushButton {
                background: rgba(255,255,255,0.25); color: white;
                border: 1px solid rgba(255,255,255,0.5);
                border-radius: 14px; padding: 5px 16px; font-size: 15px;
            }
            QPushButton:hover { background: rgba(255,255,255,0.35); }
        """)
        import_btn.clicked.connect(self._show_past_tasks)
        hdr.addWidget(import_btn)
        overlay.addLayout(hdr)

        # ── Today label ──
        today_lbl = QLabel("Today")
        today_lbl.setStyleSheet("color:white; font-size:34px; font-weight:700;")
        overlay.addWidget(today_lbl)

        # ── input bar ──
        input_row = QHBoxLayout(); input_row.setSpacing(10)
        self._input = QLineEdit()
        self._input.setPlaceholderText("Enter your today task…")
        self._input.setFixedHeight(58)
        self._input.setStyleSheet("""
            QLineEdit {
                background: rgba(255,255,255,0.90);
                border: none; border-radius: 29px;
                padding: 0 24px; font-size: 18px; color: #212121;
            }
            QLineEdit:focus { background: white; }
        """)
        self._input.returnPressed.connect(self._quick_add)
        input_row.addWidget(self._input)

        add_btn = QPushButton("+")
        add_btn.setFixedSize(58, 58)
        add_btn.setStyleSheet("""
            QPushButton {
                background: white; color: #00BCD4;
                border: none; border-radius: 29px;
                font-size: 32px; font-weight: bold;
            }
            QPushButton:hover { background: #E0F7FA; }
        """)
        add_btn.clicked.connect(self._open_add_dialog)
        input_row.addWidget(add_btn)
        overlay.addLayout(input_row)

        # ── task list ──
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        scroll.setStyleSheet("background: transparent;")
        scroll.verticalScrollBar().setStyleSheet("""
            QScrollBar:vertical { background:transparent; width:6px; }
            QScrollBar::handle:vertical { background:rgba(255,255,255,0.4); border-radius:3px; }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height:0; }
        """)

        self._list_widget = QWidget()
        self._list_widget.setStyleSheet("background: transparent;")
        self._list_layout = QVBoxLayout(self._list_widget)
        self._list_layout.setContentsMargins(0, 0, 0, 0)
        self._list_layout.setSpacing(10)
        self._list_layout.addStretch()

        scroll.setWidget(self._list_widget)
        overlay.addWidget(scroll)

        # ── empty state label ──
        self._empty_lbl = QLabel("No tasks yet.\nAdd one above! 🎯")
        self._empty_lbl.setAlignment(Qt.AlignCenter)
        self._empty_lbl.setStyleSheet(
            "color:rgba(255,255,255,0.7); font-size:19px; line-height:1.6;"
        )
        overlay.addWidget(self._empty_lbl)

    # ── Refresh ───────────────────────────────────────────────────
    def refresh(self):
        # clear list
        while self._list_layout.count() > 1:
            item = self._list_layout.takeAt(0)
            if item.widget():
                item.widget().deleteLater()

        tasks = self.db.get_today_tasks()
        self._empty_lbl.setVisible(len(tasks) == 0)

        for t in tasks:
            card = TaskCard(t, self.db, parent=self)
            card.status_changed.connect(self._on_status_changed)
            card.edit_requested.connect(self._on_edit)
            card.delete_requested.connect(self._on_delete)
            card.move_today_requested.connect(self._on_move_today)
            self._list_layout.insertWidget(self._list_layout.count() - 1, card)

    # ── Slots ─────────────────────────────────────────────────────
    def _quick_add(self):
        title = self._input.text().strip()
        if not title:
            return
        self.db.add_task(title)
        self._input.clear()
        self.refresh()
        self.tasks_changed.emit()

    def _open_add_dialog(self):
        hint = self._input.text().strip()
        dlg = AddTaskDialog(self, title_hint=hint)
        if dlg.exec_() == dlg.Accepted:
            data = dlg.result_data()
            self.db.add_task(**data)
            self._input.clear()
            self.refresh()
            self.tasks_changed.emit()

    def _on_status_changed(self, task_id: int, status: str):
        self.db.set_status(task_id, status)
        self.tasks_changed.emit()

    def _on_edit(self, task_id: int):
        tasks = self.db.get_today_tasks()
        task  = next((t for t in tasks if t['id'] == task_id), None)
        if task is None:
            # search all tasks
            all_t = self.db.get_all_tasks()
            task = next((t for t in all_t if t['id'] == task_id), None)
        if task is None:
            return
        dlg = AddTaskDialog(self, task=task)
        if dlg.exec_() == dlg.Accepted:
            data = dlg.result_data()
            self.db.update_task(task_id, **data)
            self.refresh()
            self.tasks_changed.emit()

    def _on_delete(self, task_id: int):
        reply = QMessageBox.question(
            self, "Delete Task", "Delete this task permanently?",
            QMessageBox.Yes | QMessageBox.No, QMessageBox.No
        )
        if reply == QMessageBox.Yes:
            self.db.delete_task(task_id)
            self.refresh()
            self.tasks_changed.emit()

    def _on_move_today(self, task_id: int):
        self.db.move_to_today(task_id)
        self.refresh()
        self.tasks_changed.emit()

    # ── Past tasks popup ──────────────────────────────────────────
    def _show_past_tasks(self):
        from .past_tasks_dialog import PastTasksDialog
        dlg = PastTasksDialog(self.db, self)
        dlg.exec_()
        self.refresh()
        self.tasks_changed.emit()
