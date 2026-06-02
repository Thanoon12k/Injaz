from datetime import date as _date
from PyQt5.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QTextEdit, QComboBox, QPushButton,
    QDialogButtonBox, QFormLayout, QFrame
)
from PyQt5.QtCore import Qt
import styles


class AddTaskDialog(QDialog):
    """Add or edit a task. Pass `task` dict to pre-fill for editing."""

    def __init__(self, parent=None, task: dict = None, title_hint: str = ''):
        super().__init__(parent)
        self._task = task
        self.setWindowTitle("Edit Task" if task else "New Task")
        self.setMinimumWidth(460)
        self.setModal(True)
        self.setWindowFlags(Qt.Dialog | Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self._build()
        if task:
            self._prefill(task)
        elif title_hint:
            self._title.setText(title_hint)

    def _build(self):
        # outer card
        card = QFrame(self)
        card.setObjectName("dlg_card")
        card.setStyleSheet("""
            QFrame#dlg_card {
                background: white;
                border-radius: 16px;
            }
        """)

        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.addWidget(card)

        vlay = QVBoxLayout(card)
        vlay.setContentsMargins(28, 24, 28, 24)
        vlay.setSpacing(16)

        # header
        hdr = QLabel("Edit Task" if self._task else "Add New Task")
        hdr.setStyleSheet(f"font-size:18px; font-weight:700; color:{styles.TEXT_DARK};")
        vlay.addWidget(hdr)

        # form
        form = QFormLayout(); form.setSpacing(10)
        form.setLabelAlignment(Qt.AlignRight)

        def lbl(text):
            l = QLabel(text)
            l.setStyleSheet(f"color:{styles.TEXT_GREY}; font-size:12px; font-weight:600;")
            return l

        fld_style = styles.FIELD

        self._title = QLineEdit(); self._title.setPlaceholderText("Task title…")
        self._title.setStyleSheet(fld_style)
        form.addRow(lbl("Title *"), self._title)

        self._desc = QTextEdit(); self._desc.setPlaceholderText("Description (optional)…")
        self._desc.setFixedHeight(70); self._desc.setStyleSheet(fld_style)
        form.addRow(lbl("Description"), self._desc)

        self._tag = QLineEdit(); self._tag.setPlaceholderText("e.g. Work, Study…")
        self._tag.setStyleSheet(fld_style)
        form.addRow(lbl("Tag"), self._tag)

        self._priority = QComboBox(); self._priority.setStyleSheet(fld_style)
        for p in ['low', 'medium', 'high', 'urgent']:
            self._priority.addItem(p.capitalize(), p)
        self._priority.setCurrentIndex(1)
        form.addRow(lbl("Priority"), self._priority)

        self._status = QComboBox(); self._status.setStyleSheet(fld_style)
        for s, lab in styles.STATUS_LABEL.items():
            self._status.addItem(lab, s)
        form.addRow(lbl("Status"), self._status)

        self._date = QLineEdit()
        self._date.setPlaceholderText("YYYY-MM-DD (leave blank = today)")
        self._date.setStyleSheet(fld_style)
        form.addRow(lbl("Date"), self._date)

        self._time = QLineEdit(); self._time.setPlaceholderText("HH:MM (optional)")
        self._time.setStyleSheet(fld_style)
        form.addRow(lbl("Time"), self._time)

        vlay.addLayout(form)

        # buttons
        btn_row = QHBoxLayout(); btn_row.setSpacing(10)
        btn_row.addStretch()

        cancel = QPushButton("Cancel"); cancel.setStyleSheet(styles.BTN_SECONDARY)
        cancel.clicked.connect(self.reject)
        btn_row.addWidget(cancel)

        save = QPushButton("Save Task"); save.setStyleSheet(styles.BTN_PRIMARY)
        save.clicked.connect(self._on_save)
        btn_row.addWidget(save)

        vlay.addLayout(btn_row)

    def _prefill(self, t: dict):
        self._title.setText(t.get('title', ''))
        self._desc.setPlainText(t.get('description', ''))
        self._tag.setText(t.get('tag', ''))
        idx = self._priority.findData(t.get('priority', 'medium'))
        if idx >= 0: self._priority.setCurrentIndex(idx)
        idx = self._status.findData(t.get('status', 'pending'))
        if idx >= 0: self._status.setCurrentIndex(idx)
        self._date.setText(t.get('date_assigned', ''))
        self._time.setText(t.get('due_time', ''))

    def _on_save(self):
        if not self._title.text().strip():
            self._title.setStyleSheet(self._title.styleSheet() + "border-color:#F44336;")
            return
        self.accept()

    def result_data(self) -> dict:
        d = self._date.text().strip()
        return {
            'title':         self._title.text().strip(),
            'description':   self._desc.toPlainText().strip(),
            'tag':           self._tag.text().strip(),
            'priority':      self._priority.currentData(),
            'status':        self._status.currentData(),
            'date_assigned': d if d else _date.today().isoformat(),
            'due_time':      self._time.text().strip(),
        }
