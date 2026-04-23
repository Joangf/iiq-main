CREATE TABLE IF NOT EXISTS facility (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR UNIQUE,
    location VARCHAR
);

CREATE TABLE IF NOT EXISTS supplier (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR UNIQUE,
    location VARCHAR
);

CREATE TABLE IF NOT EXISTS product (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR UNIQUE,
    category_name VARCHAR,
    supplier_id INTEGER,
    FOREIGN KEY (supplier_id) REFERENCES supplier (id)
);

CREATE TABLE IF NOT EXISTS warehouse (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    facility_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    import_date DATE,
    exp_date DATE,
    FOREIGN KEY (facility_id) REFERENCES facility (id),
    FOREIGN KEY (product_id) REFERENCES product (id)
);

CREATE TABLE IF NOT EXISTS consumption (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    facility_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    order_date DATE,
    FOREIGN KEY (facility_id) REFERENCES facility (id),
    FOREIGN KEY (product_id) REFERENCES product (id)
);
INSERT INTO facility (name, location) VALUES 
    ( 'HN', 'Ha Noi'),
    ( 'DN', 'Da Nang'),
    ( 'HCM', 'Ho Chi Minh');

INSERT INTO supplier (name, location) VALUES
    ( 'North', 'Ha Noi'),
    ( 'Central', 'Da Nang'),
    ( 'South', 'Ho Chi Minh');

INSERT INTO product (name, category_name, supplier_id) VALUES
    ( 'APW', 'Watch', 1),
    ( 'APW Pro', 'Watch', 1),
    ( 'AA', 'CPU', 2),
    ( 'AAM', 'CPU', 2),
    ( 'VNM', 'Milk', 3),
    ( 'TH', 'Milk', 3);

INSERT INTO warehouse (facility_id, product_id, quantity, import_date, exp_date) VALUES
    ( 1, 5, 100, '2026-03-01', '2026-06-01'),
    ( 1, 6, 200, '2026-03-01', '2026-06-01'),
    ( 3, 5, 200, '2026-03-01', '2026-06-01'),
    ( 3, 6, 100, '2026-03-01', '2026-06-01'),
    ( 2, 5, 500, '2025-09-01', '2026-01-01'),
    ( 2, 5, 100, '2026-02-01', '2026-05-01');

INSERT INTO consumption (facility_id, product_id, quantity, order_date) VALUES
    ( 1, 5, 50, '2026-03-01'),
    ( 1, 6, 50, '2026-03-01'),
    ( 3, 5, 50, '2026-04-01'),
    ( 3, 6, 50, '2026-04-01'),
    ( 2, 5, 200, '2025-11-01'),
    ( 2, 5, 300, '2026-04-01'),
    ( 2, 5, 50, '2025-12-01');


CREATE OR REPLACE FUNCTION get_inventory_status(p_ref_date DATE)
RETURNS TABLE (
    "Facility" VARCHAR,
    "Product" VARCHAR,
    "Supplier" VARCHAR,
    "Remain Quantity" BIGINT,
    "Overdue Quantity" BIGINT,
    "Need Import" VARCHAR
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH wh AS (
        SELECT
            w.id,
            f.name AS facility,
            p.name AS product,
            s.name AS supplier,
            w.quantity AS import_quantity,
            w.import_date,
            w.exp_date,
            COALESCE((
                SELECT SUM(c.quantity)
                FROM consumption c
                WHERE c.facility_id = w.facility_id
                  AND c.product_id = w.product_id
                  AND c.order_date >= w.import_date
                  AND c.order_date <= p_ref_date
            ), 0) AS consumed_to_ref
        FROM warehouse w
        JOIN facility f ON f.id = w.facility_id
        JOIN product p ON p.id = w.product_id
        JOIN supplier s ON s.id = p.supplier_id
    ),
    lot_status AS (
        SELECT
            facility,
            product,
            supplier,
            CASE
                WHEN exp_date >= p_ref_date THEN import_quantity - consumed_to_ref
                ELSE 0
            END AS remain_qty,
            CASE
                WHEN exp_date < p_ref_date THEN import_quantity - consumed_to_ref
                ELSE 0
            END AS overdue_qty
        FROM wh
    )
    SELECT
        ls.facility::VARCHAR,
        ls.product::VARCHAR,
        ls.supplier::VARCHAR,
        SUM(ls.remain_qty)::BIGINT AS "Remain Quantity",
        SUM(ls.overdue_qty)::BIGINT AS "Overdue Quantity",
        CASE
            WHEN SUM(ls.remain_qty) < 100 THEN 'Yes'::VARCHAR
            ELSE 'No'::VARCHAR
        END AS "Need Import"
    FROM lot_status ls
    GROUP BY ls.facility, ls.product, ls.supplier
    ORDER BY ls.facility DESC, ls.product DESC;
END;
$$;