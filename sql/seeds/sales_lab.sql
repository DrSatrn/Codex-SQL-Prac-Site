INSERT INTO sales_orders (
    customer_id,
    employee_id,
    order_timestamp,
    status,
    payment_method,
    total_amount
)
SELECT
    ((g * 7) % 30000) + 1,
    ((g * 11) % 2400) + 1,
    NOW() - ((g % 900) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL,
    (ARRAY['NEW', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'])[((g - 1) % 5) + 1],
    (ARRAY['CARD', 'ACH', 'WIRE', 'INVOICE'])[((g - 1) % 4) + 1],
    0
FROM generate_series(1, 180000) AS gs(g);

INSERT INTO sales_order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    ((o.order_id * i.item_idx * 13) % 4000) + 1,
    ((o.order_id + i.item_idx) % 8) + 1,
    p.unit_price
FROM sales_orders o
CROSS JOIN LATERAL generate_series(1, ((o.order_id % 4) + 1)::INTEGER) AS i(item_idx)
JOIN products p ON p.product_id = ((o.order_id * i.item_idx * 13) % 4000) + 1;

UPDATE sales_orders so
SET total_amount = totals.total
FROM (
    SELECT order_id, SUM(quantity * unit_price)::NUMERIC(12, 2) AS total
    FROM sales_order_items
    GROUP BY order_id
) AS totals
WHERE totals.order_id = so.order_id;
