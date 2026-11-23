# Credit Portfolio Analysis (SQL)

## Problem
Which loan products, cities and credit-score groups carry the most default risk in a lending portfolio, and where should a lender look first?

## Data
A **synthetic** dataset I generated for practice (not real customer data):
- 1,200 customers, 1,800 loans, 27,190 monthly repayments
- As-of date: 30 Sep 2026
- Files are in the `data` folder (CSV files and a SQLite database)

## Method and tools
- SQLite (queried through DB Browser for SQLite)
- 13 queries using JOINs, GROUP BY/HAVING, CASE, CTEs and window functions (SUM OVER, LAG, ROW_NUMBER, NTILE)
- Analyses: default rate by product, city and credit score; delinquency buckets; vintage analysis; early-warning list

## Key findings
1. Personal Loans default most (12.8%), while Home Loans default least (1.8%) but make up about 57% of money disbursed.
2. Credit scores below 600 default at 14.9%, about double the other bands (7-9%).
3. 6.0% of the live loan book is 90+ days past due.

## How to run
Open `data/credit_portfolio.db` in DB Browser for SQLite and run the queries in `2_SQL_Credit_Portfolio_Queries.sql`.
