DROP TABLE IF EXISTS social_comments;
DROP TABLE IF EXISTS social_posts;
DROP TABLE IF EXISTS social_users;
DROP TABLE IF EXISTS logistics_shipments;
DROP TABLE IF EXISTS logistics_warehouses;
DROP TABLE IF EXISTS healthcare_visits;
DROP TABLE IF EXISTS healthcare_patients;
DROP TABLE IF EXISTS finance_transactions;
DROP TABLE IF EXISTS finance_accounts;
DROP TABLE IF EXISTS hr_attendance;
DROP TABLE IF EXISTS hr_reviews;
DROP TABLE IF EXISTS sales_order_items;
DROP TABLE IF EXISTS sales_orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS sales_customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name TEXT NOT NULL UNIQUE,
    region TEXT NOT NULL
);

CREATE TABLE employees (
    employee_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    department_id INTEGER NOT NULL REFERENCES departments(department_id),
    manager_id BIGINT REFERENCES employees(employee_id),
    job_title TEXT NOT NULL,
    salary NUMERIC(12, 2) NOT NULL,
    hire_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE sales_customers (
    customer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name TEXT NOT NULL,
    segment TEXT NOT NULL,
    city TEXT NOT NULL,
    state_code TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE suppliers (
    supplier_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    country TEXT NOT NULL,
    risk_tier TEXT NOT NULL
);

CREATE TABLE products (
    product_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    product_name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    in_stock_units INTEGER NOT NULL
);

CREATE TABLE sales_orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES sales_customers(customer_id),
    employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
    order_timestamp TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL
);

CREATE TABLE sales_order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sales_orders(order_id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE hr_reviews (
    review_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
    reviewer_id BIGINT NOT NULL REFERENCES employees(employee_id),
    review_period DATE NOT NULL,
    score INTEGER NOT NULL,
    comments TEXT NOT NULL
);

CREATE TABLE hr_attendance (
    attendance_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
    attendance_date DATE NOT NULL,
    status TEXT NOT NULL,
    hours_worked NUMERIC(4, 2) NOT NULL
);

CREATE TABLE finance_accounts (
    account_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL,
    opened_on DATE NOT NULL,
    balance NUMERIC(14, 2) NOT NULL
);

CREATE TABLE finance_transactions (
    transaction_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id BIGINT NOT NULL REFERENCES finance_accounts(account_id),
    employee_id BIGINT REFERENCES employees(employee_id),
    transaction_ts TIMESTAMPTZ NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE healthcare_patients (
    patient_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL,
    city TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE healthcare_visits (
    visit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id BIGINT NOT NULL REFERENCES healthcare_patients(patient_id),
    attending_employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
    visit_ts TIMESTAMPTZ NOT NULL,
    visit_type TEXT NOT NULL,
    diagnosis_code TEXT NOT NULL,
    billing_amount NUMERIC(12, 2) NOT NULL
);

CREATE TABLE logistics_warehouses (
    warehouse_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_name TEXT NOT NULL,
    city TEXT NOT NULL,
    capacity_units INTEGER NOT NULL
);

CREATE TABLE logistics_shipments (
    shipment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id BIGINT NOT NULL REFERENCES logistics_warehouses(warehouse_id),
    employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
    customer_id BIGINT NOT NULL REFERENCES sales_customers(customer_id),
    shipped_at TIMESTAMPTZ NOT NULL,
    delivered_at TIMESTAMPTZ,
    status TEXT NOT NULL,
    weight_kg NUMERIC(10, 2) NOT NULL,
    shipping_cost NUMERIC(12, 2) NOT NULL
);

CREATE TABLE social_users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id BIGINT REFERENCES employees(employee_id),
    username TEXT NOT NULL UNIQUE,
    reputation INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE social_posts (
    post_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES social_users(user_id),
    topic TEXT NOT NULL,
    body TEXT NOT NULL,
    score INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE social_comments (
    comment_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES social_posts(post_id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES social_users(user_id),
    body TEXT NOT NULL,
    score INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_employees_department ON employees(department_id);
CREATE INDEX idx_sales_orders_customer ON sales_orders(customer_id);
CREATE INDEX idx_sales_orders_employee ON sales_orders(employee_id);
CREATE INDEX idx_sales_orders_timestamp ON sales_orders(order_timestamp);
CREATE INDEX idx_sales_order_items_order ON sales_order_items(order_id);
CREATE INDEX idx_hr_reviews_employee ON hr_reviews(employee_id);
CREATE INDEX idx_hr_attendance_employee_date ON hr_attendance(employee_id, attendance_date);
CREATE INDEX idx_finance_transactions_account_ts ON finance_transactions(account_id, transaction_ts);
CREATE INDEX idx_healthcare_visits_patient ON healthcare_visits(patient_id);
CREATE INDEX idx_healthcare_visits_ts ON healthcare_visits(visit_ts);
CREATE INDEX idx_logistics_shipments_warehouse ON logistics_shipments(warehouse_id);
CREATE INDEX idx_logistics_shipments_customer ON logistics_shipments(customer_id);
CREATE INDEX idx_social_posts_user ON social_posts(user_id);
CREATE INDEX idx_social_comments_post ON social_comments(post_id);
