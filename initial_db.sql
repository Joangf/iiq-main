CREATE TABLE IF NOT EXISTS facility (
    id INTEGER PRIMARY KEY,
    name VARCHAR UNIQUE,
    location VARCHAR
);

CREATE TABLE IF NOT EXISTS supplier (
    id INTEGER PRIMARY KEY,
    name VARCHAR UNIQUE,
    location VARCHAR
);

CREATE TABLE IF NOT EXISTS product (
    id INTEGER PRIMARY KEY,
    name VARCHAR UNIQUE,
    category_name VARCHAR,
    supplier_id INTEGER,
    FOREIGN KEY (supplier_id) REFERENCES supplier (id)
);

CREATE TABLE IF NOT EXISTS warehouse (
    id INTEGER PRIMARY KEY,
    facility_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    import_date DATE,
    exp_date DATE,
    FOREIGN KEY (facility_id) REFERENCES facility (id),
    FOREIGN KEY (product_id) REFERENCES product (id)
);

CREATE TABLE IF NOT EXISTS consumption (
    id INTEGER,
    facility_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    order_date DATE,
    FOREIGN KEY (facility_id) REFERENCES facility (id),
    FOREIGN KEY (product_id) REFERENCES product (id)
);