from PyQt5.QtWidgets import (
    QFrame, QHBoxLayout, QVBoxLayout, QLabel,
    QPushButton, QSizePolicy, QMenu, QCheckBox,
    QLineEdit, QWidget
)
from PyQt5.QtCore import Qt, pyqtSignal
from PyQt5.QtGui import QFont, QCursor
import styles


def _badge(text, bg, fg='#FFFFFF'):
    lbl = QLabel(text)
    lbl.setStyleSheet(f"""
        background:{bg}; color:{fg};
        border-radius:9px; padding:2px 9px;
        font-size:14px; font-weight:700;
    """)
    return lbl


class ChecklistItem(QWidget):
    toggled = pyqtSignal(int, bool)
    deleted = pyqtSignal(int)

    def __init__(self, subtask: dict, parent=None):
        super().__init__(parent)
        self.subtask = subtask
        self._build()

    def _build(self):
        lay = QHBoxLayout(self)
        lay.setContentsMargins(0, 2, 0, 2)
        lay.setSpacing(8)

        cb = QCheckBox()
        cb.setChecked(bool(self.subtask['is_done']))
        cb.setStyleSheet("""
            QCheckBox { spacing: 0px; }
            QCheckBox::indicator {
                width:18px; height:18px;
                border:2px solid #B2EBF2; border-radius:4px;
                background:white;
            }
            QCheckBox::indicator:checked {
                background:#4CAF50; border-color:#4CAF50;
            }
        """)
        cb.toggled.connect(lambda c: self.toggled.emit(self.subtask['id'], c))
        lay.addWidget(cb)

        done = bool(self.subtask['is_done'])
        style = "color:#BDBDBD; font-size:14px; text-decoration:line-through;" \
                if done else "color:#212121; font-size:14px;"
        lbl = QLabel(self.subtask['title'])
        lbl.setStyleSheet(style)
        lbl.setWordWrap(True)
        lay.addWidget(lbl, 1)

        del_btn = QPushButton("✕")
        del_btn.setFixedSize(22, 22)
        del_btn.setStyleSheet("""
            QPushButton { background:transparent; color:#BDBDBD;
                          border:none; font-size:13px; }
            QPushButton:hover { color:#F44336; }
        """)
        del_btn.clicked.connect(lambda: self.deleted.emit(self.subtask['id']))
        lay.addWidget(del_btn)


