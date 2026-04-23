# IIQ Main Project

This project is a small Flask + PostgreSQL application for the Ampere Computing SLT internship interview. It provides a simple web interface for inspecting the seeded database, submitting a facility, running the inventory status query, and exporting all database content to JSON.

## Tech Stack

- Python 3.9
- Flask
- PostgreSQL 16
- HTML / CSS
- Docker and Docker Compose

## Project Structure

- `be.py`: Flask backend and route handlers
- `initial_db.sql`: database schema, seed data, and the inventory status function
- `templates/`: Jinja2 pages for each question
- `static/css/`: page styling
- `compose.yml`: container setup for the web app and database
- `q4/`: JSON export output directory

## How To Run

1. Start the application with Docker Compose:

	```bash
	docker compose up -d --build
	```

2. Open the application in the browser:

	- `http://localhost:5000/`
	- `http://localhost:5000/q0`
	- `http://localhost:5000/q1`
	- `http://localhost:5000/q2`
	- `http://localhost:5000/q3`
	- `http://localhost:5000/q4`

3. The first time the database container starts, PostgreSQL runs `initial_db.sql` automatically and creates the schema, sample data, and the `get_inventory_status` function.

## Implemented Questions

### Q1 - Show All Data

The `/q1` endpoint reads every main table from the database and renders them in separate HTML tables. This gives a full view of the current dataset after initialization or any later changes.

### Q2 - Submit a New Facility

The `/q2` endpoint shows a form with the facility name set to `SLT` and the location set to `Ho Chi Minh`. Submitting the form inserts the facility into the `facility` table, and the backend uses an upsert pattern so the same facility name does not create duplicates.

### Q3 - Inventory Status Query

The `/q3` endpoint executes `get_inventory_status('2026-04-01')` and renders the result table. The function determines which facilities need more stock by combining warehouse, consumption, product, supplier, and expiration-date data.

### Q4 - Export Database To JSON

The optional `/q4` endpoint collects the content of the main tables and writes them into `q4/output.json`. The directory is mounted through Docker Compose so the exported file stays available on the host machine.

## Strategy

The implementation follows a simple separation of responsibilities:

- Seed and schema setup live in `initial_db.sql`, so the database can be recreated consistently from Docker.
- Flask routes are kept thin and only coordinate data retrieval, insertion, and rendering.
- Templates are responsible for presentation only, which keeps the backend logic easy to read.
- The Q3 logic is pushed into a PostgreSQL function so the inventory calculation stays close to the data and can be reused directly from SQL.
- Q4 writes one JSON snapshot for all main tables into a single directory so the output can be mounted and inspected from outside the container.

## Notes

- Database connection settings are read from `.env.local` through `python-dotenv`.
- The app listens on port `5000` and is exposed through Docker Compose.
- The project is designed to be easy to rebuild from scratch: start the containers, load the seed data, and open the matching endpoint for each question.
