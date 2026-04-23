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


CREATE OR REPLACE FUNCTION get_inventory_status(ref_date DATE DEFAULT '2026-04-01')
RETURNS TABLE (
    "Facility" VARCHAR,
    "Product" VARCHAR,
    "Supplier" VARCHAR,
    "Remain Quantity" BIGINT,
    "Overdue Quantity" BIGINT,
    "Need Import" TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Bước 1: Map mỗi lần tiêu thụ vào lô hàng warehouse tương ứng (Lô hàng nhập gần nhất trước khi xuất)
    WITH ConsumptionMapped AS (
        SELECT 
            c.quantity AS order_quantity,
            (
                SELECT w.id 
                FROM warehouse w
                WHERE w.facility_id = c.facility_id 
                  AND w.product_id = c.product_id
                  AND w.import_date <= c.order_date
                ORDER BY w.import_date DESC 
                LIMIT 1
            ) AS warehouse_id
        FROM consumption c
    ),
    -- Bước 2: Tính tổng lượng đã xuất (order) cho từng lô hàng warehouse
    OrderSums AS (
        SELECT 
            warehouse_id, 
            SUM(order_quantity) AS sum_order_quantity
        FROM ConsumptionMapped
        WHERE warehouse_id IS NOT NULL
        GROUP BY warehouse_id
    ),
    -- Bước 3: Tính toán Remain và Overdue cho từng lô hàng so với ref_date
    Temp1 AS (
        SELECT 
            w.facility_id,
            w.product_id,
            -- Nếu lô hàng đã hết hạn trước ngày mốc, toàn bộ số lượng còn lại thành overdue, remain = 0
            CASE 
                WHEN w.exp_date < ref_date THEN 0
                ELSE w.quantity - COALESCE(os.sum_order_quantity, 0) 
            END AS remain_quantity,
            CASE 
                WHEN w.exp_date < ref_date THEN w.quantity - COALESCE(os.sum_order_quantity, 0) 
                ELSE 0 
            END AS overdue_quantity
        FROM warehouse w
        LEFT JOIN OrderSums os ON w.id = os.warehouse_id
    )
    -- Bước 4: Tổng hợp lại kết quả cuối cùng theo Facility và Product
    SELECT 
        f.name AS "Facility",
        p.name AS "Product",
        s.name AS "Supplier",
        SUM(t.remain_quantity)::BIGINT AS "Remain Quantity",
        SUM(t.overdue_quantity)::BIGINT AS "Overdue Quantity",
        CASE 
            WHEN SUM(t.remain_quantity) < 100 THEN 'Yes'
            ELSE 'No'
        END AS "Need Import"
    FROM Temp1 t
    JOIN facility f ON t.facility_id = f.id
    JOIN product p ON t.product_id = p.id
    JOIN supplier s ON p.supplier_id = s.id
    GROUP BY f.name, p.name, s.name
    ORDER BY "Facility" DESC, "Product" DESC;
END;
$$ LANGUAGE plpgsql;