class TaskCard(QFrame):
    status_changed       = pyqtSignal(int, str)
    edit_requested       = pyqtSignal(int)
    delete_requested     = pyqtSignal(int)
    move_today_requested = pyqtSignal(int)

    def __init__(self, task: dict, db, show_date: bool = False, parent=None):
        super().__init__(parent)
        self.task      = task
        self.db        = db
        self.show_date = show_date
        self._expanded = False
        self.setObjectName("task_card")
        self._build()

    # ── Build ──────────────────────────────────────────────────────
    def _build(self):
        t     = self.task
        pri   = t.get('priority', 'medium')
        stat  = t.get('status',   'pending')
        color = styles.PRIORITY_COLOR.get(pri, '#9E9E9E')

        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Preferred)
        self.setStyleSheet("""
            QFrame#task_card { background:white; border-radius:12px; }
            QFrame#task_card:hover { background:#F5FEFF; }
        """)

        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        # ── main row ──
        main = QHBoxLayout()
        main.setContentsMargins(0, 0, 12, 0)
        main.setSpacing(0)

        # priority bar
        bar = QFrame()
        bar.setFixedWidth(6)
        bar.setStyleSheet(f"QFrame{{background:{color}; border-top-left-radius:12px;"
                          f"border-bottom-left-radius:12px;}}")
        main.addWidget(bar)

        # content
        cv = QVBoxLayout()
        cv.setContentsMargins(12, 10, 0, 10)
        cv.setSpacing(5)

        # row1: title + expand btn + time
        r1 = QHBoxLayout()
        title_lbl = QLabel(t.get('title', ''))
        f = QFont(); f.setPointSize(15); f.setBold(True)
        title_lbl.setFont(f)
        title_lbl.setStyleSheet(
            f"color:{'#BDBDBD' if stat=='completed' else styles.TEXT_DARK};"
        )
        r1.addWidget(title_lbl)

        # checklist expand toggle
        self._toggle_btn = QPushButton("▸ checklist")
        self._toggle_btn.setCheckable(True)
        self._toggle_btn.setStyleSheet("""
            QPushButton {
                background:transparent; color:#00BCD4;
                border:none; font-size:12px; padding:0 6px;
            }
            QPushButton:checked { color:#006064; }
            QPushButton:hover   { text-decoration:underline; }
        """)
        self._toggle_btn.clicked.connect(self._toggle_checklist)
        r1.addWidget(self._toggle_btn)

        r1.addStretch()
        if t.get('due_time'):
            r1.addWidget(QLabel(f"🕐 {t['due_time']}",
                                styleSheet="color:#9E9E9E;font-size:15px;"))
        if self.show_date and t.get('date_assigned'):
            r1.addWidget(QLabel(t['date_assigned'],
                                styleSheet="color:#BDBDBD;font-size:14px;"))
        cv.addLayout(r1)

        # row2: desc + badges
        r2 = QHBoxLayout(); r2.setSpacing(6)
        if t.get('description'):
            desc  = t['description']
            short = (desc[:45] + '…') if len(desc) > 45 else desc
            r2.addWidget(QLabel(short, styleSheet="color:#9E9E9E;font-size:15px;"))
        r2.addStretch()
        if t.get('tag'):
            r2.addWidget(_badge(t['tag'], '#E0F7FA', '#00838F'))
        r2.addWidget(_badge(pri.capitalize(), styles.PRIORITY_COLOR.get(pri, '#9E9E9E')))
        r2.addWidget(_badge(styles.STATUS_LABEL.get(stat, stat),
                            styles.STATUS_COLOR.get(stat, '#BDBDBD')))

        # subtask progress
        self._prog_badge = QLabel()
        self._prog_badge.setVisible(False)
        r2.addWidget(self._prog_badge)
        self._refresh_progress_badge()

        cv.addLayout(r2)
        main.addLayout(cv)

        # status cycle button
        self._btn = QPushButton()
        self._btn.setFixedSize(40, 40)
        self._update_btn_style()
        self._btn.clicked.connect(self._cycle_status)
        main.addWidget(self._btn)

        outer.addLayout(main)

        # ── Checklist section (collapsed) ──
        self._cl_frame = QFrame()
        self._cl_frame.setStyleSheet("""
            QFrame {
                background:#F0FAFA;
                border-top:1px solid #B2EBF2;
                border-bottom-left-radius:12px;
                border-bottom-right-radius:12px;
            }
        """)
        self._cl_frame.setVisible(False)

        cl_lay = QVBoxLayout(self._cl_frame)
        cl_lay.setContentsMargins(24, 8, 16, 10)
        cl_lay.setSpacing(3)

        self._items_layout = QVBoxLayout()
        self._items_layout.setSpacing(2)
        cl_lay.addLayout(self._items_layout)

        # add-item row
        add_row = QHBoxLayout(); add_row.setSpacing(6)
        self._new_input = QLineEdit()
        self._new_input.setPlaceholderText("Add checklist item…")
        self._new_input.setFixedHeight(34)
        self._new_input.setStyleSheet("""
            QLineEdit {
                border:1px solid #B2EBF2; border-radius:6px;
                padding:2px 10px; font-size:14px; background:white;
            }
            QLineEdit:focus { border-color:#00BCD4; }
        """)
        self._new_input.returnPressed.connect(self._add_item)
        add_row.addWidget(self._new_input)

        add_btn = QPushButton("+")
        add_btn.setFixedSize(34, 34)
        add_btn.setStyleSheet(f"""
            QPushButton {{
                background:{styles.PRIMARY}; color:white;
                border:none; border-radius:6px; font-size:20px;
            }}
            QPushButton:hover {{ background:{styles.PRIMARY_DARK}; }}
        """)
        add_btn.clicked.connect(self._add_item)
        add_row.addWidget(add_btn)
        cl_lay.addLayout(add_row)

        outer.addWidget(self._cl_frame)

    # ── Checklist helpers ─────────────────────────────────────────
    def _toggle_checklist(self, checked: bool):
        self._expanded = checked
        self._toggle_btn.setText("▾ checklist" if checked else "▸ checklist")
        self._cl_frame.setVisible(checked)
        if checked:
            self._load_checklist()

    def _load_checklist(self):
        while self._items_layout.count():
            item = self._items_layout.takeAt(0)
            if item.widget(): item.widget().deleteLater()
        for st in self.db.get_subtasks(self.task['id']):
            w = ChecklistItem(st, self)
            w.toggled.connect(self._on_toggle)
            w.deleted.connect(self._on_delete_sub)
            self._items_layout.addWidget(w)

    def _add_item(self):
        text = self._new_input.text().strip()
        if not text: return
        self.db.add_subtask(self.task['id'], text)
        self._new_input.clear()
        self._load_checklist()
        self._refresh_progress_badge()

    def _on_toggle(self, sub_id: int, done: bool):
        self.db.set_subtask_done(sub_id, done)
        self._refresh_progress_badge()

    def _on_delete_sub(self, sub_id: int):
        self.db.delete_subtask(sub_id)
        self._load_checklist()
        self._refresh_progress_badge()

    def _refresh_progress_badge(self):
        total, done = self.db.get_subtask_counts(self.task['id'])
        if total > 0:
            color = '#4CAF50' if done == total else '#FF9800'
            self._prog_badge.setText(f"☑ {done}/{total}")
            self._prog_badge.setStyleSheet(f"""
                background:{color}; color:white;
                border-radius:9px; padding:2px 9px;
                font-size:14px; font-weight:700;
            """)
            self._prog_badge.setVisible(True)
        else:
            self._prog_badge.setVisible(False)

    # ── Status ────────────────────────────────────────────────────
    def _update_btn_style(self):
        stat  = self.task.get('status', 'pending')
        s_col = styles.STATUS_COLOR.get(stat, '#BDBDBD')
        icon  = {'completed': '✓', 'in_progress': '⟳', 'pending': '○'}.get(stat, '○')
        self._btn.setText(icon)
        self._btn.setStyleSheet(f"""
            QPushButton {{
                background:{s_col}; color:white;
                border:none; border-radius:20px;
                font-size:17px; font-weight:bold;
            }}
        """)

    def _cycle_status(self):
        order = ['pending', 'in_progress', 'completed']
        cur   = self.task.get('status', 'pending')
        nxt   = order[(order.index(cur) + 1) % len(order)]
        self.task['status'] = nxt
        self._update_btn_style()
        self.status_changed.emit(self.task['id'], nxt)

    # ── Context menu ──────────────────────────────────────────────
    def contextMenuEvent(self, event):
        menu = QMenu(self)
        menu.setStyleSheet("""
            QMenu { background:white; border:1px solid #E0E0E0;
                    border-radius:8px; padding:4px; }
            QMenu::item { padding:8px 20px; font-size:15px; border-radius:4px; }
            QMenu::item:selected { background:#E0F7FA; color:#00838F; }
        """)
        a_edit   = menu.addAction("✏️  Edit")
        a_move   = menu.addAction("📅  Move to Today")
        menu.addSeparator()
        a_delete = menu.addAction("🗑️  Delete")
        act = menu.exec_(event.globalPos())
        if act == a_edit:     self.edit_requested.emit(self.task['id'])
        elif act == a_move:   self.move_today_requested.emit(self.task['id'])
        elif act == a_delete: self.delete_requested.emit(self.task['id'])
