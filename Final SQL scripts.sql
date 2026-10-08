-- =============================================================================
-- FINTRUST DIGITAL BANK - PRODUCTION ANALYTICS SCRIPT (WEEK 4 REFINED)
-- Dialect: ANSI SQL / PostgreSQL / MySQL 8.0+ / Snowflake
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. RFM Scoring & Dynamic Customer Segmentation
-- Purpose: Ranks active customers into behavioral quartiles and segment tiers.
-- -----------------------------------------------------------------------------
WITH Customer_RFM AS (
    SELECT 
        c.customer_id,
        c.customer_segment,
        MAX(t.transaction_datetime) AS last_transaction_date,
        COUNT(t.transaction_id) AS frequency,
        COALESCE(SUM(CASE WHEN t.transaction_status = 'Successful' THEN t.amount_ngn ELSE 0 END), 0) AS total_monetary_value
    FROM customers c
    LEFT JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY c.customer_id, c.customer_segment
),
RFM_Scores AS (
    SELECT 
        customer_id,
        customer_segment,
        frequency,
        total_monetary_value,
        NTILE(4) OVER (ORDER BY last_transaction_date ASC NULLS LAST) AS R_Score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS F_Score,
        NTILE(4) OVER (ORDER BY total_monetary_value ASC) AS M_Score
    FROM Customer_RFM
)
SELECT 
    customer_id,
    customer_segment,
    R_Score, F_Score, M_Score,
    (R_Score + F_Score + M_Score) AS Composite_RFM_Score,
    CASE 
        WHEN (R_Score + F_Score + M_Score) >= 10 THEN 'Champions / High Value'
        WHEN (R_Score + F_Score + M_Score) BETWEEN 7 AND 9 THEN 'Loyal Core'
        WHEN (R_Score + F_Score + M_Score) BETWEEN 4 AND 6 THEN 'At Risk / Developing'
        ELSE 'Hibernating / Low Engagement'
    END AS RFM_Segment
FROM RFM_Scores
ORDER BY Composite_RFM_Score DESC;


-- -----------------------------------------------------------------------------
-- 2. Channel Performance, Failure Rates & Processing Volume
-- Purpose: Evaluates technical channel reliability and throughput.
-- -----------------------------------------------------------------------------
SELECT 
    channel,
    COUNT(transaction_id) AS total_transactions,
    SUM(CASE WHEN transaction_status = 'Successful' THEN 1 ELSE 0 END) AS successful_transactions,
    SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions,
    ROUND(100.0 * SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(transaction_id), 0), 2) AS failure_rate_pct,
    ROUND(AVG(amount_ngn), 2) AS avg_transaction_amount,
    ROUND(SUM(CASE WHEN transaction_status = 'Successful' THEN amount_ngn ELSE 0 END), 2) AS total_successful_volume
FROM transactions
GROUP BY channel
ORDER BY total_successful_volume DESC;


-- -----------------------------------------------------------------------------
-- 3. Synthetic Risk Review Concentration by Segment & Channel
-- Purpose: Identifies operational risk hot spots across channels and demographics.
-- -----------------------------------------------------------------------------
SELECT 
    c.customer_segment,
    t.channel,
    COUNT(t.transaction_id) AS total_txns,
    SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_txns,
    ROUND(100.0 * SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN 1 ELSE 0 END) / NULLIF(COUNT(t.transaction_id), 0), 2) AS risk_flag_pct,
    ROUND(SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN t.amount_ngn ELSE 0 END), 2) AS flagged_volume
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.customer_segment, t.channel
ORDER BY risk_flag_pct DESC;


-- -----------------------------------------------------------------------------
-- 4. Month-over-Month (MoM) Growth & Risk Flag Trends
-- Purpose: Tracks volume trajectories and flags systematic risk acceleration.
-- -----------------------------------------------------------------------------
WITH Monthly_Summary AS (
    SELECT 
        DATE_TRUNC('month', transaction_datetime) AS txn_month,
        COUNT(transaction_id) AS monthly_txns,
        SUM(amount_ngn) AS monthly_volume,
        SUM(CASE WHEN risk_review_flag = 'Yes' THEN 1 ELSE 0 END) AS monthly_flagged_txns
    FROM transactions
    WHERE transaction_status = 'Successful'
    GROUP BY DATE_TRUNC('month', transaction_datetime)
)
SELECT 
    txn_month,
    monthly_txns,
    ROUND(monthly_volume, 2) AS monthly_volume,
    ROUND(LAG(monthly_volume, 1) OVER (ORDER BY txn_month), 2) AS prev_month_volume,
    ROUND(100.0 * (monthly_volume - LAG(monthly_volume, 1) OVER (ORDER BY txn_month)) / 
        NULLIF(LAG(monthly_volume, 1) OVER (ORDER BY txn_month), 0), 2) AS mom_volume_growth_pct,
    ROUND(100.0 * monthly_flagged_txns / NULLIF(monthly_txns, 0), 2) AS monthly_risk_flag_rate_pct
