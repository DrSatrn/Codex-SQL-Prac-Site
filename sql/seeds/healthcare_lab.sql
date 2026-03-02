INSERT INTO healthcare_patients (
    first_name,
    last_name,
    date_of_birth,
    gender,
    city,
    created_at
)
SELECT
    'PatientFirst' || g,
    'PatientLast' || g,
    DATE '1945-01-01' + ((g * 11) % 26000),
    (ARRAY['F', 'M', 'X'])[((g - 1) % 3) + 1],
    (ARRAY['Brisbane', 'Sydney', 'Melbourne', 'Perth', 'Adelaide', 'Canberra'])[((g - 1) % 6) + 1],
    NOW() - ((g % 2500) || ' days')::INTERVAL
FROM generate_series(1, 36000) AS gs(g);

INSERT INTO healthcare_visits (
    patient_id,
    attending_employee_id,
    visit_ts,
    visit_type,
    diagnosis_code,
    billing_amount
)
SELECT
    ((g * 13) % 36000) + 1,
    ((g * 19) % 2400) + 1,
    NOW() - ((g % 1400) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL,
    (ARRAY['CHECKUP', 'URGENT', 'FOLLOW_UP', 'SURGERY', 'REHAB'])[((g - 1) % 5) + 1],
    'D' || LPAD(((g * 31) % 9999)::TEXT, 4, '0'),
    (80 + ((g * 41) % 12000) / 10.0)::NUMERIC(12, 2)
FROM generate_series(1, 210000) AS gs(g);
