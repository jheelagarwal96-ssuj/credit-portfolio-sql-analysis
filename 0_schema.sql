-- Credit portfolio schema (SQLite). Data is SYNTHETIC, generated for practice. As-of date: 2026-09-30.
DROP TABLE IF EXISTS repayments; DROP TABLE IF EXISTS loans; DROP TABLE IF EXISTS customers;
CREATE TABLE customers (customer_id TEXT PRIMARY KEY, age INTEGER, city TEXT, income_band TEXT, employment_type TEXT, credit_score INTEGER);
CREATE TABLE loans (loan_id TEXT PRIMARY KEY, customer_id TEXT REFERENCES customers(customer_id), product_type TEXT, loan_amount INTEGER,
  interest_rate REAL, tenure_months INTEGER, disbursal_date TEXT, status TEXT CHECK(status IN ('Active','Closed','Defaulted')));
CREATE TABLE repayments (repayment_id TEXT PRIMARY KEY, loan_id TEXT REFERENCES loans(loan_id), installment_no INTEGER, due_date TEXT,
  paid_date TEXT, emi_amount INTEGER, paid_amount INTEGER, days_past_due INTEGER);
CREATE INDEX idx_loans_customer ON loans(customer_id); CREATE INDEX idx_rep_loan ON repayments(loan_id);
