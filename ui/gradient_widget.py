import random
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import Qt, QTimer, QRectF
from PyQt5.QtGui import QPainter, QColor, QLinearGradient, QBrush


class _Bubble:
    def __init__(self, w, h):
        self.reset(w, h, initial=True)

    def reset(self, w, h, initial=False):
        self.r = random.uniform(12, 55)
        self.x = random.uniform(0, max(w, 1))
        self.y = random.uniform(0, max(h, 1)) if initial else h + self.r
        self.speed = random.uniform(0.4, 1.4)
        self.alpha = random.uniform(0.05, 0.18)


class GradientWidget(QWidget):
    """Animated teal gradient background with floating bubbles."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self._bubbles: list[_Bubble] = []
        self._w = self._h = 1

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        self._timer.start(40)  # ~25 fps

    def _init_bubbles(self):
        self._bubbles = [_Bubble(self._w, self._h) for _ in range(14)]

    def _tick(self):
        for b in self._bubbles:
            b.y -= b.speed
            if b.y + b.r < 0:
                b.reset(self._w, self._h)
        self.update()

    # ── Qt overrides ──────────────────────────────────────────────
    def resizeEvent(self, event):
        super().resizeEvent(event)
        self._w, self._h = self.width(), self.height()
        if not self._bubbles:
            self._init_bubbles()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.Antialiasing)

        # gradient
        g = QLinearGradient(0, 0, 0, self._h)
        g.setColorAt(0.0, QColor('#4DD0E1'))
        g.setColorAt(0.5, QColor('#00BCD4'))
        g.setColorAt(1.0, QColor('#006064'))
        p.fillRect(self.rect(), g)

        # bubbles
        p.setPen(Qt.NoPen)
        for b in self._bubbles:
            c = QColor(255, 255, 255)
            c.setAlphaF(b.alpha)
            p.setBrush(QBrush(c))
            p.drawEllipse(QRectF(b.x - b.r, b.y - b.r, b.r * 2, b.r * 2))

        p.end()
