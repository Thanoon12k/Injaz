import sqlite3
import sys
import os
from datetime import date

# When bundled with PyInstaller, store data next to the .exe
# When running as a script, store next to database.py
if getattr(sys, 'frozen', False):
    APP_DIR = os.path.dirname(sys.executable)
else:
    APP_DIR = os.path.dirname(os.path.abspath(__file__))

DB_PATH = os.path.join(APP_DIR, 'injaz.db')


class Database:
    def __init__(self):
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row
        self._create_tables()

    def _create_tables(self):
        c = self.conn.cursor()
        c.executescript("""
            CREATE TABLE IF NOT EXISTS profile (
                id          INTEGER PRIMARY KEY,
                name        TEXT    NOT NULL DEFAULT 'User',
                bio         TEXT    DEFAULT '',
                image_path  TEXT    DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS tasks (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                title         TEXT    NOT NULL,
                description   TEXT    DEFAULT '',
                status        TEXT    DEFAULT 'pending',
                priority      TEXT    DEFAULT 'medium',
                tag           TEXT    DEFAULT '',
                date_assigned DATE    NOT NULL,
                due_time      TEXT    DEFAULT '',
                created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                completed_at  TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS subtasks (
                id       INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id  INTEGER NOT NULL,
                title    TEXT    NOT NULL,
                is_done  INTEGER DEFAULT 0,
                position INTEGER DEFAULT 0
            );
        """)
        self.conn.commit()

        c.execute("SELECT COUNT(*) FROM profile")
        if c.fetchone()[0] == 0:
            c.execute("INSERT INTO profile (name) VALUES ('User')")
            self.conn.commit()

    # ── Profile ──────────────────────────────────────────────────
    def get_profile(self):
        c = self.conn.cursor()
        c.execute("SELECT * FROM profile LIMIT 1")
        return dict(c.fetchone())

    def update_profile(self, name, bio='', image_path=''):
        self.conn.execute(
            "UPDATE profile SET name=?, bio=?, image_path=?",
            (name, bio, image_path)
        )
        self.conn.commit()

    # ── Tasks ─────────────────────────────────────────────────────
    def get_today_tasks(self):
        today = date.today().isoformat()
        c = self.conn.cursor()
        c.execute("""
            SELECT * FROM tasks
            WHERE date_assigned = ?
            ORDER BY
                CASE priority
                    WHEN 'urgent' THEN 1
                    WHEN 'high'   THEN 2
                    WHEN 'medium' THEN 3
                    WHEN 'low'    THEN 4
                END,
                created_at DESC
        """, (today,))
        return [dict(r) for r in c.fetchall()]

    def get_uncompleted_past_tasks(self):
        today = date.today().isoformat()
        c = self.conn.cursor()
        c.execute("""
            SELECT * FROM tasks
            WHERE date_assigned < ? AND status != 'completed'
            ORDER BY date_assigned DESC
        """, (today,))
        return [dict(r) for r in c.fetchall()]

    def get_all_tasks(self):
        c = self.conn.cursor()
        c.execute("SELECT * FROM tasks ORDER BY date_assigned DESC, created_at DESC")
        return [dict(r) for r in c.fetchall()]

    def add_task(self, title, description='', status='pending', priority='medium',
                 tag='', date_assigned=None, due_time=''):
        if date_assigned is None:
            date_assigned = date.today().isoformat()
        c = self.conn.cursor()
        c.execute("""
            INSERT INTO tasks (title, description, status, priority, tag, date_assigned, due_time)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (title, description, status, priority, tag, date_assigned, due_time))
        self.conn.commit()
        return c.lastrowid

    def update_task(self, task_id, **kwargs):
        if not kwargs:
            return
        set_clause = ', '.join(f"{k}=?" for k in kwargs)
        values = list(kwargs.values()) + [task_id]
        self.conn.execute(f"UPDATE tasks SET {set_clause} WHERE id=?", values)
        self.conn.commit()

    def set_status(self, task_id, status):
        if status == 'completed':
            self.conn.execute(
                "UPDATE tasks SET status=?, completed_at=CURRENT_TIMESTAMP WHERE id=?",
                (status, task_id)
            )
        else:
            self.conn.execute(
                "UPDATE tasks SET status=?, completed_at=NULL WHERE id=?",
                (status, task_id)
            )
        self.conn.commit()

    def move_to_today(self, task_id):
        today = date.today().isoformat()
        self.conn.execute("UPDATE tasks SET date_assigned=? WHERE id=?", (today, task_id))
        self.conn.commit()

    def delete_task(self, task_id):
        self.conn.execute("DELETE FROM subtasks WHERE task_id=?", (task_id,))
        self.conn.execute("DELETE FROM tasks WHERE id=?", (task_id,))
        self.conn.commit()

    # ── Subtasks ──────────────────────────────────────────────────
    def get_subtasks(self, task_id):
        c = self.conn.cursor()
        c.execute("SELECT * FROM subtasks WHERE task_id=? ORDER BY position, id", (task_id,))
        return [dict(r) for r in c.fetchall()]

    def get_subtask_counts(self, task_id):
        c = self.conn.cursor()
        c.execute("SELECT COUNT(*), SUM(is_done) FROM subtasks WHERE task_id=?", (task_id,))
        row = c.fetchone()
        return (row[0] or 0), (row[1] or 0)

    def add_subtask(self, task_id, title, position=0):
        c = self.conn.cursor()
        c.execute("INSERT INTO subtasks (task_id, title, position) VALUES (?,?,?)",
                  (task_id, title, position))
        self.conn.commit()
        return c.lastrowid

    def set_subtask_done(self, subtask_id, is_done):
        self.conn.execute("UPDATE subtasks SET is_done=? WHERE id=?",
                          (int(is_done), subtask_id))
        self.conn.commit()

    def delete_subtask(self, subtask_id):
        self.conn.execute("DELETE FROM subtasks WHERE id=?", (subtask_id,))
        self.conn.commit()

    def close(self):
        self.conn.close()
