INSERT INTO social_users (employee_id, username, reputation, created_at)
SELECT
    CASE WHEN g <= 2400 THEN g ELSE NULL END,
    'user_' || g,
    ((g * 53) % 30000),
    NOW() - ((g % 1800) || ' days')::INTERVAL
FROM generate_series(1, 70000) AS gs(g);

INSERT INTO social_posts (user_id, topic, body, score, created_at)
SELECT
    ((g * 13) % 70000) + 1,
    (ARRAY['sql', 'postgres', 'tuning', 'schema', 'transactions', 'joins'])[((g - 1) % 6) + 1],
    'Post body ' || g,
    ((g * 11) % 4000) - 200,
    NOW() - ((g % 1100) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL
FROM generate_series(1, 240000) AS gs(g);

INSERT INTO social_comments (post_id, user_id, body, score, created_at)
SELECT
    ((g * 17) % 240000) + 1,
    ((g * 19) % 70000) + 1,
    'Comment ' || g,
    ((g * 7) % 300) - 30,
    NOW() - ((g % 1100) || ' days')::INTERVAL - ((g % 86400) || ' seconds')::INTERVAL
FROM generate_series(1, 420000) AS gs(g);
