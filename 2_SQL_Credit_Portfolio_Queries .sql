-- =====================================================================
-- Credit Portfolio Analysis | SQL proof of work (SQLite)
-- Dataset: SYNTHETIC (generated for practice). As-of date: 2026-09-30.
-- Tables: customers, loans, repayments. Setup: see 0_schema.sql / credit_portfolio.db
-- Skills shown: JOINs, GROUP BY/HAVING, CASE, CTEs, window functions
--               (SUM OVER, LAG, RANK/ROW_NUMBER, NTILE), subqueries.
-- =====================================================================

-- Q1. Portfolio overview
SELECT COUNT(*)                         AS total_loans,
       COUNT(DISTINCT customer_id)      AS borrowers,
       SUM(loan_amount)                 AS total_disbursed,
       ROUND(AVG(loan_amount), 0)       AS avg_ticket_size,
       ROUND(AVG(interest_rate), 2)     AS avg_interest_rate
FROM loans;

-- Q2. Default rate by product (which product carries the most risk?)
SELECT product_type,
       COUNT(*)                                                    AS loans,
       SUM(loan_amount)                                            AS disbursed,
       SUM(CASE WHEN status = 'Defaulted' THEN 1 ELSE 0 END)       AS defaults,
       ROUND(100.0 * SUM(CASE WHEN status = 'Defaulted' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY product_type
ORDER BY default_rate_pct DESC;

-- Q3. Default rate by credit score band (does the score separate good from bad?)
SELECT CASE WHEN c.credit_score < 600 THEN '1. Below 600'
            WHEN c.credit_score < 700 THEN '2. 600-699'
            WHEN c.credit_score < 750 THEN '3. 700-749'
            ELSE '4. 750+' END                                     AS score_band,
       COUNT(*)                                                    AS loans,
       ROUND(100.0 * SUM(l.status = 'Defaulted') / COUNT(*), 2)    AS default_rate_pct
FROM loans l
JOIN customers c ON c.customer_id = l.customer_id
GROUP BY score_band
ORDER BY score_band;

-- Q4. City performance: disbursement vs default rate (HAVING filters small samples)
SELECT c.city,
       COUNT(*)                                                    AS loans,
       SUM(l.loan_amount)                                          AS disbursed,
       ROUND(100.0 * SUM(l.status = 'Defaulted') / COUNT(*), 2)    AS default_rate_pct
FROM loans l
JOIN customers c ON c.customer_id = l.customer_id
GROUP BY c.city
HAVING COUNT(*) >= 50
ORDER BY disbursed DESC;

-- Q5. Monthly disbursement with running total (window SUM OVER)
WITH monthly AS (
  SELECT strftime('%Y-%m', disbursal_date) AS month, SUM(loan_amount) AS disbursed
  FROM loans GROUP BY 1
)
SELECT month, disbursed,
       SUM(disbursed) OVER (ORDER BY month) AS running_total
FROM monthly
ORDER BY month;

-- Q6. Month-on-month disbursement growth (LAG)
WITH monthly AS (
  SELECT strftime('%Y-%m', disbursal_date) AS month, SUM(loan_amount) AS disbursed
  FROM loans GROUP BY 1
)
SELECT month, disbursed,
       LAG(disbursed) OVER (ORDER BY month)                         AS prev_month,
       ROUND(100.0 * (disbursed - LAG(disbursed) OVER (ORDER BY month))
             / LAG(disbursed) OVER (ORDER BY month), 1)             AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q7. Top 3 largest loans in each product (ROW_NUMBER with PARTITION BY)
WITH ranked AS (
  SELECT loan_id, product_type, loan_amount, status,
         ROW_NUMBER() OVER (PARTITION BY product_type ORDER BY loan_amount DESC) AS rn
  FROM loans
)
SELECT product_type, rn AS rank_in_product, loan_id, loan_amount, status
FROM ranked
WHERE rn <= 3
ORDER BY product_type, rn;

-- Q8. Delinquency buckets for live book (current DPD = oldest unpaid installment)
WITH cur AS (
  SELECT l.loan_id, l.loan_amount,
         COALESCE(MAX(CASE WHEN r.paid_date IS NULL THEN r.days_past_due END), 0) AS current_dpd
  FROM loans l
  LEFT JOIN repayments r ON r.loan_id = l.loan_id
  WHERE l.status <> 'Closed'
  GROUP BY l.loan_id, l.loan_amount
)
SELECT CASE WHEN current_dpd = 0   THEN '0 (current)'
            WHEN current_dpd <= 30 THEN '1-30'
            WHEN current_dpd <= 60 THEN '31-60'
            WHEN current_dpd <= 90 THEN '61-90'
            ELSE '90+' END                                           AS dpd_bucket,
       COUNT(*)                                                      AS loans,
       SUM(loan_amount)                                              AS exposure,
       ROUND(100.0 * SUM(loan_amount) / SUM(SUM(loan_amount)) OVER (), 2) AS pct_of_book
FROM cur
GROUP BY dpd_bucket
ORDER BY MIN(current_dpd);

-- Q9. Customers with 3+ loans and their total exposure
SELECT c.customer_id, c.city, c.credit_score,
       COUNT(*)            AS loans,
       SUM(l.loan_amount)  AS total_exposure
FROM customers c
JOIN loans l ON l.customer_id = c.customer_id
GROUP BY c.customer_id, c.city, c.credit_score
HAVING COUNT(*) >= 3
ORDER BY total_exposure DESC
LIMIT 10;

-- Q10. Vintage analysis: default rate by disbursal quarter
SELECT strftime('%Y', disbursal_date) || '-Q' || ((CAST(strftime('%m', disbursal_date) AS INTEGER) + 2) / 3) AS vintage,
       COUNT(*)                                                    AS loans,
       ROUND(100.0 * SUM(status = 'Defaulted') / COUNT(*), 2)      AS default_rate_pct
FROM loans
GROUP BY vintage
ORDER BY vintage;

-- Q11. Portfolio at risk >30 days (PAR30) by city, using disbursed amount as exposure proxy
WITH cur AS (
  SELECT l.loan_id, l.customer_id, l.loan_amount,
         COALESCE(MAX(CASE WHEN r.paid_date IS NULL THEN r.days_past_due END), 0) AS current_dpd
  FROM loans l LEFT JOIN repayments r ON r.loan_id = l.loan_id
  WHERE l.status <> 'Closed'
  GROUP BY l.loan_id, l.customer_id, l.loan_amount
)
SELECT c.city,
       SUM(cur.loan_amount)                                                        AS live_exposure,
       SUM(CASE WHEN cur.current_dpd > 30 THEN cur.loan_amount ELSE 0 END)         AS exposure_over_30dpd,
       ROUND(100.0 * SUM(CASE WHEN cur.current_dpd > 30 THEN cur.loan_amount ELSE 0 END)
             / SUM(cur.loan_amount), 2)                                            AS par30_pct
FROM cur
JOIN customers c ON c.customer_id = cur.customer_id
GROUP BY c.city
ORDER BY par30_pct DESC;

-- Q12. Default rate by credit-score quartile (NTILE)
WITH scored AS (
  SELECT l.status, c.credit_score,
         NTILE(4) OVER (ORDER BY c.credit_score) AS quartile
  FROM loans l JOIN customers c ON c.customer_id = l.customer_id
)
SELECT quartile, MIN(credit_score) AS min_score, MAX(credit_score) AS max_score,
       COUNT(*) AS loans,
       ROUND(100.0 * SUM(status = 'Defaulted') / COUNT(*), 2) AS default_rate_pct
FROM scored
GROUP BY quartile
ORDER BY quartile;

-- Q13. Early-warning list: live loans with 2+ late payments (paid >10 days late) that have not defaulted yet
SELECT l.loan_id, l.product_type, l.loan_amount, c.credit_score,
       COUNT(*)                  AS late_payments,
       MAX(r.days_past_due)      AS worst_delay_days
FROM loans l
JOIN repayments r ON r.loan_id = l.loan_id
JOIN customers c  ON c.customer_id = l.customer_id
WHERE l.status = 'Active'
  AND r.paid_date IS NOT NULL
  AND r.days_past_due > 10
GROUP BY l.loan_id, l.product_type, l.loan_amount, c.credit_score
HAVING COUNT(*) >= 2
ORDER BY late_payments DESC, worst_delay_days DESC
LIMIT 10;
