INSERT INTO logistics_warehouses (warehouse_name, city, capacity_units)
SELECT
    'Warehouse ' || g,
    (ARRAY['Dallas', 'Denver', 'Atlanta', 'Portland', 'Nashville', 'Miami'])[((g - 1) % 6) + 1],
    50000 + ((g * 137) % 90000)
FROM generate_series(1, 120) AS gs(g);

INSERT INTO logistics_shipments (
    warehouse_id,
    employee_id,
    customer_id,
    shipped_at,
    delivered_at,
    status,
    weight_kg,
    shipping_cost
)
SELECT
    ((g * 3) % 120) + 1,
    ((g * 7) % 2400) + 1,
    ((g * 11) % 30000) + 1,
    NOW() - ((g % 900) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL,
    NOW() - ((g % 900) || ' days')::INTERVAL + (((g % 120) + 2) || ' hours')::INTERVAL,
    (ARRAY['IN_TRANSIT', 'DELIVERED', 'DELAYED', 'RETURNED'])[((g - 1) % 4) + 1],
    (5 + ((g * 17) % 900) / 10.0)::NUMERIC(10, 2),
    (12 + ((g * 23) % 5000) / 10.0)::NUMERIC(12, 2)
FROM generate_series(1, 240000) AS gs(g);
