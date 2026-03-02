INSERT INTO hr_reviews (employee_id, reviewer_id, review_period, score, comments)
SELECT
    ((g * 5) % 2400) + 1,
    ((g * 7) % 2400) + 1,
    DATE '2018-01-01' + ((g * 29) % 2500),
    ((g % 5) + 1),
    'Performance review cycle ' || g
FROM generate_series(1, 90000) AS gs(g);

INSERT INTO hr_attendance (employee_id, attendance_date, status, hours_worked)
SELECT
    ((g * 3) % 2400) + 1,
    DATE '2023-01-01' + ((g * 17) % 730),
    (ARRAY['PRESENT', 'REMOTE', 'VACATION', 'SICK'])[((g - 1) % 4) + 1],
    (CASE WHEN g % 4 IN (1, 2) THEN 8.0 ELSE 7.5 END)::NUMERIC(4, 2)
FROM generate_series(1, 220000) AS gs(g);
