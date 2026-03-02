INSERT INTO finance_accounts (account_name, account_type, opened_on, balance)
SELECT
    'Account ' || g,
    (ARRAY['Asset', 'Liability', 'Revenue', 'Expense'])[((g - 1) % 4) + 1],
    DATE '2014-01-01' + ((g * 13) % 3500),
    ((g * 701) % 950000)::NUMERIC(14, 2)
FROM generate_series(1, 18000) AS gs(g);

INSERT INTO finance_transactions (
    account_id,
    employee_id,
    transaction_ts,
    amount,
    category,
    description
)
SELECT
    ((g * 17) % 18000) + 1,
    ((g * 5) % 2400) + 1,
    NOW() - ((g % 1200) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL,
    (((g * 97) % 180000) - 90000)::NUMERIC(12, 2),
    (ARRAY['PAYROLL', 'TRAVEL', 'INFRA', 'SALES', 'TAX', 'OPERATIONS'])[((g - 1) % 6) + 1],
    'Ledger movement ' || g
FROM generate_series(1, 260000) AS gs(g);
