INSERT INTO departments (department_name, region)
VALUES
    ('Sales', 'North America'),
    ('Operations', 'North America'),
    ('Finance', 'Europe'),
    ('Human Resources', 'Europe'),
    ('Engineering', 'Asia Pacific'),
    ('Data', 'Asia Pacific'),
    ('Marketing', 'North America'),
    ('Legal', 'Europe'),
    ('Support', 'Asia Pacific'),
    ('Clinical', 'North America'),
    ('Logistics', 'Europe'),
    ('Procurement', 'Asia Pacific');

INSERT INTO employees (
    first_name,
    last_name,
    email,
    department_id,
    manager_id,
    job_title,
    salary,
    hire_date,
    is_active
)
SELECT
    'First' || g,
    'Last' || g,
    'employee' || g || '@example.com',
    ((g - 1) % 12) + 1,
    CASE WHEN g <= 24 THEN NULL ELSE ((g - 1) % 24) + 1 END,
    (ARRAY['Analyst', 'Senior Analyst', 'Manager', 'Lead', 'Specialist', 'Coordinator'])[((g - 1) % 6) + 1],
    (55000 + ((g - 1) % 40) * 1800)::NUMERIC(12, 2),
    DATE '2012-01-01' + (((g - 1) * 13) % 5000),
    (g % 31) <> 0
FROM generate_series(1, 2400) AS gs(g);

INSERT INTO sales_customers (customer_name, segment, city, state_code, created_at)
SELECT
    'Customer ' || g,
    (ARRAY['Enterprise', 'SMB', 'Mid-Market', 'Public Sector'])[((g - 1) % 4) + 1],
    (ARRAY['Austin', 'Seattle', 'Chicago', 'Boston', 'Phoenix', 'San Diego'])[((g - 1) % 6) + 1],
    (ARRAY['TX', 'WA', 'IL', 'MA', 'AZ', 'CA'])[((g - 1) % 6) + 1],
    NOW() - ((g % 2200) || ' days')::INTERVAL
FROM generate_series(1, 30000) AS gs(g);

INSERT INTO suppliers (supplier_name, country, risk_tier)
SELECT
    'Supplier ' || g,
    (ARRAY['United States', 'Canada', 'Germany', 'Japan', 'India', 'Australia'])[((g - 1) % 6) + 1],
    (ARRAY['Low', 'Medium', 'High'])[((g - 1) % 3) + 1]
FROM generate_series(1, 300) AS gs(g);

INSERT INTO products (supplier_id, product_name, category, unit_price, in_stock_units)
SELECT
    ((g - 1) % 300) + 1,
    'Product ' || g,
    (ARRAY['Software', 'Hardware', 'Services', 'Medical', 'Transport', 'Media'])[((g - 1) % 6) + 1],
    (15 + ((g - 1) % 500) * 1.37)::NUMERIC(10, 2),
    20 + ((g - 1) % 400)
FROM generate_series(1, 4000) AS gs(g);
