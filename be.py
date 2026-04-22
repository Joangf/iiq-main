from flask import Flask
from flask import render_template
import sqlite3
import json

app = Flask(__name__)

# initialize db
conn = sqlite3.connect("initial.db")
cursor = conn.cursor()
with open("initial_db.sql", "r") as f:
    initial_db_str = f.read()
    cursor.executescript(initial_db_str)
conn.commit()
conn.close()

# insert data
conn = sqlite3.connect("initial.db")
cursor = conn.cursor()
cursor.execute(
    """
    INSERT OR IGNORE INTO facility (id, name, location) VALUES 
    (1, 'HN', 'Ha Noi'),
    (2, 'DN', 'Da Nang'),
    (3, 'HCM', 'Ho Chi Minh');
    """
)

conn.commit()
cursor.close()


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/q0")
def q0():
    conn = sqlite3.connect("initial.db")
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT * FROM facility;
        """
    )
    rows = cursor.fetchall()
    data = [dict(row) for row in rows]
    keys = list(data[0].keys())
    cursor.close()
    return render_template("q0.html", data=data, keys=keys)


@app.route("/q3")
def q3():
    return render_template("q3.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)