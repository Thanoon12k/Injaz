# ── Palette ───────────────────────────────────────────────────────────────────
PRIMARY        = '#00BCD4'
PRIMARY_LIGHT  = '#4DD0E1'
PRIMARY_DARK   = '#0097A7'
PRIMARY_DARKER = '#006064'
SIDEBAR_BG     = '#00838F'
SIDEBAR_ACTIVE = '#006064'
SUCCESS        = '#4CAF50'
WARNING        = '#FF9800'
ERROR          = '#F44336'
WHITE          = '#FFFFFF'
TEXT_DARK      = '#212121'
TEXT_GREY      = '#757575'
TEXT_LIGHT     = '#BDBDBD'
CARD_BG        = '#FFFFFF'
INPUT_BG       = 'rgba(255,255,255,220)'

PRIORITY_COLOR = {
    'urgent': '#F44336',
    'high':   '#FF9800',
    'medium': '#2196F3',
    'low':    '#9E9E9E',
}

STATUS_COLOR = {
    'completed':   '#4CAF50',
    'in_progress': '#FF9800',
    'pending':     '#BDBDBD',
}

STATUS_LABEL = {
    'completed':   'Completed',
    'in_progress': 'In Progress',
    'pending':     'Pending',
}

# ── Shared QSS snippets ────────────────────────────────────────────────────────
BTN_PRIMARY = f"""
QPushButton {{
    background-color: {PRIMARY};
    color: white;
    border: none;
    border-radius: 8px;
    padding: 10px 24px;
    font-size: 17px;
    font-weight: 600;
}}
QPushButton:hover   {{ background-color: {PRIMARY_DARK}; }}
QPushButton:pressed {{ background-color: {PRIMARY_DARKER}; }}
"""

BTN_SECONDARY = """
QPushButton {
    background-color: #F5F5F5;
    color: #757575;
    border: none;
    border-radius: 8px;
    padding: 10px 24px;
    font-size: 17px;
}
QPushButton:hover { background-color: #EEEEEE; }
"""

BTN_DANGER = """
QPushButton {
    background-color: #FFEBEE;
    color: #F44336;
    border: none;
    border-radius: 8px;
    padding: 10px 24px;
    font-size: 17px;
    font-weight: 600;
}
QPushButton:hover { background-color: #FFCDD2; }
"""

FIELD = f"""
QLineEdit, QTextEdit, QComboBox {{
    border: 2px solid #E0E0E0;
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 17px;
    color: {TEXT_DARK};
    background-color: #FAFAFA;
}}
QLineEdit:focus, QTextEdit:focus, QComboBox:focus {{
    border-color: {PRIMARY};
    background-color: {WHITE};
}}
QComboBox::drop-down {{ border: none; width: 24px; }}
QComboBox QAbstractItemView {{
    border: 1px solid #E0E0E0;
    border-radius: 4px;
    selection-background-color: #E0F7FA;
}}
"""
