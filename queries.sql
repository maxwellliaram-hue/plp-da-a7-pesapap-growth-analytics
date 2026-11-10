-- =====================================================================
-- PesaPap growth analytics: SQL queries (SQLite dialect)
-- Tables: users(user_id PK), transactions(txn_id PK, user_id FK -> users),
--         experiment(user_id PK/FK -> users)
-- Each query block starts with a marker line "-- ===== <id> =====" so the
-- notebook can split this file and run every query through pd.read_sql.
-- =====================================================================

-- ===== validation =====
-- Business question: How many transactions happen BEFORE the user's signup
-- date (impossible in a real product), and what share of the ledger and of
-- value do they represent?
SELECT COUNT(*)                                            AS txns_before_signup,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM transactions), 2) AS pct_of_all_txns,
       SUM(t.amount)                                       AS value_before_signup_kes,
       COUNT(DISTINCT t.user_id)                           AS users_affected
FROM transactions t
JOIN users u ON u.user_id = t.user_id
WHERE t.txn_date < u.signup_date;

-- ===== a =====
-- Business question (a): What is the total transaction value and the number
-- of transactions for each product?
SELECT product,
       COUNT(*)      AS txn_count,
       SUM(amount)   AS total_value_kes
FROM transactions
GROUP BY product
ORDER BY total_value_kes DESC;

-- ===== b =====
-- Business question (b): Which five counties generate the most transaction
-- value?
SELECT u.county,
       SUM(t.amount) AS total_value_kes,
       COUNT(*)      AS txn_count
FROM transactions t
JOIN users u ON u.user_id = t.user_id
GROUP BY u.county
ORDER BY total_value_kes DESC
LIMIT 5;

-- ===== c =====
-- Business question (c): How does monthly transaction value evolve, and what
-- is the cumulative (running) value over time?
SELECT strftime('%Y-%m', txn_date)                         AS month,
       SUM(amount)                                         AS monthly_value_kes,
       SUM(SUM(amount)) OVER (ORDER BY strftime('%Y-%m', txn_date)) AS running_total_kes
FROM transactions
GROUP BY strftime('%Y-%m', txn_date)
ORDER BY month;

-- ===== d =====
-- Business question (d): Which acquisition channels bring the most
-- transaction value (and how much per transaction)?
SELECT u.acquisition_channel,
       COUNT(*)                   AS txn_count,
       SUM(t.amount)              AS total_value_kes,
       ROUND(AVG(t.amount), 0)    AS avg_txn_value_kes
FROM transactions t
JOIN users u ON u.user_id = t.user_id
GROUP BY u.acquisition_channel
ORDER BY total_value_kes DESC;

-- ===== e =====
-- Business question (e): Who are the ten highest-value users, ranked by total
-- transaction value?
SELECT user_id,
       total_value_kes,
       RANK() OVER (ORDER BY total_value_kes DESC) AS value_rank
FROM (
    SELECT user_id, SUM(amount) AS total_value_kes
    FROM transactions
    GROUP BY user_id
)
ORDER BY value_rank
LIMIT 10;

-- ===== f =====
-- Business question (f): Which products have an average transaction value
-- above KES 1,300?
SELECT product,
       ROUND(AVG(amount), 1) AS avg_txn_value_kes,
       COUNT(*)              AS txn_count
FROM transactions
GROUP BY product
HAVING AVG(amount) > 1300
ORDER BY avg_txn_value_kes DESC;

-- ===== g =====
-- Business question (g): How many users fall into each value tier
-- (High >= KES 10,000; Medium >= KES 4,000; otherwise Low), based on lifetime
-- transaction value? Users with no transactions count as Low (value 0).
-- LAG shows the gap in user count versus the tier listed just above.
WITH user_value AS (
    SELECT u.user_id,
           COALESCE(SUM(t.amount), 0) AS total_value
    FROM users u
    LEFT JOIN transactions t ON t.user_id = u.user_id
    GROUP BY u.user_id
),
tiered AS (
    SELECT user_id,
           CASE WHEN total_value >= 10000 THEN 'High'
                WHEN total_value >= 4000  THEN 'Medium'
                ELSE 'Low' END AS value_tier
    FROM user_value
),
tier_counts AS (
    SELECT value_tier,
           COUNT(*) AS users,
           CASE value_tier WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END AS tier_order
    FROM tiered
    GROUP BY value_tier
)
SELECT value_tier,
       users,
       users - LAG(users) OVER (ORDER BY tier_order) AS change_vs_tier_above
FROM tier_counts
ORDER BY tier_order;

-- ===== h =====
-- Business question (h): How does the number of active users (distinct users
-- transacting) change month over month, in absolute and percentage terms?
-- NOTE: January (data starts 15 Jan) and June (data ends 13 Jun) are partial.
WITH monthly_active AS (
    SELECT strftime('%Y-%m', txn_date) AS month,
           COUNT(DISTINCT user_id)     AS active_users
    FROM transactions
    GROUP BY strftime('%Y-%m', txn_date)
),
with_lag AS (
    SELECT month,
           active_users,
           LAG(active_users) OVER (ORDER BY month) AS prev_active_users
    FROM monthly_active
)
SELECT month,
       active_users,
       prev_active_users,
       active_users - prev_active_users AS change,
       CASE WHEN prev_active_users IS NULL THEN NULL
            ELSE ROUND(100.0 * (active_users - prev_active_users) / prev_active_users, 1)
       END AS pct_change,
       CASE WHEN prev_active_users IS NULL THEN 'n/a (first month)'
            WHEN active_users > prev_active_users THEN 'Growth'
            WHEN active_users < prev_active_users THEN 'Decline'
            ELSE 'Flat' END AS direction
FROM with_lag
ORDER BY month;
