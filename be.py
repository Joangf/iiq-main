from flask import Flask, render_template, request, redirect, url_for
from psycopg2.extras import DictCursor
from psycopg2 import pool
import json
from pathlib import Path
from dotenv import load_dotenv
import os

load_dotenv(dotenv_path=".env.local")
DB_URL = os.getenv("DB_URL")
app = Flask(__name__)
db_pool = pool.ThreadedConnectionPool(5, 20, DB_URL)


def get_all_data():
    conn = db_pool.getconn()
    cursor = conn.cursor(cursor_factory=DictCursor)
    table_names = ["facility", "supplier", "product", "warehouse", "consumption"]
    tables = []

    for table_name in table_names:
        cursor.execute(f"SELECT * FROM {table_name};")
        rows = cursor.fetchall()
        data = [dict(row) for row in rows]
        keys = list(data[0].keys()) if data else []
        tables.append(
            {
                "name": table_name,
                "keys": keys,
                "data": data,
            }
        )
    cursor.close()
    db_pool.putconn(conn)
    return tables
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/q0")
def q0():
    conn = db_pool.getconn()
    cursor = conn.cursor(cursor_factory=DictCursor)
    cursor.execute(
        """
        SELECT * FROM facility;
        """
    )
    rows = cursor.fetchall()
    print(rows)
    data = [dict(row) for row in rows]
    keys = list(data[0].keys())
    cursor.close()
    db_pool.putconn(conn)
    return render_template("q0.html", data=data, keys=keys)

@app.route("/q1")
def q1():
    tables = get_all_data()
    return render_template("q1.html", tables=tables)
@app.route("/q2", methods=["GET", "POST"])
def q2():

    if request.method == "POST":
        conn = db_pool.getconn()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO facility (name, location)
            VALUES (%s, %s)
            ON CONFLICT (name)
            DO UPDATE SET location = EXCLUDED.location
            RETURNING id;
            """,
            ("SLT", "Ho Chi Minh"),
        )
        conn.commit()
        cursor.close()
        db_pool.putconn(conn)
        return redirect(url_for('q2'))

    conn = db_pool.getconn()
    cursor = conn.cursor(cursor_factory=DictCursor)
    cursor.execute("SELECT * FROM facility ORDER BY id;")
    rows = cursor.fetchall()
    data = [dict(row) for row in rows]
    keys = list(data[0].keys()) if data else []
    cursor.close()
    db_pool.putconn(conn)
    return render_template("q2.html", data=data, keys=keys)


@app.route("/q3")
def q3():
    conn = db_pool.getconn()
    cursor = conn.cursor(cursor_factory=DictCursor)
    cursor.execute("SELECT * FROM get_inventory_status('2026-04-01');")
    rows = cursor.fetchall()
    data = [dict(row) for row in rows]
    keys = list(data[0].keys()) if data else []
    cursor.close()
    db_pool.putconn(conn)
    return render_template("q3.html", data=data, keys=keys)

@app.route("/q4")
def q4():
    tables = get_all_data()
    output_path = Path("q4") / "output.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(tables, indent=2, default=str), encoding="utf-8")
    return "Data saved to q4/output.json"

if __name__ == "__main__":
    app.run(port=5000, host="0.0.0.0")