FROM Monthly_Summary
ORDER BY txn_month ASC;


-- -----------------------------------------------------------------------------
-- 5. Domestic vs. International Transaction Risk & Failure Profiling
-- Purpose: Compares baseline operational performance across geographic boundaries.
-- -----------------------------------------------------------------------------
SELECT 
    international_transaction,
    COUNT(t.transaction_id) AS total_transactions,
    ROUND(AVG(t.amount_ngn), 2) AS avg_amount,
    ROUND(SUM(t.amount_ngn), 2) AS total_amount,
    SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN 1 ELSE 0 END) AS total_risk_flagged,
    ROUND(100.0 * SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN 1 ELSE 0 END) / NULLIF(COUNT(t.transaction_id), 0), 2) AS risk_flag_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN t.transaction_status = 'Failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(t.transaction_id), 0), 2) AS failure_rate_pct
FROM transactions t
GROUP BY international_transaction;


-- -----------------------------------------------------------------------------
-- 6. High-Value Transaction (HVT) Statistical Outlier Identification
-- Purpose: Flags transactions exceeding 3 standard deviations from aggregate mean.
-- -----------------------------------------------------------------------------
WITH Stats AS (
    SELECT 
        AVG(amount_ngn) AS avg_amt,
        STDDEV(amount_ngn) AS stddev_amt
    FROM transactions
)
SELECT 
    t.transaction_id,
    t.customer_id,
    c.customer_segment,
    t.amount_ngn,
    t.channel,
    t.risk_review_flag,
    ROUND((t.amount_ngn - s.avg_amt) / NULLIF(s.stddev_amt, 0), 2) AS z_score
FROM transactions t
CROSS JOIN Stats s
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.amount_ngn > (s.avg_amt + (3 * s.stddev_amt))
ORDER BY t.amount_ngn DESC;


-- -----------------------------------------------------------------------------
-- 7. Customer Transaction Frequency & Velocity Tiering
-- Purpose: Groups users by activity throughput to quantify high-frequency value.
-- -----------------------------------------------------------------------------
WITH Customer_Velocity AS (
    SELECT 
        customer_id,
        COUNT(transaction_id) AS txn_count,
        SUM(amount_ngn) AS total_spent
    FROM transactions
    GROUP BY customer_id
),
Tiered_Velocity AS (
    SELECT 
        customer_id,
        txn_count,
        total_spent,
        CASE 
            WHEN txn_count >= 15 THEN 'High Velocity (>=15 Txns)'
            WHEN txn_count BETWEEN 8 AND 14 THEN 'Medium Velocity (8-14 Txns)'
            ELSE 'Low Velocity (<8 Txns)'
        END AS velocity_tier
    FROM Customer_Velocity
)
SELECT 
    velocity_tier,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_spent), 2) AS avg_customer_spend,
    ROUND(AVG(txn_count), 1) AS avg_txn_count_per_cust
FROM Tiered_Velocity
GROUP BY velocity_tier
ORDER BY avg_customer_spend DESC;


-- -----------------------------------------------------------------------------
-- 8. Digital Engagement Score vs. Financial Activity & Risk Correlation
-- Purpose: Evaluates if app/digital engagement correlates with higher spend/risk.
-- -----------------------------------------------------------------------------
WITH Digital_Engagement_Tiers AS (
    SELECT 
        c.customer_id,
        c.customer_segment,
        c.digital_engagement_score,
        CASE 
            WHEN c.digital_engagement_score >= 80 THEN 'High Engagement (80-100)'
            WHEN c.digital_engagement_score BETWEEN 50 AND 79.9 THEN 'Moderate Engagement (50-79)'
            ELSE 'Low Engagement (<50)'
        END AS engagement_tier,
        COUNT(t.transaction_id) AS total_txns,
        SUM(CASE WHEN t.transaction_status = 'Successful' THEN t.amount_ngn ELSE 0 END) AS total_spend,
        SUM(CASE WHEN t.risk_review_flag = 'Yes' THEN 1 ELSE 0 END) AS flagged_txns
    FROM customers c
    LEFT JOIN transactions t ON c.customer_id = t.customer_id
    GROUP BY c.customer_id, c.customer_segment, c.digital_engagement_score
)
SELECT 
    engagement_tier,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_txns), 1) AS avg_txns_per_customer,
    ROUND(AVG(total_spend), 2) AS avg_spend_per_customer,
    ROUND(100.0 * SUM(flagged_txns) / NULLIF(SUM(total_txns), 0), 2) AS risk_flag_pct
FROM Digital_Engagement_Tiers
GROUP BY engagement_tier
ORDER BY avg_spend_per_customer DESC;